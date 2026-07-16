class_name DiamondMaterials
extends RefCounted
## Diamond variant — confetti / starfoil laminate (tuning, blueprints, factories).


const _VariantShaderCache := preload("res://scripts/ui/variant_shader_cache.gd")


# ---------------------------------------------------------------------------
# Tuning (production) — plate → specular → dispersion → sparkle
# ---------------------------------------------------------------------------

const PLATE_STRENGTH := 0.42
const FRESNEL_STRENGTH := 0.08
const CLARITY_VEIL := 0.0
const SEAM_STRENGTH := 0.0
const PLATE_IRIDESCENCE := 0.92

const REFLECTION_STRENGTH := 0.88
const BODY_STRENGTH := 0.28
const RIM_STRENGTH := 0.06
const SPECULAR_IRIDESCENCE := 1.0
const SPECULAR_WHITE := 1.15
const FIRE_STRENGTH := 0.55
const LIGHT_DIR := Vector2(0.35, -0.75)
const LIGHT_TIME_SCALE := 0.04

const WARP_STRENGTH := 0.0
const CLARITY := 1.0
const COOL_LIFT := 0.0
const EDGE_SHARPEN := 0.0

const DISPERSION_STRENGTH := 0.72
const DISPERSION_PEAK_GATE := 0.48
const DISPERSION_SATURATION := 1.35
const DISPERSION_TIME_SCALE := 0.035

const SPARKLE_STRENGTH := 0.42
const SPARKLE_TIME_SCALE := 0.22
const SPARKLE_SIZE := 0.007


static func get_blueprints() -> Array:
	return [
		{
			"id": "crystal_plate",
			"type": "shader",
			"shader_key": "diamond_facets",
			"animation": "static",
			"z_order": 0,
			"depth": 0.05,
			"material_response": 0.60,
			"opacity": 1.0,
		},
		{
			"id": "facet_specular",
			"type": "shader",
			"shader_key": "diamond_reflection",
			"animation": "static",
			"z_order": 10,
			"depth": 0.12,
			"material_response": 0.90,
			"opacity": 1.0,
		},
		{
			"id": "dispersion_peaks",
			"type": "shader",
			"shader_key": "diamond_dispersion",
			"animation": "static",
			"z_order": 20,
			"depth": 0.16,
			"material_response": 0.70,
			"opacity": 1.0,
		},
		{
			"id": "optical_sparkle",
			"type": "shader",
			"shader_key": "diamond_sparkle",
			"animation": "static",
			"z_order": 30,
			"depth": 0.22,
			"material_response": 0.40,
			"opacity": 1.0,
		},
	]


static func create_facets_material() -> ShaderMaterial:
	var material := _VariantShaderCache.create("diamond_facets")
	if material:
		material.set_shader_parameter("plate_strength", PLATE_STRENGTH)
		material.set_shader_parameter("fresnel_strength", FRESNEL_STRENGTH)
		material.set_shader_parameter("clarity_veil", CLARITY_VEIL)
		material.set_shader_parameter("seam_strength", SEAM_STRENGTH)
		material.set_shader_parameter("iridescence", PLATE_IRIDESCENCE)
		material.set_shader_parameter("time_scale", LIGHT_TIME_SCALE)
		material.set_shader_parameter("light_dir", LIGHT_DIR)
	return material


static func create_reflection_material() -> ShaderMaterial:
	var material := _VariantShaderCache.create("diamond_reflection")
	if material:
		material.set_shader_parameter("reflection_strength", REFLECTION_STRENGTH)
		material.set_shader_parameter("body_strength", BODY_STRENGTH)
		material.set_shader_parameter("rim_strength", RIM_STRENGTH)
		material.set_shader_parameter("iridescence", SPECULAR_IRIDESCENCE)
		material.set_shader_parameter("specular_white", SPECULAR_WHITE)
		material.set_shader_parameter("fire_strength", FIRE_STRENGTH)
		material.set_shader_parameter("time_scale", LIGHT_TIME_SCALE)
		material.set_shader_parameter("light_dir", LIGHT_DIR)
	return material


static func create_refraction_material() -> ShaderMaterial:
	## Unused in V1 look (no art warp). Kept for API compatibility.
	var material := _VariantShaderCache.create("diamond_refraction")
	if material:
		material.set_shader_parameter("warp_strength", WARP_STRENGTH)
		material.set_shader_parameter("clarity", CLARITY)
		material.set_shader_parameter("cool_lift", COOL_LIFT)
		material.set_shader_parameter("edge_sharpen", EDGE_SHARPEN)
	return material


static func create_dispersion_material() -> ShaderMaterial:
	var material := _VariantShaderCache.create("diamond_dispersion")
	if material:
		material.set_shader_parameter("dispersion_strength", DISPERSION_STRENGTH)
		material.set_shader_parameter("peak_gate", DISPERSION_PEAK_GATE)
		material.set_shader_parameter("saturation", DISPERSION_SATURATION)
		material.set_shader_parameter("time_scale", DISPERSION_TIME_SCALE)
		material.set_shader_parameter("light_dir", LIGHT_DIR)
	return material


static func create_sparkle_material() -> ShaderMaterial:
	var material := _VariantShaderCache.create("diamond_sparkle")
	if material:
		material.set_shader_parameter("sparkle_strength", SPARKLE_STRENGTH)
		material.set_shader_parameter("time_scale", SPARKLE_TIME_SCALE)
		material.set_shader_parameter("sparkle_size", SPARKLE_SIZE)
		material.set_shader_parameter("light_dir", LIGHT_DIR)
	return material


static func create_named_shader_material(shader_key: String) -> ShaderMaterial:
	match shader_key:
		"diamond_facets":
			return create_facets_material()
		"diamond_reflection", "diamond_glow":
			return create_reflection_material()
		"diamond_dispersion":
			return create_dispersion_material()
		"diamond_sparkle":
			return create_sparkle_material()
		"diamond_refraction":
			return create_refraction_material()
		_:
			return null
