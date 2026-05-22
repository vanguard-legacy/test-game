extends Node3D
class_name DefenseLevelMap

const BuildPlacementResult := preload("res://scripts/build_placement_result.gd")
const CameraController := preload("res://scripts/camera_controller.gd")
const GameBalance := preload("res://scripts/game_balance.gd")
const RoadInfo := preload("res://scripts/road_info.gd")
const TerrainQuery := preload("res://scripts/terrain_query.gd")
const TowerTerrainBonus := preload("res://scripts/tower_terrain_bonus.gd")
const Materials := preload("res://scripts/materials.gd")

# Procedural game map. This node owns terrain height, road shape, pathing,
# build validation, and camera setup so gameplay code can ask higher-level
# questions such as "where can I place?" or "how do enemies reach the exit?"

const MAP_HALF_SIZE: float = 28.0
const PLAYABLE_HALF_SIZE: float = 11.0
const TERRAIN_CELLS: int = 128
const PATH_CELLS: int = 58
const ROAD_POINT_COUNT: int = 12
const TOWER_ORIGIN_OFFSET: float = 0.62
const MIN_TOWER_SPACING: float = 1.25
const MAX_BUILD_SLOPE: float = 0.55
const FOG_DRIFT_RADIUS: float = 0.75
const FOG_BREATH_AMOUNT: float = 0.08
const SPAWN_HOVER_RADIUS: float = 1.15

@export var map_seed: int = 20260522

var path_points: Array[Vector3] = []
var fog_bank_nodes: Array[Node3D] = []
var fog_bank_origins: Array[Vector3] = []
var fog_bank_drift_vectors: Array[Vector3] = []
var fog_bank_base_scales: Array[Vector3] = []
var fog_bank_phases: Array[float] = []

var active_camera: Camera3D
var camera_controller: Node
var navigation_graph := AStar3D.new()
var start_point := Vector2.ZERO
var exit_point := Vector2.ZERO
var road_points: Array[Vector2] = []
var terrain_features: Array[Vector4] = []
var terrain_noise := FastNoiseLite.new()
var detail_noise := FastNoiseLite.new()
var generation_seed: int = 0

var terrain_material := Materials.terrain()
var road_material := Materials.road()
var fog_bank_material := Materials.fog_bank()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	_animate_fog_banks()


func generate_map(seed: int, progress_callback: Callable = Callable()) -> void:
	map_seed = seed
	_report_generation_progress(progress_callback, 0.02, "Preparing terrain seed.")
	_configure_generation()
	await get_tree().process_frame
	_clear_generated_world()
	_report_generation_progress(progress_callback, 0.16, "Clearing old map.")
	await get_tree().process_frame
	_build_world()
	_report_generation_progress(progress_callback, 0.74, "Building terrain and road.")
	await get_tree().process_frame
	_build_navigation_graph()
	path_points = find_path(get_start_position(), get_exit_position())
	_report_generation_progress(progress_callback, 1.0, "Map ready.")


func _report_generation_progress(progress_callback: Callable, progress: float, message: String) -> void:
	if progress_callback.is_valid():
		progress_callback.call(progress, message)


func _clear_generated_world() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

	active_camera = null
	camera_controller = null
	navigation_graph.clear()
	path_points.clear()
	fog_bank_nodes.clear()
	fog_bank_origins.clear()
	fog_bank_drift_vectors.clear()
	fog_bank_base_scales.clear()
	fog_bank_phases.clear()


func set_map_seed(seed: int) -> void:
	map_seed = seed


func get_active_camera() -> Camera3D:
	return active_camera


func set_camera_controls_enabled(is_enabled: bool) -> void:
	if camera_controller != null and camera_controller.has_method("set_controls_enabled"):
		camera_controller.set_controls_enabled(is_enabled)


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


func find_build_position(camera: Camera3D, mouse_position: Vector2, occupied_positions: Array[Vector3]) -> BuildPlacementResult:
	if camera == null:
		return BuildPlacementResult.new(false, false, Vector3.ZERO, "No camera available for placement.")

	var hit := find_terrain_position(camera, mouse_position)
	if not hit.has_hit:
		return BuildPlacementResult.new(false, false, Vector3.ZERO, "Aim at the terrain.")

	var terrain_position := hit.position
	var ground_point := Vector2(terrain_position.x, terrain_position.z)
	var blocked_reason := _get_blocked_reason(ground_point, occupied_positions)
	var build_position := terrain_position + Vector3(0.0, TOWER_ORIGIN_OFFSET, 0.0)
	if blocked_reason.is_empty():
		return BuildPlacementResult.new(true, true, build_position)

	return BuildPlacementResult.new(true, false, build_position, blocked_reason)


