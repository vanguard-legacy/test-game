extends Node3D
class_name PrototypeEnemy

signal reached_exit(enemy: PrototypeEnemy)
signal defeated(enemy: PrototypeEnemy)

const BASE_SPEED: float = 1.75

var path_points: Array[Vector3] = []
var target_index: int = 1
var health: float = 2.0
var speed: float = BASE_SPEED
var is_finished: bool = false


func _process(delta: float) -> void:
	if is_finished or path_points.size() < 2:
		return

	var target := path_points[target_index]
	var to_target := target - global_position
	var distance := to_target.length()
	var step := speed * delta

	if distance <= step:
		global_position = target
		target_index += 1
		if target_index >= path_points.size():
			is_finished = true
			reached_exit.emit(self)
	else:
		global_position += to_target.normalized() * step


func setup(points: Array[Vector3], wave: int) -> void:
	path_points = points
	target_index = 1
	health = 2.0 + float(wave) * 0.35
	speed = BASE_SPEED + float(wave) * 0.08
	global_position = path_points[0]


func take_damage(amount: float) -> void:
	if is_finished:
		return

	health -= amount
	if health <= 0.0:
		is_finished = true
		defeated.emit(self)
