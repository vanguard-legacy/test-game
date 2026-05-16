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
