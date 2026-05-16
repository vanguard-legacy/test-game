extends Node3D
class_name PrototypeTower

const RANGE: float = 5.5
const DAMAGE: float = 1.0
const FIRE_RATE: float = 0.45
const MAX_LEVEL: int = 3

var targets: Array[PrototypeEnemy] = []
var cooldown: float = 0.0
var level: int = 1
var range: float = RANGE
var damage: float = DAMAGE
var fire_rate: float = FIRE_RATE

@onready var focus_crystal: MeshInstance3D = $FocusCrystal
@onready var tower_range: MeshInstance3D = $TowerRange


func _process(delta: float) -> void:
	cooldown -= delta
	if cooldown > 0.0:
		return

	var target := _find_target()
	if target == null:
		return

	target.take_damage(damage)
	_show_beam(global_position + Vector3(0.0, 1.0, 0.0), target.global_position + Vector3(0.0, 0.35, 0.0))
	cooldown = fire_rate


func set_targets(new_targets: Array[PrototypeEnemy]) -> void:
	targets = new_targets


func _find_target() -> PrototypeEnemy:
	var closest: PrototypeEnemy = null
	var closest_distance := range

	for target in targets:
		if not is_instance_valid(target):
			continue

		var distance := global_position.distance_to(target.global_position)
		if distance <= closest_distance:
			closest_distance = distance
			closest = target

	return closest


func can_upgrade() -> bool:
	return level < MAX_LEVEL


func get_upgrade_cost() -> int:
	if not can_upgrade():
		return 0

	return 60 + (level - 1) * 45


func upgrade() -> void:
	if not can_upgrade():
		return

	level += 1
	damage += 0.75
	range += 0.75
	fire_rate = max(0.22, fire_rate - 0.07)
	_update_upgrade_visuals()


func get_display_name() -> String:
	return "G'wizard Tower Lv. %d" % level


func get_upgrade_summary() -> String:
	if not can_upgrade():
		return "Fully upgraded"

	return "Upgrade: %d gold" % get_upgrade_cost()


func _ready() -> void:
	_update_upgrade_visuals()


func _update_upgrade_visuals() -> void:
	var crystal_scale := 0.85 + float(level - 1) * 0.18
	focus_crystal.scale = Vector3(crystal_scale, 1.3 + float(level - 1) * 0.18, crystal_scale)
	var mesh := tower_range.mesh as CylinderMesh
	if mesh != null:
		mesh.top_radius = range
		mesh.bottom_radius = range


func _show_beam(from_position: Vector3, to_position: Vector3) -> void:
	var beam := MeshInstance3D.new()
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh.surface_add_vertex(from_position)
	mesh.surface_add_vertex(to_position)
	mesh.surface_end()
	beam.mesh = mesh

	beam.material_override = PrototypeMaterials.unshaded(Color(0.85, 0.95, 1.0))
	get_tree().current_scene.add_child(beam)

	get_tree().create_timer(0.08).timeout.connect(Callable(beam, "queue_free"))
