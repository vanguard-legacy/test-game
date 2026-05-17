class_name PrototypeTerrainQuery
extends RefCounted

# Ray/terrain query result shared by the map, camera controller, and hover code.
# A typed result keeps call sites readable and avoids scattered dictionary keys.

var has_hit: bool = false
var position: Vector3 = Vector3.ZERO


func _init(new_has_hit: bool = false, new_position: Vector3 = Vector3.ZERO) -> void:
	has_hit = new_has_hit
	position = new_position
