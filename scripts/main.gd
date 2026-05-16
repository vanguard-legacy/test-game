extends Node3D

const STARTING_LIVES: int = 10
const STARTING_GOLD: int = 150
const TOWER_COST: int = 50
const BASE_ENEMIES_PER_WAVE: int = 4

const ENEMY_TYPES: Array[Dictionary] = [
	{
		"name": "Gobbelin",
		"health": 2.0,
		"health_scale": 0.28,
		"speed": 1.75,
		"speed_scale": 0.05,
		"gold": 10,
		"score": 10,
		"scale": 1.0,
		"body_color": Color(0.30, 0.72, 0.25),
		"ear_color": Color(0.19, 0.46, 0.18),
		"hat_color": Color(0.20, 0.15, 0.12),
	},
	{
		"name": "Gnuruk",
		"health": 1.35,
		"health_scale": 0.18,
		"speed": 2.35,
		"speed_scale": 0.07,
		"gold": 8,
		"score": 14,
		"scale": 0.88,
		"body_color": Color(0.28, 0.56, 0.66),
		"ear_color": Color(0.18, 0.38, 0.48),
		"hat_color": Color(0.12, 0.18, 0.23),
	},
	{
		"name": "Gnogre",
		"health": 5.2,
		"health_scale": 0.55,
		"speed": 1.05,
		"speed_scale": 0.025,
		"gold": 22,
		"score": 35,
		"scale": 1.45,
		"body_color": Color(0.62, 0.36, 0.24),
		"ear_color": Color(0.42, 0.23, 0.18),
		"hat_color": Color(0.24, 0.16, 0.13),
	},
]

@export var enemy_scene: PackedScene
@export var tower_scene: PackedScene

@onready var level_map: PrototypeLevelMap = $LevelMap
@onready var tower_placement: PrototypeTowerPlacement = $TowerPlacement
@onready var hud: PrototypeHud = $Hud
@onready var enemy_container: Node3D = $Enemies
@onready var tower_container: Node3D = $Towers

var enemies: Array[PrototypeEnemy] = []
var towers: Array[PrototypeTower] = []
var spawn_cooldown: float = 0.0
var enemies_to_spawn: int = 0
var enemies_spawned_this_wave: int = 0
var wave: int = 0
var lives: int = STARTING_LIVES
var gold: int = STARTING_GOLD
var score: int = 0
var game_over: bool = false
var game_started: bool = false
var wave_active: bool = false
var selected_tower: PrototypeTower


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
	hud.menu_requested.connect(_on_menu_requested)
	hud.resume_requested.connect(_on_resume_requested)
	hud.new_game_requested.connect(_on_new_game_requested)
	hud.restart_requested.connect(_on_restart_requested)
	hud.quit_requested.connect(_on_quit_requested)
	hud.set_message("Open the menu to start a run.")
	hud.show_main_menu("G'wizard Defense", false)
	_update_ui()


func _process(delta: float) -> void:
	if game_over or not game_started or get_tree().paused:
		return

	if wave_active:
		_spawn_wave_enemies(delta)
		_check_wave_complete()

	_update_ui()


func _unhandled_input(event: InputEvent) -> void:
	if game_over and event.is_action_pressed("ui_accept"):
		_restart_game()
		return

	if event.is_action_pressed("ui_cancel"):
		_open_pause_menu()
		return

	var mouse_event := event as InputEventMouseButton
	if mouse_event == null or not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return

	var tower := _find_tower_at_mouse()
	if tower != null:
		_select_tower(tower)


func _start_next_wave() -> void:
	if wave_active:
		return

	wave += 1
	enemies_to_spawn = BASE_ENEMIES_PER_WAVE + wave
	enemies_spawned_this_wave = 0
	spawn_cooldown = 0.2
	wave_active = true
	tower_placement.cancel_placement()
	hud.set_message("Wave %d: the gobbelins approach." % wave)


func _spawn_wave_enemies(delta: float) -> void:
	if enemies_to_spawn <= 0:
		return

	spawn_cooldown -= delta
	if spawn_cooldown > 0.0:
		return

	_spawn_enemy()
	enemies_to_spawn -= 1
	enemies_spawned_this_wave += 1
	spawn_cooldown = max(0.35, 1.0 - float(wave) * 0.05)


func _spawn_enemy() -> void:
	var enemy := enemy_scene.instantiate() as PrototypeEnemy
	enemy_container.add_child(enemy)
	enemy.setup(level_map.get_enemy_path(), wave, _choose_enemy_type())
	enemy.reached_exit.connect(_on_enemy_reached_exit)
	enemy.defeated.connect(_on_enemy_defeated)
	enemies.append(enemy)


