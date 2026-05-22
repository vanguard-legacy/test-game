extends Label3D
class_name DefenseDamageNumber

const FLOAT_SPEED: float = 0.82
const LIFETIME: float = 0.72
const START_SCALE: Vector3 = Vector3.ONE * 0.014

var age: float = 0.0


func setup(amount: float, color: Color) -> void:
	text = "-%.1f" % amount
	modulate = color
	outline_modulate = Color(0.02, 0.015, 0.01, 0.95)
	font_size = 52
	outline_size = 8
	scale = START_SCALE
	position = Vector3(randf_range(-0.12, 0.12), 1.15, randf_range(-0.06, 0.06))


func _process(delta: float) -> void:
	age += delta
	position.y += FLOAT_SPEED * delta
	var life_ratio := clampf(age / LIFETIME, 0.0, 1.0)
	modulate.a = 1.0 - life_ratio
	scale = START_SCALE * (1.0 + life_ratio * 0.28)
	if age >= LIFETIME:
		queue_free()
