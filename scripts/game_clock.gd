class_name DefenseGameClock
extends RefCounted

signal speed_changed(speed: float)

# Small boundary object for simulation timing. UI can request a speed through
# Main, but only this gameplay-side object decides which speeds are valid and
# applies the global Engine time scale.

const DEFAULT_SPEED: float = 1.0
const ALLOWED_SPEEDS: Array[float] = [1.0, 2.0, 4.0, 8.0, 16.0, 32.0]

var speed: float = DEFAULT_SPEED


func set_speed(requested_speed: float) -> bool:
	if not ALLOWED_SPEEDS.has(requested_speed):
		return false

	speed = requested_speed
	Engine.time_scale = speed
	speed_changed.emit(speed)
	return true


func reset() -> void:
	set_speed(DEFAULT_SPEED)


func restore_engine_default() -> void:
	speed = DEFAULT_SPEED
	Engine.time_scale = DEFAULT_SPEED
