class_name PrototypeMaterials
extends RefCounted


const TERRAIN_SHADER_CODE: String = """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

varying vec3 world_position;

float hash(vec2 point) {
	return fract(sin(dot(point, vec2(127.1, 311.7))) * 43758.5453123);
}

float value_noise(vec2 point) {
	vec2 cell = floor(point);
	vec2 local = fract(point);
	vec2 curve = local * local * (3.0 - 2.0 * local);
	float a = hash(cell);
	float b = hash(cell + vec2(1.0, 0.0));
	float c = hash(cell + vec2(0.0, 1.0));
	float d = hash(cell + vec2(1.0, 1.0));
	return mix(mix(a, b, curve.x), mix(c, d, curve.x), curve.y);
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float large_grain = value_noise(world_position.xz * 1.1);
	float fine_grain = value_noise(world_position.xz * 4.5);
	float altitude = smoothstep(0.75, 1.75, world_position.y);
	float lowland_shadow = 1.0 - smoothstep(-0.45, 0.35, world_position.y);
	vec3 color = COLOR.rgb;
	color = mix(color, vec3(0.35, 0.36, 0.29), altitude * 0.42);
	color = mix(color, vec3(0.12, 0.20, 0.13), lowland_shadow * 0.20);
	color *= 0.70 + large_grain * 0.28 + fine_grain * 0.10;
	ALBEDO = color;
	ROUGHNESS = 0.92;
}
"""

const ROAD_SHADER_CODE: String = """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

varying vec3 world_position;

float hash(vec2 point) {
	return fract(sin(dot(point, vec2(269.5, 183.3))) * 23819.171);
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float stone = hash(floor(world_position.xz * 2.4));
	float rut = sin((world_position.x + world_position.z) * 5.0) * 0.5 + 0.5;
	vec3 color = COLOR.rgb * (0.62 + stone * 0.20);
	color = mix(color, vec3(0.22, 0.17, 0.11), rut * 0.22);
	ALBEDO = color;
	ROUGHNESS = 0.96;
}
"""


static func standard(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.75
	material.metallic_specular = 0.25
	return material


static func transparent(color: Color) -> StandardMaterial3D:
	var material := standard(color)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material


static func unshaded(color: Color) -> StandardMaterial3D:
	var material := standard(color)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material


static func vertex_colored() -> StandardMaterial3D:
	var material := standard(Color.WHITE)
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.92
	return material


static func terrain() -> Material:
	if DisplayServer.get_name() == "headless":
		return vertex_colored()

	var shader := Shader.new()
	shader.code = TERRAIN_SHADER_CODE
	var material := ShaderMaterial.new()
	material.shader = shader
	return material


static func road() -> Material:
	if DisplayServer.get_name() == "headless":
		return vertex_colored()

	var shader := Shader.new()
	shader.code = ROAD_SHADER_CODE
	var material := ShaderMaterial.new()
	material.shader = shader
	return material
