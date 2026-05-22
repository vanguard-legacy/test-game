# Project Reference

This file is the working map for the game codebase. It documents the purpose of each authored project file and every function in the authored GDScript and PowerShell code.

## Coverage Checklist

- [x] Root project guidance and history files: `AGENTS.md`, `CHANGELOG.md`, `DESIGN.md`, `README.md`, `project.godot`.
- [x] Godot scenes: `scenes/enemy.tscn`, `scenes/hud.tscn`, `scenes/level_map.tscn`, `scenes/main.tscn`, `scenes/tower.tscn`.
- [x] Gameplay scripts: all files under `scripts/`.
- [x] Validation and setup tools: all files under `tools/`.
- [x] Smoke tests: all files under `tests/`.
- [x] Authored UI assets: all SVG files under `assets/ui/icons/`.
- [x] Godot metadata: `.uid` and `.import` files are tracked as engine metadata with no authored functions.
- [x] Vendor addon files: `addons/godot-git-plugin/` files are third-party plugin assets with no local gameplay functions.

## Root Files

### `AGENTS.md`

Project instructions for Codex and future agents. It defines Godot development rules, validation commands, daily changelog summary expectations, version-tag expectations, and workflow conventions.

### `CHANGELOG.md`

Human-readable change history. Sections are kept newest first as exactly two-sentence summaries for each day of meaningful project work.

### `DESIGN.md`

Design source of truth for the game pitch, fantasy, mechanics, art direction, inspirations, and current gameplay direction.

### `README.md`

Developer-facing project overview, current feature list, scene layout, architecture notes, Godot setup, and validation instructions.

### `REFERENCE.md`

This file. It maps authored files, generated metadata, vendor files, and function responsibilities so maintainers can find code ownership quickly.

### `project.godot`

Godot project configuration. It sets the project name, main scene, renderer features, Git plugin loading, Jolt Physics, and Windows rendering driver.

## Scenes

### `scenes/main.tscn`

Main playable scene. It instantiates the map, HUD, tower placement controller, enemy container, and tower container, then binds `scripts/main.gd`.

### `scenes/level_map.tscn`

Map scene root for procedural terrain, road/path generation, camera setup, and build-location queries through `scripts/level_map.gd`.

### `scenes/hud.tscn`

Container-based HUD scene. It owns top-bar stats, speed and auto-wave controls, build controls, tower upgrade/sell controls, command log, main menu overlay with seed/loading controls, compact reward panel, and tooltip nodes.

### `scenes/tower.tscn`

Tower scene. It contains tower meshes, range display, focus crystal, banner, roof, and attack-beam mesh used by `scripts/tower.gd`.

### `scenes/enemy.tscn`

Enemy scene. It contains body/head/hat/ear mesh nodes used by `scripts/enemy.gd` for role-colored enemy visuals.

## Scripts

### `scripts/build_placement_result.gd`

Typed result object for tower placement checks.

- `_init(new_has_hit, new_is_valid, new_position, new_reason)`: Initializes whether the cursor hit terrain, whether that point can accept a tower, the proposed build position, and any rejection reason.

### `scripts/camera_controller.gd`

RTS-style camera controller for keyboard/edge panning, middle-mouse terrain-anchored panning, right-mouse rotation, and mouse-wheel zoom.

- `setup(new_camera, new_map_half_size, new_terrain_picker)`: Stores the controlled camera, map bounds, and terrain-query callback, then applies the initial transform.
- `set_controls_enabled(is_enabled)`: Enables or disables camera input and clears drag state when disabled.
- `_process(delta)`: Applies keyboard and edge panning while controls are active.
- `_unhandled_input(event)`: Routes mouse button and mouse motion events into rotation, panning, and zoom behavior.
- `_handle_mouse_button(mouse_button)`: Starts/stops rotation or panning, captures pan anchors, and applies wheel zoom.
- `_is_camera_blocked_by_ui()`: Reports whether the cursor is over interactive UI that should own mouse input.
- `_is_interactive_ui_control(control)`: Classifies buttons, sliders, scroll areas, text inputs, and modal overlays as camera-blocking UI.
- `_stop_mouse_drag()`: Clears active mouse rotation and panning state.
- `_pan_from_keyboard_and_edges(delta)`: Calculates keyboard and edge-scroll movement in camera-relative directions.
- `_pan_by_terrain_anchor(mouse_position)`: Moves the camera target so the grabbed terrain plane follows the cursor.
- `_apply_camera_transform()`: Positions and aims the camera from target, yaw, tilt, and distance values.
- `_camera_forward()`: Returns the current yaw-based horizontal forward vector.
- `_camera_right()`: Returns the current yaw-based horizontal right vector.
- `_clamp_target_position()`: Keeps the camera target within map bounds plus a small margin.
- `_get_terrain_under_cursor(mouse_position)`: Calls the map terrain picker for the current cursor position.
- `_get_cursor_on_pan_plane(mouse_position)`: Intersects the camera ray with the fixed-height pan plane.
- `_get_unscaled_delta(delta)`: Converts scaled frame delta back to real-time delta so camera panning does not accelerate with game speed.

