# QA Release Log

## Scope
- Game loop: start, play, pause, save, load, restart
- Economy: wood, stone, metal, crystal, food
- Colonist AI: selection, job assignment, needs, combat
- Build: wall placement, validation, resource cost
- Night danger and raid behavior
- HUD readability and audio toggle

## Target checks
- [ ] Start menu opens correctly
- [ ] New game starts without crash
- [ ] Save file creates and loads safely
- [ ] Mutation of colonist state does not break game flow
- [ ] Monsters spawn during night and raid windows
- [ ] Colonists can harvest resources reliably
- [ ] Build wall placement rejects invalid positions
- [ ] Game over triggers when colony collapses
- [ ] Win condition triggers at day 30
- [ ] UI is readable on mobile-sized viewport
- [ ] Audio toggle works
- [ ] Restart from game over does not crash

## Final release gate
- [ ] No editor errors in core scripts
- [ ] No null asset load issues in runtime start
- [ ] Save/load survives repeated sessions
- [ ] Long-run session remains stable
- [ ] Android export configuration reviewed
- [ ] Final playtest is sign-off complete
