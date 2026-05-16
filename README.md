# Test Game

A 3D high-fantasy medieval tower defense prototype where terrain height, path width, seasons, weather, towers, and enemy variety shape the defense.

See `DESIGN.md` for the current design brief and `CHANGELOG.md` for project history.

## Prototype

Open the project in Godot and run the main scene. The first prototype is intentionally tiny:

- A generated 3D terrain map with low ground, high ground, and a wider exit road.
- A procedural ramped road that climbs over the terrain and descends toward the exit.
- Player-placed G'wizard towers.
- Gobbelins that ask the map for an auto-generated route to the exit.
- Lives, gold, score, waves, and a restart prompt after defeat.

Build towers from the left UI panel, click a green patch of terrain to place them, then press Start Wave when the defense is ready.

The prototype is split into small Godot scenes:

- `scenes/main.tscn` coordinates the round and tower placement.
- `scenes/level_map.tscn` owns the simple terrain and path.
- `scenes/tower.tscn` owns the tower asset and attacks.
- `scenes/enemy.tscn` owns the enemy asset, movement, and health.
- `scenes/hud.tscn` owns the container-based HUD and build/start-wave UI.
- `assets/ui/icons/` contains the first generated UI icons.

UI styling lives in `scripts/ui_theme.gd`; shared 3D material helpers live in `scripts/materials.gd`.

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
