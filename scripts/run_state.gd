class_name DefenseRunState
extends RefCounted

const GameBalance := preload("res://scripts/game_balance.gd")
const RewardDefinition := preload("res://scripts/reward_definition.gd")
const TowerModifiers := preload("res://scripts/tower_modifiers.gd")
const WaveDefinition := preload("res://scripts/wave_definition.gd")

# Pure session state for one run. This class contains no scene nodes; Main asks
# it to mutate numbers, queues, rewards, and unlocks, then renders the result.

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
var tower_modifiers: TowerModifiers = GameBalance.get_default_tower_modifiers()


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


func start_wave(wave_definition: WaveDefinition) -> void:
	wave += 1
	wave_active = true
	spawn_cooldown = 0.2
	next_spawn_index = 0
	spawn_delay = wave_definition.spawn_delay
	wave_queue = wave_definition.enemy_ids.duplicate()


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


func complete_reward(reward: RewardDefinition) -> void:
	match reward.type:
		RewardDefinition.TYPE_UNLOCK_TOWER:
			var tower_id := reward.tower_id
			if not tower_id.is_empty() and not owned_tower_ids.has(tower_id) and owned_tower_ids.size() < GameBalance.MAX_TOWER_LOADOUT:
				owned_tower_ids.append(tower_id)
		RewardDefinition.TYPE_MODIFIER:
			tower_modifiers.apply_reward(reward)
		RewardDefinition.TYPE_GOLD:
			gold += reward.gold

	if not reward.id.is_empty():
		chosen_reward_ids.append(reward.id)

	reward_level += 1
	xp_to_next = GameBalance.get_xp_required_for_level(reward_level + 1)
	reward_pending = false


func can_afford_any_owned_tower() -> bool:
	for tower_id in owned_tower_ids:
		if gold >= GameBalance.get_tower_cost(tower_id):
			return true

	return false
