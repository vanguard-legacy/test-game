class_name PrototypeGameBalance
extends RefCounted

const STARTING_LIVES: int = 10
const STARTING_GOLD: int = 150
const TOWER_COST: int = 50
const MAX_TOWER_LOADOUT: int = 3
const WAVE_CLEAR_XP: int = 12

const TOWER_BASE_RANGE: float = 5.5
const TOWER_BASE_DAMAGE: float = 1.0
const TOWER_BASE_FIRE_RATE: float = 0.45
const TOWER_MAX_LEVEL: int = 3
const TOWER_UPGRADE_BASE_COST: int = 60
const TOWER_UPGRADE_COST_STEP: int = 45
const TOWER_DAMAGE_STEP: float = 0.75
const TOWER_RANGE_STEP: float = 0.75
const TOWER_FIRE_RATE_STEP: float = 0.07
const TOWER_MIN_FIRE_RATE: float = 0.22

const TOWER_GWIZARD: String = "gwizard"
const TOWER_LONGBOW: String = "longbow_keep"
const TOWER_FROST: String = "frost_spire"
const TOWER_MORTAR: String = "rune_mortar"

const TOWER_EFFECT_BOLT: String = "bolt"
const TOWER_EFFECT_FROST: String = "frost"
const TOWER_EFFECT_SPLASH: String = "splash"

const ENEMY_GOBBELIN: String = "gobbelin"
const ENEMY_GNURUK: String = "gnuruk"
const ENEMY_GNOGRE: String = "gnogre"


static func get_starting_tower_ids() -> Array[String]:
	return [TOWER_GWIZARD]


static func get_default_tower_modifiers() -> Dictionary:
	return {
		"damage_multiplier": 1.0,
		"range_bonus": 0.0,
		"fire_rate_multiplier": 1.0,
	}


static func get_tower_config(tower_id: String) -> Dictionary:
	match tower_id:
		TOWER_LONGBOW:
			return {
				"id": TOWER_LONGBOW,
				"name": "Longbow Keep",
				"short_name": "Longbow",
				"description": "Long range and quick shots.",
				"cost": 65,
				"damage": 0.85,
				"range": 8.0,
				"fire_rate": 0.32,
				"effect": TOWER_EFFECT_BOLT,
				"beam_color": Color(1.0, 0.82, 0.34),
				"roof_color": Color(0.34, 0.20, 0.10),
				"banner_color": Color(0.78, 0.48, 0.22),
				"crystal_color": Color(1.0, 0.78, 0.28),
			}
		TOWER_FROST:
			return {
				"id": TOWER_FROST,
				"name": "Frost Spire",
				"short_name": "Frost",
				"description": "Slows enemies with chilly shots.",
				"cost": 70,
				"damage": 0.65,
				"range": 5.4,
				"fire_rate": 0.68,
				"effect": TOWER_EFFECT_FROST,
				"slow_multiplier": 0.55,
				"slow_duration": 1.2,
				"beam_color": Color(0.55, 0.90, 1.0),
				"roof_color": Color(0.13, 0.32, 0.48),
				"banner_color": Color(0.52, 0.82, 0.96),
				"crystal_color": Color(0.54, 0.92, 1.0),
			}
		TOWER_MORTAR:
			return {
				"id": TOWER_MORTAR,
				"name": "Rune Mortar",
				"short_name": "Mortar",
				"description": "Slow splash blasts for clustered lanes.",
				"cost": 85,
				"damage": 1.8,
				"range": 6.4,
				"fire_rate": 1.15,
				"effect": TOWER_EFFECT_SPLASH,
				"splash_radius": 1.55,
				"beam_color": Color(1.0, 0.42, 0.24),
				"roof_color": Color(0.46, 0.13, 0.08),
				"banner_color": Color(0.90, 0.35, 0.18),
				"crystal_color": Color(1.0, 0.34, 0.18),
			}
		_:
			return {
				"id": TOWER_GWIZARD,
				"name": "G'wizard Tower",
				"short_name": "G'wizard",
				"description": "Reliable single-target magic.",
				"cost": TOWER_COST,
				"damage": TOWER_BASE_DAMAGE,
				"range": TOWER_BASE_RANGE,
				"fire_rate": TOWER_BASE_FIRE_RATE,
				"effect": TOWER_EFFECT_BOLT,
				"beam_color": Color(0.85, 0.95, 1.0),
				"roof_color": Color(0.35, 0.13, 0.45),
				"banner_color": Color(0.88, 0.72, 0.28),
				"crystal_color": Color(0.38, 0.86, 1.0),
			}