### `scripts/enemy.gd`

Runtime enemy actor. It follows map paths, receives damage and slow effects, and emits lifecycle signals when defeated or when it reaches the exit.

- `_process(delta)`: Advances the enemy along its path and emits `reached_exit` when it finishes.
- `setup(points, wave, definition)`: Applies path, wave-scaled stats, rewards, initial position, and visuals from an enemy definition.
- `take_damage(amount)`: Reduces health and emits `defeated` when health reaches zero.
- `apply_slow(multiplier, duration)`: Applies or refreshes a movement slow effect.
- `_apply_enemy_visuals(definition)`: Sets the node name, scale, and mesh materials for the enemy archetype.
- `_update_slow(delta)`: Counts down slow duration and restores normal speed when it expires.

### `scripts/enemy_definition.gd`

Typed enemy balance definition with per-wave health and speed scaling.

- `_init(data)`: Copies authored dictionary values into named enemy definition fields.
- `health_for_wave(wave)`: Returns scaled health for a given wave.
- `speed_for_wave(wave)`: Returns scaled speed for a given wave.

### `scripts/game_balance.gd`

Central balance catalogue for lives, gold, towers, enemies, rewards, height bonuses, waves, and upgrade costs.

- `get_starting_tower_ids()`: Returns the starting tower loadout.
- `get_default_tower_modifiers()`: Creates the default run-wide tower modifier state.
- `get_tower_definition(tower_id)`: Returns a typed tower definition for the requested tower id.
- `get_tower_cost(tower_id)`: Returns the build cost for a tower id.
- `get_tower_terrain_bonus(terrain_height)`: Converts terrain height into damage/range modifiers and a readable label.
- `get_xp_required_for_level(level)`: Returns the XP threshold for a reward level.
- `get_reward_choices(owned_tower_ids, chosen_reward_ids, reward_level)`: Drafts three reward choices from unlocks, upgrades, and gold fallback rewards.
- `get_enemy_definition(enemy_id)`: Returns a typed enemy definition for the requested enemy id.
- `get_wave_definition(wave)`: Returns a scripted wave if available, otherwise a scaling wave.
- `get_tower_upgrade_cost(level)`: Returns the cost to upgrade from the current tower level.
- `_get_scripted_waves()`: Defines the early authored wave sequence.
- `_make_scaling_wave(wave)`: Builds later mixed waves by scaling count and spawn delay.
- `_repeat_enemy(enemy_id, count)`: Creates a repeated enemy id list.
- `_repeat_pattern(pattern, times)`: Repeats an enemy id pattern for compact wave authoring.
- `_get_upgrade_rewards()`: Defines the non-tower-unlock reward pool.
- `_make_unlock_reward(tower_id)`: Builds a reward that unlocks a tower type.
- `_make_gold_reward(reward_level, index)`: Builds a fallback gold reward with a unique id.
- `_get_height_bonus_label(terrain_height)`: Converts height into a readable terrain-bonus label.
- `_pick_reward_choices(candidates, reward_level)`: Selects up to three reward choices and fills gaps with gold rewards.

### `scripts/game_clock.gd`

Gameplay-side clock boundary for allowed game speed values and `Engine.time_scale`.

- `set_speed(requested_speed)`: Applies an allowed speed, updates `Engine.time_scale`, emits `speed_changed`, and reports success.
- `reset()`: Restores the default speed through the normal speed setter.
- `restore_engine_default()`: Resets the stored speed and engine time scale without emitting the normal speed-change signal.

