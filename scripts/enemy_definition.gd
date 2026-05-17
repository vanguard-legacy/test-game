class_name PrototypeEnemyDefinition
extends RefCounted

# Enemy archetype plus per-wave scaling. Instances copy from this definition
# when spawned, so balance changes stay in one place.

var id: String = ""
var display_name: String = "Enemy"
var base_health: float = 1.0
var health_scale: float = 0.0
var base_speed: float = 1.0
var speed_scale: float = 0.0
var gold_reward: int = 0
var score_reward: int = 0
var xp_reward: int = 0
var visual_scale: float = 1.0
var body_color: Color = Color.WHITE
var ear_color: Color = Color.WHITE
var hat_color: Color = Color.WHITE


func _init(data: Dictionary = {}) -> void:
	id = str(data.get("id", id))
	display_name = str(data.get("name", display_name))
	base_health = float(data.get("health", base_health))
	health_scale = float(data.get("health_scale", health_scale))
	base_speed = float(data.get("speed", base_speed))
	speed_scale = float(data.get("speed_scale", speed_scale))
	gold_reward = int(data.get("gold", gold_reward))
	score_reward = int(data.get("score", score_reward))
	xp_reward = int(data.get("xp", xp_reward))
	visual_scale = float(data.get("scale", visual_scale))
	body_color = data.get("body_color", body_color)
	ear_color = data.get("ear_color", ear_color)
	hat_color = data.get("hat_color", hat_color)


func health_for_wave(wave: int) -> float:
	return base_health + float(wave) * health_scale


func speed_for_wave(wave: int) -> float:
	return base_speed + float(wave) * speed_scale