func find_terrain_position(camera: Camera3D, mouse_position: Vector2) -> TerrainQuery:
	if camera == null:
		return TerrainQuery.new()

	var ray_origin := camera.project_ray_origin(mouse_position)
	var ray_direction := camera.project_ray_normal(mouse_position)
	return _find_terrain_hit(ray_origin, ray_direction)


func is_spawn_hovered(camera: Camera3D, mouse_position: Vector2) -> bool:
	var terrain_hit := find_terrain_position(camera, mouse_position)
	if not terrain_hit.has_hit:
		return false

	var hit_point := Vector2(terrain_hit.position.x, terrain_hit.position.z)
	return hit_point.distance_to(start_point) <= SPAWN_HOVER_RADIUS


func get_tower_terrain_bonus(build_position: Vector3) -> TowerTerrainBonus:
	return GameBalance.get_tower_terrain_bonus(build_position.y - TOWER_ORIGIN_OFFSET)


func _build_world() -> void:
	active_camera = Camera3D.new()
	active_camera.name = "Camera"
	active_camera.position = Vector3(0.0, 13.5, 13.5)
	active_camera.rotation_degrees = Vector3(-54.0, 0.0, 0.0)
	add_child(active_camera)
	active_camera.current = true

	camera_controller = CameraController.new()
	camera_controller.name = "CameraController"
	add_child(camera_controller)
	camera_controller.setup(active_camera, PLAYABLE_HALF_SIZE, Callable(self, "find_terrain_position"))

	var light := DirectionalLight3D.new()
	light.name = "Sun"
	light.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
	light.light_energy = 1.85
	light.shadow_enabled = true
	add_child(light)

	_add_terrain_mesh()
	_add_road_mesh()
	_add_atmosphere()
	_add_fog_banks()
	_add_marker("StartMarker", get_start_position(), Color(0.25, 0.58, 0.28))
	_add_marker("ExitGate", get_exit_position(), Color(0.16, 0.12, 0.10))


func _configure_generation() -> void:
	generation_seed = map_seed
	if generation_seed == 0:
		generation_seed = int(Time.get_unix_time_from_system())

	terrain_noise.seed = generation_seed
	terrain_noise.frequency = 0.075
	terrain_noise.fractal_octaves = 4
	terrain_noise.fractal_gain = 0.48
	terrain_noise.fractal_lacunarity = 2.1

	detail_noise.seed = generation_seed + 137
	detail_noise.frequency = 0.23
	detail_noise.fractal_octaves = 3
	detail_noise.fractal_gain = 0.42

	var rng := RandomNumberGenerator.new()
	rng.seed = generation_seed
	_generate_road_points(rng)
	_generate_terrain_features(rng)


func _generate_road_points(rng: RandomNumberGenerator) -> void:
	road_points.clear()
	var lane_limit := PLAYABLE_HALF_SIZE - 1.0
	start_point = Vector2(-lane_limit, rng.randf_range(-6.6, -4.2))
	exit_point = Vector2(lane_limit, rng.randf_range(4.2, 6.8))

	for index in range(ROAD_POINT_COUNT):
		var progress := float(index) / float(ROAD_POINT_COUNT - 1)
		var x: float = lerpf(start_point.x, exit_point.x, progress)
		var route_wave := sin(progress * TAU * 1.35 + rng.randf_range(-0.4, 0.4)) * rng.randf_range(2.4, 4.5)
		var route_bend := sin(progress * TAU * 3.1 + rng.randf_range(-1.2, 1.2)) * rng.randf_range(0.6, 1.8)
		var y: float = lerpf(start_point.y, exit_point.y, progress) + route_wave + route_bend
		if index == 0:
			road_points.append(start_point)
		elif index == ROAD_POINT_COUNT - 1:
			road_points.append(exit_point)
		else:
			road_points.append(Vector2(x, clampf(y, -lane_limit, lane_limit)))