### `scripts/hud.gd`

Presentation and input layer for the HUD. It renders view models, manages menus/reward overlays/tooltips, styles controls, and emits user intent without mutating run state.

- `_ready()`: Sets process mode, creates dynamic menu seed/loading controls, caches button groups, applies styles, connects signals, and initializes selection UI.
- `_build_menu_seed_controls()`: Adds the current-seed label, seed input, loading label, and loading progress bar to the menu stack.
- `_cache_button_groups()`: Stores related tower-slot, reward-choice, and speed buttons in arrays.
- `_connect_button_signals()`: Wires all HUD buttons and hover events to local handlers.
- `_process(_delta)`: Keeps the tooltip following the cursor while visible.
- `update_from_view_model(view_model)`: Applies the current HUD stats, build options, speed controls, auto-wave state, and start-wave state.
- `set_message(message)`: Appends a non-empty message to the command log and scrolls to the bottom.
- `clear_message_log()`: Clears command log text and resets scroll position.
- `set_build_mode(is_building)`: Shows/enables or hides/disables cancel-build behavior and locks build slots during placement.
- `_update_stats(view_model)`: Copies wave, lives, gold, XP, score, tower count, and incoming count into labels.
- `_update_build_options(view_model)`: Updates the three build slots from owned towers, costs, lock state, and active tower id.
- `_update_speed_controls(game_speed)`: Marks the active speed toggle and dims inactive speed buttons.
- `update_selected_tower(tower, gold)`: Displays selected tower stats and enables/disables upgrade and sell actions.
- `show_main_menu(title, can_resume, can_restart)`: Opens the menu overlay with an appropriate title and resume/restart availability.
- `set_current_seed(seed)`: Updates the menu label that reports the active map seed.
- `set_seed_input(seed_text)`: Updates the editable menu seed field.
- `show_loading_progress(progress, message)`: Updates the terrain-generation progress bar and disables menu run buttons while loading.
- `hide_menu()`: Closes the main menu overlay.
- `show_reward_choices(choices)`: Opens the compact non-modal reward panel and fills up to three reward buttons.
- `hide_reward_choices()`: Closes the reward overlay.
- `show_tower_tooltip(title, body, source)`: Shows a cursor-following tooltip from world, placement, or UI source.
- `hide_tower_tooltip()`: Hides any tooltip and clears its source.
- `hide_world_tower_tooltip()`: Hides tooltips that belong to world or placement hover sources.
- `_on_tower_slot_button_pressed(slot_index)`: Emits a build request for the clicked unlocked tower slot.
- `_on_tower_slot_mouse_entered(slot_index)`: Shows the build-slot tooltip for the hovered tower slot.
- `_on_tower_slot_mouse_exited()`: Hides UI-sourced build-slot tooltips.
- `_on_cancel_build_button_pressed()`: Emits cancel-build intent.
- `_on_start_wave_button_pressed()`: Emits start-wave intent.
- `_on_upgrade_tower_button_pressed()`: Emits selected-tower upgrade intent.
- `_on_sell_tower_button_pressed()`: Emits selected-tower sell intent.
- `_on_reward_choice_button_pressed(choice_index)`: Emits the selected reward index.
- `_on_speed_button_pressed(speed)`: Emits requested game speed.
- `_on_auto_start_button_pressed()`: Emits requested auto-wave toggle state.
- `_on_menu_button_pressed()`: Emits menu-open intent.
- `_on_resume_button_pressed()`: Emits resume intent.
- `_on_new_game_button_pressed()`: Emits new-game intent with the current seed input text.
- `_on_restart_button_pressed()`: Emits restart intent.
- `_on_seed_text_submitted(_submitted_text)`: Starts New Game when the seed input is submitted.
- `_on_quit_button_pressed()`: Emits quit intent.
- `_apply_styles()`: Applies shared panel/button/label theme overrides across HUD controls.
- `_style_stat_labels()`: Styles top-bar stat labels and values.
- `_style_button(button)`: Applies shared button styleboxes, font colors, and icon alignment.
- `_get_build_slot_tooltip(tower_definition)`: Creates tooltip data for a tower build option.
- `_position_tower_tooltip()`: Clamps the tooltip near the cursor inside the viewport.
- `_scroll_command_log_to_bottom()`: Scrolls the command log to its newest line.

