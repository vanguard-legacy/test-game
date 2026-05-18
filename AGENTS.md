# Codex Instructions

## Project Snapshot

- Godot project: `test-game`
- Engine target: Godot 4.6 features, Forward Plus renderer
- Physics: Jolt Physics for 3D
- Version control plugin: Godot Git plugin is enabled
- Game concept: 3D high-fantasy medieval tower defense where terrain height, path width, seasons, weather, towers, and enemy variety drive strategy.
- Design source of truth: `DESIGN.md`
- Change history: `CHANGELOG.md`
- Current project is intentionally small; preserve that simplicity unless the task asks for structure.

## Godot Development Rules

- Prefer Godot 4.x patterns and APIs.
- Use GDScript unless the user explicitly requests C# or GDExtension.
- Prefer statically typed GDScript: typed variables, typed arrays where useful, typed parameters, and return types.
- Prefer typed `RefCounted` payloads for cross-script data such as definitions, view models, and query results; keep raw dictionaries isolated to compact balance authoring or file/resource parsing.
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
- Keep coordinator scripts thin. If a call starts collecting many parameters, introduce a small typed model or move the ownership to the script that already owns that state.
- Keep enemy, tower, wave, and economy numbers centralized in `scripts/game_balance.gd`.
- Keep run progress/state in `scripts/run_state.gd` rather than scattering counters through scene scripts.

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
- Treat Godot validation warnings as actionable lint feedback. Fix shadowed base-class properties, shadowed built-ins such as `range`, parser warnings, and script errors before calling the work complete.

## Codex Workflow

- Read `DESIGN.md` before making gameplay, UI, art-direction, level, enemy, tower, score, or progression changes.
- Keep `CHANGELOG.md` current when making meaningful gameplay, architecture, asset, UI, validation, or documentation changes.
- Changelog entries should be dated, concise, written for future developers rather than as a transcript of the chat, and kept in reverse chronological order with `Unreleased` first.
- Version tags should use date-based names in the form `YYYY-MM-DD.N`, where `N` increments for each tag created on the same date.
- When creating a version tag, move the relevant `Unreleased` entries into a matching changelog release heading such as `## [YYYY-MM-DD.N] - YYYY-MM-DD`, and keep the bottom link references in sync.
- Inspect the relevant scenes, scripts, resources, and `project.godot` before editing.
- Keep changes tightly scoped to the requested behavior.
- For visual or game-feel work, prefer small iterative changes that are easy to tune in the editor.
- After edits, run the validation script when possible and summarize any remaining risk.
- When validation reports GDScript warnings, rerun it after fixes and confirm the warning output is clean.
- For combat, wave, tower, enemy, or reward changes, run the headless combat smoke when feasible:

```powershell
./scripts/validate-godot.ps1 -RunSmoke
```

- If Godot process launches are unstable on the current machine, first inspect the safe validation commands without running the engine:

```powershell
./scripts/validate-godot.ps1 -RunSmoke -ShowCommandOnly
```
