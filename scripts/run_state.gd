class_name PrototypeRunState
extends RefCounted

const GameBalance := preload("res://scripts/game_balance.gd")

var wave: int = 0
var lives: int = GameBalance.STARTING_LIVES
var gold: int = GameBalance.STARTING_GOLD
var score: int = 0
var xp: int = 0
var xp_to_next: int = GameBalance.get_xp_required_for_level(1)
var reward_level: int = 0
var game_over: bool = false
var game_started: bool = false
var wave_active: bool = false
var reward_pending: bool = false
var spawn_cooldown: float = 0.0
var wave_queue: Array[String] = []
var next_spawn_index: int = 0
var spawn_delay: float = 0.8
var owned_tower_ids: Array[String] = GameBalance.get_starting_tower_ids()
var chosen_reward_ids: Array[String] = []
var tower_modifiers: Dictionary = GameBalance.get_default_tower_modifiers()


func reset(keep_started: bool = true) -> void:
	wave = 0
	lives = GameBalance.STARTING_LIVES
	gold = GameBalance.STARTING_GOLD
	score = 0
	xp = 0
	xp_to_next = GameBalance.get_xp_required_for_level(1)
	reward_level = 0
	game_over = false
	wave_active = false
	reward_pending = false
	spawn_cooldown = 0.0
	wave_queue.clear()
	next_spawn_index = 0
	spawn_delay = 0.8
	game_started = keep_started
	owned_tower_ids = GameBalance.get_starting_tower_ids()
	chosen_reward_ids.clear()
	tower_modifiers = GameBalance.get_default_tower_modifiers()


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


func add_xp(amount: int) -> bool:
	if amount <= 0:
		return false

	xp += amount
	if reward_pending:
		return false

	if xp < xp_to_next:
		return false

	xp -= xp_to_next
	reward_pending = true
	return true


func complete_reward(reward: Dictionary) -> void:
	var reward_type := str(reward.get("type", ""))
	match reward_type:
		"unlock_tower":
			var tower_id := str(reward.get("tower_id", ""))
			if not tower_id.is_empty() and not owned_tower_ids.has(tower_id) and owned_tower_ids.size() < GameBalance.MAX_TOWER_LOADOUT:
				owned_tower_ids.append(tower_id)
		"modifier":
			tower_modifiers["damage_multiplier"] = float(tower_modifiers.get("damage_multiplier", 1.0)) + float(reward.get("damage_multiplier", 0.0))
			tower_modifiers["range_bonus"] = float(tower_modifiers.get("range_bonus", 0.0)) + float(reward.get("range_bonus", 0.0))
			tower_modifiers["fire_rate_multiplier"] = float(tower_modifiers.get("fire_rate_multiplier", 1.0)) * float(reward.get("fire_rate_multiplier", 1.0))
		"gold":
			gold += int(reward.get("gold", 0))

	var reward_id := str(reward.get("id", ""))
	if not reward_id.is_empty():
		chosen_reward_ids.append(reward_id)

	reward_level += 1
	xp_to_next = GameBalance.get_xp_required_for_level(reward_level + 1)
	reward_pending = false


func can_afford_any_owned_tower() -> bool:
	for tower_id in owned_tower_ids:
		if gold >= GameBalance.get_tower_cost(tower_id):
			return true

	return false


func _copy_enemy_ids(enemy_ids_variant: Variant) -> Array[String]:
	var enemy_ids: Array[String] = []
	var source := enemy_ids_variant as Array
	if source == null:
		return enemy_ids

	for enemy_id in source:
		enemy_ids.append(str(enemy_id))

	return enemy_ids
