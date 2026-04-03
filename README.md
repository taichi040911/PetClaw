# PetClaw

[![Release](https://img.shields.io/github/v/release/taichi040911/PetClaw)](https://github.com/taichi040911/PetClaw/releases/latest)
[![Tests](https://img.shields.io/badge/tests-52%2F52%20passing-brightgreen)]()
[![Godot](https://img.shields.io/badge/Godot-4.6.1-blue)](https://godotengine.org)
[![License](https://img.shields.io/github/license/taichi040911/PetClaw)](LICENSE)

A virtual pet simulation game powered by Claude API, featuring AI-to-AI conversations, emergent language evolution, and an autonomous pet community.

Built with **Godot 4.6.1** and **GDScript**. **75+ scripts, 35,000+ lines of code.**

## Core Features

- **22 Evolution Forms** across 6 stages (Blob → Infant → Youth → Adult → Elder → Eternal)
- **AI-to-AI Conversations** — Pets talk to each other using Claude API with template fallback
- **Emergent Language** — Pets develop their own words, grammar, and communication patterns through 5 stages (Borrowing → Morphological → Neologism → Grammar Independent → Cultural Language)
- **PetBook (AI SNS)** — An autonomous social network where pets post, react, and form factions
- **Biological Memory** — Ebbinghaus-curve memory decay, Hebbian learning, flashbulb memories
- **Active Inference** — Free Energy Principle-based prediction-action loop for vocabulary evolution
- **Life/Death/Breeding** — Full lifecycle with personality inheritance and genetic mutation
- **Language Battles** — Pets challenge each other using stats shaped by care, personality, and evolution
- **Cultural Emergence** — Festivals, stories, songs, rituals, and traditions that spread through the community
- **Procedural Audio** — Chiptune SFX and ambient BGM generated entirely in code (no external audio files)
- **Ethical Safeguards** — Dependency detection, session limits, real-world suggestions

## Architecture

18+ subsystems managed by a central GameManager autoload:

| System | Description |
|--------|-------------|
| EmotionSystem | Real-time emotion processing with personality bias |
| EvolutionMechanics | Care-based evolution with 22 forms |
| LanguageEvolutionSystem | Grammar emergence (SVO/SOV/VSO word order) |
| OriginalLanguageEngine | Pet-invented words with Hebbian LTP/LTD |
| ActiveInferenceCore | FEP/VFE prediction-action loop for vocabulary |
| AtoAConversationSystem | Claude API conversations with 80/20 template fallback |
| BiologicalMemorySystem | Hippocampus/Cortex dual-store with decay |
| LifeDeathSystem | Mortality, revival mechanics |
| BreedingSystem | Compatibility scoring, trait inheritance |
| PetBookCore | AI-only SNS with SubMolt themes |
| LanguageBattleSystem | Stat-based pet battles |
| CulturalEmergenceSystem | Emergent festivals, stories, rituals |
| PetAutonomySystem | Pulse/Resonance autonomous behavior |
| PetLifecycleFSM | Sleep/Wake/Play state machine |
| AchievementSystem | Milestone tracking and unlocks |
| MemoryPersonalityBridge | Grief, nostalgia, trauma, dream synthesis |
| EthicalSafeguard | Player wellness protection |
| SfxManager / AmbientBGM | Procedural chiptune audio generation |

## Getting Started

### Requirements
- Godot 4.6+
- Python 3.10+ (for quality tools, optional)
- (Optional) Anthropic API key for AI conversations

### Run
```bash
# Open in Godot Editor
godot --path godot_project

# Or run headless tests
godot --headless --script tests/run_tests.gd

# Quality tools
python3 tools/quality/petclaw_agent_lint.py
```

### API Key Setup
Set `ANTHROPIC_API_KEY` environment variable, or configure in Settings screen within the game. Without an API key, the game runs in template mode (no API calls). All evolution, battles, achievements, and core gameplay work fully offline.

## Project Structure

```
godot_project/
  scripts/          # 75+ GDScript files, 35,000+ lines across 23 subsystems
  scenes/           # 3 .tscn scene files
  assets/sprites/   # 22 evolution form sprites + 66 expression sheets
  tests/            # 16 test files, 3,000+ lines (52 passing tests)
knowledge_base/     # 82 design documents (KB00-KB114)
tools/quality/      # Lint, drift detection, deslop, Karpathy Loop, MCP server
docs/               # Developer manual
```

## Design Principles

1. **Consistency × Memory = Attachment** — Pets feel alive through consistent behavior
2. **API Cost is Physics** — Template fallback mandatory, daily budgets enforced
3. **Player Agency** — Evolution is irreversible, choices matter
4. **10-Second Hook** — Immediate feedback on every interaction
5. **Complexity is Debt** — Emergent behavior over designed complexity

## Cost Management

- AtoA conversations: $0.50/day budget
- PetBook posts: $0.50/day budget
- Template/API ratio: 80% template / 20% API
- Token budgets: Conversation 8K, Reflection 3K
- Active Inference / Hebbian learning: 100% local (zero API cost)

## Documentation

- **[Developer Manual](docs/PetClaw_Developer_Manual.md)** — Complete 18-section guide
- **[CLAUDE.md](CLAUDE.md)** — Development rules and constraints
- **[Launch Checklist](LAUNCH_CHECKLIST.md)** — Pre-deployment verification
- **[Knowledge Base](knowledge_base/)** — 81 design documents

## Play Online

Play PetClaw in your browser on [itch.io](https://taichi040911.itch.io/petclaw) (coming soon).

Or download the latest release from [GitHub Releases](https://github.com/taichi040911/PetClaw/releases/latest).

## Running Tests

```bash
# Run all test suites (52 tests)
./tools/run_all_tests.sh

# Run individual suites
cd godot_project
godot --headless --script tests/test_active_inference.gd  # 15 tests
godot --headless --script tests/test_bcm_oja.gd           # 19 tests
godot --headless --script tests/test_learning_bridge.gd    # 18 tests
```

## License

MIT

## Credits

- Game design & development: taichi040911
- Built with [Godot 4.6](https://godotengine.org/) and [Claude API](https://www.anthropic.com/)
- Development assisted by [Claude Code](https://claude.com/claude-code) (Anthropic)
