extends Node3D
class_name PrototypeLevelMap

const MAP_HALF_SIZE: float = 7.0
const TERRAIN_CELLS: int = 56
const PATH_CELLS: int = 36
const TOWER_ORIGIN_OFFSET: float = 0.62
const MIN_TOWER_SPACING: float = 1.25
const MAX_BUILD_SLOPE: float = 0.55

var path_points: Array[Vector3] = []

var active_camera: Camera3D
var navigation_graph := AStar3D.new()
var start_point := Vector2(-6.2, -2.4)
var exit_point := Vector2(6.1, 2.4)
var road_points: Array[Vector2] = [
	Vector2(-6.2, -2.4),
	Vector2(-3.2, -2.25),
	Vector2(-1.25, -0.75),
	Vector2(0.8, 0.05),
	Vector2(2.8, 0.35),
	Vector2(4.8, 1.8),
	Vector2(6.1, 2.4),
]

var terrain_material := PrototypeMaterials.standard(Color(0.30, 0.52, 0.29))
var road_material := PrototypeMaterials.standard(Color(0.56, 0.44, 0.28))


func _ready() -> void:
	_build_world()
	_build_navigation_graph()
	path_points = find_path(get_start_position(), get_exit_position())


func get_active_camera() -> Camera3D:
	return active_camera


func get_start_position() -> Vector3:
	return _world_from_ground(start_point)


func get_exit_position() -> Vector3:
	return _world_from_ground(exit_point)


func find_path(from_position: Vector3, to_position: Vector3) -> Array[Vector3]:
	var start_id := navigation_graph.get_closest_point(from_position)
	var end_id := navigation_graph.get_closest_point(to_position)
	if start_id == -1 or end_id == -1:
		return [from_position, to_position]

	var raw_path := navigation_graph.get_point_path(start_id, end_id)
	if raw_path.is_empty():
		return [from_position, to_position]

	var smoothed_path: Array[Vector3] = []
	for point in raw_path:
		var path_point: Vector3 = point
		if smoothed_path.is_empty() or smoothed_path[-1].distance_to(path_point) > 0.35:
			smoothed_path.append(path_point)

	return smoothed_path


func get_enemy_path() -> Array[Vector3]:
	return find_path(get_start_position(), get_exit_position())


func find_build_position(camera: Camera3D, mouse_position: Vector2, occupied_positions: Array[Vector3]) -> Dictionary:
	if camera == null:
		return {"has_hit": false, "is_valid": false, "reason": "No camera available for placement."}

	var ray_origin := camera.project_ray_origin(mouse_position)
	var ray_direction := camera.project_ray_normal(mouse_position)
	var hit := _find_terrain_hit(ray_origin, ray_direction)
	if not bool(hit.get("has_hit", false)):
		return {"has_hit": false, "is_valid": false, "reason": "Aim at the terrain."}

	var terrain_position: Vector3 = hit["position"]
	var ground_point := Vector2(terrain_position.x, terrain_position.z)
	var blocked_reason := _get_blocked_reason(ground_point, occupied_positions)
	return {
		"has_hit": true,
		"is_valid": blocked_reason.is_empty(),
		"position": terrain_position + Vector3(0.0, TOWER_ORIGIN_OFFSET, 0.0),
		"reason": blocked_reason,
	}


func _build_world() -> void:
	active_camera = Camera3D.new()
	active_camera.name = "Camera"
	active_camera.position = Vector3(0.0, 10.5, 10.5)
	active_camera.rotation_degrees = Vector3(-54.0, 0.0, 0.0)
	add_child(active_camera)
	active_camera.current = true

	var light := DirectionalLight3D.new()
	light.name = "Sun"
	light.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
	light.light_energy = 2.4
	add_child(light)

	_add_terrain_mesh()
	_add_road_mesh()
	_add_marker("StartMarker", get_start_position(), Color(0.42, 0.78, 0.44))
	_add_marker("ExitGate", get_exit_position(), Color(0.28, 0.22, 0.18))


