class_name PrototypeRunState
extends RefCounted

const GameBalance := preload("res://scripts/game_balance.gd")

var wave: int = 0
var lives: int = GameBalance.STARTING_LIVES
var gold: int = GameBalance.STARTING_GOLD
var score: int = 0
var game_over: bool = false
var game_started: bool = false
var wave_active: bool = false
var spawn_cooldown: float = 0.0
var wave_queue: Array[String] = []
var next_spawn_index: int = 0
var spawn_delay: float = 0.8


func reset(keep_started: bool = true) -> void:
	wave = 0
	lives = GameBalance.STARTING_LIVES
	gold = GameBalance.STARTING_GOLD
	score = 0
	game_over = false
	wave_active = false
	spawn_cooldown = 0.0
	wave_queue.clear()
	next_spawn_index = 0
	spawn_delay = 0.8
	game_started = keep_started


func start_wave(wave_definition: Dictionary) -> void:
	wave += 1
	wave_active = true
	spawn_cooldown = 0.2
	next_spawn_index = 0
	spawn_delay = float(wave_definition.get("spawn_delay", 0.8))
	wave_queue = _copy_enemy_ids(wave_definition.get("enemy_ids", []))


func has_pending_spawns() -> bool:
	return next_spawn_index < wave_queue.size()


func next_enemy_id() -> String:
	if not has_pending_spawns():
		return ""

	var enemy_id := wave_queue[next_spawn_index]
	next_spawn_index += 1
	return enemy_id


func incoming_count(active_enemy_count: int) -> int:
	return active_enemy_count + max(0, wave_queue.size() - next_spawn_index)


func _copy_enemy_ids(enemy_ids_variant: Variant) -> Array[String]:
	var enemy_ids: Array[String] = []
	var source := enemy_ids_variant as Array
	if source == null:
		return enemy_ids

	for enemy_id in source:
		enemy_ids.append(str(enemy_id))

	return enemy_ids
