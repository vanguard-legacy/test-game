extends Node3D

const GameBalance := preload("res://scripts/game_balance.gd")
const HudViewModel := preload("res://scripts/hud_view_model.gd")
const RewardDefinition := preload("res://scripts/reward_definition.gd")
const RunState := preload("res://scripts/run_state.gd")
const BuildPlacementResult := preload("res://scripts/build_placement_result.gd")
const GameClock := preload("res://scripts/game_clock.gd")
const LevelMap := preload("res://scripts/level_map.gd")
const TowerPlacement := preload("res://scripts/tower_placement.gd")
const Hud := preload("res://scripts/hud.gd")
const Enemy := preload("res://scripts/enemy.gd")
const Tower := preload("res://scripts/tower.gd")

const TOWER_SCREEN_PICK_RADIUS: float = 52.0
const TOWER_GROUND_PICK_RADIUS: float = 0.95

# Scene coordinator for the game. Main wires scenes together and translates
# user intent into gameplay actions, while balance, run state, HUD formatting,
# and per-node behavior stay in focused scripts.

@export var enemy_scene: PackedScene
@export var tower_scene: PackedScene

@onready var level_map: LevelMap = $LevelMap
@onready var tower_placement: TowerPlacement = $TowerPlacement
@onready var hud: Hud = $Hud
@onready var enemy_container: Node3D = $Enemies
@onready var tower_container: Node3D = $Towers

var enemies: Array[Enemy] = []
var towers: Array[Tower] = []
var run_state: RunState = RunState.new()
var selected_tower: Tower = null
var selected_tower_id: String = GameBalance.TOWER_GWIZARD
var active_reward_choices: Array[RewardDefinition] = []
var game_clock: GameClock = GameClock.new()
var current_map_seed: int = 0
var is_generating_map: bool = false


func _ready() -> void:
	game_clock.restore_engine_default()
	_connect_scene_signals()
	_show_initial_menu()


func _connect_scene_signals() -> void:
	tower_placement.setup(level_map)
	tower_placement.placement_confirmed.connect(_on_tower_placement_confirmed)
	tower_placement.placement_cancelled.connect(_on_tower_placement_cancelled)
	tower_placement.placement_rejected.connect(_on_tower_placement_rejected)
	tower_placement.placement_mode_changed.connect(_on_placement_mode_changed)
	tower_placement.placement_updated.connect(_on_tower_placement_updated)
	hud.build_tower_requested.connect(_on_build_tower_requested)
	hud.cancel_build_requested.connect(_on_cancel_build_requested)
	hud.start_wave_requested.connect(_on_start_wave_requested)
	hud.upgrade_tower_requested.connect(_on_upgrade_tower_requested)
	hud.sell_tower_requested.connect(_on_sell_tower_requested)
	hud.reward_choice_selected.connect(_on_reward_choice_selected)
	hud.menu_requested.connect(_on_menu_requested)
	hud.resume_requested.connect(_on_resume_requested)
	hud.new_game_requested.connect(_on_new_game_requested)
	hud.restart_requested.connect(_on_restart_requested)
	hud.quit_requested.connect(_on_quit_requested)
	hud.game_speed_requested.connect(_on_game_speed_requested)


func _show_initial_menu() -> void:
	hud.clear_message_log()
	hud.set_current_seed(current_map_seed)
	hud.set_seed_input("")
	hud.show_loading_progress(1.0, "Choose a seed or leave it blank.")
	hud.set_message("Choose New Game to generate a map.")
	hud.show_main_menu("G'wizard Defense", false, false)
	_update_ui()


func _process(delta: float) -> void:
	if run_state.game_over or not run_state.game_started or get_tree().paused:
		return

	if run_state.wave_active:
		_spawn_wave_enemies(delta)
		_check_wave_complete()

	# Hovering is intentionally owned by Main because tower picking needs the
	# active 3D camera, while the tooltip rendering belongs to the HUD.
	_update_hovered_tower()
	_update_ui()


func _unhandled_input(event: InputEvent) -> void:
	if run_state.game_over and event.is_action_pressed("ui_accept"):
		if current_map_seed != 0:
			await _start_run(current_map_seed, true)
		return

	if event.is_action_pressed("ui_cancel"):
		if tower_placement.is_active:
			return

		_open_pause_menu()
		return

	var mouse_event := event as InputEventMouseButton
	if mouse_event == null or not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return

	var tower := _find_tower_at_mouse()
	if tower != null:
		_select_tower(tower)
	else:
		_clear_selected_tower()


func _start_next_wave() -> void:
	if run_state.wave_active:
		return

	var next_wave: int = run_state.wave + 1
	var wave_definition := GameBalance.get_wave_definition(next_wave)
	run_state.start_wave(wave_definition)
	tower_placement.cancel_placement()
	hud.set_message(wave_definition.title)


