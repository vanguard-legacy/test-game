class_name DefenseTowerModifiers
extends RefCounted

const RewardDefinition := preload("res://scripts/reward_definition.gd")

# Run-wide tower modifiers earned from reward drafts. Towers receive a copy so
# existing and future towers share the same upgrade math.

var damage_multiplier: float = 1.0
var range_bonus: float = 0.0
var fire_rate_multiplier: float = 1.0


func duplicate_modifiers():
	var copy = get_script().new()
	copy.damage_multiplier = damage_multiplier
	copy.range_bonus = range_bonus
	copy.fire_rate_multiplier = fire_rate_multiplier
	return copy


func apply_reward(reward: RewardDefinition) -> void:
	damage_multiplier += reward.damage_multiplier_bonus
	range_bonus += reward.range_bonus
	fire_rate_multiplier *= reward.fire_rate_multiplier
