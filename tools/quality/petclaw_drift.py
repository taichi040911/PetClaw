#!/usr/bin/env python3
"""
PetClaw Drift Detection Tool
Detects drift between design docs and implementation.
Inspired by agentsys's /drift-detect command.
"""

import click
import json
import sys
import os
import re
from pathlib import Path
from typing import List, Dict, Set, Tuple, Any

# Result types
class DriftCheck:
    def __init__(self, category: str, description: str, status: str, certainty: str, detail: str):
        self.category = category
        self.description = description
        self.status = status  # MATCH, DRIFT, MISSING
        self.certainty = certainty  # HIGH, MEDIUM, LOW
        self.detail = detail
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            'category': self.category,
            'description': self.description,
            'status': self.status,
            'certainty': self.certainty,
            'detail': self.detail
        }


class DriftResult:
    def __init__(self):
        self.checks: List[DriftCheck] = []
    
    def add_check(self, category: str, description: str, status: str, certainty: str, detail: str):
        self.checks.append(DriftCheck(category, description, status, certainty, detail))
    
    def count_by_status(self) -> Tuple[int, int, int]:
        """Returns (matches, drifts, missing)"""
        matches = sum(1 for c in self.checks if c.status == 'MATCH')
        drifts = sum(1 for c in self.checks if c.status == 'DRIFT')
        missing = sum(1 for c in self.checks if c.status == 'MISSING')
        return matches, drifts, missing
    
    def has_drift(self) -> bool:
        return any(c.status in ['DRIFT', 'MISSING'] for c in self.checks)
    
    def summary(self) -> str:
        matches, drifts, missing = self.count_by_status()
        total = len(self.checks)
        return f"Drift check complete: {total} checks ({matches} MATCH, {drifts} DRIFT, {missing} MISSING)"


def extract_signals_from_doc(doc_content: str) -> Set[str]:
    """Extract signal names from architecture documentation."""
    signals = set()
    
    # Look for signal definitions like:
    # - signal_name (...)
    # signal: signal_name
    # Signals: signal_name, other_signal
    
    # Pattern 1: "signal: name" or "signal_name"
    signal_patterns = [
        r'signal\s*:\s*(\w+)',
        r'(?:signal|emit)\s+(\w+)\(',
        r'- (\w+)\s*signal',
        r'"(\w+)"\s*:\s*"signal"'
    ]
    
    for pattern in signal_patterns:
        matches = re.finditer(pattern, doc_content, re.IGNORECASE)
        for match in matches:
            signals.add(match.group(1))
    
    return signals


def extract_systems_from_doc(doc_content: str) -> Set[str]:
    """Extract system names from architecture documentation."""
    systems = set()
    
    # Look for system listings like:
    # - SystemName
    # ## System: SystemName
    # systems: system1, system2
    
    system_patterns = [
        r'##\s+(\w+)\s*System',
        r'System\s*:\s*(\w+)',
        r'-\s+(\w+)\s+(?:system|manager)',
        r'`(\w+)System`',
        r'"(\w+)"\s*:\s*"system"'
    ]
    
    for pattern in system_patterns:
        matches = re.finditer(pattern, doc_content, re.IGNORECASE)
        for match in matches:
            systems.add(match.group(1))
    
    return systems


def extract_directory_structure(doc_content: str) -> List[str]:
    """Extract directory structure paths from documentation."""
    paths = []
    
    # Look for markdown code blocks with directory structure
    code_blocks = re.findall(r'```(?:.*?)?\n(.*?)```', doc_content, re.DOTALL)
    
    for block in code_blocks:
        lines = block.split('\n')
        for line in lines:
            # Match lines like:
            # godot_project/scripts/
            # knowledge_base/
            # /path/to/something
            match = re.search(r'([a-zA-Z_/]+/(?:[a-zA-Z_/]+)*)', line)
            if match:
                paths.append(match.group(1))
    
    return paths


