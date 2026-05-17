# Changelog

Track meaningful project changes here so future work has a clear history. Use short, dated entries and keep implementation detail high-level unless a detail affects future development.

## 2026-05-16

- Added Codex project guidance in `AGENTS.md`.
- Added the game design brief in `DESIGN.md`.
- Created a simple Godot validation script at `scripts/validate-godot.ps1`.
- Built the first playable prototype with waves, lives, score, gold, enemies, towers, and player tower placement.
- Split the prototype into focused Godot scenes for the map, enemies, towers, HUD, and round coordination.
- Added first-pass generated scene assets for the Gobbelin enemy and G'wizard tower.
- Added SVG UI icons and a container-based HUD with shared UI styling.
- Replaced box terrain with procedural terrain, a ramped road, terrain-aware tower placement, and A* enemy routing.
- Verified project validation and a brief headless scene run with Godot 4.6.2.
- Stabilized HUD panel sizing so build controls do not resize the UI when entering or leaving tower placement mode.
- Added multiple enemy archetypes, selectable tower upgrades, and a start/pause/restart menu overlay.
- Refactored balance data, wave definitions, and run progress out of `main.gd` into focused helper classes.

## 2026-05-17

- Added strategy-style camera controls for edge/keyboard panning, mouse drag panning, mouse rotation, and zoom.
- Added XP progression with three-choice reward drafts that can unlock tower types or apply global tower buffs.
- Added three fixed build slots and new tower archetypes for long-range, slowing, and splash damage play.
- Inverted vertical mouse camera tilt, disabled camera controls during overlays, and added cursor-following tower info tooltips.
- Reused tower beam effects instead of allocating shot effects every attack, tightened validation so GDScript warnings fail the pass, and added a short combat smoke script.
- Fixed reward choice selection so exhausted or even-sized reward pools cannot hang the game.
- Changed middle-mouse camera panning to anchor on the terrain point under the cursor instead of using fixed pixel-speed movement.
- Locked middle-mouse camera panning to a horizontal grab plane so terrain height changes do not cause accidental zoom-like motion.
- Refactored gameplay, HUD, reward, terrain, and placement data flow around typed definitions, view models, and query results instead of long parameter lists and scattered dictionaries.
- Added onboarding comments to core prototype scripts and documented the current architecture boundaries for future contributors and agents.
- Changed the command message panel into a stable scrollable event log so players can review run messages.
- Prevented camera mouse controls from responding while the cursor is over HUD controls, including the command log scrollbar.