### `scripts/hud_view_model.gd`

One-frame HUD data snapshot built by `main.gd` and consumed by `hud.gd`.

No functions.

### `scripts/level_map.gd`

Seeded procedural map owner. It creates broad surrounding terrain, a central generated road, route graph, start/exit markers, atmospheric fog, camera, and tower placement queries.

- `_ready()`: Enables always-on processing so ambient fog animation can continue during menus and paused moments.
- `_process(_delta)`: Updates animated fog bank drift, breathing, and yaw.
- `generate_map(seed, progress_callback)`: Rebuilds the seeded map, reports loading progress, and refreshes the cached enemy path.
- `_report_generation_progress(progress_callback, progress, message)`: Sends a progress value and status message to the caller when a callback is available.
- `_clear_generated_world()`: Removes generated map children and clears camera, controller, path, and navigation state before rebuilding.
- `set_map_seed(seed)`: Stores the seed used by the next generation pass.
- `get_active_camera()`: Returns the map camera used for placement, hover, and camera control.
- `set_camera_controls_enabled(is_enabled)`: Enables or disables the map camera controller when present.
- `get_start_position()`: Returns the 3D start point on generated terrain.
- `get_exit_position()`: Returns the 3D exit point on generated terrain.
- `find_path(from_position, to_position)`: Uses the AStar road graph to return a smoothed path between two world positions.
- `get_enemy_path()`: Returns a fresh path from start to exit for spawned enemies.
- `find_build_position(camera, mouse_position, occupied_positions)`: Converts cursor position into a tower build result with validation.
- `find_terrain_position(camera, mouse_position)`: Raycasts against the procedural heightfield using camera projection.
- `get_tower_terrain_bonus(build_position)`: Converts a build position into a tower height bonus.
- `_build_world()`: Creates the camera, camera controller, sun, terrain mesh, road mesh, atmosphere, fog banks, and start/exit markers.
- `_configure_generation()`: Applies the map seed to terrain noise, detail noise, route generation, and terrain features.
- `_generate_road_points(rng)`: Builds a deterministic winding road from start to exit inside the playable area.
- `_generate_terrain_features(rng)`: Builds deterministic hill and valley features that blend into the terrain heightfield.
- `_add_terrain_mesh()`: Generates the terrain mesh grid and assigns terrain material.
- `_add_road_mesh()`: Generates the road mesh over cells that overlap the authored road.
- `_build_navigation_graph()`: Builds AStar points and connections over road cells.
- `_add_terrain_quad(surface, a, b, c, d)`: Adds two colored triangles for one terrain cell.
- `_add_road_quad(surface, a, b, c, d)`: Adds two colored triangles for one road cell.
- `_add_colored_vertex(surface, vertex, color)`: Adds one vertex with vertex color to a surface.
- `_add_marker(node_name, marker_position, color)`: Creates a start or exit marker mesh.
- `_add_atmosphere()`: Adds world environment fog, volumetric fog, ambient light, and background color for distance atmosphere.
- `_add_fog_banks()`: Places seeded, clustered fog banks around the outer terrain.
- `_add_fog_bank_cluster(parent, index, ground_point, rng)`: Creates one overlapping cluster of shader-softened volumetric-style mist puffs.
- `_animate_fog_banks()`: Applies real-time seeded drift, breathing scale, and slow yaw to generated fog bank clusters.
- `_world_from_ground(point, y_offset)`: Converts an X/Z ground point into a 3D world position at generated height.
- `_height_at(point)`: Calculates blended terrain and road height for a ground point.
- `_rolling_height_at(point)`: Calculates the seed-driven terrain height before road smoothing is applied.
- `_terrain_color_at(point)`: Picks terrain vertex color from height and local slope.
- `_road_color_at(point)`: Picks road vertex color from distance to road edge.
- `_edge_atmosphere_amount(point)`: Calculates how much terrain and road color should fade into the edge atmosphere.
- `_road_height(progress)`: Evaluates road elevation along route progress.
- `_road_half_width(progress)`: Evaluates changing road half-width along route progress.
- `_is_road(point)`: Returns whether a ground point lies inside the road width.
- `_get_road_info(point)`: Finds nearest road segment distance and normalized route progress.
- `_road_length()`: Calculates total polyline road length.
- `_find_terrain_hit(ray_origin, ray_direction)`: Marches a ray against the procedural heightfield and returns the first hit.
- `_refine_hit_distance(ray_origin, ray_direction, min_distance, max_distance)`: Binary-searches a terrain hit distance for smoother cursor placement.
- `_get_blocked_reason(ground_point, occupied_positions)`: Returns the first reason a tower cannot be placed at a ground point.
- `_get_local_slope(point)`: Samples nearby heights to estimate local slope.
- `_path_id(x_index, z_index)`: Converts navigation-grid coordinates into a stable AStar id.

