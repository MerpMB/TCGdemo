class_name CardVisualLibrary
extends RefCounted
## VisualLibrary — centralized renderer asset pipeline for cards.
## CardScene / CardRenderer request assets here — they never contain asset paths.
## Missing textures return null (or StyleBox fallbacks) so cards always render.

const _VariantLayer := preload("res://scripts/ui/variant_layer.gd")


enum CardBackType {
	DEFAULT,
	EVENT,
	BLACKJACK,
	DEVELOPER,
}


const FRAME_KEYS := {
	CardData.Rarity.COMMON: "common",
	CardData.Rarity.RARE: "rare",
	CardData.Rarity.EPIC: "epic",
	CardData.Rarity.LEGENDARY: "legendary",
}

## Production folders — artists drop PNGs here; no CardScene changes needed.
const CARDS_ROOT := "res://assets/cards"
const FRAMES_ROOT := "res://assets/frames"
const VARIANTS_ROOT := "res://assets/variants"
const VARIANT_OVERLAYS_ROOT := "res://assets/variants/overlays"
const VARIANT_SHINES_ROOT := "res://assets/variants/shines"
const VARIANT_SPARKLES_ROOT := "res://assets/variants/sparkles"
const CARD_BACKS_ROOT := "res://assets/backs"
const GLOWS_ROOT := "res://assets/glows"
const SHADERS_ROOT := "res://assets/shaders"

## Rarity → artwork subfolder under assets/cards/.
const RARITY_ART_FOLDERS := {
	CardData.Rarity.COMMON: "common",
	CardData.Rarity.RARE: "rare",
	CardData.Rarity.EPIC: "epic",
	CardData.Rarity.LEGENDARY: "legendary",
}

## Card set → artwork subfolder (overrides rarity folder when applicable).
const SET_ART_FOLDERS := {
	"Event Set": "event",
	"Developer Set": "developer",
}

## Variant → subfolder under assets/variants/.
const VARIANT_FOLDER_KEYS := {
	CardData.Variant.FOIL: "foil",
	CardData.Variant.NEGATIVE: "negative",
	CardData.Variant.DIAMOND: "diamond",
	CardData.Variant.SYNTH: "synth",
}

## Default filenames inside variant / glow folders.
const VARIANT_OVERLAY_FILE := "overlay"
const VARIANT_SHINE_FILE := "shine"
const VARIANT_SPARKLE_FILE := "sparkle"
const GLOW_OVERLAY_FILE := "glow"

## Future idle parallax multipliers (legacy — depth drives parallax in VariantRenderer).
const VARIANT_PARALLAX_ARTWORK := 1.0
const VARIANT_PARALLAX_OVERLAY := 0.85
const VARIANT_PARALLAX_SHINE := 1.15
const VARIANT_PARALLAX_GLOW := 0.6

# ---------------------------------------------------------------------------
# Global idle parallax tuning — one driver, depth-scaled per layer.
# ---------------------------------------------------------------------------
## Max pixel offset at depth 1.0. Sparkles at depth 0.35 move ~35% of this.
const PARALLAX_DISTANCE := 3.0
## Full center → left → right → center cycle duration scale (lower = slower).
const IDLE_SPEED := 0.065
## Easing curve for idle path segments (1 = linear, 2+ = softer corners).
const IDLE_CURVE := 2.0

# ---------------------------------------------------------------------------
# Foil material tuning (production) — one laminated sheet.
# Layer order: grain → rainbow → shine → glitter → sparkles.
# Artwork first; foil supports art. Shared idle driver × depth × material_response.
# Look target: Pokémon SR / Full Art holofoil — diagonal beams, prism sweep, etch.
# ---------------------------------------------------------------------------

## 1. Micro Grain — film grain (isotropic speckles); almost locked to artwork.
const FOIL_GRAIN_OPACITY := 0.05
const FOIL_GRAIN_NOISE_SCALE := 1.15
const FOIL_GRAIN_CONTRAST := 1.55

## 2. Rainbow — sparse ~40° diagonal beams (BL→TR); gaps clear for art.
const FOIL_STRENGTH := 0.48
const FOIL_RAINBOW_STRENGTH := 0.50
const FOIL_EDGE_FRESNEL := 0.13
const FOIL_RAINBOW_TIME_SCALE := 0.04
const FOIL_NOISE_SCALE := 28.0
const FOIL_BEAM_COUNT := 3.2
const FOIL_ETCH_DENSITY := 48.0
const FOIL_RADIAL_STRENGTH := 0.24
## Across-stripe weights for ~40° lines (bottom-left → top-right).
const FOIL_BEAM_ANGLE := Vector2(0.78, -0.62)

## 3. Shine — same diagonal as beams; stronger specular catch.
const FOIL_SHINE_OPACITY := 0.34
const FOIL_SHINE_SPEED := 8.0
const FOIL_SHINE_WIDTH := 0.24
const FOIL_SHINE_FALLOFF := 0.14
const FOIL_SHINE_ANGLE := Vector2(0.78, -0.62)
const FOIL_SHINE_PRISM := 0.95

## 4. Glitter — sparse metallic dust.
const FOIL_GLITTER_OPACITY := 0.065
const FOIL_GLITTER_DENSITY := 0.968
const FOIL_GLITTER_DRIFT_SPEED := 0.35
const FOIL_GLITTER_SCALE := 1.12
const FOIL_GLITTER_BRIGHTNESS := 0.42

## 5. Sparkles — rare flecks (low material_response).
const FOIL_SPARKLE_OPACITY := 0.05
const FOIL_SPARKLE_DENSITY := 0.985
const FOIL_SPARKLE_PULSE_SPEED := 0.30
const FOIL_SPARKLE_SIZE := 0.92
const FOIL_SPARKLE_BRIGHTNESS := 0.44

