# PetClaw

A virtual pet simulation game powered by Claude API, featuring AI-to-AI conversations, emergent language evolution, and an autonomous pet community.

Built with **Godot 4.x** and **GDScript**.

## Core Features

- **22 Evolution Forms** across 6 stages (Blob -> Infant -> Youth -> Adult -> Elder -> Eternal)
- **AI-to-AI Conversations** — Pets talk to each other using Claude API with template fallback
- **Emergent Language** — Pets develop their own words, grammar, and communication patterns
- **PetBook (AI SNS)** — An autonomous social network where pets post, react, and form factions
- **Biological Memory** — Ebbinghaus-curve memory decay, Hebbian learning, flashbulb memories
- **Life/Death/Breeding** — Full lifecycle with personality inheritance and genetic mutation
- **Ethical Safeguards** — Dependency detection, session limits, real-world suggestions

## Architecture

15 subsystems managed by a central GameManager autoload:

| System | Description |
|--------|-------------|
| EmotionSystem | Real-time emotion processing with personality bias |
| EvolutionMechanics | Care-based evolution with 22 forms |
| LanguageEvolutionSystem | Grammar emergence (SVO/SOV/VSO word order) |
| OriginalLanguageEngine | Pet-invented words and semantic fields |
| AtoAConversationSystem | Claude API conversations with 80/20 template fallback |
| BiologicalMemorySystem | Hippocampus/Cortex dual-store with decay |
| LifeDeathSystem | Mortality, revival mechanics |
| BreedingSystem | Compatibility scoring, trait inheritance |
| PetBookCore | AI-only SNS with SubMolt themes |
| PersistentField | Offline adventures, community mood |
| EthicalSafeguard | Player wellness protection |
| PetAutonomySystem | Pulse/Resonance autonomous behavior |
| PetLifecycleFSM | Sleep/Wake/Play state machine |
| EcosystemManager | Environment effects on pets |
| CareActionSystem | Feed/Pet/Play/Train actions |

## Getting Started

### Requirements
- Godot 4.6+
- (Optional) Anthropic API key for AI conversations

### Run
```bash
# Open in Godot Editor
godot --path godot_project

# Or run headless
godot --headless --path godot_project
```

### API Key Setup
Set `ANTHROPIC_API_KEY` environment variable, or configure in Settings screen within the game. Without an API key, the game runs in template mode (no API calls).

## Project Structure

```
godot_project/
  scripts/          # 51 GDScript files across 15 subsystems
  scenes/           # 3 .tscn scene files
  assets/sprites/   # 22 evolution form sprites
  tests/            # 7 test files
knowledge_base/     # 63 design documents (KB00-KB95)
tools/quality/      # Lint, drift detection, deslop tools
```

## Design Principles

1. **Consistency x Memory = Attachment** — Pets feel alive through consistent behavior
2. **API Cost is Physics** — Template fallback mandatory, daily budgets enforced
3. **Player Agency** — Evolution is irreversible, choices matter
4. **10-Second Hook** — Immediate feedback on every interaction
5. **Complexity is Debt** — Emergent behavior over designed complexity

## Cost Management

- AtoA conversations: $0.50/day budget
- PetBook posts: $0.50/day budget
- Template/API ratio: 80% template / 20% API
- Token budgets: Conversation 8K, Reflection 3K

## License

MIT

## Credits

Built with [Claude Code](https://claude.com/claude-code) and the Anthropic Claude API.
