extends Node3D
class_name PrototypeTowerPlacement

const BuildPlacementResult := preload("res://scripts/build_placement_result.gd")

# Handles the preview/click lifecycle for placing towers. Main decides which
# tower is being built; LevelMap decides whether the hovered terrain is legal.

signal placement_confirmed(position: Vector3)
signal placement_cancelled
signal placement_rejected(reason: String)
signal placement_mode_changed(is_active: bool)

const PREVIEW_SURFACE_OFFSET: float = 0.56

var level_map: PrototypeLevelMap
var active_camera: Camera3D
var occupied_positions: Array[Vector3] = []
var is_active: bool = false
var current_result: BuildPlacementResult = BuildPlacementResult.new()

var preview: MeshInstance3D
var valid_material: StandardMaterial3D
var invalid_material: StandardMaterial3D


func _ready() -> void:
	_build_preview()


func setup(map: PrototypeLevelMap) -> void:
	level_map = map
	active_camera = level_map.get_active_camera()


func begin_placement(new_occupied_positions: Array[Vector3]) -> void:
	occupied_positions = new_occupied_positions
	is_active = true
	preview.visible = true
	placement_mode_changed.emit(true)


func cancel_placement() -> void:
	if not is_active:
		return

	is_active = false
	current_result = BuildPlacementResult.new()
	preview.visible = false
	placement_cancelled.emit()
	placement_mode_changed.emit(false)


func _process(_delta: float) -> void:
	if not is_active or active_camera == null or level_map == null:
		return

	_update_preview()


func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return

	if event.is_action_pressed("ui_cancel"):
		cancel_placement()
		get_viewport().set_input_as_handled()
		return

	var mouse_event := event as InputEventMouseButton
	if mouse_event == null:
		return

	if not mouse_event.pressed:
		return

	if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
		cancel_placement()
		get_viewport().set_input_as_handled()
		return

	if mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return

	if current_result.is_valid:
		placement_confirmed.emit(current_result.position)
	else:
		placement_rejected.emit(current_result.reason if not current_result.reason.is_empty() else "Choose a valid patch of land.")

	get_viewport().set_input_as_handled()


func _update_preview() -> void:
	var mouse_position := get_viewport().get_mouse_position()
	current_result = level_map.find_build_position(active_camera, mouse_position, occupied_positions)
	preview.visible = current_result.has_hit

	if not current_result.has_hit:
		return

	preview.global_position = current_result.position - Vector3(0.0, PREVIEW_SURFACE_OFFSET, 0.0)
	preview.material_override = valid_material if current_result.is_valid else invalid_material


func _build_preview() -> void:
	preview = MeshInstance3D.new()
	preview.name = "TowerPlacementPreview"
	preview.visible = false

	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.55
	mesh.bottom_radius = 0.55
	mesh.height = 0.08
	preview.mesh = mesh

	valid_material = PrototypeMaterials.transparent(Color(0.35, 0.95, 0.45, 0.45))
	invalid_material = PrototypeMaterials.transparent(Color(0.95, 0.2, 0.2, 0.45))
	preview.material_override = valid_material
	add_child(preview)