# ---------------------------------------------------------------------------
# Synth material tuning (production) — cyber circuitry, emissive digital energy.
# Layer order: micro circuit → trace network → data stream → energy pulse → nodes.
# Occupies ~20–40% of surface; artwork-first. No rainbow / metal / glitter.
# ---------------------------------------------------------------------------

## Shared motion clock — all Synth shaders derive timing from this.
const SYNTH_MASTER_TIME_SCALE := 1.0

## 1. Micro Circuit Texture — faint PCB etch (MUL).
const SYNTH_MICRO_CIRCUIT_STRENGTH := 0.032
const SYNTH_MICRO_CIRCUIT_FREQUENCY := 2.4

## 2. Circuit Trace Network — thin Tron light-roads (ADD).
const SYNTH_TRACE_STRENGTH := 0.38
const SYNTH_TRACE_TIME_SCALE := 0.04
const SYNTH_TRACE_EDGE_GLOW := 0.04

## 3. Flowing Data Stream — racing light packets along roads (ADD).
const SYNTH_STREAM_STRENGTH := 0.55
const SYNTH_STREAM_TIME_SCALE := 0.16
const SYNTH_PACKET_SPEED := 1.35
const SYNTH_PACKET_SIZE := 0.045

## 4. Energy Pulse — slow heartbeat through network (ADD).
const SYNTH_PULSE_STRENGTH := 0.42
const SYNTH_PULSE_TIME_SCALE := 0.05
const SYNTH_PULSE_INTERVAL := 5.5
const SYNTH_PULSE_WIDTH := 0.16

## 5. Tiny Data Nodes — sparse junction lights (ADD + pulse).
const SYNTH_NODE_OPACITY := 0.18
const SYNTH_NODE_DENSITY := 0.988
const SYNTH_NODE_PULSE_SPEED := 0.18
const SYNTH_NODE_SIZE := 0.92
const SYNTH_NODE_BRIGHTNESS := 0.55

## Per-variant layer blueprints — renderer consumes materialized VariantLayer instances only.
## Layer type keys: texture, shader, color, particles
## Animation keys: static, scroll, rotate, pulse, shimmer
## Foil uses procedural textures / shaders via "procedural" / "shader_key" (no PNG required).
const VARIANT_LAYER_BLUEPRINTS := {
	CardData.Variant.FOIL: [
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
			"opacity": FOIL_GLITTER_OPACITY,
			"blend_mode": "add",
			"scroll_speed": FOIL_GLITTER_DRIFT_SPEED,
			"scroll_direction": FOIL_SHINE_ANGLE,
			"uv_scale": Vector2(FOIL_GLITTER_SCALE, FOIL_GLITTER_SCALE),
		},
		{
			"id": "tiny_sparkle",
			"type": "texture",
			"procedural": "foil_sparkle",
			"animation": "pulse",
			"z_order": 40,
			"depth": 0.35,
			"material_response": 0.55,
			"opacity": FOIL_SPARKLE_OPACITY,
			"blend_mode": "add",
			"pulse_speed": FOIL_SPARKLE_PULSE_SPEED,
			"uv_scale": Vector2(FOIL_SPARKLE_SIZE, FOIL_SPARKLE_SIZE),
		},
	],
	CardData.Variant.SYNTH: [
		{
			"id": "micro_circuit_texture",
			"type": "texture",
			"procedural": "synth_micro_circuit",
			"animation": "static",
			"z_order": 0,
			"depth": 0.02,
			"material_response": 0.35,
			"opacity": 1.0,
			"blend_mode": "mul",
		},
		{
			"id": "circuit_trace_network",
			"type": "shader",
			"shader_key": "synth_circuit_traces",
			"animation": "static",
			"z_order": 10,
			"depth": 0.06,
			"material_response": 0.65,
			"opacity": 1.0,
		},
		{
			"id": "flowing_data_stream",
			"type": "shader",
			"shader_key": "synth_data_stream",
			"animation": "static",
			"z_order": 20,
			"depth": 0.12,
			"material_response": 0.85,
			"opacity": 1.0,
		},
		{
			"id": "energy_pulse",
			"type": "shader",
			"shader_key": "synth_energy_pulse",
			"animation": "static",
			"z_order": 30,
			"depth": 0.18,
			"material_response": 1.0,
			"opacity": 1.0,
		},
		{
			"id": "tiny_data_nodes",
			"type": "texture",
			"procedural": "synth_data_nodes",
			"animation": "pulse",
			"z_order": 40,
			"depth": 0.22,
			"material_response": 0.4,
			"opacity": SYNTH_NODE_OPACITY,
			"blend_mode": "add",
			"pulse_speed": SYNTH_NODE_PULSE_SPEED,
			"uv_scale": Vector2(SYNTH_NODE_SIZE, SYNTH_NODE_SIZE),
		},
	],
	CardData.Variant.DIAMOND: [
		{
			"id": "crystal_pattern",
			"type": "texture",
			"slot": "overlay",
			"animation": "static",
			"z_order": 0,
			"parallax_strength": VARIANT_PARALLAX_OVERLAY,
		},
		{
			"id": "rainbow_refraction",
			"type": "texture",
			"slot": "shine",
			"animation": "scroll",
			"z_order": 10,
			"opacity": 0.55,
			"scroll_speed": 28.0,
			"scroll_direction": Vector2(1.0, 0.0),
			"parallax_strength": VARIANT_PARALLAX_SHINE,
		},
		{
			"id": "shimmer",
			"type": "texture",
			"slot": "shimmer",
			"animation": "shimmer",
			"z_order": 20,
			"opacity": 0.6,
		},
		{
			"id": "sparkle",
			"type": "texture",
			"slot": "sparkle",
			"animation": "static",
			"z_order": 30,
		},
	],
	CardData.Variant.NEGATIVE: [
		{
			"id": "invert",
			"type": "texture",
			"slot": "overlay",
			"animation": "static",
			"z_order": 0,
			"parallax_strength": VARIANT_PARALLAX_OVERLAY,
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
	],
}

