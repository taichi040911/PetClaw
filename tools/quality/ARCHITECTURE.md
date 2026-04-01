# PetClaw Quality Tools Architecture

## Overview

Three complementary Python CLI tools for validating PetClaw's Godot 4.x codebase, inspired by agentsys's quality infrastructure.

```
tools/quality/
├── petclaw_agent_lint.py      (284 lines)  Configuration validation
├── petclaw_deslop.py          (293 lines)  Code quality analysis  
├── petclaw_drift.py           (332 lines)  Documentation sync
├── install.sh                            Dependencies setup
├── README.md                             User guide
└── ARCHITECTURE.md                       This file
```

---

## Tool 1: petclaw_agent_lint.py

### Purpose
Validates Agent Teams configuration files to ensure consistency with PetClaw's agent-oriented development model.

### Design
```
Input Validation Pipeline:
  ├── Agent Files (.claude/agents/*.md)
  │   ├── YAML frontmatter (name, tools, model, memory)
  │   ├── Model validation (opus/sonnet/haiku)
  │   ├── Heading match
  │   └── File reference checks
  ├── Command Files (.claude/commands/*.md)
  │   ├── Frontmatter (allowed-tools with TeammateTool)
  │   ├── Step numbering (### Step 1, 2, ...)
  │   ├── spawnTeammate/spawnTeam references
  │   └── Prompt block detection
  ├── CLAUDE.md Root File
  │   ├── Agent listings
  │   ├── Command listings
  │   └── Coding conventions section
  └── Cross-references
      └── capabilities.md consistency
```

### Rules (26 checks)
- 6 agent configuration checks
- 5 command configuration checks
- 3 CLAUDE.md checks
- 2 cross-reference checks

### Output
```
[PASS] AGENT_REFERENCES: gdscript-engineer
[FAIL] COMMAND_STEPS: implement.md: no numbered steps found
[WARN] CLAUDE_MD_CONVENTIONS: no coding conventions section found
```

### Exit Code
- 0: All checks pass
- 1: Any FAIL detected

---

## Tool 2: petclaw_deslop.py

### Purpose
Detects AI-generated "slop" patterns and enforces GDScript quality standards specific to PetClaw.

### Design
```
Three-Phase Analysis:

Phase 1: Pattern Detection (Regex)
├── EXCESSIVE_COMMENTS      (comment lines > code lines)
├── DEBUG_PRINTS            (print() with DEBUG/TODO/FIXME/TEST)
├── EMPTY_MATCH_BRANCH      (match with only 'pass')
├── REDUNDANT_NULL_CHECK    (null checks on typed vars)
└── TRAILING_WHITESPACE     (spaces/tabs at EOL)

Phase 2: Structure Analysis
├── MISSING_CLASS_NAME      (no class_name declaration)
├── DEEP_NESTING            (4+ indentation levels)
├── LONG_FUNCTION           (>50 lines)
├── MISSING_TYPE_ANNOTATION (func parameters without types)
└── UNSAFE_GAMEMANAGER      (GameManager.instance without null check)

Phase 3: PetClaw-Specific
├── MISSING_SAVE_LOAD       (state vars but no to_dict/from_dict)
├── ORPHAN_SIGNAL           (signal declared but never emitted)
└── EMOTION_RANGE           (emotion values outside [0.0, 1.0])
```

### Implementation
- Scans all .gd files in godot_project/scripts/
- Line-by-line analysis with position tracking
- Pattern matching with context awareness
- Summary with count by severity

### Output
```
[FAIL] MISSING_CLASS_NAME (Pet.gd:1): Missing 'class_name' declaration
[WARN] LONG_FUNCTION (AIBrain.gd:42): Function is 65 lines (exceeds 50)
[INFO] TRAILING_WHITESPACE (EvolutionSystem.gd:128): Line has trailing whitespace

Scanned 42 files: 8 issues (2 FAIL, 3 WARN, 3 INFO)
```