### `scripts/main.gd`

Game coordinator. It connects map generation, placement, HUD, clock, run state, enemies, towers, rewards, economy, wave flow, selection, and camera control.

- `_ready()`: Restores default game speed, connects scene signals, and shows the initial menu.
- `_connect_scene_signals()`: Wires map placement signals and HUD intent signals into coordinator handlers.
- `_show_initial_menu()`: Clears log, shows the seed-aware initial menu, and refreshes HUD.
- `_process(delta)`: Advances spawning/wave-complete checks, hover tooltips, and HUD updates while the game is active.
- `_unhandled_input(event)`: Handles restart, pause/menu, tower selection, and deselection input.
- `_start_next_wave()`: Starts the next wave from balance data and cancels tower placement.
- `_spawn_wave_enemies(delta)`: Counts down spawn cooldown and spawns the next queued enemy.
- `_spawn_enemy(enemy_id)`: Instantiates an enemy, applies setup, connects lifecycle signals, and tracks it.
- `_on_enemy_reached_exit(enemy)`: Removes an exited enemy, reduces lives, and triggers defeat if needed.
- `_on_enemy_defeated(enemy)`: Removes a defeated enemy, awards score/gold/XP, and opens rewards if XP levels up.
- `_check_wave_complete()`: Detects empty queues/enemy lists, closes waves, and grants wave-clear XP.
- `_on_build_tower_requested(tower_id)`: Validates build availability and starts tower placement.
- `_on_cancel_build_requested()`: Cancels active tower placement.
- `_on_start_wave_requested()`: Validates start-wave conditions and starts the next wave.
- `_on_tower_placement_confirmed(placement_position)`: Instantiates and configures a tower, spends gold, selects it, and updates HUD.
- `_on_tower_placement_cancelled()`: Hides placement tooltip and logs cancellation.
- `_on_tower_placement_rejected(reason)`: Logs why placement was rejected.
- `_on_placement_mode_changed(is_placing)`: Mirrors placement state into HUD build controls.
- `_on_tower_placement_updated(result)`: Shows placement tooltip with tower and terrain-bonus preview.
- `_on_upgrade_tower_requested()`: Validates gold/level and upgrades the selected tower.
- `_on_sell_tower_requested()`: Sells the selected tower, refunds half build cost, clears selection, and removes the node.
- `_on_reward_choice_selected(choice_index)`: Applies the chosen reward, clears reward state, unpauses, and updates HUD.
- `_on_menu_requested()`: Opens the pause menu.
- `_on_resume_requested()`: Unpauses, hides the menu, and restores camera controls.
- `_on_new_game_requested(seed_text)`: Parses the requested seed text and starts a fresh generated map.
- `_on_restart_requested()`: Restarts the run by regenerating the current map seed.
- `_on_quit_requested()`: Restores normal time scale and quits the tree.
- `_on_game_speed_requested(requested_speed)`: Passes requested speed to the game clock.
- `_on_auto_start_toggled(is_enabled)`: Stores auto-wave preference, announces the change, and starts a wave immediately when appropriate.
- `_game_over()`: Marks defeat, cancels placement, shows defeat menu, and updates HUD.
- `_start_run(seed, regenerate_map)`: Shows loading UI, optionally regenerates the map for a seed, and starts a clean run.
- `_on_map_generation_progress(progress, message)`: Forwards map-generation progress updates to the HUD.
- `_clear_run_entities()`: Frees enemies/towers and clears selection/reward arrays.
- `_restart_game()`: Resets selections, clock, run state, logs, overlays, and HUD after entities have been cleared.
- `_update_ui()`: Sends a fresh view model and selected tower data to the HUD, then syncs camera controls.
- `_make_hud_view_model()`: Builds the HUD snapshot from run state, placement state, auto-wave state, and game clock.
- `_get_tower_positions()`: Collects placed tower positions for placement spacing checks.
- `_select_tower(tower)`: Deselects the previous tower, selects a new one, and updates tower controls.
- `_clear_selected_tower()`: Clears current tower selection and updates tower controls.
- `_find_tower_at_mouse()`: Picks a tower under the mouse using screen-space then terrain-space checks.
- `_find_tower_near_screen_position(camera, mouse_position)`: Returns the closest tower projected near the cursor.
- `_open_pause_menu()`: Pauses and opens the menu when the game can be paused.
- `_open_reward_choices()`: Drafts reward choices and shows the non-modal reward panel without pausing gameplay.
- `_maybe_auto_start_next_wave()`: Starts the next wave automatically when auto-wave is enabled and the board can launch safely.
- `_apply_tower_modifiers()`: Reapplies run-wide tower modifiers to every valid tower.
- `_update_hovered_tower()`: Shows or hides world tower tooltips based on cursor and placement state.
- `_sync_camera_controls()`: Enables camera controls only while gameplay can accept them.
- `_set_game_speed(requested_speed, announce_change)`: Applies game speed through the clock, optionally logs it, and refreshes HUD.
- `_seed_from_text(seed_text)`: Converts empty, numeric, or text seed input into a non-zero integer map seed.
- `_make_random_seed()`: Produces a non-zero random seed for fresh maps.