## Texture caches (null misses included) so grid/gallery never hits disk twice.
static var _frame_texture_cache: Dictionary = {}
static var _artwork_texture_cache: Dictionary = {}
static var _variant_texture_cache: Dictionary = {}
static var _card_back_texture_cache: Dictionary = {}
static var _glow_texture_cache: Dictionary = {}
static var _variant_shader_cache: Dictionary = {}

## One warning per missing key per session.
static var _missing_frame_warned: Dictionary = {}
static var _missing_card_back_warned: Dictionary = {}
static var _missing_artwork_warned: Dictionary = {}
static var _missing_variant_layer_warned: Dictionary = {}
static var _missing_glow_warned: Dictionary = {}

const DEFAULT_CARD_BACK := "default"

const REVEAL_DURATIONS := {
	CardData.Rarity.COMMON: 0.28,
	CardData.Rarity.RARE: 0.34,
	CardData.Rarity.EPIC: 0.42,
	CardData.Rarity.LEGENDARY: 0.62,
}

const REVEAL_LIFT_OFFSETS := {
	CardData.Rarity.COMMON: -10.0,
	CardData.Rarity.RARE: -14.0,
	CardData.Rarity.EPIC: -18.0,
	CardData.Rarity.LEGENDARY: -26.0,
}

const REVEAL_GLOW_ALPHAS := {
	CardData.Rarity.COMMON: 0.0,
	CardData.Rarity.RARE: 0.18,
	CardData.Rarity.EPIC: 0.28,
	CardData.Rarity.LEGENDARY: 0.45,
}


# ---------------------------------------------------------------------------
# Texture assets (PNG) — primary production path
# ---------------------------------------------------------------------------

## Resolve card artwork: explicit CardData.artwork, then convention path.
## Convention: assets/cards/<folder>/<card_id>.png (lowercase, underscores).
static func resolve_artwork(card: CardData) -> Texture2D:
	if card == null:
		return null
	if card.artwork != null:
		return card.artwork
	return get_artwork_texture_by_id(card.card_id, get_art_folder_for_card(card))


## Load artwork by card_id from the standard cards tree. Cached per path.
static func get_artwork_texture_by_id(card_id: String, folder: String) -> Texture2D:
	var key := "%s/%s" % [folder, card_id.to_lower()]
	if _artwork_texture_cache.has(key):
		return _artwork_texture_cache[key]

	var texture := _try_load_png("%s/%s" % [CARDS_ROOT, folder], card_id.to_lower())
	_artwork_texture_cache[key] = texture
	return texture


## Pick artwork subfolder from card set, falling back to rarity folder.
static func get_art_folder_for_card(card: CardData) -> String:
	if card == null:
		return RARITY_ART_FOLDERS.get(CardData.Rarity.COMMON, "common")
	if SET_ART_FOLDERS.has(card.card_set):
		return SET_ART_FOLDERS[card.card_set]
	return RARITY_ART_FOLDERS.get(card.rarity, "common")


## Build the conventional artwork path for documentation / tooling (no load).
static func get_artwork_path(card_id: String, folder: String) -> String:
	return "%s/%s/%s.png" % [CARDS_ROOT, folder, card_id.to_lower()]


## PNG frame by rarity or frame key string (e.g. "common", "rare").
## Returns null when missing; caller should use get_frame_overlay_style() fallback.
static func get_frame_texture(rarity_or_key: String) -> Texture2D:
	var key := rarity_or_key.to_lower()
	if key.is_empty():
		key = "common"

	if _frame_texture_cache.has(key):
		return _frame_texture_cache[key]

	var path := "%s/%s.png" % [FRAMES_ROOT, key]
	var texture: Texture2D = null
	if ResourceLoader.exists(path):
		texture = load(path) as Texture2D
	else:
		_warn_missing_frame(key, path)

	_frame_texture_cache[key] = texture
	return texture


## Convenience overload that maps CardData.Rarity → frame key → texture.
static func get_frame_texture_for_rarity(rarity: CardData.Rarity) -> Texture2D:
	return get_frame_texture(FRAME_KEYS.get(rarity, "common"))


## Materialized VariantLayer stack for a variant. Accepts CardData.Variant or folder key string.
static func get_variant_layers(variant_or_key) -> Array:
	var folder_key := ""
	var variant_enum := CardData.Variant.NORMAL

	if variant_or_key is String:
		folder_key = variant_or_key.to_lower()
		variant_enum = _variant_from_folder_key(folder_key)
	elif variant_or_key is int:
		variant_enum = variant_or_key as CardData.Variant
		folder_key = VARIANT_FOLDER_KEYS.get(variant_enum, "")
	else:
		return []

	if folder_key.is_empty():
		return []

	var blueprints: Array = VARIANT_LAYER_BLUEPRINTS.get(variant_enum, [])
	var layers: Array = []
	for blueprint in blueprints:
		var layer = _materialize_variant_layer(folder_key, blueprint)
		if layer != null and _is_layer_spawnable(layer):
			layers.append(layer)
	return layers


## Variant overlay texture for a CardData.Variant enum value.
## Tries overlays/<key>.png, variants/<key>/overlay.png, variants/<key>.png, then variants/<key>/default.png.
static func get_variant_overlay_texture(variant: CardData.Variant) -> Texture2D:
	var folder_key: String = VARIANT_FOLDER_KEYS.get(variant, "")
	if folder_key.is_empty():
		return null
	return _resolve_layer_texture(folder_key, "overlay", VARIANT_OVERLAY_FILE)


