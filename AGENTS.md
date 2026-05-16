# Codex Instructions

## Project Snapshot

- Godot project: `test-game`
- Engine target: Godot 4.6 features, Forward Plus renderer
- Physics: Jolt Physics for 3D
- Version control plugin: Godot Git plugin is enabled
- Game concept: 3D high-fantasy medieval tower defense where terrain height, path width, seasons, weather, towers, and enemy variety drive strategy.
- Design source of truth: `DESIGN.md`
- Current project is intentionally small; preserve that simplicity unless the task asks for structure.

## Godot Development Rules

- Prefer Godot 4.x patterns and APIs.
- Use GDScript unless the user explicitly requests C# or GDExtension.
- Prefer statically typed GDScript: typed variables, typed arrays where useful, typed parameters, and return types.
- Keep scripts scene-local until logic is clearly shared by multiple scenes.
- Use signals for decoupled gameplay events.
- Favor data-driven level, wave, enemy, tower, season, and weather definitions when those systems emerge.
- Preserve existing scene and node names unless the task requires a rename.
- Do not rename input actions, exported variables, resources, or scenes without explaining why.
- Avoid hand-editing `.tscn`, `.tres`, `.godot`, and `.import` files unless necessary for the requested change.
- Do not commit `.godot/`, exports, or generated platform folders.

## Scene And Script Conventions

- Name nodes by role: `Player`, `CameraRig`, `HealthBar`, `Hitbox`, `Hurtbox`, `StateMachine`, `AnimationPlayer`.
- Put reusable gameplay code under `res://scripts/` once it is shared.
- Put scenes under `res://scenes/` when the project grows beyond a prototype.
- Put temporary validation or test scenes under `res://tests/`.
- Keep exported variables designer-friendly with clear names and sensible defaults.

## Validation

- Preferred local validation command:

```powershell
./scripts/validate-godot.ps1
```

- If Godot is not on `PATH`, pass the executable explicitly:

```powershell
./scripts/validate-godot.ps1 -GodotPath "C:\Path\To\Godot.exe"
```

- If the script cannot find Godot, still inspect changed GDScript and scene files carefully and report that runtime validation was not available.

## Codex Workflow

- Read `DESIGN.md` before making gameplay, UI, art-direction, level, enemy, tower, score, or progression changes.
- Inspect the relevant scenes, scripts, resources, and `project.godot` before editing.
- Keep changes tightly scoped to the requested behavior.
- For visual or game-feel work, prefer small iterative changes that are easy to tune in the editor.
- After edits, run the validation script when possible and summarize any remaining risk.
