class_name NegativeMaterials
extends RefCounted
## Negative variant — invert / edge FX + optional PNG layer blueprints.


const _VariantShaderCache := preload("res://scripts/ui/variant_shader_cache.gd")


const TIME_SCALE := 0.28
const EDGE_STRENGTH := 0.14
const ART_BRIGHTNESS := 1.0

## Legacy parallax multiplier used by PNG overlay blueprint (depth system preferred).
const OVERLAY_PARALLAX := 0.85


static func get_blueprints() -> Array:
	return [
		{
			"id": "invert",
			"type": "texture",
			"slot": "overlay",
			"animation": "static",
			"z_order": 0,
			"parallax_strength": OVERLAY_PARALLAX,
		},
		{
			"id": "scanline",
			"type": "texture",
			"slot": "scanline",
			"animation": "scroll",
			"z_order": 10,
			"scroll_speed": 0.0,
			"scroll_direction": Vector2(0.0, 1.0),
		},
		{
			"id": "distortion",
			"type": "texture",
			"slot": "distortion",
			"animation": "pulse",
			"z_order": 20,
			"opacity": 0.5,
			"pulse_speed": 3.0,
		},
	]


static func create_invert_material() -> ShaderMaterial:
	var material := _VariantShaderCache.create("negative_invert")
	if material:
		material.set_shader_parameter("brightness", ART_BRIGHTNESS)
		material.set_shader_parameter("time_scale", TIME_SCALE)
	return material


static func create_edge_material() -> ShaderMaterial:
	var material := _VariantShaderCache.create("negative_edge")
	if material:
		material.set_shader_parameter("edge_strength", EDGE_STRENGTH)
		material.set_shader_parameter("time_scale", TIME_SCALE)
	return material


static func create_named_shader_material(shader_key: String) -> ShaderMaterial:
	match shader_key:
		"negative_invert":
			return create_invert_material()
		"negative_edge":
			return create_edge_material()
		_:
			return null
