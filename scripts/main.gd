extends Node3D

const GameBalance := preload("res://scripts/game_balance.gd")
const RunState := preload("res://scripts/run_state.gd")

@export var enemy_scene: PackedScene
@export var tower_scene: PackedScene

@onready var level_map: PrototypeLevelMap = $LevelMap
@onready var tower_placement: PrototypeTowerPlacement = $TowerPlacement
@onready var hud: PrototypeHud = $Hud
@onready var enemy_container: Node3D = $Enemies
@onready var tower_container: Node3D = $Towers

var enemies: Array[PrototypeEnemy] = []
var towers: Array[PrototypeTower] = []
var run_state := RunState.new()
var selected_tower: PrototypeTower
var selected_tower_id: String = GameBalance.TOWER_GWIZARD
var active_reward_choices: Array[Dictionary] = []


func _ready() -> void:
	tower_placement.setup(level_map)
	tower_placement.placement_confirmed.connect(_on_tower_placement_confirmed)
	tower_placement.placement_cancelled.connect(_on_tower_placement_cancelled)
	tower_placement.placement_rejected.connect(_on_tower_placement_rejected)
	tower_placement.placement_mode_changed.connect(_on_placement_mode_changed)
	hud.build_tower_requested.connect(_on_build_tower_requested)
	hud.cancel_build_requested.connect(_on_cancel_build_requested)
	hud.start_wave_requested.connect(_on_start_wave_requested)
	hud.upgrade_tower_requested.connect(_on_upgrade_tower_requested)
	hud.reward_choice_selected.connect(_on_reward_choice_selected)
	hud.menu_requested.connect(_on_menu_requested)
	hud.resume_requested.connect(_on_resume_requested)
	hud.new_game_requested.connect(_on_new_game_requested)
	hud.restart_requested.connect(_on_restart_requested)
	hud.quit_requested.connect(_on_quit_requested)
	hud.set_message("Open the menu to start a run.")
	hud.show_main_menu("G'wizard Defense", false)
	_update_ui()


func _process(delta: float) -> void:
	if run_state.game_over or not run_state.game_started or get_tree().paused:
		return

	if run_state.wave_active:
		_spawn_wave_enemies(delta)
		_check_wave_complete()

	_update_hovered_tower()
	_update_ui()


func _unhandled_input(event: InputEvent) -> void:
	if run_state.game_over and event.is_action_pressed("ui_accept"):
		_restart_game()
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


func _start_next_wave() -> void:
	if run_state.wave_active:
		return

	var next_wave: int = run_state.wave + 1
	var wave_definition: Dictionary = GameBalance.get_wave_definition(next_wave)
	run_state.start_wave(wave_definition)
	tower_placement.cancel_placement()
	hud.set_message(str(wave_definition.get("title", "Wave %d begins." % run_state.wave)))


func _spawn_wave_enemies(delta: float) -> void:
	if not run_state.has_pending_spawns():
		return

	run_state.spawn_cooldown -= delta
	if run_state.spawn_cooldown > 0.0:
		return

	_spawn_enemy(run_state.next_enemy_id())
	run_state.spawn_cooldown = run_state.spawn_delay


func _spawn_enemy(enemy_id: String) -> void:
	var enemy := enemy_scene.instantiate() as PrototypeEnemy
	enemy_container.add_child(enemy)
	enemy.setup(level_map.get_enemy_path(), run_state.wave, GameBalance.get_enemy_config(enemy_id))
	enemy.reached_exit.connect(_on_enemy_reached_exit)
	enemy.defeated.connect(_on_enemy_defeated)
	enemies.append(enemy)


func _on_enemy_reached_exit(enemy: PrototypeEnemy) -> void:
	enemies.erase(enemy)
	enemy.queue_free()
	run_state.lives -= 1
	hud.set_message("An enemy reached the exit.")

	if run_state.lives <= 0:
		_game_over()


