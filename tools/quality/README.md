# PetClaw Quality Tools

Three Python CLI tools for validating and monitoring PetClaw's codebase quality. Inspired by agentsys's /agnix, /deslop, and /drift-detect commands.

## Tools Overview

### 1. petclaw_agent_lint.py — Agent Teams Configuration Validator

Validates Agent Teams configuration files (.claude/agents/ and .claude/commands/).

**Rules:**
- Agent definitions must have YAML frontmatter with: name, tools, model, memory
- Models: opus, sonnet, or haiku
- Memory: must be "project"
- Commands must have numbered steps and TeammateTool in allowed-tools
- CLAUDE.md root file lists all agents and commands
- Cross-references between configs are consistent

**Usage:**
```bash
python3 petclaw_agent_lint.py
python3 petclaw_agent_lint.py --project-root /path/to/petclaw
python3 petclaw_agent_lint.py --json  # Machine-readable output
```

**Exit codes:**
- 0: No failures detected
- 1: One or more FAIL results

---

### 2. petclaw_deslop.py — AI-Generated Code Pattern Detector

Scans GDScript files for "slop" patterns and code quality issues. Three-phase analysis:

**Phase 1 — Pattern Detection:**
- EXCESSIVE_COMMENTS: comment lines > code lines
- DEBUG_PRINTS: print() with DEBUG/TODO/FIXME/TEST keywords
- EMPTY_MATCH_BRANCH: match branches with only `pass`
- REDUNDANT_NULL_CHECK: unnecessary null checks on typed variables
- TRAILING_WHITESPACE: lines ending with spaces/tabs

**Phase 2 — Structure Analysis:**
- MISSING_CLASS_NAME: .gd file without class_name declaration
- DEEP_NESTING: code with 4+ indentation levels
- LONG_FUNCTION: functions exceeding 50 lines
- MISSING_TYPE_ANNOTATION: function parameters without type hints
- UNSAFE_GAMEMANAGER: GameManager.instance access without null check

**Phase 3 — PetClaw-Specific:**
- MISSING_SAVE_LOAD: state vars but no to_dict/from_dict methods
- ORPHAN_SIGNAL: signal declared but never emitted
- EMOTION_RANGE: emotion values outside [0.0, 1.0]

**Usage:**
```bash
python3 petclaw_deslop.py
python3 petclaw_deslop.py --scripts-dir /path/to/godot_project/scripts
python3 petclaw_deslop.py --json
```

**Exit codes:**
- 0: No FAIL issues detected
- 1: One or more FAIL results

---

### 3. petclaw_drift.py — Design/Implementation Drift Detection

Detects drift between design documentation and implementation.

**Checks:**

1. **Signal Drift** — Documented signals exist in code
2. **System Listing Drift** — Documented systems have corresponding files
3. **File Structure Drift** — Documented paths exist in filesystem
4. **Dependency Matrix Drift** — Dependencies reference valid systems

**Status Values:**
- MATCH: Documentation matches implementation
- DRIFT: Documentation exists but implementation differs
- MISSING: Documentation is incomplete or implementation is missing

**Certainty Levels:**
- HIGH: Confident in assessment (exact match/absence)
- MEDIUM: Reasonable inference based on naming conventions
- LOW: Uncertain (documentation incomplete, fuzzy match)

**Usage:**
```bash
python3 petclaw_drift.py
python3 petclaw_drift.py --architecture-doc /path/to/system/overview.md
python3 petclaw_drift.py --scripts-dir /path/to/scripts
python3 petclaw_drift.py --json
```

**Exit codes:**
- 0: No drift or missing items detected
- 1: DRIFT or MISSING status found

---

## Common Usage Patterns

### Run all three tools:
```bash
cd /sessions/practical-stoic-bell/mnt/「PetClaw」/tools/quality
python3 petclaw_agent_lint.py && echo "✓ Agent config OK"
python3 petclaw_deslop.py && echo "✓ Code quality OK"
python3 petclaw_drift.py && echo "✓ Design/impl aligned"
```

### CI/CD Integration:
```bash
python3 petclaw_agent_lint.py --json > lint-results.json
python3 petclaw_deslop.py --json > slop-results.json
python3 petclaw_drift.py --json > drift-results.json
```

### Quick status check:
```bash
python3 petclaw_deslop.py 2>&1 | tail -1  # Just the summary
```

---

## Requirements

- Python 3.7+
- click (install with: `pip install click pyyaml`)
- No external dependencies for file I/O

---

## Notes

- All tools auto-discover project root by searching for `.claude/` directory
- Use `--project-root` to override auto-discovery
- JSON output includes both raw results and summary counts
- Tools are read-only and produce no side effects
