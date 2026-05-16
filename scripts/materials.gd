class_name PrototypeMaterials
extends RefCounted


static func standard(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.75
	return material


static func transparent(color: Color) -> StandardMaterial3D:
	var material := standard(color)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material


static func unshaded(color: Color) -> StandardMaterial3D:
	var material := standard(color)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material