func _on_enemy_defeated(enemy: PrototypeEnemy) -> void:
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
	var tower_config := GameBalance.get_tower_config(selected_tower_id)
	hud.set_message("Place the %s on a green patch of land." % str(tower_config.get("name", "tower")))


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

	var tower := tower_scene.instantiate() as PrototypeTower
	tower_container.add_child(tower)
	tower.setup(selected_tower_id, run_state.tower_modifiers)
	tower.global_position = placement_position
	tower.set_targets(enemies)
	towers.append(tower)
	run_state.gold -= tower_cost
	tower_placement.cancel_placement()
	_select_tower(tower)
	hud.set_message("%s placed. Build more or start the wave." % tower.get_display_name())
	_update_ui()


func _on_tower_placement_cancelled() -> void:
	if not run_state.game_over:
		hud.set_message("Build cancelled.")


func _on_tower_placement_rejected(reason: String) -> void:
	hud.set_message(reason)


func _on_placement_mode_changed(is_placing: bool) -> void:
	hud.set_build_mode(is_placing)
	_update_ui()


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
	hud.set_message("Reward chosen: %s." % str(reward.get("title", "Upgrade")))
	_update_ui()


func _on_menu_requested() -> void:
	_open_pause_menu()


func _on_resume_requested() -> void:
	get_tree().paused = false
	hud.hide_menu()
	_sync_camera_controls()


func _on_new_game_requested() -> void:
	get_tree().paused = false
	run_state.game_started = true
	_restart_game()
	hud.hide_menu()


func _on_restart_requested() -> void:
	get_tree().paused = false
	run_state.game_started = true
	_restart_game()
	hud.hide_menu()


func _on_quit_requested() -> void:
	get_tree().quit()


func _game_over() -> void:
	run_state.game_over = true
	run_state.wave_active = false
	tower_placement.cancel_placement()
	hud.hide_tower_tooltip()
	hud.set_message("Defeat. Press Enter or Space to try again.")
	hud.show_main_menu("Defeat", false)
	_update_ui()


func _restart_game() -> void:
	for enemy in enemies:
		enemy.queue_free()

	for tower in towers:
		tower.queue_free()

	enemies.clear()
	towers.clear()
	selected_tower = null
	selected_tower_id = GameBalance.TOWER_GWIZARD
	active_reward_choices.clear()
	run_state.reset(run_state.game_started)
	hud.set_message("Build a tower, then start the wave.")
	hud.hide_menu()
	hud.hide_reward_choices()
	hud.hide_tower_tooltip()
	_update_ui()


func _update_ui() -> void:
	hud.update_stats(run_state.wave, run_state.lives, run_state.score, run_state.gold, run_state.xp, run_state.xp_to_next, run_state.incoming_count(enemies.size()), towers.size())
	hud.update_build_options(run_state.owned_tower_ids, selected_tower_id, run_state.gold, run_state.game_started and not run_state.game_over, tower_placement.is_active)
	hud.set_start_wave_enabled(run_state.game_started and not run_state.game_over and not run_state.wave_active and not towers.is_empty())
	hud.update_selected_tower(selected_tower, run_state.gold)
	_sync_camera_controls()


func _get_tower_positions() -> Array[Vector3]:
	var positions: Array[Vector3] = []
	for tower in towers:
		positions.append(tower.global_position)

	return positions


func _select_tower(tower: PrototypeTower) -> void:
	selected_tower = tower
	hud.update_selected_tower(selected_tower, run_state.gold)


func _find_tower_at_mouse() -> PrototypeTower:
	var camera := level_map.get_active_camera()
	if camera == null:
		return null

	var mouse_position := get_viewport().get_mouse_position()
	var placement := level_map.find_build_position(camera, mouse_position, [])
	if not bool(placement.get("has_hit", false)):
		return null

	var hit_position: Vector3 = placement["position"]
	var hit_point := Vector2(hit_position.x, hit_position.z)
	for tower in towers:
		var tower_point := Vector2(tower.global_position.x, tower.global_position.z)
		if tower_point.distance_to(hit_point) <= 0.85:
			return tower

	return null


func _open_pause_menu() -> void:
	if not run_state.game_started or run_state.game_over:
		return

	get_tree().paused = true
	hud.hide_tower_tooltip()
	hud.show_main_menu("Paused", true)
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
	var can_control_camera := run_state.game_started and not run_state.game_over and not run_state.reward_pending and not get_tree().paused and active_reward_choices.is_empty()
	level_map.set_camera_controls_enabled(can_control_camera)