func _spawn_wave_enemies(delta: float) -> void:
	if not run_state.has_pending_spawns():
		return

	run_state.spawn_cooldown -= delta
	if run_state.spawn_cooldown > 0.0:
		return

	_spawn_enemy(run_state.next_enemy_id())
	run_state.spawn_cooldown = run_state.spawn_delay


func _spawn_enemy(enemy_id: String) -> void:
	var enemy := enemy_scene.instantiate() as Enemy
	enemy_container.add_child(enemy)
	enemy.setup(level_map.get_enemy_path(), run_state.wave, GameBalance.get_enemy_definition(enemy_id))
	enemy.reached_exit.connect(_on_enemy_reached_exit)
	enemy.defeated.connect(_on_enemy_defeated)
	enemies.append(enemy)


func _on_enemy_reached_exit(enemy: Enemy) -> void:
	enemies.erase(enemy)
	enemy.queue_free()
	run_state.lives -= 1
	hud.set_message("An enemy reached the exit.")

	if run_state.lives <= 0:
		_game_over()


func _on_enemy_defeated(enemy: Enemy) -> void:
	enemies.erase(enemy)
	enemy.queue_free()
	run_state.score += enemy.score_reward
	run_state.gold += enemy.gold_reward
	if run_state.add_xp(enemy.xp_reward):
		_open_reward_choices()


func _check_wave_complete() -> void:
	if run_state.has_pending_spawns() or not enemies.is_empty():
		return

	run_state.wave_active = false
	if run_state.add_xp(GameBalance.WAVE_CLEAR_XP):
		_open_reward_choices()
		return

	hud.set_message("Wave clear. Build more or start the next wave.")


func _on_build_tower_requested(tower_id: String) -> void:
	if run_state.game_over or not run_state.game_started:
		return

	hud.hide_tower_tooltip()
	if not run_state.owned_tower_ids.has(tower_id):
		hud.set_message("That tower is not unlocked yet.")
		return

	var tower_cost := GameBalance.get_tower_cost(tower_id)
	if run_state.gold < tower_cost:
		hud.set_message("Not enough gold for that tower.")
		return

	selected_tower_id = tower_id
	tower_placement.begin_placement(_get_tower_positions())
	var tower_definition := GameBalance.get_tower_definition(selected_tower_id)
	hud.set_message("Place the %s on a green patch of land." % tower_definition.display_name)


func _on_cancel_build_requested() -> void:
	tower_placement.cancel_placement()


func _on_start_wave_requested() -> void:
	if run_state.game_over or run_state.wave_active or not run_state.game_started:
		return

	if towers.is_empty():
		hud.set_message("Place at least one tower before starting the wave.")
		return

	_start_next_wave()


func _on_tower_placement_confirmed(placement_position: Vector3) -> void:
	var tower_cost := GameBalance.get_tower_cost(selected_tower_id)
	if run_state.gold < tower_cost:
		hud.set_message("Not enough gold for that tower.")
		tower_placement.cancel_placement()
		return

	var tower := tower_scene.instantiate() as Tower
	tower_container.add_child(tower)
	tower.setup(selected_tower_id, run_state.tower_modifiers)
	tower.global_position = placement_position
	tower.apply_terrain_bonus(level_map.get_tower_terrain_bonus(placement_position))
	tower.set_targets(enemies)
	towers.append(tower)
	run_state.gold -= tower_cost
	tower_placement.cancel_placement()
	_select_tower(tower)
	hud.set_message("%s placed. Build more or start the wave." % tower.get_display_name())
	_update_ui()


func _on_tower_placement_cancelled() -> void:
	hud.hide_tower_tooltip()
	if not run_state.game_over:
		hud.set_message("Build cancelled.")


func _on_tower_placement_rejected(reason: String) -> void:
	hud.set_message(reason)


func _on_placement_mode_changed(is_placing: bool) -> void:
	hud.set_build_mode(is_placing)
	if not is_placing:
		hud.hide_tower_tooltip()
	_update_ui()


func _on_tower_placement_updated(result: BuildPlacementResult) -> void:
	if not result.has_hit or not result.is_valid:
		hud.hide_tower_tooltip()
		return

	var tower_definition := GameBalance.get_tower_definition(selected_tower_id)
	var terrain_bonus := level_map.get_tower_terrain_bonus(result.position)
	hud.show_tower_tooltip(
		"%s placement" % tower_definition.short_name,
		"%s\n%s" % [tower_definition.description, terrain_bonus.get_summary()],
		"placement"
	)


func _on_upgrade_tower_requested() -> void:
	if selected_tower == null or not is_instance_valid(selected_tower):
		hud.set_message("Select a tower to upgrade.")
		return

	var upgrade_cost := selected_tower.get_upgrade_cost()
	if upgrade_cost <= 0:
		hud.set_message("That tower is already fully upgraded.")
		return

	if run_state.gold < upgrade_cost:
		hud.set_message("Not enough gold for that upgrade.")
		return

	run_state.gold -= upgrade_cost
	selected_tower.upgrade()
	hud.set_message("%s upgraded." % selected_tower.get_display_name())
	_update_ui()


