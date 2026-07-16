class_name FoilMaterials
extends RefCounted
## Foil variant — laminated holographic sheet (tuning, blueprints, factories).


const _VariantShaderCache := preload("res://scripts/ui/variant_shader_cache.gd")


# ---------------------------------------------------------------------------
# Tuning (production) — grain → rainbow → shine → glitter → sparkles
# ---------------------------------------------------------------------------

const GRAIN_OPACITY := 0.05
const GRAIN_NOISE_SCALE := 1.15
const GRAIN_CONTRAST := 1.55

const STRENGTH := 0.48
const RAINBOW_STRENGTH := 0.50
const EDGE_FRESNEL := 0.13
const RAINBOW_TIME_SCALE := 0.04
const NOISE_SCALE := 28.0
const BEAM_COUNT := 3.2
const ETCH_DENSITY := 48.0
const RADIAL_STRENGTH := 0.24
const BEAM_ANGLE := Vector2(0.78, -0.62)

const SHINE_OPACITY := 0.34
const SHINE_SPEED := 8.0
const SHINE_WIDTH := 0.24
const SHINE_FALLOFF := 0.14
const SHINE_ANGLE := Vector2(0.78, -0.62)
const SHINE_PRISM := 0.95

const GLITTER_OPACITY := 0.065
const GLITTER_DENSITY := 0.968
const GLITTER_DRIFT_SPEED := 0.35
const GLITTER_SCALE := 1.12
const GLITTER_BRIGHTNESS := 0.42

const SPARKLE_OPACITY := 0.05
const SPARKLE_DENSITY := 0.985
const SPARKLE_PULSE_SPEED := 0.30
const SPARKLE_SIZE := 0.92
const SPARKLE_BRIGHTNESS := 0.44


static func get_blueprints() -> Array:
	return [
		{
			"id": "micro_grain",
			"type": "texture",
			"procedural": "foil_grain",
			"animation": "static",
			"z_order": 0,
			"depth": 0.02,
			"material_response": 0.5,
			"opacity": 1.0,
			"blend_mode": "mul",
		},
		{
			"id": "foil_rainbow",
			"type": "shader",
			"shader_key": "foil_rainbow",
			"animation": "static",
			"z_order": 10,
			"depth": 0.08,
			"material_response": 0.9,
			"opacity": 1.0,
		},
		{
			"id": "large_shine",
			"type": "shader",
			"shader_key": "foil_soft_shine",
			"animation": "static",
			"z_order": 20,
			"depth": 0.15,
			"material_response": 1.0,
			"opacity": 1.0,
		},
		{
			"id": "fine_glitter",
			"type": "texture",
			"procedural": "foil_glitter",
			"animation": "scroll",
			"z_order": 30,
			"depth": 0.25,
			"material_response": 0.85,
			"opacity": GLITTER_OPACITY,
			"blend_mode": "add",
			"scroll_speed": GLITTER_DRIFT_SPEED,
			"scroll_direction": SHINE_ANGLE,
			"uv_scale": Vector2(GLITTER_SCALE, GLITTER_SCALE),
		},
		{
			"id": "tiny_sparkle",
			"type": "texture",
			"procedural": "foil_sparkle",
			"animation": "pulse",
			"z_order": 40,
			"depth": 0.35,
			"material_response": 0.55,
			"opacity": SPARKLE_OPACITY,
			"blend_mode": "add",
			"pulse_speed": SPARKLE_PULSE_SPEED,
			"uv_scale": Vector2(SPARKLE_SIZE, SPARKLE_SIZE),
		},
	]


