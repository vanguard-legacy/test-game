extends Node3D

const STARTING_LIVES: int = 10
const STARTING_GOLD: int = 150
const TOWER_COST: int = 50
const GOLD_PER_DEFEAT: int = 10
const SCORE_PER_DEFEAT: int = 10
const BASE_ENEMIES_PER_WAVE: int = 4

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
var wave: int = 0
var lives: int = STARTING_LIVES
var gold: int = STARTING_GOLD
var score: int = 0
var game_over: bool = false
var wave_active: bool = false


func _ready() -> void:
	tower_placement.setup(level_map)
	tower_placement.placement_confirmed.connect(_on_tower_placement_confirmed)
	tower_placement.placement_cancelled.connect(_on_tower_placement_cancelled)
	tower_placement.placement_rejected.connect(_on_tower_placement_rejected)
	tower_placement.placement_mode_changed.connect(_on_placement_mode_changed)
	hud.build_tower_requested.connect(_on_build_tower_requested)
	hud.cancel_build_requested.connect(_on_cancel_build_requested)
	hud.start_wave_requested.connect(_on_start_wave_requested)
	hud.set_message("Build a tower, then start the wave.")
	_update_ui()


func _process(delta: float) -> void:
	if game_over:
		return

	if wave_active:
		_spawn_wave_enemies(delta)
		_check_wave_complete()

	_update_ui()


func _unhandled_input(event: InputEvent) -> void:
	if game_over and event.is_action_pressed("ui_accept"):
		_restart_game()


func _start_next_wave() -> void:
	if wave_active:
		return

	wave += 1
	enemies_to_spawn = BASE_ENEMIES_PER_WAVE + wave
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
	spawn_cooldown = max(0.35, 1.0 - float(wave) * 0.05)


func _spawn_enemy() -> void:
	var enemy := enemy_scene.instantiate() as PrototypeEnemy
	enemy_container.add_child(enemy)
	enemy.setup(level_map.get_enemy_path(), wave)
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
	score += SCORE_PER_DEFEAT
	gold += GOLD_PER_DEFEAT


func _check_wave_complete() -> void:
	if enemies_to_spawn > 0 or not enemies.is_empty():
		return

	wave_active = false
	hud.set_message("Wave clear. Build more or start the next wave.")


func _on_build_tower_requested() -> void:
	if game_over:
		return

	if gold < TOWER_COST:
		hud.set_message("Not enough gold for another G'wizard tower.")
		return

	tower_placement.begin_placement(_get_tower_positions())
	hud.set_message("Choose a green patch of land for the tower.")


func _on_cancel_build_requested() -> void:
	tower_placement.cancel_placement()


func _on_start_wave_requested() -> void:
	if game_over or wave_active:
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
	hud.set_message("Tower placed. Build more or start the wave.")
	_update_ui()


func _on_tower_placement_cancelled() -> void:
	if not game_over:
		hud.set_message("Build cancelled.")


func _on_tower_placement_rejected(reason: String) -> void:
	hud.set_message(reason)


func _on_placement_mode_changed(is_placing: bool) -> void:
	hud.set_build_mode(is_placing)


func _game_over() -> void:
	game_over = true
	wave_active = false
	tower_placement.cancel_placement()
	hud.set_message("Defeat. Press Enter or Space to try again.")
	_update_ui()


func _restart_game() -> void:
	for enemy in enemies:
		enemy.queue_free()

	for tower in towers:
		tower.queue_free()

	enemies.clear()
	towers.clear()
	spawn_cooldown = 0.0
	enemies_to_spawn = 0
	wave = 0
	lives = STARTING_LIVES
	gold = STARTING_GOLD
	score = 0
	game_over = false
	wave_active = false
	hud.set_message("Build a tower, then start the wave.")
	_update_ui()


func _update_ui() -> void:
	var incoming := enemies.size() + enemies_to_spawn
	hud.update_stats(wave, lives, score, gold, incoming, towers.size())
	hud.set_build_enabled(not game_over and gold >= TOWER_COST)
	hud.set_start_wave_enabled(not game_over and not wave_active and not towers.is_empty())


func _get_tower_positions() -> Array[Vector3]:
	var positions: Array[Vector3] = []
	for tower in towers:
		positions.append(tower.global_position)

	return positions