### `scripts/materials.gd`

Shared 3D material and shader factory for terrain, roads, tower visuals, enemies, highlights, and beams.

- `standard(color)`: Creates a rough standard 3D material with the provided color.
- `transparent(color)`: Creates an alpha-enabled material from the standard material setup.
- `unshaded(color)`: Creates an unshaded material from the standard material setup.
- `vertex_colored()`: Creates a material that uses mesh vertex colors as albedo.
- `terrain()`: Returns the terrain shader material, or a vertex-color fallback in headless mode.
- `road()`: Returns the road shader material, or a vertex-color fallback in headless mode.
- `fog_bank()`: Returns the animated noisy volumetric-style fog bank shader material, or an alpha fallback in headless mode.

### `scripts/reward_definition.gd`

Typed reward data for tower unlocks, run modifiers, and gold caches.

- `_init(data)`: Copies authored dictionary values into named reward fields.

### `scripts/road_info.gd`

Small typed result for road distance/progress calculations.

- `_init(new_distance, new_progress)`: Initializes nearest-road distance and normalized route progress.

### `scripts/run_state.gd`

Pure run-state model with no scene nodes. It owns economy, wave queue, XP/rewards, unlocks, modifiers, and game status flags.

- `reset(keep_started)`: Resets all run numbers, queues, rewards, unlocks, and modifiers.
- `start_wave(wave_definition)`: Advances wave number and fills the spawn queue from a wave definition.
- `has_pending_spawns()`: Reports whether the spawn queue has unspawned entries.
- `next_enemy_id()`: Pops and returns the next enemy id from the spawn queue.
- `incoming_count(active_enemy_count)`: Combines active enemies and queued enemies for HUD display.
- `add_xp(amount)`: Adds XP and marks reward pending when the next threshold is reached.
- `complete_reward(reward)`: Applies unlock, modifier, or gold rewards and advances reward level.
- `can_afford_any_owned_tower()`: Reports whether current gold can buy any unlocked tower.

### `scripts/terrain_query.gd`

Typed result for camera-to-terrain hit checks.

- `_init(new_has_hit, new_position)`: Initializes terrain-hit state and hit position.

### `scripts/tooltip_data.gd`

Typed UI payload for tooltip title/body pairs.

- `_init(new_title, new_body)`: Initializes tooltip title and body text.

### `scripts/tower.gd`

Runtime tower actor. It handles targeting, attack effects, upgrades, terrain/global modifiers, selection visuals, selling value, and hover text.

