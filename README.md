# Test Game

A 3D high-fantasy medieval tower defense prototype where terrain height, path width, seasons, weather, towers, and enemy variety shape the defense.

See `DESIGN.md` for the current design brief and `CHANGELOG.md` for project history.

## Prototype

Open the project in Godot and run the main scene. The first prototype is intentionally tiny:

- A generated 3D terrain map with low ground, high ground, and a wider exit road.
- A procedural ramped road that climbs over the terrain and descends toward the exit.
- Player-placed G'wizard towers.
- Strategy-style camera controls for panning, rotating, and zooming around the terrain.
- Multiple enemy types that ask the map for an auto-generated route to the exit.
- Three persistent build slots, starting with the G'wizard tower and unlocking more tower types through XP rewards.
- XP reward choices that offer one of three run upgrades, including tower unlocks and global tower buffs.
- Selectable towers with gold upgrades for stronger damage, range, and fire rate.
- A game menu for starting, pausing, restarting, and quitting.
- Lives, gold, score, waves, and a restart prompt after defeat.

Build towers from the HUD build panel, click a green patch of terrain to place them, then press Start Wave when the defense is ready.
Hover tower buttons or placed towers to inspect their role and stats. Camera controls are disabled while menus and reward choices are open.

The prototype is split into small Godot scenes:

- `scenes/main.tscn` coordinates the round and tower placement.
- `scenes/level_map.tscn` owns the simple terrain and path.
- `scenes/tower.tscn` owns the tower asset and attacks.
- `scenes/enemy.tscn` owns the enemy asset, movement, and health.
- `scenes/hud.tscn` owns the container-based HUD and build/start-wave UI.
- `assets/ui/icons/` contains the first generated UI icons.

Game balance, tower definitions, reward choices, and wave definitions live in `scripts/game_balance.gd`; run progress lives in `scripts/run_state.gd`. Camera behavior lives in `scripts/camera_controller.gd`. UI styling lives in `scripts/ui_theme.gd`; shared 3D material helpers live in `scripts/materials.gd`.

## Development

Codex project guidance lives in `AGENTS.md`.
Meaningful changes should be recorded in `CHANGELOG.md`.

Run a basic Godot project validation with:

```powershell
./scripts/validate-godot.ps1
```

If Godot is not on `PATH`, pass the executable path:

```powershell
./scripts/validate-godot.ps1 -GodotPath "C:\Path\To\Godot.exe"
```

For combat-loop changes, run the short headless smoke:

```powershell
& "C:\Path\To\Godot.exe" --headless --path "C:\Users\Nova\Documents\test-game" --script res://tests/stability_smoke.gd
```
