extends Node3D

const STARTING_LIVES: int = 10
const ENEMY_BASE_SPEED: float = 1.75
const TOWER_RANGE: float = 5.5
const TOWER_DAMAGE: float = 1.0
const TOWER_FIRE_RATE: float = 0.45

var path_points: Array[Vector3] = [
	Vector3(-6.0, 0.35, -2.0),
	Vector3(-2.0, 0.35, -2.0),
	Vector3(-1.0, 1.35, 0.0),
	Vector3(2.0, 1.35, 0.0),
	Vector3(4.0, 0.35, 2.0),
	Vector3(6.0, 0.35, 2.0),
]

var enemies: Array[Dictionary] = []
var tower_position: Vector3 = Vector3(1.2, 1.55, -0.2)
var tower_cooldown: float = 0.0
var spawn_cooldown: float = 0.0
var wave_break: float = 1.5
var enemies_to_spawn: int = 0
var wave: int = 0
var lives: int = STARTING_LIVES
var score: int = 0
var game_over: bool = false

var status_label: Label
var message_label: Label


func _ready() -> void:
	_build_world()
	_build_ui()
	_start_next_wave()
	_update_ui()


func _process(delta: float) -> void:
	if game_over:
		return

	_spawn_wave_enemies(delta)
	_move_enemies(delta)
	_update_tower(delta)

	if enemies_to_spawn == 0 and enemies.is_empty():
		wave_break -= delta
		if wave_break <= 0.0:
			_start_next_wave()

	_update_ui()


func _unhandled_input(event: InputEvent) -> void:
	if game_over and event.is_action_pressed("ui_accept"):
		_restart_game()


func _build_world() -> void:
	var camera := Camera3D.new()
	camera.name = "Camera"
	camera.position = Vector3(0.0, 9.0, 9.0)
	camera.rotation_degrees = Vector3(-52.0, 0.0, 0.0)
	add_child(camera)
	camera.current = true

	var light := DirectionalLight3D.new()
	light.name = "Sun"
	light.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
	light.light_energy = 2.4
	add_child(light)

	_add_box("Grass", Vector3(0.0, -0.15, 0.0), Vector3(14.0, 0.3, 10.0), Color(0.30, 0.54, 0.28))
	_add_box("HighGround", Vector3(1.0, 0.55, 0.0), Vector3(4.5, 1.1, 4.0), Color(0.33, 0.46, 0.30))
	_add_box("LowNarrowRoad", Vector3(-4.0, 0.04, -2.0), Vector3(4.6, 0.08, 1.0), Color(0.55, 0.43, 0.27))
	_add_box("HighRidgeRoad", Vector3(0.6, 1.14, 0.0), Vector3(4.4, 0.08, 1.2), Color(0.62, 0.49, 0.30))
	_add_box("WideExitRoad", Vector3(5.0, 0.04, 2.0), Vector3(3.0, 0.08, 2.0), Color(0.58, 0.45, 0.28))
	_add_box("ExitGate", Vector3(6.35, 0.8, 2.0), Vector3(0.25, 1.6, 2.2), Color(0.22, 0.20, 0.18))

	_add_tower()
	_add_range_ring()


func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "Hud"
	add_child(canvas)

	var panel := PanelContainer.new()
	panel.position = Vector2(16.0, 16.0)
	panel.custom_minimum_size = Vector2(250.0, 0.0)
	canvas.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	margin.add_child(stack)

	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 18)
	stack.add_child(status_label)

	message_label = Label.new()
	message_label.add_theme_font_size_override("font_size", 14)
	message_label.text = "One tower. One road. Hold the exit."
	stack.add_child(message_label)


func _add_tower() -> void:
	var tower := Node3D.new()
	tower.name = "GwizardTower"
	tower.position = tower_position
	add_child(tower)

	var base := MeshInstance3D.new()
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = 0.35
	base_mesh.bottom_radius = 0.45
	base_mesh.height = 1.2
	base.mesh = base_mesh
	base.material_override = _make_material(Color(0.48, 0.48, 0.52))
	tower.add_child(base)

	var roof := MeshInstance3D.new()
	var roof_mesh := CylinderMesh.new()
	roof_mesh.top_radius = 0.0
	roof_mesh.bottom_radius = 0.55
	roof_mesh.height = 0.65
	roof.position = Vector3(0.0, 0.9, 0.0)
	roof.mesh = roof_mesh
	roof.material_override = _make_material(Color(0.38, 0.12, 0.45))
	tower.add_child(roof)


func _add_range_ring() -> void:
	var ring := MeshInstance3D.new()
	ring.name = "TowerRange"
	ring.position = Vector3(tower_position.x, 1.18, tower_position.z)

	var mesh := CylinderMesh.new()
	mesh.top_radius = TOWER_RANGE
	mesh.bottom_radius = TOWER_RANGE
	mesh.height = 0.02
	ring.mesh = mesh

	var material := _make_material(Color(0.65, 0.85, 1.0, 0.12))
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override = material
	add_child(ring)


