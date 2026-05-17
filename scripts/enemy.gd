extends Node3D
class_name PrototypeEnemy

signal reached_exit(enemy: PrototypeEnemy)
signal defeated(enemy: PrototypeEnemy)

const BASE_SPEED: float = 1.75

var path_points: Array[Vector3] = []
var target_index: int = 1
var enemy_type_name: String = "Gobbelin"
var health: float = 2.0
var speed: float = BASE_SPEED
var gold_reward: int = 10
var score_reward: int = 10
var xp_reward: int = 6
var is_finished: bool = false
var slow_multiplier: float = 1.0
var slow_timer: float = 0.0

@onready var body: MeshInstance3D = $Body
@onready var head: MeshInstance3D = $Head
@onready var hat: MeshInstance3D = $Hat
@onready var left_ear: MeshInstance3D = $LeftEar
@onready var right_ear: MeshInstance3D = $RightEar


func _process(delta: float) -> void:
	if is_finished or path_points.size() < 2:
		return

	_update_slow(delta)
	var target := path_points[target_index]
	var to_target := target - global_position
	var distance := to_target.length()
	var step := speed * slow_multiplier * delta

	if distance <= step:
		global_position = target
		target_index += 1
		if target_index >= path_points.size():
			is_finished = true
			reached_exit.emit(self)
	else:
		global_position += to_target.normalized() * step


func setup(points: Array[Vector3], wave: int, enemy_config: Dictionary) -> void:
	path_points = points
	target_index = 1
	enemy_type_name = str(enemy_config.get("name", "Gobbelin"))
	health = float(enemy_config.get("health", 2.0)) + float(wave) * float(enemy_config.get("health_scale", 0.25))
	speed = float(enemy_config.get("speed", BASE_SPEED)) + float(wave) * float(enemy_config.get("speed_scale", 0.04))
	gold_reward = int(enemy_config.get("gold", 10))
	score_reward = int(enemy_config.get("score", 10))
	xp_reward = int(enemy_config.get("xp", 6))
	global_position = path_points[0]
	_apply_enemy_visuals(enemy_config)


func take_damage(amount: float) -> void:
	if is_finished:
		return

	health -= amount
	if health <= 0.0:
		is_finished = true
		defeated.emit(self)


func apply_slow(multiplier: float, duration: float) -> void:
	slow_multiplier = minf(slow_multiplier, multiplier)
	slow_timer = maxf(slow_timer, duration)


func _apply_enemy_visuals(enemy_config: Dictionary) -> void:
	name = enemy_type_name
	scale = Vector3.ONE * float(enemy_config.get("scale", 1.0))
	body.material_override = PrototypeMaterials.standard(enemy_config.get("body_color", Color(0.30, 0.72, 0.25)))
	head.material_override = body.material_override
	hat.material_override = PrototypeMaterials.standard(enemy_config.get("hat_color", Color(0.20, 0.15, 0.12)))
	left_ear.material_override = PrototypeMaterials.standard(enemy_config.get("ear_color", Color(0.19, 0.46, 0.18)))
	right_ear.material_override = left_ear.material_override


func _update_slow(delta: float) -> void:
	if slow_timer <= 0.0:
		slow_multiplier = 1.0
		return

	slow_timer -= delta
	if slow_timer <= 0.0:
		slow_multiplier = 1.0
