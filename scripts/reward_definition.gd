class_name DefenseRewardDefinition
extends RefCounted

const TYPE_UNLOCK_TOWER: String = "unlock_tower"
const TYPE_MODIFIER: String = "modifier"
const TYPE_GOLD: String = "gold"

# Reward choices are presented in the HUD and then applied by RunState.
# Named fields keep both sides aligned without duplicating string keys.

var id: String = ""
var type: String = ""
var title: String = "Reward"
var description: String = ""
var tower_id: String = ""
var gold: int = 0
var damage_multiplier_bonus: float = 0.0
var range_bonus: float = 0.0
var fire_rate_multiplier: float = 1.0


func _init(data: Dictionary = {}) -> void:
	id = str(data.get("id", id))
	type = str(data.get("type", type))
	title = str(data.get("title", title))
	description = str(data.get("description", description))
	tower_id = str(data.get("tower_id", tower_id))
	gold = int(data.get("gold", gold))
	damage_multiplier_bonus = float(data.get("damage_multiplier", damage_multiplier_bonus))
	range_bonus = float(data.get("range_bonus", range_bonus))
	fire_rate_multiplier = float(data.get("fire_rate_multiplier", fire_rate_multiplier))
