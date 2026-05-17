extends Node3D
class_name PrototypeTower

const GameBalance := preload("res://scripts/game_balance.gd")

var targets: Array[PrototypeEnemy] = []
var cooldown: float = 0.0
var tower_id: String = GameBalance.TOWER_GWIZARD
var tower_type_name: String = "G'wizard Tower"
var level: int = 1
var base_range: float = GameBalance.TOWER_BASE_RANGE
var base_damage: float = GameBalance.TOWER_BASE_DAMAGE
var base_fire_rate: float = GameBalance.TOWER_BASE_FIRE_RATE
var attack_range: float = GameBalance.TOWER_BASE_RANGE
var damage: float = GameBalance.TOWER_BASE_DAMAGE
var fire_rate: float = GameBalance.TOWER_BASE_FIRE_RATE
var effect: String = GameBalance.TOWER_EFFECT_BOLT
var beam_color: Color = Color(0.85, 0.95, 1.0)
var slow_multiplier: float = 1.0
var slow_duration: float = 0.0
var splash_radius: float = 0.0
var global_modifiers: Dictionary = GameBalance.get_default_tower_modifiers()
var beam_visible_timer: float = 0.0
var beam_mesh := ImmediateMesh.new()

@onready var focus_crystal: MeshInstance3D = $FocusCrystal
@onready var tower_range: MeshInstance3D = $TowerRange
@onready var roof: MeshInstance3D = $Roof
@onready var banner: MeshInstance3D = $Banner
@onready var beam: MeshInstance3D = $AttackBeam


func _process(delta: float) -> void:
	_update_beam(delta)

	cooldown -= delta
	if cooldown > 0.0:
		return

	var target := _find_target()
	if target == null:
		return

	var beam_end := target.global_position + Vector3(0.0, 0.35, 0.0)
	_attack(target)
	_show_beam(global_position + Vector3(0.0, 1.0, 0.0), beam_end)
	cooldown = fire_rate


func setup(new_tower_id: String, modifiers: Dictionary) -> void:
	tower_id = new_tower_id
	global_modifiers = modifiers.duplicate(true)
	_apply_tower_config(GameBalance.get_tower_config(tower_id))


func set_targets(new_targets: Array[PrototypeEnemy]) -> void:
	targets = new_targets


func apply_global_modifiers(modifiers: Dictionary) -> void:
	global_modifiers = modifiers.duplicate(true)
	_recalculate_stats()
	_update_upgrade_visuals()


func _find_target() -> PrototypeEnemy:
	var closest: PrototypeEnemy = null
	var closest_distance := attack_range

	for target in targets:
		if not is_instance_valid(target):
			continue

		var distance := global_position.distance_to(target.global_position)
		if distance <= closest_distance:
			closest_distance = distance
			closest = target

	return closest


func can_upgrade() -> bool:
	return level < GameBalance.TOWER_MAX_LEVEL


func get_upgrade_cost() -> int:
	if not can_upgrade():
		return 0

	return GameBalance.get_tower_upgrade_cost(level)


func upgrade() -> void:
	if not can_upgrade():
		return

	level += 1
	_recalculate_stats()
	_update_upgrade_visuals()


func get_display_name() -> String:
	return "%s Lv. %d" % [tower_type_name, level]


func get_upgrade_summary() -> String:
	if not can_upgrade():
		return "Fully upgraded"

	return "Upgrade: %d gold" % get_upgrade_cost()


func get_hover_description() -> String:
	var effect_summary := "Single-target magic."
	match effect:
		GameBalance.TOWER_EFFECT_FROST:
			effect_summary = "Slows enemies while dealing steady damage."
		GameBalance.TOWER_EFFECT_SPLASH:
			effect_summary = "Deals splash damage around the target."

	return "Damage %.1f  Range %.1f\nFires every %.2fs\n%s\n%s" % [damage, attack_range, fire_rate, effect_summary, get_upgrade_summary()]


