extends Node3D
class_name DefenseEnemy

signal reached_exit(enemy: DefenseEnemy)
signal defeated(enemy: DefenseEnemy)

const EnemyDefinition := preload("res://scripts/enemy_definition.gd")
const DamageNumber := preload("res://scripts/damage_number.gd")
const Materials := preload("res://scripts/materials.gd")

# Enemy movement/combat actor. Spawn setup copies an EnemyDefinition so each
# instance can be damaged, slowed, and freed without mutating shared balance.

const BASE_SPEED: float = 1.75
const HEALTH_BAR_WIDTH: float = 0.76
const HEALTH_BAR_Y: float = 1.14

var path_points: Array[Vector3] = []
var target_index: int = 1
var enemy_id: String = "gobbelin"
var enemy_type_name: String = "Gobbelin"
var max_health: float = 2.0
var health: float = 2.0
var speed: float = BASE_SPEED
var gold_reward: int = 10
var score_reward: int = 10
var xp_reward: int = 6
var is_finished: bool = false
var slow_multiplier: float = 1.0
var slow_timer: float = 0.0
var health_bar_root: Node3D
var health_bar_fill: MeshInstance3D

@onready var body: MeshInstance3D = $Body
@onready var head: MeshInstance3D = $Head
@onready var hat: MeshInstance3D = $Hat
@onready var left_ear: MeshInstance3D = $LeftEar
@onready var right_ear: MeshInstance3D = $RightEar


func _process(delta: float) -> void:
	if is_finished or path_points.size() < 2:
		return

	_update_slow(delta)
	_update_health_bar()
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
	enemy_id = definition.id
	enemy_type_name = definition.display_name
	max_health = definition.health_for_wave(wave)
	health = max_health
	speed = definition.speed_for_wave(wave)
	gold_reward = definition.gold_reward
	score_reward = definition.score_reward
	xp_reward = definition.xp_reward
	if path_points.is_empty():
		return

	global_position = path_points[0]
	_apply_enemy_visuals(definition)
	_build_health_bar()
	_update_health_bar()


func take_damage(amount: float) -> void:
	if is_finished:
		return

	health -= amount
	_spawn_damage_number(amount)
	_update_health_bar()
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


func _build_health_bar() -> void:
	if health_bar_root != null:
		health_bar_root.queue_free()

	health_bar_root = Node3D.new()
	health_bar_root.name = "HealthBar"
	health_bar_root.position = Vector3(0.0, HEALTH_BAR_Y, 0.0)
	add_child(health_bar_root)

	var background := MeshInstance3D.new()
	background.name = "Background"
	background.mesh = _make_bar_mesh(HEALTH_BAR_WIDTH, 0.09)
	background.material_override = Materials.unshaded(Color(0.05, 0.03, 0.025, 0.92))
	health_bar_root.add_child(background)

	health_bar_fill = MeshInstance3D.new()
	health_bar_fill.name = "Fill"
	health_bar_fill.position = Vector3(0.0, 0.006, 0.0)
	health_bar_fill.mesh = _make_bar_mesh(HEALTH_BAR_WIDTH, 0.052)
	health_bar_fill.material_override = Materials.unshaded(Color(0.86, 0.16, 0.10, 0.98))
	health_bar_root.add_child(health_bar_fill)


func _make_bar_mesh(width: float, height: float) -> QuadMesh:
	var mesh := QuadMesh.new()
	mesh.size = Vector2(width, height)
	return mesh


func _update_health_bar() -> void:
	if health_bar_root == null or health_bar_fill == null:
		return

	var camera := get_viewport().get_camera_3d()
	if camera != null:
		health_bar_root.look_at(camera.global_position, Vector3.UP)
		health_bar_root.rotate_y(PI)

	var ratio := clampf(health / maxf(max_health, 0.01), 0.0, 1.0)
	health_bar_fill.scale.x = ratio
	health_bar_fill.position.x = -(HEALTH_BAR_WIDTH * (1.0 - ratio)) * 0.5


func _spawn_damage_number(amount: float) -> void:
	var damage_number := DamageNumber.new()
	add_child(damage_number)
	damage_number.setup(amount, Color(1.0, 0.72, 0.28))


func _update_slow(delta: float) -> void:
	if slow_timer <= 0.0:
		slow_multiplier = 1.0
		return

	slow_timer -= delta
	if slow_timer <= 0.0:
		slow_multiplier = 1.0
