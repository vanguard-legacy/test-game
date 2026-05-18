# Changelog

Track meaningful project changes here so future work has a clear history. Use short, dated entries and keep implementation detail high-level unless a detail affects future development.

Format: based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), adjusted for this always-in-progress prototype. Keep tagged release sections in reverse chronological order. Version headings should match Git tags in the form `YYYY-MM-DD.N`.

## [2026-05-19.2] - 2026-05-19

- Added a Godot command setup script that stores the active executable in `GODOT_EXE`, refreshes the `godot.cmd` shim, and keeps validation independent of versioned install folders.
- Added procedural terrain and road shader materials with vertex color blending, altitude tinting, grain, road edge darkening, and extra terrain detail.
- Increased map visual contrast with darker terrain/road palettes, stronger shader shading, and lower sun intensity.
- Added a selected-tower sell action that removes placed towers and refunds half of their build cost.
- Improved tower selection with screen-space picking and a visible selected-tower range highlight.
- Tightened Godot validation so logs are written to the ignored project-local `.godot/codex_validation` folder and the launch command can be inspected without running the engine.
- Added 1x/2x/4x game speed controls, kept keyboard/edge camera panning stable while time is scaled, and increased enemy counts across scripted and scaling waves.
- Introduced a small gameplay clock boundary so HUD speed buttons emit intent while the simulation side owns valid speed values and `Engine.time_scale`.
- Expanded the Godot validation wrapper with recovery-mode project validation, project-local smoke logs, and an optional `-RunSmoke` test pass.
- Reordered the changelog to follow Keep a Changelog-style reverse chronological sections.
- Documented date-based version tags in the form `YYYY-MM-DD.N`.
- Linked changelog release headings to matching Git version tags.
- Removed the `Unreleased` heading because this prototype is always in active development.

## 2026-05-18

- Added terrain-height tower bonuses so high ground increases tower damage and range while low ground applies a small penalty.
- Added placement hover tooltips that preview the terrain bonus before a tower is placed.
- Expanded the prototype map with a larger terrain footprint, a longer winding route, more varied elevation, and changing road widths.

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

[2026-05-19.2]: https://github.com/vanguard-legacy/test-game/tree/2026-05-19.2
