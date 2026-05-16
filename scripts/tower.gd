extends Node3D
class_name PrototypeTower

const RANGE: float = 5.5
const DAMAGE: float = 1.0
const FIRE_RATE: float = 0.45

var targets: Array[PrototypeEnemy] = []
var cooldown: float = 0.0


func _process(delta: float) -> void:
	cooldown -= delta
	if cooldown > 0.0:
		return

	var target := _find_target()
	if target == null:
		return

	target.take_damage(DAMAGE)
	_show_beam(global_position + Vector3(0.0, 1.0, 0.0), target.global_position + Vector3(0.0, 0.35, 0.0))
	cooldown = FIRE_RATE


func set_targets(new_targets: Array[PrototypeEnemy]) -> void:
	targets = new_targets


func _find_target() -> PrototypeEnemy:
	var closest: PrototypeEnemy = null
	var closest_distance := RANGE

	for target in targets:
		if not is_instance_valid(target):
			continue

		var distance := global_position.distance_to(target.global_position)
		if distance <= closest_distance:
			closest_distance = distance
			closest = target

	return closest


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