func _ready() -> void:
	_apply_tower_config(GameBalance.get_tower_config(tower_id))
	_update_upgrade_visuals()


func _attack(target: PrototypeEnemy) -> void:
	match effect:
		GameBalance.TOWER_EFFECT_FROST:
			target.take_damage(damage)
			if is_instance_valid(target):
				target.apply_slow(slow_multiplier, slow_duration)
		GameBalance.TOWER_EFFECT_SPLASH:
			var splash_center := target.global_position
			target.take_damage(damage)
			for nearby_target in targets.duplicate():
				if not is_instance_valid(nearby_target) or nearby_target == target:
					continue

				if nearby_target.global_position.distance_to(splash_center) <= splash_radius:
					nearby_target.take_damage(damage * 0.55)
		_:
			target.take_damage(damage)


func _apply_tower_config(tower_config: Dictionary) -> void:
	tower_type_name = str(tower_config.get("name", "G'wizard Tower"))
	base_damage = float(tower_config.get("damage", GameBalance.TOWER_BASE_DAMAGE))
	base_range = float(tower_config.get("range", GameBalance.TOWER_BASE_RANGE))
	base_fire_rate = float(tower_config.get("fire_rate", GameBalance.TOWER_BASE_FIRE_RATE))
	effect = str(tower_config.get("effect", GameBalance.TOWER_EFFECT_BOLT))
	beam_color = tower_config.get("beam_color", Color(0.85, 0.95, 1.0))
	slow_multiplier = float(tower_config.get("slow_multiplier", 1.0))
	slow_duration = float(tower_config.get("slow_duration", 0.0))
	splash_radius = float(tower_config.get("splash_radius", 0.0))
	roof.material_override = PrototypeMaterials.standard(tower_config.get("roof_color", Color(0.35, 0.13, 0.45)))
	banner.material_override = PrototypeMaterials.standard(tower_config.get("banner_color", Color(0.88, 0.72, 0.28)))
	focus_crystal.material_override = PrototypeMaterials.transparent(tower_config.get("crystal_color", Color(0.38, 0.86, 1.0)))
	beam.material_override = PrototypeMaterials.unshaded(beam_color)
	_recalculate_stats()
	_update_upgrade_visuals()


func _recalculate_stats() -> void:
	var damage_multiplier := float(global_modifiers.get("damage_multiplier", 1.0))
	var range_bonus := float(global_modifiers.get("range_bonus", 0.0))
	var fire_rate_multiplier := float(global_modifiers.get("fire_rate_multiplier", 1.0))
	damage = (base_damage + float(level - 1) * GameBalance.TOWER_DAMAGE_STEP) * damage_multiplier
	attack_range = base_range + float(level - 1) * GameBalance.TOWER_RANGE_STEP + range_bonus
	fire_rate = maxf(GameBalance.TOWER_MIN_FIRE_RATE, (base_fire_rate - float(level - 1) * GameBalance.TOWER_FIRE_RATE_STEP) * fire_rate_multiplier)


func _update_upgrade_visuals() -> void:
	var crystal_scale := 0.85 + float(level - 1) * 0.18
	focus_crystal.scale = Vector3(crystal_scale, 1.3 + float(level - 1) * 0.18, crystal_scale)
	var mesh := tower_range.mesh as CylinderMesh
	if mesh != null:
		mesh.top_radius = attack_range
		mesh.bottom_radius = attack_range


func _show_beam(from_position: Vector3, to_position: Vector3) -> void:
	beam_mesh.clear_surfaces()
	beam_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	beam_mesh.surface_add_vertex(to_local(from_position))
	beam_mesh.surface_add_vertex(to_local(to_position))
	beam_mesh.surface_end()
	beam.mesh = beam_mesh
	beam.visible = true
	beam_visible_timer = 0.08


func _update_beam(delta: float) -> void:
	if beam_visible_timer <= 0.0:
		return

	beam_visible_timer -= delta
	if beam_visible_timer <= 0.0:
		beam.visible = false