func _generate_terrain_features(rng: RandomNumberGenerator) -> void:
	terrain_features.clear()
	for _index in range(7):
		var feature_position := Vector2(
			rng.randf_range(-PLAYABLE_HALF_SIZE, PLAYABLE_HALF_SIZE),
			rng.randf_range(-PLAYABLE_HALF_SIZE, PLAYABLE_HALF_SIZE)
		)
		var radius := rng.randf_range(3.6, 7.2)
		var height := rng.randf_range(-0.55, 0.95)
		terrain_features.append(Vector4(feature_position.x, feature_position.y, radius, height))


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
			_add_terrain_quad(surface, Vector2(x0, z0), Vector2(x1, z0), Vector2(x1, z1), Vector2(x0, z1))

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
			if road_info.distance > _road_half_width(road_info.progress) + 0.08:
				continue

			var x0 := center.x - step * 0.5
			var z0 := center.y - step * 0.5
			var x1 := center.x + step * 0.5
			var z1 := center.y + step * 0.5
			_add_road_quad(surface, Vector2(x0, z0), Vector2(x1, z0), Vector2(x1, z1), Vector2(x0, z1))

	surface.generate_normals()
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "ProceduralRoad"
	mesh_instance.mesh = surface.commit()
	add_child(mesh_instance)


func _build_navigation_graph() -> void:
	navigation_graph.clear()
	var step := (PLAYABLE_HALF_SIZE * 2.0) / float(PATH_CELLS)

	for x_index in range(PATH_CELLS + 1):
		for z_index in range(PATH_CELLS + 1):
			var point := Vector2(-PLAYABLE_HALF_SIZE + float(x_index) * step, -PLAYABLE_HALF_SIZE + float(z_index) * step)
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


func _add_terrain_quad(surface: SurfaceTool, a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> void:
	_add_colored_vertex(surface, _world_from_ground(a), _terrain_color_at(a))
	_add_colored_vertex(surface, _world_from_ground(b), _terrain_color_at(b))
	_add_colored_vertex(surface, _world_from_ground(c), _terrain_color_at(c))
	_add_colored_vertex(surface, _world_from_ground(a), _terrain_color_at(a))
	_add_colored_vertex(surface, _world_from_ground(c), _terrain_color_at(c))
	_add_colored_vertex(surface, _world_from_ground(d), _terrain_color_at(d))


func _add_road_quad(surface: SurfaceTool, a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> void:
	_add_colored_vertex(surface, _world_from_ground(a, 0.04), _road_color_at(a))
	_add_colored_vertex(surface, _world_from_ground(b, 0.04), _road_color_at(b))
	_add_colored_vertex(surface, _world_from_ground(c, 0.04), _road_color_at(c))
	_add_colored_vertex(surface, _world_from_ground(a, 0.04), _road_color_at(a))
	_add_colored_vertex(surface, _world_from_ground(c, 0.04), _road_color_at(c))
	_add_colored_vertex(surface, _world_from_ground(d, 0.04), _road_color_at(d))


func _add_colored_vertex(surface: SurfaceTool, vertex: Vector3, color: Color) -> void:
	surface.set_color(color)
	surface.add_vertex(vertex)


func _add_marker(node_name: String, marker_position: Vector3, color: Color) -> void:
	var marker := MeshInstance3D.new()
	marker.name = node_name
	marker.position = marker_position + Vector3(0.0, 0.35, 0.0)

	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0 if node_name == "ExitGate" else 0.28
	mesh.bottom_radius = 0.45
	mesh.height = 0.7
	marker.mesh = mesh
	marker.material_override = Materials.standard(color)
	add_child(marker)


func _add_atmosphere() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.33, 0.39, 0.38)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.31, 0.37, 0.34)
	environment.ambient_light_energy = 0.38
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.15, 0.20, 0.18)
	environment.fog_light_energy = 0.45
	environment.fog_density = 0.018
	environment.fog_sky_affect = 0.72
	environment.volumetric_fog_enabled = true
	environment.volumetric_fog_density = 0.022
	environment.volumetric_fog_albedo = Color(0.15, 0.19, 0.17)
	environment.volumetric_fog_length = 48.0
	environment.volumetric_fog_detail_spread = 1.9

	var world_environment := WorldEnvironment.new()
	world_environment.name = "Atmosphere"
	world_environment.environment = environment
	add_child(world_environment)