## Shine sweep texture — prefer get_variant_layers().
static func get_variant_shine_texture(variant: CardData.Variant) -> Texture2D:
	var folder_key: String = VARIANT_FOLDER_KEYS.get(variant, "")
	if folder_key.is_empty():
		return null
	return _resolve_layer_texture(folder_key, "shine", VARIANT_SHINE_FILE)


## Sparkle preset texture — prefer get_variant_layers().
static func get_variant_sparkle_texture(variant: CardData.Variant) -> Texture2D:
	var folder_key: String = VARIANT_FOLDER_KEYS.get(variant, "")
	if folder_key.is_empty():
		return null
	return _resolve_layer_texture(folder_key, "sparkle", VARIANT_SPARKLE_FILE)


## Legacy string lookup — prefer get_variant_overlay_texture() for variants.
static func get_variant_texture(variant_name: String) -> Texture2D:
	return _load_cached_texture(
		_variant_texture_cache,
		VARIANTS_ROOT,
		variant_name.to_lower(),
		false
	)


## Rarity glow texture. Tries glows/<rarity>/glow.png then glows/<rarity>.png.
static func get_glow_texture_for_rarity(rarity: CardData.Rarity) -> Texture2D:
	var folder_key: String = FRAME_KEYS.get(rarity, "common")
	var cache_key := "glow_%s" % folder_key
	if _glow_texture_cache.has(cache_key):
		return _glow_texture_cache[cache_key]

	var texture := _try_load_glow_texture(folder_key, GLOW_OVERLAY_FILE)
	if texture == null:
		texture = _try_load_png(GLOWS_ROOT, folder_key)

	_glow_texture_cache[cache_key] = texture
	return texture


## Legacy string lookup — prefer get_glow_texture_for_rarity().
static func get_glow_texture(rarity_name: String) -> Texture2D:
	return get_glow_texture_for_rarity(_parse_rarity_name(rarity_name))


## Warn once per card when an explicit artwork reference fails validation.
static func validate_card_assets(card: CardData) -> void:
	if card == null or card.card_id.is_empty():
		return
	if card.artwork != null:
		return
	# Placeholder cards with null artwork are valid — convention path resolves at render time.


## Variant FX tuning — shader uniforms; idle motion uses TIME (no per-card tweens).
const DIAMOND_ART_MODULATE := Color(1.03, 1.06, 1.12, 1.0)
const DIAMOND_GLOW_INTENSITY := 0.18
const DIAMOND_SPARKLE_INTENSITY := 0.3

const NEGATIVE_TIME_SCALE := 0.28
const NEGATIVE_EDGE_STRENGTH := 0.14
const NEGATIVE_ART_BRIGHTNESS := 1.0


## Card-back art under assets/backs/<name>.png.
## Empty / unknown names fall back to default.png. Missing named backs warn once,
## then try default — never leaves the card blank if default exists.
static func get_card_back_texture(name: String) -> Texture2D:
	var key := name.to_lower().strip_edges()
	if key.is_empty():
		key = DEFAULT_CARD_BACK

	if _card_back_texture_cache.has(key):
		return _card_back_texture_cache[key]

	var texture := _try_load_png(CARD_BACKS_ROOT, key)
	if texture == null and key != DEFAULT_CARD_BACK:
		_warn_missing_card_back(key)
		if _card_back_texture_cache.has(DEFAULT_CARD_BACK):
			texture = _card_back_texture_cache[DEFAULT_CARD_BACK]
		else:
			texture = _try_load_png(CARD_BACKS_ROOT, DEFAULT_CARD_BACK)
			_card_back_texture_cache[DEFAULT_CARD_BACK] = texture
			if texture == null:
				push_warning(
					"CardVisualLibrary: default card back missing (%s/%s.png)."
					% [CARD_BACKS_ROOT, DEFAULT_CARD_BACK]
				)

	_card_back_texture_cache[key] = texture
	return texture


# ---------------------------------------------------------------------------
# Variant shader materials (procedural FX fallback when PNG overlays are absent)
# ---------------------------------------------------------------------------

static func create_variant_material(shader_name: String) -> ShaderMaterial:
	var cache_key := shader_name
	if _variant_shader_cache.has(cache_key):
		var cached: Shader = _variant_shader_cache[cache_key]
		var material := ShaderMaterial.new()
		material.shader = cached
		return material

	var path := "%s/%s.gdshader" % [SHADERS_ROOT, shader_name]
	if not ResourceLoader.exists(path):
		push_warning("CardVisualLibrary: variant shader missing '%s'." % path)
		return null

	var shader := load(path) as Shader
	_variant_shader_cache[cache_key] = shader
	var material := ShaderMaterial.new()
	material.shader = shader
	return material


static func create_foil_rainbow_material() -> ShaderMaterial:
	var material := create_variant_material("foil_rainbow")
	if material:
		material.set_shader_parameter("rainbow_strength", FOIL_RAINBOW_STRENGTH)
		material.set_shader_parameter("foil_strength", FOIL_STRENGTH)
		material.set_shader_parameter("edge_fresnel", FOIL_EDGE_FRESNEL)
		material.set_shader_parameter("time_scale", FOIL_RAINBOW_TIME_SCALE)
		material.set_shader_parameter("noise_scale", FOIL_NOISE_SCALE)
		material.set_shader_parameter("beam_count", FOIL_BEAM_COUNT)
		material.set_shader_parameter("etch_density", FOIL_ETCH_DENSITY)
		material.set_shader_parameter("radial_strength", FOIL_RADIAL_STRENGTH)
		material.set_shader_parameter("beam_angle", FOIL_BEAM_ANGLE)
	return material


