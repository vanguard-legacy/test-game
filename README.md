# Test Game

A 3D high-fantasy medieval tower defense prototype where terrain height, path width, seasons, weather, towers, and enemy variety shape the defense.

See `DESIGN.md` for the current design brief.

## Prototype

Open the project in Godot and run the main scene. The first prototype is intentionally tiny:

- A generated 3D terrain map with low ground, high ground, and a wider exit road.
- A single G'wizard tower on the ridge.
- Gobbelins that follow the path toward the exit.
- Lives, score, waves, and a restart prompt after defeat.

## Development

Codex project guidance lives in `AGENTS.md`.

Run a basic Godot project validation with:

```powershell
./scripts/validate-godot.ps1
```

If Godot is not on `PATH`, pass the executable path:

```powershell
./scripts/validate-godot.ps1 -GodotPath "C:\Path\To\Godot.exe"
```