func _add_fog_banks() -> void:
	var fog_root := Node3D.new()
	fog_root.name = "FogBanks"
	add_child(fog_root)

	var rng := RandomNumberGenerator.new()
	rng.seed = generation_seed + 991
	for index in range(16):
		var angle := rng.randf_range(0.0, TAU)
		var distance_from_center := rng.randf_range(PLAYABLE_HALF_SIZE + 5.5, MAP_HALF_SIZE - 4.0)
		var ground_point := Vector2(cos(angle), sin(angle)) * distance_from_center
		_add_fog_bank_cluster(fog_root, index, ground_point, rng)


func _add_fog_bank_cluster(parent: Node3D, index: int, ground_point: Vector2, rng: RandomNumberGenerator) -> void:
	var cluster := Node3D.new()
	cluster.name = "FogBank%d" % index
	cluster.position = _world_from_ground(ground_point, rng.randf_range(0.2, 0.45))
	parent.add_child(cluster)
	fog_bank_nodes.append(cluster)
	fog_bank_origins.append(cluster.position)
	fog_bank_drift_vectors.append(Vector3(rng.randf_range(-1.0, 1.0), 0.0, rng.randf_range(-1.0, 1.0)).normalized())
	fog_bank_base_scales.append(Vector3.ONE)
	fog_bank_phases.append(rng.randf_range(0.0, TAU))

	var puff_count := rng.randi_range(3, 5)
	for puff_index in range(puff_count):
		var offset := Vector2(rng.randf_range(-2.8, 2.8), rng.randf_range(-2.4, 2.4))
		var puff := MeshInstance3D.new()
		puff.name = "Puff%d" % puff_index
		puff.position = Vector3(offset.x, rng.randf_range(0.28, 0.92), offset.y)
		puff.rotation_degrees = Vector3(rng.randf_range(-3.0, 3.0), rng.randf_range(0.0, 360.0), rng.randf_range(-4.0, 4.0))
		puff.scale = Vector3(rng.randf_range(3.2, 6.8), rng.randf_range(0.42, 0.95), rng.randf_range(2.2, 5.4))

		var mesh := SphereMesh.new()
		mesh.radius = 1.0
		mesh.height = 2.0
		mesh.radial_segments = 24
		mesh.rings = 12
		puff.mesh = mesh
		puff.material_override = fog_bank_material
		cluster.add_child(puff)


func _animate_fog_banks() -> void:
	if fog_bank_nodes.is_empty():
		return

	var time := float(Time.get_ticks_msec()) / 1000.0
	for index in range(fog_bank_nodes.size()):
		var bank := fog_bank_nodes[index]
		if not is_instance_valid(bank):
			continue

		var phase := fog_bank_phases[index]
		var drift_vector := fog_bank_drift_vectors[index]
		var side_vector := drift_vector.cross(Vector3.UP)
		var drift := drift_vector * sin(time * 0.11 + phase) * FOG_DRIFT_RADIUS
		drift += side_vector * cos(time * 0.07 + phase) * (FOG_DRIFT_RADIUS * 0.55)
		var breath := 1.0 + sin(time * 0.23 + phase) * FOG_BREATH_AMOUNT
		bank.position = fog_bank_origins[index] + drift
		bank.scale = fog_bank_base_scales[index] * Vector3(breath, 1.0 + (breath - 1.0) * 0.32, breath)
		bank.rotation_degrees.y = sin(time * 0.09 + phase) * 1.5



func _world_from_ground(point: Vector2, y_offset: float = 0.0) -> Vector3:
	return Vector3(point.x, _height_at(point) + y_offset, point.y)


func _height_at(point: Vector2) -> float:
	var rolling_height := _rolling_height_at(point)
	var road_info := _get_road_info(point)
	var progress := road_info.progress
	var road_height: float = _road_height(progress)
	var road_blend: float = 1.0 - clampf(road_info.distance / (_road_half_width(progress) + 1.15), 0.0, 1.0)
	road_blend = smoothstep(0.0, 1.0, road_blend)
	return lerp(rolling_height, road_height, road_blend)


