extends Node3D
class_name DefenseTower

const GameBalance := preload("res://scripts/game_balance.gd")
const TowerDefinition := preload("res://scripts/tower_definition.gd")
const TowerModifiers := preload("res://scripts/tower_modifiers.gd")
const TowerTerrainBonus := preload("res://scripts/tower_terrain_bonus.gd")
const Enemy := preload("res://scripts/enemy.gd")
const Materials := preload("res://scripts/materials.gd")
const TowerProjectile := preload("res://scripts/tower_projectile.gd")

# Tower combat actor. Definitions provide base identity and visuals; local level
# and run-wide modifiers combine into the live combat stats recalculated here.

var targets: Array[Enemy] = []
var cooldown: float = 0.0
var tower_id: String = GameBalance.TOWER_GWIZARD
var tower_type_name: String = "G'wizard Tower"
var build_cost: int = GameBalance.TOWER_COST
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
var global_modifiers: TowerModifiers = GameBalance.get_default_tower_modifiers()
var terrain_bonus: TowerTerrainBonus = GameBalance.get_tower_terrain_bonus(0.0)
var is_selected: bool = false
var projectile_rng := RandomNumberGenerator.new()
var range_material := Materials.transparent(Color(0.55, 0.80, 1.0, 0.12))
var selected_range_material := Materials.transparent(Color(1.0, 0.84, 0.28, 0.28))

@onready var focus_crystal: MeshInstance3D = $FocusCrystal
@onready var tower_range: MeshInstance3D = $TowerRange
@onready var roof: MeshInstance3D = $Roof
@onready var banner: MeshInstance3D = $Banner
@onready var beam: MeshInstance3D = $AttackBeam


func _process(delta: float) -> void:
	cooldown -= delta
	if cooldown > 0.0:
		return

	var target := _find_target()
	if target == null:
		return

	var beam_end := target.global_position + Vector3(0.0, 0.35, 0.0)
	var attack_origin := global_position + Vector3(0.0, 1.22, 0.0)
	_show_projectile(attack_origin, beam_end, target)
	cooldown = fire_rate


func setup(new_tower_id: String, modifiers: TowerModifiers) -> void:
	tower_id = new_tower_id
	build_cost = GameBalance.get_tower_cost(tower_id)
	global_modifiers = modifiers.duplicate_modifiers()
	_apply_tower_definition(GameBalance.get_tower_definition(tower_id))


func set_targets(new_targets: Array[Enemy]) -> void:
	targets = new_targets


func apply_global_modifiers(modifiers: TowerModifiers) -> void:
	global_modifiers = modifiers.duplicate_modifiers()
	_recalculate_stats()
	_update_upgrade_visuals()


func apply_terrain_bonus(new_terrain_bonus: TowerTerrainBonus) -> void:
	terrain_bonus = new_terrain_bonus
	_recalculate_stats()
	_update_upgrade_visuals()


func set_selected(new_is_selected: bool) -> void:
	is_selected = new_is_selected
	tower_range.visible = is_selected
	tower_range.material_override = selected_range_material if is_selected else range_material


func _find_target() -> Enemy:
	var closest: Enemy = null
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


func get_sell_value() -> int:
	return int(floor(float(build_cost) * 0.5))


func get_hover_description() -> String:
	return "Damage %.1f  Range %.1f\nFires every %.2fs\n%s\n%s\n%s\nSell refund: %d gold" % [damage, attack_range, fire_rate, _get_effect_summary(), terrain_bonus.get_summary(), get_upgrade_summary(), get_sell_value()]


func _ready() -> void:
	projectile_rng.randomize()
	tower_range.material_override = range_material
	tower_range.visible = false
	beam.visible = false
	_apply_tower_definition(GameBalance.get_tower_definition(tower_id))
	_update_upgrade_visuals()


func _attack(target: Enemy) -> void:
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


func _get_effect_summary() -> String:
	match effect:
		GameBalance.TOWER_EFFECT_FROST:
			return "Slows enemies while dealing steady damage."
		GameBalance.TOWER_EFFECT_SPLASH:
			return "Deals splash damage around the target."
		_:
			return "Single-target magic."


func _apply_tower_definition(definition: TowerDefinition) -> void:
	tower_type_name = definition.display_name
	base_damage = definition.base_damage
	base_range = definition.base_range
	base_fire_rate = definition.base_fire_rate
	effect = definition.effect
	beam_color = definition.beam_color
	slow_multiplier = definition.slow_multiplier
	slow_duration = definition.slow_duration
	splash_radius = definition.splash_radius
	roof.material_override = Materials.standard(definition.roof_color)
	banner.material_override = Materials.standard(definition.banner_color)
	focus_crystal.material_override = Materials.transparent(definition.crystal_color)
	beam.material_override = Materials.unshaded(beam_color)
	_recalculate_stats()
	_update_upgrade_visuals()


func _recalculate_stats() -> void:
	damage = (base_damage + float(level - 1) * GameBalance.TOWER_DAMAGE_STEP) * global_modifiers.damage_multiplier * terrain_bonus.damage_multiplier
	attack_range = base_range + float(level - 1) * GameBalance.TOWER_RANGE_STEP + global_modifiers.range_bonus + terrain_bonus.range_bonus
	fire_rate = maxf(GameBalance.TOWER_MIN_FIRE_RATE, (base_fire_rate - float(level - 1) * GameBalance.TOWER_FIRE_RATE_STEP) * global_modifiers.fire_rate_multiplier)


func _update_upgrade_visuals() -> void:
	var crystal_scale := 0.85 + float(level - 1) * 0.18
	focus_crystal.scale = Vector3(crystal_scale, 1.3 + float(level - 1) * 0.18, crystal_scale)
	var mesh := tower_range.mesh as CylinderMesh
	if mesh != null:
		mesh.top_radius = attack_range
		mesh.bottom_radius = attack_range


func _show_projectile(from_position: Vector3, to_position: Vector3, target: Enemy) -> void:
	var projectile := TowerProjectile.new()
	var projectile_parent := get_tree().current_scene
	if projectile_parent == null:
		projectile_parent = get_parent()

	projectile_parent.add_child(projectile)
	projectile.impact.connect(_on_projectile_impact.bind(target))
	projectile.setup(from_position, to_position, _get_projectile_color())


func _on_projectile_impact(target: Variant) -> void:
	if not is_instance_valid(target):
		return

	var enemy := target as Enemy
	if enemy == null:
		return

	_attack(enemy)


func _get_projectile_color() -> Color:
	var hue_shift := projectile_rng.randf_range(-0.08, 0.08)
	var saturation := projectile_rng.randf_range(0.72, 1.0)
	var value := projectile_rng.randf_range(0.92, 1.18)
	var color := Color.from_hsv(fposmod(beam_color.h + hue_shift, 1.0), saturation, value)
	color.a = 1.0
	return color
