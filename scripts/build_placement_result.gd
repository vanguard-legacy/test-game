class_name PrototypeBuildPlacementResult
extends RefCounted

# Validated tower placement result. `has_hit` answers whether the cursor touched
# terrain; `is_valid` answers whether the touched point accepts a tower.

var has_hit: bool = false
var is_valid: bool = false
var position: Vector3 = Vector3.ZERO
var reason: String = ""


func _init(new_has_hit: bool = false, new_is_valid: bool = false, new_position: Vector3 = Vector3.ZERO, new_reason: String = "") -> void:
	has_hit = new_has_hit
	is_valid = new_is_valid
	position = new_position
	reason = new_reason