func _on_sell_tower_requested() -> void:
	if selected_tower == null or not is_instance_valid(selected_tower):
		hud.set_message("Select a tower to sell.")
		return

	var sold_tower := selected_tower
	var refund := sold_tower.get_sell_value()
	var sold_name := sold_tower.get_display_name()
	towers.erase(sold_tower)
	_clear_selected_tower()
	run_state.gold += refund
	hud.hide_tower_tooltip()
	sold_tower.queue_free()
	hud.set_message("%s sold for %d gold." % [sold_name, refund])
	_update_ui()


func _on_reward_choice_selected(choice_index: int) -> void:
	if choice_index < 0 or choice_index >= active_reward_choices.size():
		return

	var reward := active_reward_choices[choice_index]
	run_state.complete_reward(reward)
	_apply_tower_modifiers()
	if not run_state.owned_tower_ids.has(selected_tower_id):
		selected_tower_id = run_state.owned_tower_ids[0]

	active_reward_choices.clear()
	hud.hide_reward_choices()
	get_tree().paused = false
	hud.set_message("Reward chosen: %s." % reward.title)
	_update_ui()


func _on_menu_requested() -> void:
	_open_pause_menu()


func _on_resume_requested() -> void:
	if is_generating_map:
		return

	get_tree().paused = false
	hud.hide_menu()
	_sync_camera_controls()


func _on_new_game_requested(seed_text: String = "") -> void:
	if is_generating_map:
		return

	var next_seed := _seed_from_text(seed_text)
	await _start_run(next_seed, true)


func _on_restart_requested() -> void:
	if is_generating_map or current_map_seed == 0:
		return

	await _start_run(current_map_seed, true)


func _on_quit_requested() -> void:
	game_clock.restore_engine_default()
	get_tree().quit()


func _on_game_speed_requested(requested_speed: float) -> void:
	_set_game_speed(requested_speed)


func _game_over() -> void:
	run_state.game_over = true
	run_state.wave_active = false
	tower_placement.cancel_placement()
	hud.hide_tower_tooltip()
	hud.set_message("Defeat. Press Enter or Space to try again.")
	hud.show_main_menu("Defeat", false, current_map_seed != 0)
	_update_ui()


func _start_run(seed: int, regenerate_map: bool) -> void:
	is_generating_map = true
	get_tree().paused = false
	hud.hide_tower_tooltip()
	hud.hide_reward_choices()
	hud.show_main_menu("Generating Map", false, false)
	hud.set_current_seed(seed)
	hud.show_loading_progress(0.0, "Preparing map.")
	_clear_run_entities()

	if regenerate_map:
		await level_map.generate_map(seed, Callable(self, "_on_map_generation_progress"))
		tower_placement.setup(level_map)

	current_map_seed = seed
	is_generating_map = false
	_restart_game()
	hud.set_current_seed(current_map_seed)
	hud.show_loading_progress(1.0, "Map ready.")
	hud.hide_menu()


func _on_map_generation_progress(progress: float, message: String) -> void:
	hud.show_loading_progress(progress, message)


func _clear_run_entities() -> void:
	for enemy in enemies:
		enemy.queue_free()

	for tower in towers:
		tower.queue_free()

	enemies.clear()
	towers.clear()
	selected_tower = null
	selected_tower_id = GameBalance.TOWER_GWIZARD
	active_reward_choices.clear()


func _restart_game() -> void:
	_clear_run_entities()
	game_clock.reset()
	run_state.game_started = true
	run_state.reset(run_state.game_started)
	hud.clear_message_log()
	hud.set_message("Map seed %d. Build a tower, then start the wave." % current_map_seed)
	hud.hide_menu()
	hud.hide_reward_choices()
	hud.hide_tower_tooltip()
	_update_ui()


func _update_ui() -> void:
	hud.update_from_view_model(_make_hud_view_model())
	hud.update_selected_tower(selected_tower, run_state.gold)
	_sync_camera_controls()


func _make_hud_view_model() -> HudViewModel:
	var view_model := HudViewModel.new()
	view_model.wave = run_state.wave
	view_model.lives = run_state.lives
	view_model.score = run_state.score
	view_model.gold = run_state.gold
	view_model.xp = run_state.xp
	view_model.xp_to_next = run_state.xp_to_next
	view_model.incoming = run_state.incoming_count(enemies.size())
	view_model.tower_count = towers.size()
	view_model.owned_tower_ids = run_state.owned_tower_ids.duplicate()
	view_model.active_tower_id = selected_tower_id
	view_model.can_build = run_state.game_started and not run_state.game_over
	view_model.is_building = tower_placement.is_active
	view_model.can_start_wave = run_state.game_started and not run_state.game_over and not run_state.wave_active and not towers.is_empty()
	view_model.game_speed = game_clock.speed
	return view_model


