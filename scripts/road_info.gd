class_name PrototypeRoadInfo
extends RefCounted

# Distance/progress pair for procedural road calculations.

var distance: float = INF
var progress: float = 0.0


func _init(new_distance: float = INF, new_progress: float = 0.0) -> void:
	distance = new_distance
	progress = new_progress
