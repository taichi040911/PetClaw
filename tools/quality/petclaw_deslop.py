#!/usr/bin/env python3
"""
PetClaw Deslop Tool
Detects AI-generated GDScript "slop" patterns and code quality issues.
Inspired by agentsys's /deslop command.
"""

import click
import json
import sys
import os
import re
from pathlib import Path
from typing import List, Dict, Any, Tuple
from collections import defaultdict

# Result types
class Issue:
    def __init__(self, level: str, rule: str, file: str, line: int, detail: str):
        self.level = level  # FAIL, WARN, INFO
        self.rule = rule
        self.file = file
        self.line = line
        self.detail = detail
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            'level': self.level,
            'rule': self.rule,
            'file': self.file,
            'line': self.line,
            'detail': self.detail
        }


class DesloppingResult:
    def __init__(self):
        self.issues: List[Issue] = []
        self.files_scanned = 0
    
    def add_issue(self, level: str, rule: str, file: str, line: int, detail: str):
        self.issues.append(Issue(level, rule, file, line, detail))
    
    def count_by_level(self) -> Tuple[int, int, int]:
        """Returns (fails, warns, infos)"""
        fails = sum(1 for i in self.issues if i.level == 'FAIL')
        warns = sum(1 for i in self.issues if i.level == 'WARN')
        infos = sum(1 for i in self.issues if i.level == 'INFO')
        return fails, warns, infos
    
    def has_failures(self) -> bool:
        return any(i.level == 'FAIL' for i in self.issues)
    
    def summary(self) -> str:
        fails, warns, infos = self.count_by_level()
        total = len(self.issues)
        return f"Scanned {self.files_scanned} files: {total} issues ({fails} FAIL, {warns} WARN, {infos} INFO)"


def scan_gd_files(scripts_dir: Path) -> List[Path]:
    """Find all .gd files in scripts directory."""
    if not scripts_dir.exists():
        return []
    return sorted(scripts_dir.rglob('*.gd'))