- `_process(delta)`: Updates beam visibility, counts down attack cooldown, finds targets, attacks, and shows beams.
- `setup(new_tower_id, modifiers)`: Applies tower identity, cost, global modifiers, and definition data.
- `set_targets(new_targets)`: Stores the shared enemy target array.
- `apply_global_modifiers(modifiers)`: Copies run-wide tower modifiers and recalculates stats.
- `apply_terrain_bonus(new_terrain_bonus)`: Stores terrain-derived modifiers and recalculates stats.
- `set_selected(new_is_selected)`: Shows or hides the selected tower range highlight.
- `_find_target()`: Chooses the closest valid enemy inside attack range.
- `can_upgrade()`: Reports whether the tower is below max level.
- `get_upgrade_cost()`: Returns the next upgrade cost or zero at max level.
- `upgrade()`: Increases level and refreshes stats/visual scale.
- `get_display_name()`: Returns tower name with level suffix.
- `get_upgrade_summary()`: Returns upgrade cost text or max-level text.
- `get_sell_value()`: Returns half of the tower build cost.
- `get_hover_description()`: Returns multi-line combat, terrain, upgrade, and sell tooltip text.
- `_ready()`: Initializes range material, applies current tower definition, and refreshes visuals.
- `_attack(target)`: Applies bolt, frost, or splash attack behavior to the target and nearby enemies.
- `_get_effect_summary()`: Returns readable text for the tower effect.
- `_apply_tower_definition(definition)`: Copies definition stats/visual colors and refreshes live stats.
- `_recalculate_stats()`: Combines base stats, level bonuses, global modifiers, and terrain bonuses.
- `_update_upgrade_visuals()`: Scales the focus crystal and tower range mesh to current level/range.
- `_show_beam(from_position, to_position)`: Draws and shows a short-lived attack beam.
- `_update_beam(delta)`: Hides the attack beam after its display timer expires.

### `scripts/tower_definition.gd`

Typed tower balance/visual definition built from compact authored data.

- `_init(data)`: Copies authored dictionary values into named tower definition fields.
- `get_effect_summary()`: Returns readable effect text for build tooltips.
- `get_build_tooltip_body()`: Returns a multi-line tower build tooltip.

### `scripts/tower_modifiers.gd`

Run-wide tower modifier state earned from reward choices.

- `duplicate_modifiers()`: Creates an independent copy of the current modifier values.
- `apply_reward(reward)`: Adds damage/range modifiers and multiplies fire-rate modifiers from a reward.

### `scripts/tower_placement.gd`

Tower placement preview and click lifecycle controller.

- `_ready()`: Builds the placement preview mesh.
- `setup(map)`: Stores the level map and active camera.
- `begin_placement(new_occupied_positions)`: Starts placement with current occupied tower positions.
- `cancel_placement()`: Ends placement, hides preview, resets result, and emits cancellation/state signals.
- `_process(_delta)`: Updates the placement preview while placement is active.
- `_unhandled_input(event)`: Handles cancel/confirm input during placement.
- `_update_preview()`: Queries build validity, emits placement updates, positions preview, and sets preview material.
- `_build_preview()`: Creates the cylinder preview mesh and its valid/invalid materials.

### `scripts/tower_terrain_bonus.gd`

Typed combat modifier created from terrain height under a tower.

- `_init(new_height, new_damage_multiplier, new_range_bonus, new_label)`: Initializes terrain height, damage multiplier, range bonus, and label.
- `get_summary()`: Returns readable terrain bonus text for tooltips.

### `scripts/ui_theme.gd`

Shared HUD style factory and color constants.

- `panel_style()`: Creates the shared panel stylebox.
- `button_style(color)`: Creates a shared button stylebox for a given button color.

### `scripts/wave_definition.gd`

Typed wave data consumed by run state and spawning code.

- `from_values(new_title, new_enemy_ids, new_spawn_delay)`: Builds a wave definition from title, enemy id list, and spawn delay.
- `_copy_enemy_ids(value)`: Copies a variant array into a typed string array.

## Tests

### `tests/stability_smoke.gd`

Headless gameplay smoke test that checks reward drafting, starting a game, speed control, auto-wave toggling, non-modal rewards, tower placement, selected-tower selling, and two wave completions.

