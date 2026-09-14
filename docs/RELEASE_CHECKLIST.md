# Pixel Galaxy World - Release Readiness Checklist

## 1. Core game loop
- [ ] Main menu starts correctly
- [ ] New game starts and resets world state
- [ ] Day/night cycle advances correctly
- [ ] Resource gathering works
- [ ] Monster spawning works at night and raid events
- [ ] Colony win/lose states trigger correctly

## 2. Stability and runtime safety
- [ ] No invalid colony index access
- [ ] Null asset load handled gracefully
- [ ] Save/load handles corrupted or missing file safely
- [ ] Pause/play/fast-forward controls do not break state
- [ ] Restart from game over works

## 3. Economy and progression
- [ ] Wood/stone/metal/crystal/food economy is balanced
- [ ] Food consumption and starvation are fair
- [ ] Building cost feels meaningful
- [ ] Player can reach day 30 without frustration

## 4. Colony / AI behavior
- [ ] Colonists can select target resource nodes
- [ ] Colonists can fight nearby monsters
- [ ] Colonists do not get stuck on invalid targets
- [ ] Health, hunger, sleep, and mood degrade realistically

## 5. UI / UX
- [ ] HUD remains readable on mobile resolution
- [ ] Buttons are easy to tap
- [ ] Alert messages appear and clear correctly
- [ ] Tutorial text helps first-time players
- [ ] Pause/fast-forward controls are clear

## 6. Save / load
- [ ] Auto-save occurs while playing
- [ ] Save file survives restart
- [ ] Load data restores colony, resources, day, and monsters properly
- [ ] Missing save file starts new game cleanly

## 7. Audio / feedback
- [ ] Ambient audio starts when game begins
- [ ] Build, hit, alert, and menu sounds trigger correctly
- [ ] Volume is acceptable for mobile play

## 8. Quality assurance
- [ ] Test on desktop resolution
- [ ] Test on Android screen size
- [ ] Test with touch input only
- [ ] Test with mouse input only
- [ ] Test long sessions for hours to catch state drift
- [ ] Test restart and recovery after multiple runs

## 9. Build & release
- [ ] Godot export preset configured
- [ ] Android icons and metadata prepared
- [ ] APK package name validated
- [ ] Screen orientation set correctly
- [ ] Release notes written
- [ ] Final QA sign-off completed

## 10. Future roadmap
- [ ] Additional building types
- [ ] Better combat effects
- [ ] More monster classes and boss wave
- [ ] Improved colony management UI
- [ ] More world biomes and procedural variation
- [ ] Leaderboard or achievements if desired
