# PetClaw Launch Checklist

## Pre-Launch

### Gameplay Verification
- [ ] All 22 evolution forms reachable
- [ ] Save/load works across sessions (browser refresh, close/reopen)
- [ ] AtoA conversations functional in template mode (no API key)
- [ ] Battle system complete (challenge, fight, result, stat changes)
- [ ] Achievement system functional (unlock, persist, display)
- [ ] Breeding system works end-to-end
- [ ] PetBook feed generates posts correctly
- [ ] Tutorial completes without issues
- [ ] Demo mode works (accelerated timers)
- [ ] Emotional contagion spreads between pets
- [ ] Language dictionary displays vocabulary correctly

### Technical Verification
- [ ] Web export builds cleanly (`godot --export-release "Web (HTML5)"`)
- [ ] No console errors on startup
- [ ] No console errors during 5-minute play session
- [ ] Save data survives browser refresh
- [ ] Game loads with no API key configured (template mode default)
- [ ] Export size is reasonable (< 100 MB)
- [ ] IndexedDB storage works in Chrome, Firefox, Safari

### Build
- [ ] Export presets point to correct path (`exports/web/index.html`)
- [ ] `upload_itch.sh` tested with dry run
- [x] Version strings updated to v1.2.0

### Neural Learning Pipeline (v1.2.0)
- [x] Active Inference Core: 15/15 tests passing
- [x] BCM Theory: 19/19 tests passing (incl. Oja)
- [x] Learning Model Bridge: 18/18 tests passing
- [x] Bridge wired into AtoA _finalize_conversation()
- [x] Save/load includes all 21+ subsystems

## Launch

- [ ] `~/bin/butler login` (interactive -- opens browser for one-time auth)
- [ ] `./tools/upload_itch.sh 1.2.0`
- [ ] Verify itch.io page renders correctly (https://taichi040911.itch.io/petclaw)
- [ ] Test web build in Chrome
- [ ] Test web build in Firefox
- [ ] Test web build in Safari
- [ ] itch.io page description matches `tools/itch_page_content.md`
- [ ] Screenshots/GIFs uploaded to itch.io page
- [ ] Tags set: virtual-pet, ai, simulation, evolution, language, emergent-gameplay
- [x] GitHub release v1.2.0 created

## Post-Launch

- [ ] Monitor error reports (first 24 hours)
- [ ] Run Karpathy Loop iteration on launch-day conversation data
- [ ] Community feedback collection (itch.io comments)
- [ ] Check save/load compatibility if hotfix needed
- [ ] Plan v1.3.0 based on feedback
