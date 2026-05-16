class_name PrototypeGameBalance
extends RefCounted

const STARTING_LIVES: int = 10
const STARTING_GOLD: int = 150
const TOWER_COST: int = 50

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

const ENEMY_GOBBELIN: String = "gobbelin"
const ENEMY_GNURUK: String = "gnuruk"
const ENEMY_GNOGRE: String = "gnogre"


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