func _add_terrain_mesh() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_material(terrain_material)

	var step := (MAP_HALF_SIZE * 2.0) / float(TERRAIN_CELLS)
	for x_index in range(TERRAIN_CELLS):
		for z_index in range(TERRAIN_CELLS):
			var x0 := -MAP_HALF_SIZE + float(x_index) * step
			var z0 := -MAP_HALF_SIZE + float(z_index) * step
			var x1 := x0 + step
			var z1 := z0 + step
			_add_quad(surface, _world_from_ground(Vector2(x0, z0)), _world_from_ground(Vector2(x1, z0)), _world_from_ground(Vector2(x1, z1)), _world_from_ground(Vector2(x0, z1)))

	surface.generate_normals()
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "ProceduralTerrain"
	mesh_instance.mesh = surface.commit()
	add_child(mesh_instance)


func _add_road_mesh() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_material(road_material)

	var step := (MAP_HALF_SIZE * 2.0) / float(TERRAIN_CELLS)
	for x_index in range(TERRAIN_CELLS):
		for z_index in range(TERRAIN_CELLS):
			var center := Vector2(
				-MAP_HALF_SIZE + (float(x_index) + 0.5) * step,
				-MAP_HALF_SIZE + (float(z_index) + 0.5) * step
			)
			var road_info := _get_road_info(center)
			if float(road_info["distance"]) > _road_half_width(float(road_info["progress"])) + 0.08:
				continue

			var x0 := center.x - step * 0.5
			var z0 := center.y - step * 0.5
			var x1 := center.x + step * 0.5
			var z1 := center.y + step * 0.5
			_add_quad(surface, _world_from_ground(Vector2(x0, z0), 0.035), _world_from_ground(Vector2(x1, z0), 0.035), _world_from_ground(Vector2(x1, z1), 0.035), _world_from_ground(Vector2(x0, z1), 0.035))

	surface.generate_normals()
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "ProceduralRoad"
	mesh_instance.mesh = surface.commit()
	add_child(mesh_instance)


func _build_navigation_graph() -> void:
	navigation_graph.clear()
	var step := (MAP_HALF_SIZE * 2.0) / float(PATH_CELLS)

	for x_index in range(PATH_CELLS + 1):
		for z_index in range(PATH_CELLS + 1):
			var point := Vector2(-MAP_HALF_SIZE + float(x_index) * step, -MAP_HALF_SIZE + float(z_index) * step)
			if not _is_road(point):
				continue

			var point_id := _path_id(x_index, z_index)
			navigation_graph.add_point(point_id, _world_from_ground(point))

	for x_index in range(PATH_CELLS + 1):
		for z_index in range(PATH_CELLS + 1):
			var point_id := _path_id(x_index, z_index)
			if not navigation_graph.has_point(point_id):
				continue

			for offset in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, -1)]:
				var neighbor_id := _path_id(x_index + offset.x, z_index + offset.y)
				if navigation_graph.has_point(neighbor_id):
					navigation_graph.connect_points(point_id, neighbor_id)


func _add_quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	surface.add_vertex(a)
	surface.add_vertex(b)
	surface.add_vertex(c)
	surface.add_vertex(a)
	surface.add_vertex(c)
	surface.add_vertex(d)


func _add_marker(node_name: String, marker_position: Vector3, color: Color) -> void:
	var marker := MeshInstance3D.new()
	marker.name = node_name
	marker.position = marker_position + Vector3(0.0, 0.35, 0.0)

	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0 if node_name == "ExitGate" else 0.28
	mesh.bottom_radius = 0.45
	mesh.height = 0.7
	marker.mesh = mesh
	marker.material_override = PrototypeMaterials.standard(color)
	add_child(marker)


func _world_from_ground(point: Vector2, y_offset: float = 0.0) -> Vector3:
	return Vector3(point.x, _height_at(point) + y_offset, point.y)


func _height_at(point: Vector2) -> float:
	var rolling_height: float = 0.18 * sin(point.x * 0.75) + 0.12 * cos(point.y * 0.9) + 0.05 * sin((point.x + point.y) * 1.2)
	var road_info := _get_road_info(point)
	var progress := float(road_info["progress"])
	var road_height: float = _road_height(progress)
	var road_blend: float = 1.0 - clampf(float(road_info["distance"]) / (_road_half_width(progress) + 1.15), 0.0, 1.0)
	road_blend = smoothstep(0.0, 1.0, road_blend)
	return lerp(rolling_height, road_height, road_blend)