### Exit Code
- 0: No FAIL issues
- 1: One or more FAIL

---

## Tool 3: petclaw_drift.py

### Purpose
Detects divergence between design documentation and implementation using multiple verification strategies.

### Design
```
Drift Detection Matrix:

1. Signal Drift
   Parse: knowledge_base/00_System_Architecture_Overview.md
   Extract: signal_name patterns → grep in .gd files
   Check: signal declared + emitted
   
2. System Listing Drift
   Parse: system names from architecture doc
   Search: corresponding .gd files (System, SystemManager, SystemSystem)
   Check: file existence
   
3. File Structure Drift
   Parse: markdown code blocks with paths
   Extract: directory structure (godot_project/scripts/, etc.)
   Check: Path.exists() in filesystem
   
4. Dependency Matrix Drift
   Parse: depends on, →, requires patterns
   Extract: dependency declarations
   Check: referenced system exists
```

### Status & Certainty
```
Status:
├── MATCH   ✓ Documentation matches implementation
├── DRIFT   ✗ Documentation exists but implementation differs
└── MISSING ✗ Documentation incomplete or implementation missing

Certainty:
├── HIGH    Exact match/absence detected
├── MEDIUM  Inference via naming conventions
└── LOW     Uncertain (fuzzy match)
```

### Output
```
[MATCH] Signal Drift: Signal "pet_evolved"
    Certainty: HIGH - Found in implementation

[DRIFT] System Listing Drift: System "EthicalSafeguard"
    Certainty: MEDIUM - Not found as [EthicalSafeguard, EthicalSafeguardManager, EthicalSafeguardSystem]

Drift check complete: 23 checks (18 MATCH, 4 DRIFT, 1 MISSING)
```

### Exit Code
- 0: No DRIFT or MISSING
- 1: DRIFT or MISSING found

---

## Common Workflows

### Verify Agent Configuration
```bash
python3 petclaw_agent_lint.py --json | jq '.summary'
```

### Code Quality Scan (Pre-commit)
```bash
python3 petclaw_deslop.py || echo "Code quality issues found"
```

### Design/Implementation Alignment
```bash
python3 petclaw_drift.py --architecture-doc knowledge_base/00_*.md
```

### CI/CD Pipeline
```bash
for tool in petclaw_*; do
  echo "Running $tool..."
  python3 $tool --json > ${tool%.py}.json || exit 1
done
```

---

## Dependencies

- **click** (2.7.1+) — CLI framework with --json support
- **yaml** (PyYAML 5.1+) — YAML frontmatter parsing
- **re** (stdlib) — Regex patterns
- **pathlib** (stdlib) — Cross-platform path handling

```bash
pip install click pyyaml
```

---

## Design Principles

### P1: Single Responsibility
Each tool validates one aspect:
- agent_lint: Configuration integrity
- deslop: Code quality
- drift: Documentation sync

### P2: Auto-Discovery
Tools find project root automatically by searching for `.claude/` directory.
Use `--project-root` to override.

### P3: Machine-Readable Output
All tools support `--json` for CI/CD integration and programmatic parsing.

### P4: No Side Effects
All tools are read-only. They report issues without modifying files.

### P5: Certainty Levels
drift.py reports confidence in findings (HIGH/MEDIUM/LOW) to distinguish between
verified issues and heuristic guesses.

---

## Future Enhancements

1. **petclaw_agent_lint.py**
   - Validate tool availability matrix
   - Check memory costs against OpenAI pricing

2. **petclaw_deslop.py**
   - Metrics dashboard (avg function length, nesting depth)
   - Git blame integration for slop detection

3. **petclaw_drift.py**
   - Bidirectional sync (implement → doc)
   - Changelog generation from drift reports

---

## Testing

All tools validated for:
- Python 3.7+ compatibility
- UTF-8 filename handling (Japanese characters in paths)
- JSON serialization with non-ASCII content
- Edge cases (empty files, missing directories)

