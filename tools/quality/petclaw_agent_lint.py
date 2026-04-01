#!/usr/bin/env python3
"""
PetClaw Agent Lint Tool
Validates PetClaw Agent Teams configuration files (.claude/agents/ and .claude/commands/).
Inspired by agentsys's /agnix command.
"""

import click
import json
import sys
import os
import re
from pathlib import Path
from typing import List, Tuple, Dict, Any
import yaml

# Result types
class LintResult:
    def __init__(self):
        self.passes = []
        self.warnings = []
        self.fails = []
    
    def add_pass(self, rule: str, detail: str = ""):
        self.passes.append((rule, detail))
    
    def add_warn(self, rule: str, detail: str = ""):
        self.warnings.append((rule, detail))
    
    def add_fail(self, rule: str, detail: str = ""):
        self.fails.append((rule, detail))
    
    def has_failures(self) -> bool:
        return len(self.fails) > 0
    
    def summary(self) -> str:
        total = len(self.passes) + len(self.warnings) + len(self.fails)
        return f"Lint complete: {total} checks ({len(self.passes)} PASS, {len(self.warnings)} WARN, {len(self.fails)} FAIL)"


def discover_project_root(script_path: str) -> Path:
    """Discover project root by finding .claude/ directory."""
    current = Path(script_path).parent
    while current != current.parent:
        if (current / '.claude').exists():
            return current
        current = current.parent
    return Path.cwd()


def parse_frontmatter(content: str) -> Tuple[Dict[str, Any], str]:
    """Parse YAML frontmatter from markdown file."""
    lines = content.split('\n')
    if not lines[0].startswith('---'):
        return {}, content
    
    end_idx = -1
    for i in range(1, len(lines)):
        if lines[i].startswith('---'):
            end_idx = i
            break
    
    if end_idx == -1:
        return {}, content
    
    frontmatter_text = '\n'.join(lines[1:end_idx])
    body = '\n'.join(lines[end_idx+1:])
    
    try:
        frontmatter = yaml.safe_load(frontmatter_text) or {}
    except yaml.YAMLError:
        frontmatter = {}
    
    return frontmatter, body


