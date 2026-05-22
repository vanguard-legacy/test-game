class_name DefenseTowerDefinition
extends RefCounted

# Immutable-ish tower tuning object. Balance data may still be authored as
# dictionaries, but gameplay scripts should read named fields from this class.

var id: String = ""
var display_name: String = "Tower"
var short_name: String = "Tower"
var description: String = ""
var cost: int = 0
var base_damage: float = 1.0
var base_range: float = 5.0
var base_fire_rate: float = 0.5
var effect: String = ""
var slow_multiplier: float = 1.0
var slow_duration: float = 0.0
var splash_radius: float = 0.0
var beam_color: Color = Color.WHITE
var roof_color: Color = Color.WHITE
var banner_color: Color = Color.WHITE
var crystal_color: Color = Color.WHITE


func _init(data: Dictionary = {}) -> void:
	id = str(data.get("id", id))
	display_name = str(data.get("name", display_name))
	short_name = str(data.get("short_name", short_name))
	description = str(data.get("description", description))
	cost = int(data.get("cost", cost))
	base_damage = float(data.get("damage", base_damage))
	base_range = float(data.get("range", base_range))
	base_fire_rate = float(data.get("fire_rate", base_fire_rate))
	effect = str(data.get("effect", effect))
	slow_multiplier = float(data.get("slow_multiplier", slow_multiplier))
	slow_duration = float(data.get("slow_duration", slow_duration))
	splash_radius = float(data.get("splash_radius", splash_radius))
	beam_color = data.get("beam_color", beam_color)
	roof_color = data.get("roof_color", roof_color)
	banner_color = data.get("banner_color", banner_color)
	crystal_color = data.get("crystal_color", crystal_color)


func get_effect_summary() -> String:
	match effect:
		"frost":
			return "Applies a slowing chill on hit."
		"splash":
			return "Splashes nearby enemies around the target."
		_:
			return "Reliable single-target damage."


func get_build_tooltip_body() -> String:
	return "%s\nCost %d gold\nDamage %.1f  Range %.1f\nFires every %.2fs\n%s" % [
		description,
		cost,
		base_damage,
		base_range,
		base_fire_rate,
		get_effect_summary(),
	]
