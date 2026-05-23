extends Node3D
class_name DefenseTowerProjectile

const Materials := preload("res://scripts/materials.gd")

signal impact

const ARC_HEIGHT: float = 1.85
const LIFETIME: float = 0.34
const TRAIL_POINTS: int = 10

var start_position: Vector3 = Vector3.ZERO
var end_position: Vector3 = Vector3.ZERO
var age: float = 0.0
var has_impacted: bool = false
var projectile_color: Color = Color.WHITE
var projectile_mesh: MeshInstance3D
var trail_mesh: MeshInstance3D
var trail_immediate_mesh := ImmediateMesh.new()


func setup(new_start_position: Vector3, new_end_position: Vector3, new_color: Color) -> void:
	start_position = new_start_position
	end_position = new_end_position
	projectile_color = new_color
	global_position = start_position
	_build_visuals()
	_update_visuals(0.0)


func _process(delta: float) -> void:
	if has_impacted:
		return

	age += delta
	var progress := clampf(age / LIFETIME, 0.0, 1.0)
	_update_visuals(progress)
	if progress >= 1.0:
		has_impacted = true
		impact.emit()
		queue_free()


func _build_visuals() -> void:
	projectile_mesh = MeshInstance3D.new()
	projectile_mesh.name = "Projectile"
	var sphere := SphereMesh.new()
	sphere.radius = 0.105
	sphere.height = 0.21
	projectile_mesh.mesh = sphere
	projectile_mesh.material_override = Materials.unshaded(projectile_color)
	add_child(projectile_mesh)

	trail_mesh = MeshInstance3D.new()
	trail_mesh.name = "Trail"
	trail_mesh.mesh = trail_immediate_mesh
	trail_mesh.material_override = Materials.unshaded(Color(projectile_color.r, projectile_color.g, projectile_color.b, 0.72))
	add_child(trail_mesh)


func _update_visuals(progress: float) -> void:
	global_position = _arc_position(progress)
	var next_progress := minf(progress + 0.04, 1.0)
	var direction := _arc_position(next_progress) - global_position
	if direction.length_squared() > 0.001:
		look_at(global_position + direction.normalized(), Vector3.UP)

	_update_trail(progress)


func _update_trail(progress: float) -> void:
	trail_immediate_mesh.clear_surfaces()
	trail_immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	var start_progress := maxf(0.0, progress - 0.38)
	for index in range(TRAIL_POINTS):
		var step := float(index) / float(TRAIL_POINTS - 1)
		var trail_progress := lerpf(start_progress, progress, step)
		trail_immediate_mesh.surface_add_vertex(to_local(_arc_position(trail_progress)))

	trail_immediate_mesh.surface_end()


func _arc_position(progress: float) -> Vector3:
	var position := start_position.lerp(end_position, progress)
	position.y += sin(progress * PI) * ARC_HEIGHT
	return position