func _add_box(node_name: String, box_position: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	mesh_instance.position = box_position

	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.material_override = _make_material(color)
	add_child(mesh_instance)
	return mesh_instance


func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.75
	return material


func _start_next_wave() -> void:
	wave += 1
	enemies_to_spawn = 4 + wave
	spawn_cooldown = 0.2
	wave_break = 2.0
	message_label.text = "Wave %d: the gobbelins approach." % wave


func _spawn_wave_enemies(delta: float) -> void:
	if enemies_to_spawn <= 0:
		return

	spawn_cooldown -= delta
	if spawn_cooldown > 0.0:
		return

	_spawn_enemy()
	enemies_to_spawn -= 1
	spawn_cooldown = max(0.35, 1.0 - float(wave) * 0.05)


func _spawn_enemy() -> void:
	var enemy := Node3D.new()
	enemy.name = "Gobbelin"
	enemy.position = path_points[0]
	add_child(enemy)

	var body := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.22
	mesh.height = 0.8
	body.mesh = mesh
	body.material_override = _make_material(Color(0.30, 0.72, 0.25))
	enemy.add_child(body)

	var hat := MeshInstance3D.new()
	var hat_mesh := CylinderMesh.new()
	hat_mesh.top_radius = 0.0
	hat_mesh.bottom_radius = 0.23
	hat_mesh.height = 0.35
	hat.position = Vector3(0.0, 0.55, 0.0)
	hat.mesh = hat_mesh
	hat.material_override = _make_material(Color(0.20, 0.15, 0.12))
	enemy.add_child(hat)

	enemies.append({
		"node": enemy,
		"health": 2.0 + float(wave) * 0.35,
		"target_index": 1,
	})


func _move_enemies(delta: float) -> void:
	for index in range(enemies.size() - 1, -1, -1):
		var enemy_data: Dictionary = enemies[index]
		var enemy := enemy_data["node"] as Node3D
		var target_index: int = enemy_data["target_index"]
		var target := path_points[target_index]
		var to_target := target - enemy.position
		var distance := to_target.length()
		var speed := ENEMY_BASE_SPEED + float(wave) * 0.08
		var step := speed * delta

		if distance <= step:
			enemy.position = target
			target_index += 1
			if target_index >= path_points.size():
				lives -= 1
				enemy.queue_free()
				enemies.remove_at(index)
				message_label.text = "An enemy reached the exit."
				if lives <= 0:
					_game_over()
				continue

			enemy_data["target_index"] = target_index
			enemies[index] = enemy_data
		else:
			enemy.position += to_target.normalized() * step


func _update_tower(delta: float) -> void:
	tower_cooldown -= delta
	if tower_cooldown > 0.0:
		return

	var target_index := _find_tower_target()
	if target_index == -1:
		return

	var enemy_data: Dictionary = enemies[target_index]
	var enemy := enemy_data["node"] as Node3D
	enemy_data["health"] = float(enemy_data["health"]) - TOWER_DAMAGE
	_show_beam(tower_position + Vector3(0.0, 1.0, 0.0), enemy.position + Vector3(0.0, 0.35, 0.0))

	if float(enemy_data["health"]) <= 0.0:
		score += 10
		enemy.queue_free()
		enemies.remove_at(target_index)
	else:
		enemies[target_index] = enemy_data

	tower_cooldown = TOWER_FIRE_RATE


func _find_tower_target() -> int:
	var closest_index := -1
	var closest_distance := TOWER_RANGE

	for index in range(enemies.size()):
		var enemy_data: Dictionary = enemies[index]
		var enemy := enemy_data["node"] as Node3D
		var distance := tower_position.distance_to(enemy.position)
		if distance <= closest_distance:
			closest_distance = distance
			closest_index = index

	return closest_index


func _show_beam(from_position: Vector3, to_position: Vector3) -> void:
	var beam := MeshInstance3D.new()
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh.surface_add_vertex(from_position)
	mesh.surface_add_vertex(to_position)
	mesh.surface_end()
	beam.mesh = mesh

	var material := _make_material(Color(0.85, 0.95, 1.0))
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beam.material_override = material
	add_child(beam)

	get_tree().create_timer(0.08).timeout.connect(Callable(beam, "queue_free"))


func _game_over() -> void:
	game_over = true
	message_label.text = "Defeat. Press Enter or Space to try again."
	_update_ui()


func _restart_game() -> void:
	for enemy_data in enemies:
		var enemy := enemy_data["node"] as Node3D
		enemy.queue_free()

	enemies.clear()
	tower_cooldown = 0.0
	spawn_cooldown = 0.0
	wave_break = 1.5
	enemies_to_spawn = 0
	wave = 0
	lives = STARTING_LIVES
	score = 0
	game_over = false
	_start_next_wave()
	_update_ui()


func _update_ui() -> void:
	var incoming := enemies.size() + enemies_to_spawn
	status_label.text = "Wave: %d\nLives: %d\nScore: %d\nIncoming: %d" % [wave, lives, score, incoming]