def check_agent_files(agents_dir: Path, project_root: Path, result: LintResult):
    """Check all agent definition files (except capabilities.md)."""
    if not agents_dir.exists():
        result.add_fail("AGENT_DIRECTORY_EXISTS", f"{agents_dir} not found")
        return
    
    agent_files = [f for f in agents_dir.glob('*.md') if f.name != 'capabilities.md']
    
    if not agent_files:
        result.add_warn("AGENT_FILES_EXIST", "No agent files found in .claude/agents/")
        return
    
    for agent_file in agent_files:
        with open(agent_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        frontmatter, body = parse_frontmatter(content)
        
        # Check required frontmatter fields
        required_fields = ['name', 'tools', 'model', 'memory']
        for field in required_fields:
            if field not in frontmatter:
                result.add_fail("AGENT_FRONTMATTER_REQUIRED", 
                    f"{agent_file.name}: missing '{field}'")
        
        # Check model value
        if 'model' in frontmatter:
            valid_models = ['opus', 'sonnet', 'haiku']
            if frontmatter['model'] not in valid_models:
                result.add_fail("AGENT_MODEL_VALID", 
                    f"{agent_file.name}: model '{frontmatter['model']}' not in {valid_models}")
        
        # Check memory is 'project'
        if 'memory' in frontmatter and frontmatter['memory'] != 'project':
            result.add_fail("AGENT_MEMORY_PROJECT",
                f"{agent_file.name}: memory must be 'project', got '{frontmatter['memory']}'")
        
        # Check for agent name heading
        agent_name = frontmatter.get('name', '')
        if agent_name and f"## {agent_name}" not in body and f"# {agent_name}" not in body:
            result.add_warn("AGENT_NAME_HEADING",
                f"{agent_file.name}: no heading matching agent name '{agent_name}'")
        
        # Check for file path references
        has_references = bool(re.search(r'(godot_project/|knowledge_base/)', body))
        if not has_references:
            result.add_warn("AGENT_REFERENCES",
                f"{agent_file.name}: no references to godot_project/ or knowledge_base/")
        else:
            result.add_pass("AGENT_REFERENCES", agent_file.name)


def check_command_files(commands_dir: Path, result: LintResult):
    """Check all command definition files."""
    if not commands_dir.exists():
        result.add_fail("COMMAND_DIRECTORY_EXISTS", f"{commands_dir} not found")
        return
    
    command_files = list(commands_dir.glob('*.md'))
    
    if not command_files:
        result.add_warn("COMMAND_FILES_EXIST", "No command files found in .claude/commands/")
        return
    
    for cmd_file in command_files:
        with open(cmd_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        frontmatter, body = parse_frontmatter(content)
        
        # Check for allowed-tools with TeammateTool
        if 'allowed-tools' not in frontmatter:
            result.add_fail("COMMAND_ALLOWED_TOOLS",
                f"{cmd_file.name}: missing 'allowed-tools' in frontmatter")
        elif 'TeammateTool' not in str(frontmatter.get('allowed-tools', [])):
            result.add_warn("COMMAND_TEAMMATE_TOOL",
                f"{cmd_file.name}: 'TeammateTool' not in allowed-tools")
        
        # Check for numbered steps
        steps = re.findall(r'### Step \d+', body)
        if not steps:
            result.add_fail("COMMAND_STEPS",
                f"{cmd_file.name}: no numbered steps found (e.g., '### Step 1')")
        else:
            result.add_pass("COMMAND_STEPS", f"{cmd_file.name} ({len(steps)} steps)")
        
        # Check for spawnTeammate or spawnTeam references
        if 'spawnTeammate' not in body and 'spawnTeam' not in body:
            result.add_fail("COMMAND_SPAWN_REFERENCE",
                f"{cmd_file.name}: no spawnTeammate or spawnTeam references")
        
        # Check for prompt blocks
        if '```prompt' not in body and '```' not in body:
            result.add_warn("COMMAND_PROMPT_BLOCK",
                f"{cmd_file.name}: no prompt code blocks found")
        else:
            result.add_pass("COMMAND_PROMPT_BLOCK", cmd_file.name)


def check_claude_md(claude_file: Path, agents_dir: Path, commands_dir: Path, result: LintResult):
    """Check CLAUDE.md root file."""
    if not claude_file.exists():
        result.add_fail("CLAUDE_MD_EXISTS", "CLAUDE.md not found")
        return
    
    with open(claude_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Check for agent listings
    agent_files = [f.stem for f in agents_dir.glob('*.md') if f.name != 'capabilities.md']
    for agent_name in agent_files:
        if agent_name not in content:
            result.add_warn("CLAUDE_MD_AGENT_LISTING",
                f"CLAUDE.md: agent '{agent_name}' not mentioned")
    if agent_files:
        result.add_pass("CLAUDE_MD_AGENT_LISTING", f"checked {len(agent_files)} agents")
    
    # Check for command listings
    command_files = [f.stem for f in commands_dir.glob('*.md')]
    for cmd_name in command_files:
        if cmd_name not in content:
            result.add_warn("CLAUDE_MD_COMMAND_LISTING",
                f"CLAUDE.md: command '{cmd_name}' not mentioned")
    if command_files:
        result.add_pass("CLAUDE_MD_COMMAND_LISTING", f"checked {len(command_files)} commands")
    
    # Check for coding conventions
    if '## Coding' in content or '## コーディング' in content or 'GDScript' in content:
        result.add_pass("CLAUDE_MD_CONVENTIONS", "coding conventions section found")
    else:
        result.add_warn("CLAUDE_MD_CONVENTIONS", "no coding conventions section found")


def check_cross_references(agents_dir: Path, commands_dir: Path, result: LintResult):
    """Check cross-references between agents and commands."""
    # Check capabilities.md lists existing agents
    capabilities_file = agents_dir / 'capabilities.md'
    if capabilities_file.exists():
        with open(capabilities_file, 'r', encoding='utf-8') as f:
            capabilities_content = f.read()
        
        agent_files = set(f.stem for f in agents_dir.glob('*.md') if f.name != 'capabilities.md')
        
        # Extract agent names from capabilities
        for agent_name in agent_files:
            if agent_name in capabilities_content:
                result.add_pass("CROSS_REFERENCE_AGENT", agent_name)
            else:
                result.add_warn("CROSS_REFERENCE_AGENT",
                    f"agent '{agent_name}' not found in capabilities.md")


@click.command()
@click.option('--project-root', type=click.Path(exists=True), default=None,
              help='Project root directory (auto-discovered if not provided)')
@click.option('--json', 'output_json', is_flag=True, help='Output results as JSON')
def main(project_root: str, output_json: bool):
    """
    Validate PetClaw Agent Teams configuration files.
    
    Checks:
    - Agent definitions (.claude/agents/*.md)
    - Command definitions (.claude/commands/*.md)
    - CLAUDE.md root file
    - Cross-references between configs
    """
    
    if project_root:
        root = Path(project_root)
    else:
        root = discover_project_root(__file__)
    
    agents_dir = root / '.claude' / 'agents'
    commands_dir = root / '.claude' / 'commands'
    claude_file = root / 'CLAUDE.md'
    
    result = LintResult()
    
    # Run checks
    check_agent_files(agents_dir, root, result)
    check_command_files(commands_dir, result)
    check_claude_md(claude_file, agents_dir, commands_dir, result)
    check_cross_references(agents_dir, commands_dir, result)
    
    # Output
    if output_json:
        output = {
            'passes': [{'rule': r, 'detail': d} for r, d in result.passes],
            'warnings': [{'rule': r, 'detail': d} for r, d in result.warnings],
            'fails': [{'rule': r, 'detail': d} for r, d in result.fails],
            'summary': result.summary()
        }
        click.echo(json.dumps(output, indent=2, ensure_ascii=False))
    else:
        for rule, detail in result.passes:
            click.echo(f"[PASS] {rule}: {detail}")
        for rule, detail in result.warnings:
            click.echo(f"[WARN] {rule}: {detail}")
        for rule, detail in result.fails:
            click.echo(f"[FAIL] {rule}: {detail}")
        click.echo()
        click.echo(result.summary())
    
    sys.exit(1 if result.has_failures() else 0)


if __name__ == '__main__':
    main()
