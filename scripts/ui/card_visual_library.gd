class_name CardVisualLibrary
extends RefCounted
## VisualLibrary — centralized renderer asset pipeline for cards.
## CardScene / CardRenderer request assets here — they never contain asset paths.
## Missing textures return null (or StyleBox fallbacks) so cards always render.


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
const FRAMES_ROOT := "res://assets/frames"
const VARIANTS_ROOT := "res://assets/variants"
const CARD_BACKS_ROOT := "res://assets/backs"
const GLOWS_ROOT := "res://assets/glows"
const SHADERS_ROOT := "res://assets/shaders"

## Texture caches (null misses included) so grid/gallery never hits disk twice.
static var _frame_texture_cache: Dictionary = {}
static var _variant_texture_cache: Dictionary = {}
static var _card_back_texture_cache: Dictionary = {}
static var _glow_texture_cache: Dictionary = {}
static var _variant_shader_cache: Dictionary = {}

## Variant FX tuning — animation reads these; shaders receive duplicated materials.
const FOIL_SWEEP_DURATION := 2.8
const FOIL_SWEEP_PAUSE := 1.1
const FOIL_INTENSITY := 0.28

const DIAMOND_ART_MODULATE := Color(1.04, 1.07, 1.14, 1.0)
const DIAMOND_GLOW_INTENSITY := 0.2
const DIAMOND_SPARKLE_INTENSITY := 0.32

const NEGATIVE_PULSE_DURATION := 3.6
const NEGATIVE_EDGE_STRENGTH := 0.12
const NEGATIVE_ART_BRIGHTNESS := 1.02

## One warning per missing key per session.
static var _missing_frame_warned: Dictionary = {}
static var _missing_card_back_warned: Dictionary = {}

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


## Future: variant overlay textures under assets/variants/<name>.png.
static func get_variant_texture(variant: String) -> Texture2D:
	return _load_cached_texture(
		_variant_texture_cache,
		VARIANTS_ROOT,
		variant.to_lower(),
		false
	)


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


## Future: rarity glow textures under assets/glows/<rarity>.png.
static func get_glow_texture(rarity: String) -> Texture2D:
	return _load_cached_texture(
		_glow_texture_cache,
		GLOWS_ROOT,
		rarity.to_lower(),
		false
	)


# ---------------------------------------------------------------------------
# Variant shader materials (polished procedural FX — no scene changes)
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


static func create_foil_shine_material() -> ShaderMaterial:
	var material := create_variant_material("foil_shine")
	if material:
		material.set_shader_parameter("intensity", FOIL_INTENSITY)
	return material


static func create_diamond_glow_material() -> ShaderMaterial:
	var material := create_variant_material("diamond_glow")
	if material:
		material.set_shader_parameter("intensity", DIAMOND_GLOW_INTENSITY)
		material.set_shader_parameter("time_scale", 0.85)
	return material


static func create_diamond_sparkle_material() -> ShaderMaterial:
	var material := create_variant_material("diamond_sparkle")
	if material:
		material.set_shader_parameter("intensity", DIAMOND_SPARKLE_INTENSITY)
		material.set_shader_parameter("time_scale", 1.05)
	return material


static func create_negative_invert_material() -> ShaderMaterial:
	var material := create_variant_material("negative_invert")
	if material:
		material.set_shader_parameter("brightness", NEGATIVE_ART_BRIGHTNESS)
	return material


static func create_negative_edge_material() -> ShaderMaterial:
	var material := create_variant_material("negative_edge")
	if material:
		material.set_shader_parameter("edge_strength", NEGATIVE_EDGE_STRENGTH)
	return material


static func make_foil_overlay_full_rect(foil_node: ColorRect) -> void:
	foil_node.set_anchors_preset(Control.PRESET_FULL_RECT)
	foil_node.offset_left = 0.0
	foil_node.offset_top = 0.0
	foil_node.offset_right = 0.0
	foil_node.offset_bottom = 0.0
	foil_node.mouse_filter = Control.MOUSE_FILTER_IGNORE


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