static func get_tower_cost(tower_id: String) -> int:
	return int(get_tower_config(tower_id).get("cost", TOWER_COST))


static func get_xp_required_for_level(level: int) -> int:
	return 42 + max(0, level - 1) * 28


static func get_reward_choices(owned_tower_ids: Array[String], chosen_reward_ids: Array[String], reward_level: int) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	if owned_tower_ids.size() < MAX_TOWER_LOADOUT:
		for tower_id in [TOWER_LONGBOW, TOWER_FROST, TOWER_MORTAR]:
			if not owned_tower_ids.has(tower_id):
				candidates.append(_make_unlock_reward(tower_id))

	for reward in _get_upgrade_rewards():
		if not chosen_reward_ids.has(str(reward.get("id", ""))):
			candidates.append(reward.duplicate(true))

	return _pick_reward_choices(candidates, reward_level)


static func get_enemy_config(enemy_id: String) -> Dictionary:
	match enemy_id:
		ENEMY_GNURUK:
			return {
				"id": ENEMY_GNURUK,
				"name": "Gnuruk",
				"health": 1.35,
				"health_scale": 0.18,
				"speed": 2.35,
				"speed_scale": 0.07,
				"gold": 8,
				"score": 14,
				"xp": 8,
				"scale": 0.88,
				"body_color": Color(0.28, 0.56, 0.66),
				"ear_color": Color(0.18, 0.38, 0.48),
				"hat_color": Color(0.12, 0.18, 0.23),
			}
		ENEMY_GNOGRE:
			return {
				"id": ENEMY_GNOGRE,
				"name": "Gnogre",
				"health": 5.2,
				"health_scale": 0.55,
				"speed": 1.05,
				"speed_scale": 0.025,
				"gold": 22,
				"score": 35,
				"xp": 18,
				"scale": 1.45,
				"body_color": Color(0.62, 0.36, 0.24),
				"ear_color": Color(0.42, 0.23, 0.18),
				"hat_color": Color(0.24, 0.16, 0.13),
			}
		_:
			return {
				"id": ENEMY_GOBBELIN,
				"name": "Gobbelin",
				"health": 2.0,
				"health_scale": 0.28,
				"speed": 1.75,
				"speed_scale": 0.05,
				"gold": 10,
				"score": 10,
				"xp": 6,
				"scale": 1.0,
				"body_color": Color(0.30, 0.72, 0.25),
				"ear_color": Color(0.19, 0.46, 0.18),
				"hat_color": Color(0.20, 0.15, 0.12),
			}


static func get_wave_definition(wave: int) -> Dictionary:
	var scripted_waves := _get_scripted_waves()
	if wave <= scripted_waves.size():
		return scripted_waves[wave - 1].duplicate(true)

	return _make_scaling_wave(wave)


static func get_tower_upgrade_cost(level: int) -> int:
	if level >= TOWER_MAX_LEVEL:
		return 0

	return TOWER_UPGRADE_BASE_COST + (level - 1) * TOWER_UPGRADE_COST_STEP