- `_initialize()`: Defers the smoke test until the scene tree is ready.
- `_run_smoke()`: Orchestrates the full smoke scenario, waits for async map generation, verifies wave progress, and exits with success on `STABILITY_SMOKE_OK`.
- `_verify_reward_choices()`: Ensures reward drafting always returns three non-empty reward ids.
- `_place_test_towers(main)`: Places a fixed set of towers at known ground points.
- `_verify_game_speed(main)`: Confirms 4x and 1x speed requests update `Engine.time_scale`.
- `_verify_auto_start_toggle(main)`: Confirms auto-wave intent toggles gameplay state on and off.
- `_verify_reward_overlay_non_modal(main)`: Confirms reward choices open without pausing gameplay.
- `_verify_sell_tower(main)`: Confirms selecting and selling a non-last tower removes it and refunds gold.
- `_run_wave_until_complete(main)`: Manually steps main, towers, and enemies until a wave ends, reward appears, defeat occurs, or timeout fails the test.

### `tests/stability_smoke.gd.uid`

Godot script UID metadata for the smoke test. No authored functions.

## Tools

### `tools/set-godot.ps1`

PowerShell setup script for switching Godot versions. It stores the selected executable in user-level `GODOT_EXE`, writes a stable `godot.cmd` shim to `~/bin`, updates the user PATH if needed, and prints the active Godot version.

No named PowerShell functions.

### `tools/validate-godot.ps1`

PowerShell validation wrapper that resolves Godot, keeps validation logs under `.godot/codex_validation`, runs project validation, and optionally runs the stability smoke.

- `Resolve-Godot(ExplicitPath)`: Resolves an explicit Godot executable, `GODOT_EXE`, a PATH command, or a project-local candidate.
- `Read-Log-With-Retry(Path, ExpectedPattern, Attempts)`: Reads a Godot log file, retrying until content or an expected pattern appears.

## Assets And Metadata

### Authored UI Icons

- `assets/ui/icons/cancel.svg`: Cancel/sell-style icon used by HUD buttons.
- `assets/ui/icons/tower.svg`: Tower icon used by build and upgrade controls.
- `assets/ui/icons/wave.svg`: Wave icon used by the start-wave control.

### Godot Import Metadata

- `assets/ui/icons/cancel.svg.import`: Godot import metadata for the cancel icon. No functions.
- `assets/ui/icons/tower.svg.import`: Godot import metadata for the tower icon. No functions.
- `assets/ui/icons/wave.svg.import`: Godot import metadata for the wave icon. No functions.
- `icon.svg`: Project icon source asset.
- `icon.svg.import`: Godot import metadata for the project icon. No functions.

### Script UID Metadata

The following files are Godot UID metadata for scripts and contain no authored functions:

- `scripts/build_placement_result.gd.uid`
- `scripts/camera_controller.gd.uid`
- `scripts/enemy.gd.uid`
- `scripts/enemy_definition.gd.uid`
- `scripts/game_balance.gd.uid`
- `scripts/hud.gd.uid`
- `scripts/hud_view_model.gd.uid`
- `scripts/level_map.gd.uid`
- `scripts/main.gd.uid`
- `scripts/materials.gd.uid`
- `scripts/reward_definition.gd.uid`
- `scripts/road_info.gd.uid`
- `scripts/run_state.gd.uid`
- `scripts/terrain_query.gd.uid`
- `scripts/tooltip_data.gd.uid`
- `scripts/tower.gd.uid`
- `scripts/tower_definition.gd.uid`
- `scripts/tower_modifiers.gd.uid`
- `scripts/tower_placement.gd.uid`
- `scripts/tower_terrain_bonus.gd.uid`
- `scripts/ui_theme.gd.uid`
- `scripts/wave_definition.gd.uid`

### Godot Git Plugin Vendor Files

These files belong to the Godot Git plugin and are not authored gameplay code:

- `addons/godot-git-plugin/LICENSE`: Plugin license.
- `addons/godot-git-plugin/THIRDPARTY.md`: Plugin third-party notices.
- `addons/godot-git-plugin/git_plugin.gdextension`: Plugin extension registration.
- `addons/godot-git-plugin/git_plugin.gdextension.uid`: Godot UID metadata for the extension registration.
- `addons/godot-git-plugin/windows/libgit_plugin.windows.editor.x86_64.dll`: Windows editor plugin binary.
- `addons/godot-git-plugin/linux/libgit_plugin.linux.editor.x86_64.so`: Linux editor plugin binary.
- `addons/godot-git-plugin/macos/libgit_plugin.macos.editor.universal.dylib`: macOS editor plugin binary.
