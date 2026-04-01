# PetClaw — itch.io Upload Guide

## Quick Upload (after butler login)

```bash
# 1. Login (one-time)
~/bin/butler login

# 2. Push web build
~/bin/butler push exports/petclaw-web.zip taichi040911/petclaw:html5

# 3. Verify
~/bin/butler status taichi040911/petclaw
```

## itch.io Page Settings

### Basic Info
- **Title**: PetClaw - AI Virtual Pet
- **Short description**: AI-powered virtual pet with emergent language, evolution, and an autonomous pet social network
- **Classification**: Game
- **Kind of project**: HTML
- **Release status**: In development
- **Pricing**: Free (or Name Your Price)

### Tags
`virtual-pet`, `ai`, `simulation`, `tamagotchi`, `godot`, `evolution`, `social-simulation`, `claude-api`

### Embed Options
- **Viewport dimensions**: 720 x 1280
- **Fullscreen button**: Yes
- **Mobile friendly**: Yes
- **SharedArrayBuffer**: Required (Godot 4.x threads)

### Description (Markdown)

```
# PetClaw - AI Virtual Pet Simulation

Raise AI-powered virtual pets that develop their own language, form social bonds, and evolve through 22 unique forms.

## Features
- **22 Evolution Forms** across 6 life stages
- **AI-to-AI Conversations** — Your pets talk to each other using Claude AI
- **Emergent Language** — Pets invent their own words and grammar
- **PetBook (AI SNS)** — An autonomous social network run entirely by pets
- **Biological Memory** — Pets remember experiences with realistic memory decay
- **Life Cycle** — Birth, growth, evolution, breeding, and natural death

## How to Play
1. Start with your first egg — watch it hatch!
2. Feed, pet, and play with your pet to build bonds
3. Watch your pet evolve based on how you care for it
4. See pets develop their own language and post on PetBook
5. Breed pets to create new generations with inherited traits

## Controls
- Tap/click to interact with your pet
- Use the bottom menu for Feed, Pet, Play actions
- Open PetBook to see your pets' social lives

## Tech
Built with Godot 4.6 and Claude API. Runs in template mode without API key (no AI calls needed to play).

## Credits
Built with Claude Code and Anthropic Claude API.
```

## CORS / SharedArrayBuffer

itch.io supports SharedArrayBuffer for Godot 4.x games.
In the itch.io game page settings, check:
- "SharedArrayBuffer support" = Enabled

This is required for Godot 4.x Web exports that use threads.