static func _get_scripted_waves() -> Array[Dictionary]:
	return [
		{
			"title": "Wave 1: gobbelins on the road.",
			"enemy_ids": _repeat_enemy(ENEMY_GOBBELIN, 5),
			"spawn_delay": 0.95,
		},
		{
			"title": "Wave 2: a wider gobbelin push.",
			"enemy_ids": _repeat_enemy(ENEMY_GOBBELIN, 7),
			"spawn_delay": 0.85,
		},
		{
			"title": "Wave 3: gnuruks join the sprint.",
			"enemy_ids": [
				ENEMY_GOBBELIN,
				ENEMY_GOBBELIN,
				ENEMY_GNURUK,
				ENEMY_GOBBELIN,
				ENEMY_GNURUK,
				ENEMY_GOBBELIN,
				ENEMY_GOBBELIN,
			],
			"spawn_delay": 0.78,
		},
		{
			"title": "Wave 4: fast feet and shielded heads.",
			"enemy_ids": [
				ENEMY_GOBBELIN,
				ENEMY_GNURUK,
				ENEMY_GOBBELIN,
				ENEMY_GNURUK,
				ENEMY_GOBBELIN,
				ENEMY_GOBBELIN,
				ENEMY_GNURUK,
				ENEMY_GOBBELIN,
			],
			"spawn_delay": 0.72,
		},
		{
			"title": "Wave 5: the first gnogre lumbers in.",
			"enemy_ids": [
				ENEMY_GOBBELIN,
				ENEMY_GNURUK,
				ENEMY_GOBBELIN,
				ENEMY_GNOGRE,
				ENEMY_GOBBELIN,
				ENEMY_GNURUK,
				ENEMY_GOBBELIN,
				ENEMY_GNOGRE,
			],
			"spawn_delay": 0.68,
		},
	]


static func _make_scaling_wave(wave: int) -> Dictionary:
	var enemy_ids: Array[String] = []
	var count := 6 + wave
	for index in range(count):
		if index % 6 == 5:
			enemy_ids.append(ENEMY_GNOGRE)
		elif index % 3 == 2:
			enemy_ids.append(ENEMY_GNURUK)
		else:
			enemy_ids.append(ENEMY_GOBBELIN)

	return {
		"title": "Wave %d: mixed raiders." % wave,
		"enemy_ids": enemy_ids,
		"spawn_delay": maxf(0.4, 0.78 - float(wave - 5) * 0.035),
	}


static func _repeat_enemy(enemy_id: String, count: int) -> Array[String]:
	var enemy_ids: Array[String] = []
	for _index in range(count):
		enemy_ids.append(enemy_id)

	return enemy_ids


static func _get_upgrade_rewards() -> Array[Dictionary]:
	return [
		{
			"id": "sharper_runes",
			"type": "modifier",
			"title": "Sharper Runes",
			"description": "+20% tower damage.",
			"damage_multiplier": 0.20,
		},
		{
			"id": "focus_lenses",
			"type": "modifier",
			"title": "Focus Lenses",
			"description": "+0.8 tower range.",
			"range_bonus": 0.8,
		},
		{
			"id": "quick_chanting",
			"type": "modifier",
			"title": "Quick Chanting",
			"description": "Towers fire 12% faster.",
			"fire_rate_multiplier": 0.88,
		},
		{
			"id": "battle_scribes",
			"type": "modifier",
			"title": "Battle Scribes",
			"description": "+15% damage and +0.4 range.",
			"damage_multiplier": 0.15,
			"range_bonus": 0.4,
		},
		{
			"id": "haste_runes",
			"type": "modifier",
			"title": "Haste Runes",
			"description": "Towers fire 10% faster.",
			"fire_rate_multiplier": 0.90,
		},
	]


static func _make_unlock_reward(tower_id: String) -> Dictionary:
	var tower_config := get_tower_config(tower_id)
	return {
		"id": "unlock_%s" % tower_id,
		"type": "unlock_tower",
		"title": "Unlock %s" % str(tower_config.get("short_name", tower_config.get("name", "Tower"))),
		"description": str(tower_config.get("description", "Adds a new tower to the build bar.")),
		"tower_id": tower_id,
	}


static func _make_gold_reward(reward_level: int, index: int) -> Dictionary:
	return {
		"id": "gold_cache_%d_%d" % [reward_level, index],
		"type": "gold",
		"title": "Royal Stipend",
		"description": "+75 gold for more building.",
		"gold": 75,
	}


static func _pick_reward_choices(candidates: Array[Dictionary], reward_level: int) -> Array[Dictionary]:
	var choices: Array[Dictionary] = []
	if not candidates.is_empty():
		var start_index := reward_level % candidates.size()
		for offset in range(candidates.size()):
			choices.append(candidates[(start_index + offset) % candidates.size()])
			if choices.size() >= 3:
				break

	var gold_index := 0
	while choices.size() < 3:
		choices.append(_make_gold_reward(reward_level, gold_index))
		gold_index += 1

	return choices