static func create_foil_soft_shine_material() -> ShaderMaterial:
	var material := create_variant_material("foil_soft_shine")
	if material:
		material.set_shader_parameter("shine_opacity", FOIL_SHINE_OPACITY)
		material.set_shader_parameter(
			"time_scale",
			clampf(FOIL_SHINE_SPEED * 0.0023, 0.01, 0.06)
		)
		material.set_shader_parameter("band_width", FOIL_SHINE_WIDTH)
		material.set_shader_parameter("softness", FOIL_SHINE_FALLOFF)
		material.set_shader_parameter("angle_weights", FOIL_SHINE_ANGLE)
		material.set_shader_parameter("etch_density", FOIL_ETCH_DENSITY * 0.75)
		material.set_shader_parameter("prism_strength", FOIL_SHINE_PRISM)
	return material


static func create_synth_circuit_traces_material() -> ShaderMaterial:
	var material := create_variant_material("synth_circuit_traces")
	if material:
		material.set_shader_parameter("trace_strength", SYNTH_TRACE_STRENGTH)
		material.set_shader_parameter(
			"time_scale", SYNTH_TRACE_TIME_SCALE * SYNTH_MASTER_TIME_SCALE
		)
		material.set_shader_parameter("edge_glow", SYNTH_TRACE_EDGE_GLOW)
	return material


static func create_synth_data_stream_material() -> ShaderMaterial:
	var material := create_variant_material("synth_data_stream")
	if material:
		material.set_shader_parameter("stream_strength", SYNTH_STREAM_STRENGTH)
		material.set_shader_parameter(
			"time_scale", SYNTH_STREAM_TIME_SCALE * SYNTH_MASTER_TIME_SCALE
		)
		material.set_shader_parameter("packet_speed", SYNTH_PACKET_SPEED)
		material.set_shader_parameter("packet_size", SYNTH_PACKET_SIZE)
		material.set_shader_parameter("pulse_interval", SYNTH_PULSE_INTERVAL)
		material.set_shader_parameter("pulse_width", SYNTH_PULSE_WIDTH)
	return material


static func create_synth_energy_pulse_material() -> ShaderMaterial:
	var material := create_variant_material("synth_energy_pulse")
	if material:
		material.set_shader_parameter("pulse_strength", SYNTH_PULSE_STRENGTH)
		material.set_shader_parameter(
			"time_scale", SYNTH_PULSE_TIME_SCALE * SYNTH_MASTER_TIME_SCALE
		)
		material.set_shader_parameter("pulse_interval", SYNTH_PULSE_INTERVAL)
		material.set_shader_parameter("pulse_width", SYNTH_PULSE_WIDTH)
	return material


static func create_diamond_glow_material() -> ShaderMaterial:
	var material := create_variant_material("diamond_glow")
	if material:
		material.set_shader_parameter("intensity", DIAMOND_GLOW_INTENSITY)
		material.set_shader_parameter("time_scale", 1.1)
	return material


static func create_diamond_sparkle_material() -> ShaderMaterial:
	var material := create_variant_material("diamond_sparkle")
	if material:
		material.set_shader_parameter("intensity", DIAMOND_SPARKLE_INTENSITY)
		material.set_shader_parameter("time_scale", 1.35)
	return material


static func create_negative_invert_material() -> ShaderMaterial:
	var material := create_variant_material("negative_invert")
	if material:
		material.set_shader_parameter("brightness", NEGATIVE_ART_BRIGHTNESS)
		material.set_shader_parameter("time_scale", NEGATIVE_TIME_SCALE)
	return material


static func create_negative_edge_material() -> ShaderMaterial:
	var material := create_variant_material("negative_edge")
	if material:
		material.set_shader_parameter("edge_strength", NEGATIVE_EDGE_STRENGTH)
		material.set_shader_parameter("time_scale", NEGATIVE_TIME_SCALE)
	return material


static func make_overlay_full_rect(overlay_node: ColorRect) -> void:
	overlay_node.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_node.offset_left = 0.0
	overlay_node.offset_top = 0.0
	overlay_node.offset_right = 0.0
	overlay_node.offset_bottom = 0.0
	overlay_node.mouse_filter = Control.MOUSE_FILTER_IGNORE


# ---------------------------------------------------------------------------
# Procedural StyleBox fallbacks (used only when a PNG is missing)
# ---------------------------------------------------------------------------

static func get_frame_style(rarity: CardData.Rarity) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	style.bg_color = Color(0.1, 0.11, 0.15, 1.0)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	style.shadow_color = Color(0, 0, 0, 0.35)

	match rarity:
		CardData.Rarity.COMMON:
			style.border_color = Color(0.18, 0.72, 0.32)
			style.shadow_color = Color(0.1, 0.4, 0.2, 0.35)
		CardData.Rarity.RARE:
			style.border_width_left = 4
			style.border_width_top = 4
			style.border_width_right = 4
			style.border_width_bottom = 4
			style.border_color = Color(0.22, 0.48, 0.95)
			style.shadow_color = Color(0.1, 0.25, 0.6, 0.4)
		CardData.Rarity.EPIC:
			style.border_width_left = 5
			style.border_width_top = 5
			style.border_width_right = 5
			style.border_width_bottom = 5
			style.border_color = Color(0.62, 0.28, 0.82)
			style.shadow_size = 8
			style.shadow_color = Color(0.35, 0.1, 0.5, 0.45)
		CardData.Rarity.LEGENDARY:
			style.border_width_left = 6
			style.border_width_top = 6
			style.border_width_right = 6
			style.border_width_bottom = 6
			style.border_color = Color(0.95, 0.78, 0.18)
			style.shadow_size = 12
			style.shadow_color = Color(0.55, 0.4, 0.05, 0.55)

	return style


## Transparent-fill StyleBox overlay used as the frame fallback when PNG is absent.
static func get_frame_overlay_style(rarity: CardData.Rarity) -> StyleBoxFlat:
	var style := get_frame_style(rarity)
	style.bg_color = Color(0, 0, 0, 0)
	return style


