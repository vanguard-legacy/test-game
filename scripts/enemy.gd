extends Node3D
class_name DefenseEnemy

signal reached_exit(enemy: DefenseEnemy)
signal defeated(enemy: DefenseEnemy)

const EnemyDefinition := preload("res://scripts/enemy_definition.gd")
const Materials := preload("res://scripts/materials.gd")

# Enemy movement/combat actor. Spawn setup copies an EnemyDefinition so each
# instance can be damaged, slowed, and freed without mutating shared balance.

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


func setup(points: Array[Vector3], wave: int, definition: EnemyDefinition) -> void:
	path_points = points
	target_index = 1
	enemy_type_name = definition.display_name
	health = definition.health_for_wave(wave)
	speed = definition.speed_for_wave(wave)
	gold_reward = definition.gold_reward
	score_reward = definition.score_reward
	xp_reward = definition.xp_reward
	if path_points.is_empty():
		return

	global_position = path_points[0]
	_apply_enemy_visuals(definition)


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


func _apply_enemy_visuals(definition: EnemyDefinition) -> void:
	name = enemy_type_name
	scale = Vector3.ONE * definition.visual_scale
	body.material_override = Materials.standard(definition.body_color)
	head.material_override = body.material_override
	hat.material_override = Materials.standard(definition.hat_color)
	left_ear.material_override = Materials.standard(definition.ear_color)
	right_ear.material_override = left_ear.material_override


func _update_slow(delta: float) -> void:
	if slow_timer <= 0.0:
		slow_multiplier = 1.0
		return

	slow_timer -= delta
	if slow_timer <= 0.0:
		slow_multiplier = 1.0