def analyze_file(file_path: Path, result: DesloppingResult):
    """Analyze a single GDScript file for slop patterns."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
    except Exception as e:
        result.add_issue('WARN', 'FILE_READ_ERROR', str(file_path), 0, str(e))
        return
    
    result.files_scanned += 1
    
    # Phase 1: Pattern Detection
    phase1_patterns(file_path, lines, result)
    
    # Phase 2: Structure Analysis
    phase2_structure(file_path, lines, result)
    
    # Phase 3: PetClaw-Specific
    phase3_petclaw(file_path, lines, result)


def phase1_patterns(file_path: Path, lines: List[str], result: DesloppingResult):
    """Phase 1: Regex pattern detection."""
    
    # EXCESSIVE_COMMENTS
    comment_lines = sum(1 for line in lines if re.match(r'^\s*#', line))
    code_lines = len(lines) - comment_lines - sum(1 for line in lines if line.strip() == '')
    if code_lines > 0 and comment_lines > code_lines:
        result.add_issue('WARN', 'EXCESSIVE_COMMENTS', str(file_path), 0,
                        f"Comment lines ({comment_lines}) > code lines ({code_lines})")
    
    # DEBUG_PRINTS
    for i, line in enumerate(lines, 1):
        if re.search(r'print\s*\(', line):
            if any(keyword in line.upper() for keyword in ['DEBUG', 'TODO', 'FIXME', 'TEST']):
                result.add_issue('WARN', 'DEBUG_PRINTS', str(file_path), i,
                                f"Debug print found: {line.strip()[:60]}")
    
    # EMPTY_MATCH_BRANCH
    for i, line in enumerate(lines, 1):
        if re.search(r'^\s*pass\s*$', line):
            # Check if previous line is a match branch
            if i > 1 and (re.search(r'^\s*\w+\s*:', lines[i-2]) or 
                         re.search(r'^\s*_\s*:', lines[i-2])):
                result.add_issue('WARN', 'EMPTY_MATCH_BRANCH', str(file_path), i,
                                "Empty match branch with only 'pass'")
    
    # REDUNDANT_NULL_CHECK
    for i, line in enumerate(lines, 1):
        if re.search(r'if\s+(\w+)\s*!=\s*null\s+and\s+\1\.', line):
            result.add_issue('INFO', 'REDUNDANT_NULL_CHECK', str(file_path), i,
                            f"Redundant null check: {line.strip()[:60]}")
    
    # TRAILING_WHITESPACE
    for i, line in enumerate(lines, 1):
        if line.rstrip('\n') != line.rstrip('\n').rstrip():
            result.add_issue('INFO', 'TRAILING_WHITESPACE', str(file_path), i,
                            "Line has trailing whitespace")


def phase2_structure(file_path: Path, lines: List[str], result: DesloppingResult):
    """Phase 2: Structure analysis."""
    
    content = ''.join(lines)
    
    # MISSING_CLASS_NAME
    if 'class_name ' not in content:
        result.add_issue('FAIL', 'MISSING_CLASS_NAME', str(file_path), 1,
                        "Missing 'class_name' declaration")
    
    # DEEP_NESTING and LONG_FUNCTION
    in_function = False
    func_start = 0
    func_lines = 0
    max_indent = 0
    
    for i, line in enumerate(lines, 1):
        # Check for function definition
        if re.match(r'^\s*func\s+\w+', line):
            if in_function:
                # End previous function
                if func_lines > 50:
                    result.add_issue('WARN', 'LONG_FUNCTION', str(file_path), func_start,
                                    f"Function is {func_lines} lines (exceeds 50)")
            in_function = True
            func_start = i
            func_lines = 0
            max_indent = 0
        
        if in_function:
            func_lines += 1
            # Count indentation
            indent = len(line) - len(line.lstrip())
            tabs = line[:indent].count('\t')
            spaces = (indent - tabs * 4) // 4  # Assume tab = 4 spaces
            total_indent = tabs + spaces
            
            if total_indent > 4:
                result.add_issue('WARN', 'DEEP_NESTING', str(file_path), i,
                                f"Deep nesting level {total_indent}")
    
    # Check last function
    if in_function and func_lines > 50:
        result.add_issue('WARN', 'LONG_FUNCTION', str(file_path), func_start,
                        f"Function is {func_lines} lines (exceeds 50)")
    
    # MISSING_TYPE_ANNOTATION
    for i, line in enumerate(lines, 1):
        if re.search(r'func\s+\w+\s*\([^)]*\)', line):
            # Check for parameters without type hints
            if re.search(r'func\s+\w+\s*\(\s*\w+\s*(?:,|\))', line):
                # Parameter without type hint
                result.add_issue('WARN', 'MISSING_TYPE_ANNOTATION', str(file_path), i,
                                f"Function parameter without type: {line.strip()[:60]}")
    
    # UNSAFE_GAMEMANAGER
    for i, line in enumerate(lines, 1):
        if 'GameManager.instance' in line:
            # Check if there's a null check in previous lines
            has_null_check = False
            for j in range(max(0, i-5), i):
                if 'GameManager.instance' in lines[j-1] and 'null' in lines[j-1]:
                    has_null_check = True
            
            if not has_null_check and 'if' not in line:
                result.add_issue('FAIL', 'UNSAFE_GAMEMANAGER', str(file_path), i,
                                f"GameManager.instance access without null check: {line.strip()[:60]}")


def phase3_petclaw(file_path: Path, lines: List[str], result: DesloppingResult):
    """Phase 3: PetClaw-specific patterns."""
    
    content = ''.join(lines)
    
    # MISSING_SAVE_LOAD: class with state vars but no to_dict/from_dict
    has_vars = bool(re.search(r'var\s+\w+\s*:', content))
    has_to_dict = 'func to_dict' in content
    has_from_dict = 'func from_dict' in content
    
    if has_vars and (not has_to_dict or not has_from_dict):
        result.add_issue('WARN', 'MISSING_SAVE_LOAD', str(file_path), 1,
                        "Class has state variables but no to_dict/from_dict methods")
    
    # ORPHAN_SIGNAL: signal declared but never emitted
    signal_matches = re.finditer(r'signal\s+(\w+)', content)
    for match in signal_matches:
        signal_name = match.group(1)
        if f'emit_signal("{signal_name}"' not in content and f"emit_signal('{signal_name}'" not in content:
            line_num = content[:match.start()].count('\n') + 1
            result.add_issue('WARN', 'ORPHAN_SIGNAL', str(file_path), line_num,
                            f"Signal '{signal_name}' declared but never emitted")
    
    # EMOTION_RANGE: emotion values outside 0.0-1.0
    emotion_vars = ['happiness', 'sadness', 'hunger', 'energy', 'affection', 'stress']
    for emotion in emotion_vars:
        for i, line in enumerate(lines, 1):
            if emotion in line.lower():
                # Look for assignments like "= 1.5" or "= -0.1"
                if re.search(rf'{emotion}\s*=\s*(-?\d+\.?\d*)', line):
                    match = re.search(rf'{emotion}\s*=\s*(-?\d+\.?\d*)', line)
                    if match:
                        value = float(match.group(1))
                        if value < 0.0 or value > 1.0:
                            result.add_issue('FAIL', 'EMOTION_RANGE', str(file_path), i,
                                            f"Emotion '{emotion}' value {value} outside [0.0, 1.0]")


@click.command()
@click.option('--project-root', type=click.Path(exists=True), default=None,
              help='Project root directory')
@click.option('--scripts-dir', type=click.Path(exists=True), default=None,
              help='Scripts directory (defaults to godot_project/scripts)')
@click.option('--json', 'output_json', is_flag=True, help='Output results as JSON')
def main(project_root: str, scripts_dir: str, output_json: bool):
    """
    Detect AI-generated GDScript "slop" patterns.
    
    Phases:
    1. Pattern Detection (comments, debug prints, empty branches)
    2. Structure Analysis (nesting, function length, type annotations)
    3. PetClaw-Specific (save/load, signals, emotion ranges)
    """
    
    if not scripts_dir:
        if project_root:
            scripts_dir = os.path.join(project_root, 'godot_project', 'scripts')
        else:
            scripts_dir = os.path.join(os.path.dirname(__file__), '..', '..', 'godot_project', 'scripts')
    
    scripts_path = Path(scripts_dir)
    
    result = DesloppingResult()
    
    # Find and analyze all .gd files
    gd_files = scan_gd_files(scripts_path)
    if not gd_files:
        click.echo(f"No .gd files found in {scripts_path}")
        sys.exit(0)
    
    for gd_file in gd_files:
        analyze_file(gd_file, result)
    
    # Output
    if output_json:
        fails, warns, infos = result.count_by_level()
        output = {
            'files_scanned': result.files_scanned,
            'issues': [issue.to_dict() for issue in result.issues],
            'summary': {
                'total': len(result.issues),
                'fails': fails,
                'warnings': warns,
                'infos': infos
            }
        }
        click.echo(json.dumps(output, indent=2, ensure_ascii=False))
    else:
        for issue in result.issues:
            click.echo(f"[{issue.level}] {issue.rule} ({issue.file}:{issue.line}): {issue.detail}")
        click.echo()
        click.echo(result.summary())
    
    sys.exit(1 if result.has_failures() else 0)


if __name__ == '__main__':
    main()