static func get_card_back_style(back_type: CardBackType = CardBackType.DEFAULT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3

	match back_type:
		CardBackType.DEFAULT:
			style.bg_color = Color(0.12, 0.14, 0.22, 1.0)
			style.border_color = Color(0.35, 0.42, 0.62, 1.0)
		CardBackType.EVENT:
			style.bg_color = Color(0.2, 0.1, 0.18, 1.0)
			style.border_color = Color(0.85, 0.35, 0.55, 1.0)
		CardBackType.BLACKJACK:
			style.bg_color = Color(0.08, 0.1, 0.08, 1.0)
			style.border_color = Color(0.15, 0.55, 0.2, 1.0)
		CardBackType.DEVELOPER:
			style.bg_color = Color(0.15, 0.12, 0.08, 1.0)
			style.border_color = Color(0.95, 0.55, 0.2, 1.0)

	return style


# ---------------------------------------------------------------------------
# Reveal timing (animation constants — not visual assets)
# ---------------------------------------------------------------------------

static func get_reveal_duration(rarity: CardData.Rarity) -> float:
	return REVEAL_DURATIONS.get(rarity, 0.28)


static func get_reveal_lift(rarity: CardData.Rarity) -> float:
	return REVEAL_LIFT_OFFSETS.get(rarity, -10.0)


static func get_reveal_glow_alpha(rarity: CardData.Rarity) -> float:
	return REVEAL_GLOW_ALPHAS.get(rarity, 0.0)


static func parse_card_back(back_id: String) -> CardBackType:
	match back_id.to_lower():
		"event":
			return CardBackType.EVENT
		"blackjack":
			return CardBackType.BLACKJACK
		"developer":
			return CardBackType.DEVELOPER
		_:
			return CardBackType.DEFAULT


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

static func _load_cached_texture(
	cache: Dictionary,
	root: String,
	key: String,
	warn_if_missing: bool
) -> Texture2D:
	if key.is_empty():
		return null
	if cache.has(key):
		return cache[key]

	var texture := _try_load_png(root, key)
	if texture == null and warn_if_missing:
		push_warning("CardVisualLibrary: missing texture '%s/%s.png'." % [root, key])

	cache[key] = texture
	return texture


static func _try_load_png(root: String, key: String) -> Texture2D:
	var path := "%s/%s.png" % [root, key]
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


static func _try_load_variant_texture(folder_key: String, file_key: String) -> Texture2D:
	return _try_load_png("%s/%s" % [VARIANTS_ROOT, folder_key], file_key)


static func _try_load_glow_texture(folder_key: String, file_key: String) -> Texture2D:
	return _try_load_png("%s/%s" % [GLOWS_ROOT, folder_key], file_key)


static func _resolve_layer_texture(
	folder_key: String,
	slot: String,
	legacy_file_key: String = ""
) -> Texture2D:
	var cache_key := "layer_%s/%s" % [folder_key, slot]
	if _variant_texture_cache.has(cache_key):
		return _variant_texture_cache[cache_key]

	var texture: Texture2D = null
	match slot:
		"overlay":
			texture = _try_load_png(VARIANT_OVERLAYS_ROOT, folder_key)
			if texture == null:
				texture = _try_load_variant_texture(folder_key, legacy_file_key if legacy_file_key else VARIANT_OVERLAY_FILE)
			if texture == null:
				texture = _try_load_png(VARIANTS_ROOT, folder_key)
			if texture == null:
				texture = _try_load_variant_texture(folder_key, "default")
		"shine":
			texture = _try_load_png(VARIANT_SHINES_ROOT, folder_key)
			if texture == null:
				texture = _try_load_png(
					"%s/%s" % [VARIANT_SHINES_ROOT, folder_key],
					legacy_file_key if legacy_file_key else VARIANT_SHINE_FILE
				)
		"sparkle":
			texture = _try_load_png(VARIANT_SPARKLES_ROOT, folder_key)
			if texture == null:
				texture = _try_load_png(
					"%s/%s" % [VARIANT_SPARKLES_ROOT, folder_key],
					legacy_file_key if legacy_file_key else VARIANT_SPARKLE_FILE
				)
		_:
			texture = _try_load_variant_texture(folder_key, slot)
			if texture == null:
				texture = _try_load_png(VARIANT_OVERLAYS_ROOT, "%s/%s" % [folder_key, slot])
			if texture == null:
				texture = _try_load_png(VARIANT_SHINES_ROOT, "%s/%s" % [folder_key, slot])
			if texture == null:
				texture = _try_load_png(VARIANT_SPARKLES_ROOT, "%s/%s" % [folder_key, slot])

	if texture == null:
		_warn_missing_variant_layer(folder_key, slot)

	_variant_texture_cache[cache_key] = texture
	return texture


static func _materialize_variant_layer(folder_key: String, blueprint: Dictionary):
	var layer_type := _parse_layer_type(String(blueprint.get("type", "texture")))
	var slot: String = blueprint.get("slot", "")
	var procedural: String = blueprint.get("procedural", "")
	var shader_key: String = blueprint.get("shader_key", "")
	var layer_id: String = String(blueprint.get("id", procedural if not procedural.is_empty() else slot))
	if layer_id.is_empty():
		layer_id = shader_key if not shader_key.is_empty() else "layer"

	var layer = _VariantLayer.new()
	layer.layer_id = layer_id
	layer.type = layer_type
	layer.blend_mode = _parse_blend_mode(blueprint.get("blend_mode", _VariantLayer.BlendMode.MIX))
	layer.opacity = float(blueprint.get("opacity", 1.0))
	layer.tint = blueprint.get("tint", Color.WHITE)
	layer.z_order = int(blueprint.get("z_order", 0))
	layer.depth = float(blueprint.get("depth", 0.0))
	layer.material_response = float(blueprint.get("material_response", 1.0))
	layer.uv_scale = blueprint.get("uv_scale", Vector2.ONE)
	layer.parallax_strength = float(blueprint.get("parallax_strength", 0.0))
	layer.scroll_direction = blueprint.get("scroll_direction", Vector2(1.0, 0.0))
	layer.scroll_speed = float(blueprint.get("scroll_speed", 0.0))
	layer.rotation_speed = float(blueprint.get("rotation_speed", 0.0))
	layer.pulse_speed = float(blueprint.get("pulse_speed", 3.0))
	layer.animation_type = _parse_layer_animation_type(String(blueprint.get("animation", "static")))

	match layer_type:
		_VariantLayer.LayerType.TEXTURE:
			if not procedural.is_empty():
				layer.texture = _get_procedural_variant_texture(procedural)
			elif not slot.is_empty():
				layer.texture = _resolve_layer_texture(folder_key, slot, slot)
		_VariantLayer.LayerType.SHADER:
			if not shader_key.is_empty():
				layer.material = _create_named_variant_shader_material(shader_key)
			else:
				layer.shader = blueprint.get("shader", null)
				layer.material = blueprint.get("material", null)
		_VariantLayer.LayerType.COLOR:
			layer.tint = blueprint.get("tint", layer.tint)
		_VariantLayer.LayerType.PARTICLES:
			pass

	return layer


static func _is_layer_spawnable(layer) -> bool:
	match layer.type:
		_VariantLayer.LayerType.TEXTURE:
			return layer.texture != null
		_VariantLayer.LayerType.SHADER:
			return layer.shader != null or layer.material != null
		_VariantLayer.LayerType.COLOR:
			return false
		_VariantLayer.LayerType.PARTICLES:
			return false
		_:
			return false


static func _parse_layer_type(type_key: String) -> int:
	match type_key.to_lower():
		"shader":
			return _VariantLayer.LayerType.SHADER
		"color":
			return _VariantLayer.LayerType.COLOR
		"particles":
			return _VariantLayer.LayerType.PARTICLES
		_:
			return _VariantLayer.LayerType.TEXTURE


static func _parse_blend_mode(value) -> int:
	if value is int:
		return value
	match String(value).to_lower():
		"add":
			return _VariantLayer.BlendMode.ADD
		"sub":
			return _VariantLayer.BlendMode.SUB
		"mul", "multiply":
			return _VariantLayer.BlendMode.MUL
		_:
			return _VariantLayer.BlendMode.MIX


static func _parse_layer_animation_type(animation_key: String) -> int:
	match animation_key.to_lower():
		"scroll":
			return _VariantLayer.AnimationType.SCROLL
		"rotate":
			return _VariantLayer.AnimationType.ROTATE
		"pulse":
			return _VariantLayer.AnimationType.PULSE
		"shimmer":
			return _VariantLayer.AnimationType.SHIMMER
		_:
			return _VariantLayer.AnimationType.STATIC


static func _create_named_variant_shader_material(shader_key: String) -> ShaderMaterial:
	match shader_key:
		"foil_rainbow":
			return create_foil_rainbow_material()
		"foil_soft_shine":
			return create_foil_soft_shine_material()
		"synth_circuit_traces":
			return create_synth_circuit_traces_material()
		"synth_data_stream":
			return create_synth_data_stream_material()
		"synth_energy_pulse":
			return create_synth_energy_pulse_material()
		_:
			return create_variant_material(shader_key)


static func _get_procedural_variant_texture(procedural_key: String) -> Texture2D:
	var cache_key := "proc_%s" % procedural_key
	if _variant_texture_cache.has(cache_key):
		return _variant_texture_cache[cache_key]

	var texture: Texture2D = null
	match procedural_key:
		"foil_grain":
			texture = _build_foil_grain_texture()
		"foil_glitter":
			texture = _build_foil_speckle_texture(FOIL_GLITTER_DENSITY, FOIL_GLITTER_BRIGHTNESS, 211)
		"foil_sparkle":
			texture = _build_foil_speckle_texture(FOIL_SPARKLE_DENSITY, FOIL_SPARKLE_BRIGHTNESS, 733)
		"synth_micro_circuit":
			texture = _build_synth_micro_circuit_texture()
		"synth_data_nodes":
			texture = _build_synth_data_nodes_texture()
		_:
			push_warning("CardVisualLibrary: unknown procedural texture '%s'." % procedural_key)

	_variant_texture_cache[cache_key] = texture
	return texture


static func _build_foil_grain_texture() -> Texture2D:
	## Film grain — fine isotropic speckles (no directional etch).
	## High res + caller uses LINEAR filter (project default is nearest).
	## MUL overlay — strength baked via FOIL_GRAIN_OPACITY.
	var size := 1024
	var coarse := FastNoiseLite.new()
	coarse.seed = 17
	coarse.noise_type = FastNoiseLite.TYPE_SIMPLEX
	coarse.frequency = FOIL_GRAIN_NOISE_SCALE * 0.22
	coarse.fractal_type = FastNoiseLite.FRACTAL_FBM
	coarse.fractal_octaves = 4

	var fine := FastNoiseLite.new()
	fine.seed = 91
	fine.noise_type = FastNoiseLite.TYPE_VALUE
	fine.frequency = FOIL_GRAIN_NOISE_SCALE * 1.35
	fine.fractal_type = FastNoiseLite.FRACTAL_FBM
	fine.fractal_octaves = 2

	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var strength := clampf(FOIL_GRAIN_OPACITY * 2.4, 0.02, 0.16)
	for y in size:
		for x in size:
			var n1 := (coarse.get_noise_2d(float(x), float(y)) + 1.0) * 0.5
			var n2 := (fine.get_noise_2d(float(x), float(y)) + 1.0) * 0.5
			# Mostly fine speckles with a soft low-frequency lift (film stock).
			var n := lerpf(n2, n1, 0.28)
			n = clampf((n - 0.5) * FOIL_GRAIN_CONTRAST + 0.5, 0.0, 1.0)
			var g := 1.0 + (n - 0.5) * strength * 2.0
			g = clampf(g, 0.88, 1.08)
			img.set_pixel(x, y, Color(g, g, g, 1.0))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


static func _build_foil_speckle_texture(density_threshold: float, brightness: float, seed: int) -> Texture2D:
	## Sparse reflective dots. Higher density_threshold => fewer speckles.
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
			# Tiny hot spots only — no large blobs.
			var spark := smoothstep(density_threshold, 1.0, n)
			spark = pow(spark, 3.2) * brightness
			if spark < 0.12:
				continue
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, spark))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


