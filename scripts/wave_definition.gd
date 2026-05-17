class_name PrototypeWaveDefinition
extends RefCounted

# Small wave payload consumed by RunState. Keeping this typed lets spawning code
# avoid fragile dictionary keys while still authoring wave data compactly.

var title: String = "Wave begins."
var enemy_ids: Array[String] = []
var spawn_delay: float = 0.8


static func from_values(new_title: String, new_enemy_ids: Array[String], new_spawn_delay: float) -> PrototypeWaveDefinition:
	var definition := PrototypeWaveDefinition.new()
	definition.title = new_title
	definition.enemy_ids = definition._copy_enemy_ids(new_enemy_ids)
	definition.spawn_delay = new_spawn_delay
	return definition


func _copy_enemy_ids(value: Variant) -> Array[String]:
	var copied_ids: Array[String] = []
	var source := value as Array
	if source == null:
		return copied_ids

	for enemy_id in source:
		copied_ids.append(str(enemy_id))

	return copied_ids