static func create_rainbow_material() -> ShaderMaterial:
	var material := _VariantShaderCache.create("foil_rainbow")
	if material:
		material.set_shader_parameter("rainbow_strength", RAINBOW_STRENGTH)
		material.set_shader_parameter("foil_strength", STRENGTH)
		material.set_shader_parameter("edge_fresnel", EDGE_FRESNEL)
		material.set_shader_parameter("time_scale", RAINBOW_TIME_SCALE)
		material.set_shader_parameter("noise_scale", NOISE_SCALE)
		material.set_shader_parameter("beam_count", BEAM_COUNT)
		material.set_shader_parameter("etch_density", ETCH_DENSITY)
		material.set_shader_parameter("radial_strength", RADIAL_STRENGTH)
		material.set_shader_parameter("beam_angle", BEAM_ANGLE)
	return material


static func create_soft_shine_material() -> ShaderMaterial:
	var material := _VariantShaderCache.create("foil_soft_shine")
	if material:
		material.set_shader_parameter("shine_opacity", SHINE_OPACITY)
		material.set_shader_parameter(
			"time_scale",
			clampf(SHINE_SPEED * 0.0023, 0.01, 0.06)
		)
		material.set_shader_parameter("band_width", SHINE_WIDTH)
		material.set_shader_parameter("softness", SHINE_FALLOFF)
		material.set_shader_parameter("angle_weights", SHINE_ANGLE)
		material.set_shader_parameter("etch_density", ETCH_DENSITY * 0.75)
		material.set_shader_parameter("prism_strength", SHINE_PRISM)
	return material


static func create_named_shader_material(shader_key: String) -> ShaderMaterial:
	match shader_key:
		"foil_rainbow":
			return create_rainbow_material()
		"foil_soft_shine":
			return create_soft_shine_material()
		_:
			return null


static func build_procedural_texture(procedural_key: String) -> Texture2D:
	match procedural_key:
		"foil_grain":
			return _build_grain_texture()
		"foil_glitter":
			return _build_speckle_texture(GLITTER_DENSITY, GLITTER_BRIGHTNESS, 211)
		"foil_sparkle":
			return _build_speckle_texture(SPARKLE_DENSITY, SPARKLE_BRIGHTNESS, 733)
		_:
			return null


static func _build_grain_texture() -> Texture2D:
	var size := 1024
	var coarse := FastNoiseLite.new()
	coarse.seed = 17
	coarse.noise_type = FastNoiseLite.TYPE_SIMPLEX
	coarse.frequency = GRAIN_NOISE_SCALE * 0.22
	coarse.fractal_type = FastNoiseLite.FRACTAL_FBM
	coarse.fractal_octaves = 4

	var fine := FastNoiseLite.new()
	fine.seed = 91
	fine.noise_type = FastNoiseLite.TYPE_VALUE
	fine.frequency = GRAIN_NOISE_SCALE * 1.35
	fine.fractal_type = FastNoiseLite.FRACTAL_FBM
	fine.fractal_octaves = 2

	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var strength := clampf(GRAIN_OPACITY * 2.4, 0.02, 0.16)
	for y in size:
		for x in size:
			var n1 := (coarse.get_noise_2d(float(x), float(y)) + 1.0) * 0.5
			var n2 := (fine.get_noise_2d(float(x), float(y)) + 1.0) * 0.5
			var n := lerpf(n2, n1, 0.28)
			n = clampf((n - 0.5) * GRAIN_CONTRAST + 0.5, 0.0, 1.0)
			var g := 1.0 + (n - 0.5) * strength * 2.0
			g = clampf(g, 0.88, 1.08)
			img.set_pixel(x, y, Color(g, g, g, 1.0))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


static func _build_speckle_texture(density_threshold: float, brightness: float, seed: int) -> Texture2D:
	var size := 512
	var noise := FastNoiseLite.new()
	noise.seed = seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.55
	noise.fractal_type = FastNoiseLite.FRACTAL_NONE

	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in size:
		for x in size:
			var n := (noise.get_noise_2d(float(x), float(y)) + 1.0) * 0.5
			if n < density_threshold:
				continue
			var spark := smoothstep(density_threshold, 1.0, n)
			spark = pow(spark, 3.2) * brightness
			if spark < 0.12:
				continue
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, spark))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)