static func _build_synth_micro_circuit_texture() -> Texture2D:
	## Microscopic PCB etch — extremely fine Manhattan grid (MUL, static).
	var size := 1024
	var fine := FastNoiseLite.new()
	fine.seed = 67
	fine.noise_type = FastNoiseLite.TYPE_VALUE
	fine.frequency = SYNTH_MICRO_CIRCUIT_FREQUENCY * 1.8
	fine.fractal_type = FastNoiseLite.FRACTAL_NONE

	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var strength := clampf(SYNTH_MICRO_CIRCUIT_STRENGTH * 2.2, 0.015, 0.08)
	for y in size:
		for x in size:
			var fx := float(x) / float(size)
			var fy := float(y) / float(size)
			# Fine orthogonal etch lines.
			var grid := vec2_like_grid(fx, fy, 48.0)
			var h_line: float = 1.0 - smoothstep(0.0, 0.012, absf(grid.y - 0.5))
			var v_line: float = 1.0 - smoothstep(0.0, 0.012, absf(grid.x - 0.5))
			var etch: float = maxf(h_line, v_line) * 0.55
			var n := (fine.get_noise_2d(float(x), float(y)) + 1.0) * 0.5
			etch = clampf(etch + (n - 0.5) * 0.08, 0.0, 1.0)
			var g: float = 1.0 - etch * strength
			g = clampf(g, 0.94, 1.0)
			img.set_pixel(x, y, Color(g, g, g, 1.0))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


