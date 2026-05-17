extends Node
class_name PrototypeCameraController

const TerrainQuery := preload("res://scripts/terrain_query.gd")

# RTS-style camera controller. Middle-drag panning grabs a fixed-height plane
# under the cursor so the terrain appears to move with the mouse without
# accidental zooming over hills.

const ROTATE_BUTTON: MouseButton = MOUSE_BUTTON_RIGHT
const PAN_BUTTON: MouseButton = MOUSE_BUTTON_MIDDLE

@export var edge_size: float = 18.0
@export var keyboard_pan_speed: float = 8.0
@export var rotate_speed: float = 0.24
@export var tilt_speed: float = 0.18
@export var zoom_step: float = 1.15
@export var min_distance: float = 7.0
@export var max_distance: float = 20.0
@export var min_tilt_degrees: float = 36.0
@export var max_tilt_degrees: float = 72.0

var camera: Camera3D
var map_half_size: float = 7.0
var target_position: Vector3 = Vector3.ZERO
var yaw_degrees: float = 0.0
var tilt_degrees: float = 54.0
var distance: float = 14.5
var controls_enabled: bool = false
var is_rotating: bool = false
var is_panning: bool = false
var terrain_picker: Callable
var pan_anchor: Vector3 = Vector3.ZERO
var pan_plane_height: float = 0.0
var has_pan_anchor: bool = false


func setup(new_camera: Camera3D, new_map_half_size: float, new_terrain_picker: Callable) -> void:
	camera = new_camera
	map_half_size = new_map_half_size
	terrain_picker = new_terrain_picker
	_apply_camera_transform()


func set_controls_enabled(is_enabled: bool) -> void:
	controls_enabled = is_enabled
	if not controls_enabled:
		is_rotating = false
		is_panning = false
		has_pan_anchor = false


func _process(delta: float) -> void:
	if camera == null or not controls_enabled or get_tree().paused:
		return

	_pan_from_keyboard_and_edges(delta)
	_apply_camera_transform()


func _unhandled_input(event: InputEvent) -> void:
	if camera == null or not controls_enabled or get_tree().paused:
		return

	var mouse_button := event as InputEventMouseButton
	if mouse_button != null:
		_handle_mouse_button(mouse_button)
		return

	var mouse_motion := event as InputEventMouseMotion
	if mouse_motion == null:
		return

	if is_rotating:
		yaw_degrees -= mouse_motion.relative.x * rotate_speed
		tilt_degrees = clampf(tilt_degrees + mouse_motion.relative.y * tilt_speed, min_tilt_degrees, max_tilt_degrees)
		get_viewport().set_input_as_handled()
	elif is_panning:
		_pan_by_terrain_anchor(mouse_motion.position)
		get_viewport().set_input_as_handled()


func _handle_mouse_button(mouse_button: InputEventMouseButton) -> void:
	if _is_mouse_over_ui():
		_stop_mouse_drag()
		return

	if mouse_button.button_index == ROTATE_BUTTON:
		is_rotating = mouse_button.pressed
		get_viewport().set_input_as_handled()
		return

	if mouse_button.button_index == PAN_BUTTON:
		is_panning = mouse_button.pressed
		has_pan_anchor = false
		if is_panning:
			var anchor_result := _get_terrain_under_cursor(mouse_button.position)
			has_pan_anchor = anchor_result.has_hit
			if has_pan_anchor:
				pan_anchor = anchor_result.position
				pan_plane_height = pan_anchor.y
		get_viewport().set_input_as_handled()
		return

	if not mouse_button.pressed:
		return

	if mouse_button.button_index == MOUSE_BUTTON_WHEEL_UP:
		distance = maxf(min_distance, distance - zoom_step)
		get_viewport().set_input_as_handled()
	elif mouse_button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		distance = minf(max_distance, distance + zoom_step)
		get_viewport().set_input_as_handled()


func _is_mouse_over_ui() -> bool:
	return get_viewport().gui_get_hovered_control() != null


func _stop_mouse_drag() -> void:
	is_rotating = false
	is_panning = false
	has_pan_anchor = false


func _pan_from_keyboard_and_edges(delta: float) -> void:
	var move_direction := Vector3.ZERO
	var forward := _camera_forward()
	var right := _camera_right()

	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		move_direction += forward
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		move_direction -= forward
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		move_direction += right
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		move_direction -= right

	if get_viewport().gui_get_hovered_control() == null:
		var viewport_rect := get_viewport().get_visible_rect()
		var mouse_position := get_viewport().get_mouse_position()
		if mouse_position.y <= edge_size:
			move_direction += forward
		elif mouse_position.y >= viewport_rect.size.y - edge_size:
			move_direction -= forward

		if mouse_position.x <= edge_size:
			move_direction -= right
		elif mouse_position.x >= viewport_rect.size.x - edge_size:
			move_direction += right

	if move_direction == Vector3.ZERO:
		return

	var scaled_speed := keyboard_pan_speed * (distance / 14.0)
	target_position += move_direction.normalized() * scaled_speed * delta
	_clamp_target_position()


func _pan_by_terrain_anchor(mouse_position: Vector2) -> void:
	if not has_pan_anchor:
		return

	var current_result := _get_cursor_on_pan_plane(mouse_position)
	if not current_result.has_hit:
		return

	var current_position := current_result.position
	var pan_delta := pan_anchor - current_position
	pan_delta.y = 0.0
	target_position += pan_delta
	_clamp_target_position()
	_apply_camera_transform()


func _apply_camera_transform() -> void:
	var tilt_radians := deg_to_rad(tilt_degrees)
	var horizontal_distance := cos(tilt_radians) * distance
	var height := sin(tilt_radians) * distance
	var camera_back := -_camera_forward()
	camera.global_position = target_position + camera_back * horizontal_distance + Vector3.UP * height
	camera.look_at(target_position, Vector3.UP)


func _camera_forward() -> Vector3:
	var yaw_radians := deg_to_rad(yaw_degrees)
	return Vector3(-sin(yaw_radians), 0.0, -cos(yaw_radians)).normalized()


func _camera_right() -> Vector3:
	return _camera_forward().cross(Vector3.UP).normalized()


func _clamp_target_position() -> void:
	var margin := map_half_size + 1.5
	target_position.x = clampf(target_position.x, -margin, margin)
	target_position.z = clampf(target_position.z, -margin, margin)


func _get_terrain_under_cursor(mouse_position: Vector2) -> TerrainQuery:
	if not terrain_picker.is_valid():
		return TerrainQuery.new()

	var query := terrain_picker.call(camera, mouse_position) as TerrainQuery
	return query if query != null else TerrainQuery.new()


func _get_cursor_on_pan_plane(mouse_position: Vector2) -> TerrainQuery:
	var ray_origin := camera.project_ray_origin(mouse_position)
	var ray_direction := camera.project_ray_normal(mouse_position)
	if absf(ray_direction.y) < 0.001:
		return TerrainQuery.new()

	var distance_to_plane := (pan_plane_height - ray_origin.y) / ray_direction.y
	if distance_to_plane <= 0.0:
		return TerrainQuery.new()

	return TerrainQuery.new(true, ray_origin + ray_direction * distance_to_plane)
