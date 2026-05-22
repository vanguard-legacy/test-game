class_name DefenseTowerTerrainBonus
extends RefCounted

# Placement-derived combat modifier. Height is measured from the terrain under
# the tower, not from the tower scene origin.

var terrain_height: float = 0.0
var damage_multiplier: float = 1.0
var range_bonus: float = 0.0
var label: String = "Level ground"


func _init(new_height: float = 0.0, new_damage_multiplier: float = 1.0, new_range_bonus: float = 0.0, new_label: String = "Level ground") -> void:
	terrain_height = new_height
	damage_multiplier = new_damage_multiplier
	range_bonus = new_range_bonus
	label = new_label


func get_summary() -> String:
	return "%s\nDamage x%.2f  Range %+0.1f" % [label, damage_multiplier, range_bonus]