func _on_enemy_reached_exit(enemy: PrototypeEnemy) -> void:
	enemies.erase(enemy)
	enemy.queue_free()
	lives -= 1
	hud.set_message("An enemy reached the exit.")

	if lives <= 0:
		_game_over()


func _on_enemy_defeated(enemy: PrototypeEnemy) -> void:
	enemies.erase(enemy)
	enemy.queue_free()
	score += enemy.score_reward
	gold += enemy.gold_reward


func _check_wave_complete() -> void:
	if enemies_to_spawn > 0 or not enemies.is_empty():
		return

	wave_active = false
	hud.set_message("Wave clear. Build more or start the next wave.")


func _on_build_tower_requested() -> void:
	if game_over or not game_started:
		return

	if gold < TOWER_COST:
		hud.set_message("Not enough gold for another G'wizard tower.")
		return

	tower_placement.begin_placement(_get_tower_positions())
	hud.set_message("Choose a green patch of land for the tower.")


func _on_cancel_build_requested() -> void:
	tower_placement.cancel_placement()


func _on_start_wave_requested() -> void:
	if game_over or wave_active or not game_started:
		return

	if towers.is_empty():
		hud.set_message("Place at least one tower before starting the wave.")
		return

	_start_next_wave()


func _on_tower_placement_confirmed(position: Vector3) -> void:
	if gold < TOWER_COST:
		hud.set_message("Not enough gold for another G'wizard tower.")
		tower_placement.cancel_placement()
		return

	var tower := tower_scene.instantiate() as PrototypeTower
	tower_container.add_child(tower)
	tower.global_position = position
	tower.set_targets(enemies)
	towers.append(tower)
	gold -= TOWER_COST
	tower_placement.cancel_placement()
	_select_tower(tower)
	hud.set_message("Tower placed. Build more or start the wave.")
	_update_ui()


func _on_tower_placement_cancelled() -> void:
	if not game_over:
		hud.set_message("Build cancelled.")


func _on_tower_placement_rejected(reason: String) -> void:
	hud.set_message(reason)


func _on_placement_mode_changed(is_placing: bool) -> void:
	hud.set_build_mode(is_placing)


func _on_upgrade_tower_requested() -> void:
	if selected_tower == null or not is_instance_valid(selected_tower):
		hud.set_message("Select a tower to upgrade.")
		return

	var upgrade_cost := selected_tower.get_upgrade_cost()
	if upgrade_cost <= 0:
		hud.set_message("That tower is already fully upgraded.")
		return

	if gold < upgrade_cost:
		hud.set_message("Not enough gold for that upgrade.")
		return

	gold -= upgrade_cost
	selected_tower.upgrade()
	hud.set_message("%s upgraded." % selected_tower.get_display_name())
	_update_ui()


func _on_menu_requested() -> void:
	_open_pause_menu()


func _on_resume_requested() -> void:
	get_tree().paused = false
	hud.hide_menu()


func _on_new_game_requested() -> void:
	get_tree().paused = false
	game_started = true
	_restart_game()
	hud.hide_menu()


func _on_restart_requested() -> void:
	get_tree().paused = false
	game_started = true
	_restart_game()
	hud.hide_menu()


func _on_quit_requested() -> void:
	get_tree().quit()


func _game_over() -> void:
	game_over = true
	wave_active = false
	tower_placement.cancel_placement()
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
	spawn_cooldown = 0.0
	enemies_to_spawn = 0
	enemies_spawned_this_wave = 0
	wave = 0
	lives = STARTING_LIVES
	gold = STARTING_GOLD
	score = 0
	game_over = false
	wave_active = false
	hud.set_message("Build a tower, then start the wave.")
	hud.hide_menu()
	_update_ui()


func _update_ui() -> void:
	var incoming := enemies.size() + enemies_to_spawn
	hud.update_stats(wave, lives, score, gold, incoming, towers.size())
	hud.set_build_enabled(game_started and not game_over and gold >= TOWER_COST)
	hud.set_start_wave_enabled(game_started and not game_over and not wave_active and not towers.is_empty())
	hud.update_selected_tower(selected_tower, gold)


func _get_tower_positions() -> Array[Vector3]:
	var positions: Array[Vector3] = []
	for tower in towers:
		positions.append(tower.global_position)

	return positions


func _choose_enemy_type() -> Dictionary:
	if wave >= 5 and enemies_spawned_this_wave % 5 == 4:
		return ENEMY_TYPES[2]

	if wave >= 3 and enemies_spawned_this_wave % 3 == 2:
		return ENEMY_TYPES[1]

	return ENEMY_TYPES[0]


func _select_tower(tower: PrototypeTower) -> void:
	selected_tower = tower
	hud.update_selected_tower(selected_tower, gold)


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
	if not game_started or game_over:
		return

	get_tree().paused = true
	hud.show_main_menu("Paused", true)