func _rolling_height_at(point: Vector2) -> float:
	var ridge_height: float = 0.44 * terrain_noise.get_noise_2d(point.x, point.y)
	var detail: float = 0.12 * detail_noise.get_noise_2d(point.x, point.y)
	var seeded_features := 0.0
	for feature in terrain_features:
		var feature_point := Vector2(feature.x, feature.y)
		var feature_radius := feature.z
		var influence := 1.0 - clampf(point.distance_to(feature_point) / feature_radius, 0.0, 1.0)
		seeded_features += smoothstep(0.0, 1.0, influence) * feature.w

	var distant_rolloff := smoothstep(PLAYABLE_HALF_SIZE * 0.82, MAP_HALF_SIZE, maxf(absf(point.x), absf(point.y)))
	var outer_terrain: float = -0.28 + 0.18 * terrain_noise.get_noise_2d(point.x + 41.0, point.y - 17.0)
	return lerp(ridge_height + detail + seeded_features, outer_terrain, distant_rolloff * 0.62)


func _terrain_color_at(point: Vector2) -> Color:
	var height := _height_at(point)
	var slope := _get_local_slope(point)
	var lowland := Color(0.12, 0.27, 0.14)
	var meadow := Color(0.20, 0.39, 0.18)
	var high_grass := Color(0.30, 0.36, 0.20)
	var stone := Color(0.28, 0.28, 0.23)
	var color := lowland.lerp(meadow, smoothstep(-0.35, 0.7, height))
	color = color.lerp(high_grass, smoothstep(0.55, 1.25, height) * 0.52)
	color = color.lerp(stone, smoothstep(0.36, 0.86, slope))
	var edge_mist := _edge_atmosphere_amount(point)
	color = color.lerp(Color(0.045, 0.075, 0.065), edge_mist * 0.82)
	return color


func _road_color_at(point: Vector2) -> Color:
	var road_info := _get_road_info(point)
	var edge_ratio := clampf(road_info.distance / maxf(0.01, _road_half_width(road_info.progress)), 0.0, 1.0)
	var center := Color(0.36, 0.27, 0.17)
	var edge := Color(0.20, 0.16, 0.11)
	var color := center.lerp(edge, smoothstep(0.48, 1.0, edge_ratio))
	return color.lerp(Color(0.06, 0.055, 0.045), _edge_atmosphere_amount(point) * 0.75)


func _edge_atmosphere_amount(point: Vector2) -> float:
	var distance_to_edge: float = maxf(absf(point.x), absf(point.y))
	return smoothstep(PLAYABLE_HALF_SIZE + 7.0, MAP_HALF_SIZE - 1.5, distance_to_edge)


func _road_height(progress: float) -> float:
	if progress < 0.22:
		return lerp(-0.05, 0.72, smoothstep(0.0, 1.0, progress / 0.22))

	if progress < 0.47:
		return lerp(0.72, -0.22, smoothstep(0.0, 1.0, (progress - 0.22) / 0.25))

	if progress < 0.72:
		return lerp(-0.22, 1.46, smoothstep(0.0, 1.0, (progress - 0.47) / 0.25)) + 0.08 * sin(progress * TAU * 4.0)

	return lerp(1.46, 0.36, smoothstep(0.0, 1.0, (progress - 0.72) / 0.28))


func _road_half_width(progress: float) -> float:
	var base_width: float = lerp(0.72, 1.18, smoothstep(0.0, 1.0, progress))
	var choke_a: float = 0.34 * smoothstep(0.0, 1.0, 1.0 - absf(progress - 0.30) / 0.08)
	var choke_b: float = 0.28 * smoothstep(0.0, 1.0, 1.0 - absf(progress - 0.69) / 0.10)
	var plaza: float = 0.46 * smoothstep(0.0, 1.0, 1.0 - absf(progress - 0.52) / 0.12)
	return maxf(0.46, base_width - choke_a - choke_b + plaza)


func _is_road(point: Vector2) -> bool:
	var road_info := _get_road_info(point)
	return road_info.distance <= _road_half_width(road_info.progress)


func _get_road_info(point: Vector2) -> RoadInfo:
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

	return RoadInfo.new(closest_distance, closest_progress)


func _road_length() -> float:
	var length := 0.0
	for index in range(road_points.size() - 1):
		length += road_points[index].distance_to(road_points[index + 1])

	return length


func _find_terrain_hit(ray_origin: Vector3, ray_direction: Vector3) -> TerrainQuery:
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
			return TerrainQuery.new(true, Vector3(hit.x, _height_at(Vector2(hit.x, hit.z)), hit.z))

		previous_distance = distance
		previous_delta = current_delta

	return TerrainQuery.new()


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

	for occupied_position in occupied_positions:
		var tower_point := Vector2(occupied_position.x, occupied_position.z)
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
