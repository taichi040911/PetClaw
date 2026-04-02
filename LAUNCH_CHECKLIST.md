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
- [ ] Version strings updated to v1.0.0

## Launch

- [ ] `butler login` (interactive -- opens browser for one-time auth)
- [ ] `./tools/upload_itch.sh v1.0.0`
- [ ] Verify itch.io page renders correctly (https://taichi040911.itch.io/petclaw)
- [ ] Test web build in Chrome
- [ ] Test web build in Firefox
- [ ] Test web build in Safari
- [ ] itch.io page description matches `itch_page.md`
- [ ] Screenshots/GIFs uploaded to itch.io page
- [ ] Tags set: virtual-pet, ai, language, evolution, tamagotchi, pixel-art
- [ ] GitHub release v1.0.0 created

## Post-Launch

- [ ] Monitor error reports (first 24 hours)
- [ ] Run Karpathy Loop iteration on launch-day conversation data
- [ ] Community feedback collection (itch.io comments)
- [ ] Check save/load compatibility if hotfix needed
- [ ] Plan v1.1.0 based on feedback