func _get_tower_positions() -> Array[Vector3]:
	var positions: Array[Vector3] = []
	for tower in towers:
		positions.append(tower.global_position)

	return positions


func _select_tower(tower: Tower) -> void:
	if selected_tower != null and is_instance_valid(selected_tower):
		selected_tower.set_selected(false)

	selected_tower = tower
	if selected_tower != null and is_instance_valid(selected_tower):
		selected_tower.set_selected(true)

	hud.update_selected_tower(selected_tower, run_state.gold)


func _clear_selected_tower() -> void:
	if selected_tower != null and is_instance_valid(selected_tower):
		selected_tower.set_selected(false)

	selected_tower = null
	hud.update_selected_tower(null, run_state.gold)


func _find_tower_at_mouse() -> Tower:
	var camera := level_map.get_active_camera()
	if camera == null:
		return null

	var mouse_position := get_viewport().get_mouse_position()
	var screen_picked_tower := _find_tower_near_screen_position(camera, mouse_position)
	if screen_picked_tower != null:
		return screen_picked_tower

	var terrain_hit := level_map.find_terrain_position(camera, mouse_position)
	if not terrain_hit.has_hit:
		return null

	var hit_position := terrain_hit.position
	var hit_point := Vector2(hit_position.x, hit_position.z)
	for tower in towers:
		var tower_point := Vector2(tower.global_position.x, tower.global_position.z)
		if tower_point.distance_to(hit_point) <= TOWER_GROUND_PICK_RADIUS:
			return tower

	return null


func _find_tower_near_screen_position(camera: Camera3D, mouse_position: Vector2) -> Tower:
	var closest_tower: Tower = null
	var closest_distance := TOWER_SCREEN_PICK_RADIUS
	for tower in towers:
		if not is_instance_valid(tower):
			continue

		var pick_position := tower.global_position + Vector3(0.0, 0.75, 0.0)
		if camera.is_position_behind(pick_position):
			continue

		var screen_position := camera.unproject_position(pick_position)
		var screen_distance := screen_position.distance_to(mouse_position)
		if screen_distance <= closest_distance:
			closest_distance = screen_distance
			closest_tower = tower

	return closest_tower


func _open_pause_menu() -> void:
	if is_generating_map or not run_state.game_started or run_state.game_over:
		return

	get_tree().paused = true
	hud.hide_tower_tooltip()
	hud.show_main_menu("Paused", true, current_map_seed != 0)
	_sync_camera_controls()


func _open_reward_choices() -> void:
	active_reward_choices = GameBalance.get_reward_choices(run_state.owned_tower_ids, run_state.chosen_reward_ids, run_state.reward_level)
	if active_reward_choices.is_empty():
		return

	get_tree().paused = true
	hud.hide_tower_tooltip()
	hud.show_reward_choices(active_reward_choices)
	hud.set_message("Choose a reward to shape the run.")
	_sync_camera_controls()


func _apply_tower_modifiers() -> void:
	for tower in towers:
		if is_instance_valid(tower):
			tower.apply_global_modifiers(run_state.tower_modifiers)


func _update_hovered_tower() -> void:
	if get_viewport().gui_get_hovered_control() != null:
		hud.hide_world_tower_tooltip()
		return

	if tower_placement.is_active:
		hud.hide_world_tower_tooltip()
		return

	var tower := _find_tower_at_mouse()
	if tower == null:
		hud.hide_tower_tooltip()
		return

	hud.show_tower_tooltip(tower.get_display_name(), tower.get_hover_description())


func _sync_camera_controls() -> void:
	var can_control_camera := run_state.game_started and not is_generating_map and not run_state.game_over and not run_state.reward_pending and not get_tree().paused and active_reward_choices.is_empty()
	level_map.set_camera_controls_enabled(can_control_camera)


func _set_game_speed(requested_speed: float, announce_change: bool = true) -> void:
	if not game_clock.set_speed(requested_speed):
		return

	if announce_change:
		hud.set_message("Game speed set to %dx." % int(game_clock.speed))

	if is_node_ready():
		_update_ui()


func _seed_from_text(seed_text: String) -> int:
	if seed_text.is_empty():
		return _make_random_seed()

	if seed_text.is_valid_int():
		var numeric_seed := absi(seed_text.to_int())
		return numeric_seed if numeric_seed != 0 else _make_random_seed()

	var hashed_seed := absi(seed_text.hash())
	return hashed_seed if hashed_seed != 0 else _make_random_seed()


func _make_random_seed() -> int:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return rng.randi_range(1, 2147483647)
