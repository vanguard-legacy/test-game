# Test Game

A 3D high-fantasy medieval tower defense game where terrain height, path width, seasons, weather, towers, and enemy variety shape the defense.

See `DESIGN.md` for the current design brief, `CHANGELOG.md` for project history, and `REFERENCE.md` for a file/function map.

## Game

Open the project in Godot and run the main scene. The current build focuses on:

- A larger generated 3D terrain map with low ground, ridges, valleys, and wider build zones.
- A longer procedural road with multiple bends, climbs, descents, chokepoints, and wider sections.
- Procedural terrain and road materials with height tinting, edge darkening, and subtle surface grain.
- Terrain-height bonuses that reward placing towers on high ground and warn about low ground.
- Player-placed G'wizard towers.
- Strategy-style camera controls for panning, rotating, and zooming around the terrain.
- Multiple enemy types that ask the map for an auto-generated route to the exit.
- Three persistent build slots, starting with the G'wizard tower and unlocking more tower types through XP rewards.
- XP reward choices that offer one of three run upgrades, including tower unlocks and global tower buffs.
- Selectable towers with gold upgrades for stronger damage, range, and fire rate.
- A game menu for starting, pausing, restarting, and quitting.
- A scrollable command log that keeps the run's event history visible.
- Lives, gold, score, waves, and a restart prompt after defeat.

Build towers from the HUD build panel, click a green patch of terrain to place them, then press Start Wave when the defense is ready.
Hover tower buttons or placed towers to inspect their role and stats. Camera controls are disabled while menus and reward choices are open.

The game is split into small Godot scenes:

- `scenes/main.tscn` coordinates the round and tower placement.
- `scenes/level_map.tscn` owns the simple terrain and path.
- `scenes/tower.tscn` owns the tower asset and attacks.
- `scenes/enemy.tscn` owns the enemy asset, movement, and health.
- `scenes/hud.tscn` owns the container-based HUD and build/start-wave UI.
- `assets/ui/icons/` contains the first generated UI icons.

Game balance lives in `scripts/game_balance.gd`, but gameplay scripts consume typed definitions from `scripts/tower_definition.gd`, `scripts/enemy_definition.gd`, `scripts/wave_definition.gd`, and `scripts/reward_definition.gd`. Run progress lives in `scripts/run_state.gd`; HUD updates flow through `scripts/hud_view_model.gd`; terrain/build queries use small typed result objects instead of ad hoc dictionaries.

Camera behavior lives in `scripts/camera_controller.gd`. UI styling lives in `scripts/ui_theme.gd`; shared 3D material helpers live in `scripts/materials.gd`.

## Development

Codex project guidance lives in `AGENTS.md`.
Meaningful changes should be recorded in `CHANGELOG.md`.

Architecture rule of thumb: keep `main.gd` as the scene coordinator, keep balance numbers in `game_balance.gd`, keep mutable run values in `run_state.gd`, and prefer typed payload objects over long parameter lists or cross-script dictionaries.
Treat gameplay state as the simulation core and HUD code as a presentation/input client. Godot scene-tree work should stay on the main thread unless a system is deliberately designed around thread-safe data handoff.

Version tags use date-based names: `YYYY-MM-DD.N`, incrementing `N` for each tag created on the same date.

### Godot Command Setup

Use the setup script whenever installing or switching Godot versions:

```powershell
./tools/set-godot.ps1 -GodotPath "C:\Path\To\Godot.exe"
```

It stores the executable path in the user-level `GODOT_EXE` environment variable, writes a stable `godot.cmd` shim to `~/bin`, and makes sure `~/bin` is on the user `Path`. After that, new terminals can use:

```powershell
godot --version
```

Run a basic Godot project validation with:

```powershell
./tools/validate-godot.ps1
```

If Godot is not on `PATH`, pass the executable path:

```powershell
./tools/validate-godot.ps1 -GodotPath "C:\Path\To\Godot.exe"
```

For combat-loop changes, run the short headless smoke:

```powershell
./tools/validate-godot.ps1 -RunSmoke
```

To inspect the exact commands without launching Godot, add `-ShowCommandOnly`.