static func vec2_like_grid(fx: float, fy: float, cells: float) -> Vector2:
	var gx := fmod(fx * cells, 1.0)
	var gy := fmod(fy * cells, 1.0)
	return Vector2(gx, gy)


static func _build_synth_data_nodes_texture() -> Texture2D:
	## Sparse junction lights — cyan/teal emissive dots on trace crossings (ADD).
	var size := 512
	var noise := FastNoiseLite.new()
	noise.seed = 331
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.42
	noise.fractal_type = FastNoiseLite.FRACTAL_NONE

	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in size:
		for x in size:
			var fx := float(x) / float(size)
			var fy := float(y) / float(size)
			var grid := vec2_like_grid(fx, fy, 11.0)
			var junction: float = smoothstep(0.14, 0.0, grid.distance_to(Vector2(0.5, 0.5)))
			if junction < 0.05:
				continue
			var n := (noise.get_noise_2d(float(x), float(y)) + 1.0) * 0.5
			if n < SYNTH_NODE_DENSITY:
				continue
			var spark := pow(smoothstep(SYNTH_NODE_DENSITY, 1.0, n), 3.6) * SYNTH_NODE_BRIGHTNESS
			if spark < 0.08:
				continue
			var col := Color(0.22, 0.92, 1.0, spark * junction)
			img.set_pixel(x, y, col)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


static func _variant_from_folder_key(folder_key: String) -> CardData.Variant:
	match folder_key.to_lower():
		"foil":
			return CardData.Variant.FOIL
		"negative":
			return CardData.Variant.NEGATIVE
		"diamond":
			return CardData.Variant.DIAMOND
		"synth":
			return CardData.Variant.SYNTH
		_:
			return CardData.Variant.NORMAL


static func _parse_rarity_name(rarity_name: String) -> CardData.Rarity:
	match rarity_name.to_lower():
		"rare":
			return CardData.Rarity.RARE
		"epic":
			return CardData.Rarity.EPIC
		"legendary":
			return CardData.Rarity.LEGENDARY
		_:
			return CardData.Rarity.COMMON


static func _warn_missing_artwork(card_id: String, path: String) -> void:
	if _missing_artwork_warned.has(card_id):
		return
	_missing_artwork_warned[card_id] = true
	push_warning(
		"CardVisualLibrary: artwork missing for '%s' (%s) — using rarity color fallback."
		% [card_id, path]
	)


static func _warn_missing_variant_layer(folder_key: String, slot: String) -> void:
	var warn_key := "%s/%s" % [folder_key, slot]
	if _missing_variant_layer_warned.has(warn_key):
		return
	_missing_variant_layer_warned[warn_key] = true
	push_warning(
		"CardVisualLibrary: variant layer '%s' missing for '%s' — layer stays inactive."
		% [slot, folder_key]
	)


static func _warn_missing_glow(folder_key: String) -> void:
	if _missing_glow_warned.has(folder_key):
		return
	_missing_glow_warned[folder_key] = true
	push_warning(
		"CardVisualLibrary: glow texture missing for '%s' — using ColorRect fallback."
		% folder_key
	)


static func _warn_missing_frame(key: String, path: String) -> void:
	if _missing_frame_warned.has(key):
		return
	_missing_frame_warned[key] = true
	push_warning(
		"CardVisualLibrary: frame PNG missing for '%s' (%s) — using StyleBox fallback."
		% [key, path]
	)


static func _warn_missing_card_back(key: String) -> void:
	if _missing_card_back_warned.has(key):
		return
	_missing_card_back_warned[key] = true
	push_warning(
		"CardVisualLibrary: card back '%s' missing — using default back."
		% key
	)