func _road_height(progress: float) -> float:
	if progress < 0.42:
		return lerp(0.05, 1.2, smoothstep(0.0, 1.0, progress / 0.42))

	if progress < 0.68:
		return 1.2 + 0.06 * sin(progress * TAU * 2.0)

	return lerp(1.2, 0.16, smoothstep(0.0, 1.0, (progress - 0.68) / 0.32))


func _road_half_width(progress: float) -> float:
	return lerp(0.52, 1.05, smoothstep(0.0, 1.0, progress))


func _is_road(point: Vector2) -> bool:
	var road_info := _get_road_info(point)
	return float(road_info["distance"]) <= _road_half_width(float(road_info["progress"]))


func _get_road_info(point: Vector2) -> Dictionary:
	var closest_distance: float = INF
	var closest_progress := 0.0
	var traveled := 0.0
	var total_length := _road_length()

	for index in range(road_points.size() - 1):
		var start: Vector2 = road_points[index]
		var end: Vector2 = road_points[index + 1]
		var segment: Vector2 = end - start
		var segment_length := segment.length()
		var segment_progress: float = clampf((point - start).dot(segment) / segment.length_squared(), 0.0, 1.0)
		var closest: Vector2 = start + segment * segment_progress
		var distance := point.distance_to(closest)
		if distance < closest_distance:
			closest_distance = distance
			closest_progress = (traveled + segment_length * segment_progress) / total_length

		traveled += segment_length

	return {"distance": closest_distance, "progress": closest_progress}


func _road_length() -> float:
	var length := 0.0
	for index in range(road_points.size() - 1):
		length += road_points[index].distance_to(road_points[index + 1])

	return length


func _find_terrain_hit(ray_origin: Vector3, ray_direction: Vector3) -> Dictionary:
	var previous_distance := 0.0
	var previous_delta := ray_origin.y - _height_at(Vector2(ray_origin.x, ray_origin.z))

	for step_index in range(1, 160):
		var distance := float(step_index) * 0.45
		var point := ray_origin + ray_direction * distance
		if absf(point.x) > MAP_HALF_SIZE + 0.5 or absf(point.z) > MAP_HALF_SIZE + 0.5:
			continue

		var current_delta := point.y - _height_at(Vector2(point.x, point.z))
		if current_delta <= 0.0 and previous_delta >= 0.0:
			var hit_distance := _refine_hit_distance(ray_origin, ray_direction, previous_distance, distance)
			var hit := ray_origin + ray_direction * hit_distance
			return {"has_hit": true, "position": Vector3(hit.x, _height_at(Vector2(hit.x, hit.z)), hit.z)}

		previous_distance = distance
		previous_delta = current_delta

	return {"has_hit": false}


func _refine_hit_distance(ray_origin: Vector3, ray_direction: Vector3, min_distance: float, max_distance: float) -> float:
	var low := min_distance
	var high := max_distance
	for _iteration in range(8):
		var mid := (low + high) * 0.5
		var point := ray_origin + ray_direction * mid
		var delta := point.y - _height_at(Vector2(point.x, point.z))
		if delta > 0.0:
			low = mid
		else:
			high = mid

	return high


func _get_blocked_reason(ground_point: Vector2, occupied_positions: Array[Vector3]) -> String:
	if absf(ground_point.x) > MAP_HALF_SIZE or absf(ground_point.y) > MAP_HALF_SIZE:
		return "Build inside the map."

	if _is_road(ground_point):
		return "Can't build on the road."

	if _get_local_slope(ground_point) > MAX_BUILD_SLOPE:
		return "Find flatter ground for the tower."

	for position in occupied_positions:
		var tower_point := Vector2(position.x, position.z)
		if tower_point.distance_to(ground_point) < MIN_TOWER_SPACING:
			return "Towers need more space."

	return ""


func _get_local_slope(point: Vector2) -> float:
	var sample_distance := 0.45
	var center_height := _height_at(point)
	var x_height := _height_at(point + Vector2(sample_distance, 0.0))
	var z_height := _height_at(point + Vector2(0.0, sample_distance))
	return max(absf(x_height - center_height), absf(z_height - center_height)) / sample_distance


func _path_id(x_index: int, z_index: int) -> int:
	return x_index * (PATH_CELLS + 1) + z_index