def check_signal_drift(doc_content: str, scripts_dir: Path, result: DriftResult):
    """Check if documented signals exist in implementation."""
    signals = extract_signals_from_doc(doc_content)
    
    if not signals:
        result.add_check('Signal Drift', 'No signals found in documentation',
                        'MISSING', 'LOW', 'Documentation may be incomplete')
        return
    
    # Search for signal definitions in .gd files
    found_signals = set()
    if scripts_dir.exists():
        for gd_file in scripts_dir.rglob('*.gd'):
            try:
                with open(gd_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                    for signal in signals:
                        if f'signal {signal}' in content or f'signal "{signal}"' in content:
                            found_signals.add(signal)
            except Exception:
                pass
    
    for signal in signals:
        if signal in found_signals:
            result.add_check('Signal Drift', f'Signal "{signal}"',
                            'MATCH', 'HIGH', 'Found in implementation')
        else:
            result.add_check('Signal Drift', f'Signal "{signal}"',
                            'DRIFT', 'MEDIUM', 'Documented but not found in code')


def check_system_drift(doc_content: str, scripts_dir: Path, result: DriftResult):
    """Check if documented systems have corresponding files."""
    systems = extract_systems_from_doc(doc_content)
    
    if not systems:
        result.add_check('System Listing Drift', 'No systems found in documentation',
                        'MISSING', 'LOW', 'Documentation may be incomplete')
        return
    
    # Look for system files (e.g., GameManager.gd, AIManager.gd, etc.)
    system_files = set()
    if scripts_dir.exists():
        for gd_file in scripts_dir.glob('*.gd'):
            system_files.add(gd_file.stem)
    
    for system in systems:
        system_file_name = f"{system}"
        possible_names = [
            system_file_name,
            f"{system}Manager",
            f"{system}System",
            system_file_name.lower(),
        ]
        
        found = any(name in system_files for name in possible_names)
        
        if found:
            result.add_check('System Listing Drift', f'System "{system}"',
                            'MATCH', 'HIGH', f'Found in scripts: {possible_names}')
        else:
            result.add_check('System Listing Drift', f'System "{system}"',
                            'DRIFT', 'MEDIUM', f'Not found as {possible_names}')


def check_file_structure_drift(doc_content: str, project_root: Path, result: DriftResult):
    """Check if documented directory structure matches actual filesystem."""
    documented_paths = extract_directory_structure(doc_content)
    
    if not documented_paths:
        result.add_check('File Structure Drift', 'No directory structure found in docs',
                        'MISSING', 'LOW', 'Documentation may lack structure section')
        return
    
    for path in documented_paths:
        full_path = project_root / path
        if full_path.exists():
            result.add_check('File Structure Drift', f'Path "{path}"',
                            'MATCH', 'HIGH', 'Path exists in filesystem')
        else:
            result.add_check('File Structure Drift', f'Path "{path}"',
                            'DRIFT', 'MEDIUM', f'Not found at {full_path}')


def check_dependency_drift(doc_content: str, scripts_dir: Path, result: DriftResult):
    """Check if documented dependencies exist in code."""
    
    # Look for dependency matrix or dependency mentions
    dependency_patterns = [
        r'depends?\s+on\s+(\w+)',
        r'(\w+)\s+→\s+(\w+)',
        r'requires?\s+(\w+)',
    ]
    
    dependencies = set()
    for pattern in dependency_patterns:
        matches = re.finditer(pattern, doc_content, re.IGNORECASE)
        for match in matches:
            if len(match.groups()) == 1:
                dependencies.add(match.group(1))
            else:
                dependencies.add(match.group(2))
    
    if not dependencies:
        result.add_check('Dependency Matrix Drift', 'No dependencies found in documentation',
                        'MISSING', 'LOW', 'Documentation may lack dependency section')
        return
    
    # Check if dependencies reference existing systems
    systems = extract_systems_from_doc(doc_content)
    
    for dep in dependencies:
        # Check if it's a known system
        if dep in systems or any(dep.lower() in s.lower() for s in systems):
            result.add_check('Dependency Matrix Drift', f'Dependency "{dep}"',
                            'MATCH', 'MEDIUM', 'Referenced system exists')
        else:
            result.add_check('Dependency Matrix Drift', f'Dependency "{dep}"',
                            'DRIFT', 'LOW', f'No system found matching "{dep}"')


@click.command()
@click.option('--project-root', type=click.Path(exists=True), default=None,
              help='Project root directory')
@click.option('--architecture-doc', type=click.Path(exists=True), default=None,
              help='Path to architecture document (defaults to knowledge_base/00_System_Architecture_Overview.md)')
@click.option('--scripts-dir', type=click.Path(exists=True), default=None,
              help='Scripts directory (defaults to godot_project/scripts)')
@click.option('--json', 'output_json', is_flag=True, help='Output results as JSON')
def main(project_root: str, architecture_doc: str, scripts_dir: str, output_json: bool):
    """
    Detect drift between design docs and implementation.
    
    Checks:
    1. Signal Drift: Documented signals exist in code
    2. System Listing Drift: Documented systems have files
    3. File Structure Drift: Documented paths exist
    4. Dependency Matrix Drift: Dependencies are valid
    """
    
    if not project_root:
        project_root = os.path.dirname(__file__)
        while project_root and '.claude' not in os.listdir(project_root):
            project_root = os.path.dirname(project_root)
    
    project_path = Path(project_root) if project_root else Path.cwd()
    
    # Resolve architecture doc
    if not architecture_doc:
        architecture_doc = str(project_path / 'knowledge_base' / '00_System_Architecture_Overview.md')
    
    arch_doc_path = Path(architecture_doc)
    if not arch_doc_path.exists():
        click.echo(f"Architecture document not found: {architecture_doc}")
        sys.exit(1)
    
    # Resolve scripts dir
    if not scripts_dir:
        scripts_dir = str(project_path / 'godot_project' / 'scripts')
    
    scripts_path = Path(scripts_dir)
    
    # Read architecture document
    try:
        with open(arch_doc_path, 'r', encoding='utf-8') as f:
            doc_content = f.read()
    except Exception as e:
        click.echo(f"Failed to read architecture document: {e}")
        sys.exit(1)
    
    result = DriftResult()
    
    # Run drift checks
    check_signal_drift(doc_content, scripts_path, result)
    check_system_drift(doc_content, scripts_path, result)
    check_file_structure_drift(doc_content, project_path, result)
    check_dependency_drift(doc_content, scripts_path, result)
    
    # Output
    if output_json:
        matches, drifts, missing = result.count_by_status()
        output = {
            'checks': [check.to_dict() for check in result.checks],
            'summary': {
                'total': len(result.checks),
                'matches': matches,
                'drifts': drifts,
                'missing': missing
            },
            'has_drift': result.has_drift()
        }
        click.echo(json.dumps(output, indent=2, ensure_ascii=False))
    else:
        for check in result.checks:
            click.echo(f"[{check.status}] {check.category}: {check.description}")
            click.echo(f"    Certainty: {check.certainty} - {check.detail}")
        click.echo()
        click.echo(result.summary())
    
    sys.exit(1 if result.has_drift() else 0)


if __name__ == '__main__':
    main()
