class_name CardVisualLibrary
extends RefCounted
## VisualLibrary facade — asset paths, frame/back/art loading, and variant entry points.
## Variant FX live in FoilMaterials / SynthMaterials / DiamondMaterials / NegativeMaterials.
## UI scripts call this class only — they never hardcode res://assets/... paths.

const _VariantLayer := preload("res://scripts/ui/variant_layer.gd")
const _FoilMaterials := preload("res://scripts/ui/foil_materials.gd")
const _SynthMaterials := preload("res://scripts/ui/synth_materials.gd")
const _DiamondMaterials := preload("res://scripts/ui/diamond_materials.gd")
const _NegativeMaterials := preload("res://scripts/ui/negative_materials.gd")
const _VariantShaderCache := preload("res://scripts/ui/variant_shader_cache.gd")


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

## Per-variant layer blueprints — aggregated from Foil/Synth/Diamond/Negative modules.
## Renderer consumes materialized VariantLayer instances only.
static var VARIANT_LAYER_BLUEPRINTS: Dictionary:
	get:
		return {
			CardData.Variant.FOIL: _FoilMaterials.get_blueprints(),
			CardData.Variant.SYNTH: _SynthMaterials.get_blueprints(),
			CardData.Variant.DIAMOND: _DiamondMaterials.get_blueprints(),
			CardData.Variant.NEGATIVE: _NegativeMaterials.get_blueprints(),
		}

## Texture caches (null misses included) so grid/gallery never hits disk twice.
static var _frame_texture_cache: Dictionary = {}
static var _artwork_texture_cache: Dictionary = {}
static var _variant_texture_cache: Dictionary = {}
static var _card_back_texture_cache: Dictionary = {}
static var _glow_texture_cache: Dictionary = {}
## True after warmup() has filled caches (shaders, procedural maps, frames, art).
static var _warmup_complete := false

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


## Resolve frame folder key from CardData.frame or rarity — presentation only.
static func resolve_frame_key(card: CardData) -> String:
	if card == null:
		return "common"
	if not card.frame.is_empty():
		return card.frame.to_lower()
	return FRAME_KEYS.get(card.rarity, "common")


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


## Optional / dev-only asset check. Not called during CardDatabase registration.
## Placeholder cards with null artwork are valid — convention path resolves at render time.
static func validate_card_assets(card: CardData) -> void:
	if card == null or card.card_id.is_empty():
		return
	if card.artwork != null:
		return


## Whether startup warmup has already filled visual caches.
static func is_warmup_complete() -> bool:
	return _warmup_complete


## Load shaders, procedural textures, Synth topology, frames, backs, glows, and
## catalog artwork at game start so pack opening does not hitch on first use.
## Pass CardDatabase (or any node with get_all_cards()) to prefetch card art.
## Returns ShaderMaterials the caller should draw once to force GPU compile.
static func warmup(catalog: Node = null) -> Array[ShaderMaterial]:
	if _warmup_complete:
		return _build_warmup_materials()

	var started_msec := Time.get_ticks_msec()

	_warmup_frames_and_backs()
	_warmup_glows()
	_warmup_procedural_textures()
	_warmup_synth_topology()
	var materials := _build_warmup_materials()
	_warmup_variant_layer_stacks()
	if catalog != null and catalog.has_method("get_all_cards"):
		_warmup_catalog_artwork(catalog)

	_warmup_complete = true
	var elapsed := Time.get_ticks_msec() - started_msec
	print(
		"CardVisualLibrary: warmup complete in %d ms (%d shaders cached, %d compile materials)."
		% [elapsed, _VariantShaderCache.cached_count(), materials.size()]
	)
	return materials


static func _warmup_frames_and_backs() -> void:
	for rarity in FRAME_KEYS.keys():
		get_frame_texture(FRAME_KEYS[rarity])
	## Only the default back is guaranteed; named backs load on demand.
	get_card_back_texture(DEFAULT_CARD_BACK)


static func _warmup_glows() -> void:
	for rarity in FRAME_KEYS.keys():
		get_glow_texture_for_rarity(rarity)


static func _warmup_procedural_textures() -> void:
	for procedural_key in [
		"foil_grain",
		"foil_glitter",
		"foil_sparkle",
		"synth_micro_circuit",
		"synth_junction_pads",
	]:
		_get_procedural_variant_texture(procedural_key)


static func _warmup_synth_topology() -> void:
	## Forces the 512×720 board/flow/pads bake once at startup.
	_SynthMaterials.warmup_topology()


static func _build_warmup_materials() -> Array[ShaderMaterial]:
	## Create one configured material per production shader so GPU compile can run offscreen.
	var materials: Array[ShaderMaterial] = []
	var candidates: Array = [
		create_foil_rainbow_material(),
		create_foil_soft_shine_material(),
		create_synth_pcb_board_material(),
		create_synth_fiber_traffic_material(),
		create_synth_fiber_deep_material(),
		create_diamond_facets_material(),
		create_diamond_reflection_material(),
		create_diamond_refraction_material(),
		create_diamond_dispersion_material(),
		create_diamond_sparkle_material(),
		create_negative_invert_material(),
		create_negative_edge_material(),
	]
	for material in candidates:
		if material is ShaderMaterial:
			materials.append(material as ShaderMaterial)
	return materials


static func _warmup_variant_layer_stacks() -> void:
	## Only variants whose layers are shader/procedural-backed (no missing-PNG spam).
	for variant in [
		CardData.Variant.FOIL,
		CardData.Variant.DIAMOND,
		CardData.Variant.SYNTH,
	]:
		get_variant_layers(variant)


static func _warmup_catalog_artwork(catalog: Node) -> void:
	var cards: Array = catalog.get_all_cards()
	for card in cards:
		if card is CardData:
			resolve_artwork(card as CardData)


## Variant FX — factories live in Foil/Synth/Diamond/Negative modules; CVL is the facade.


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
# Variant shader materials — facade over Foil/Synth/Diamond/Negative modules
# ---------------------------------------------------------------------------

static func create_variant_material(shader_name: String) -> ShaderMaterial:
	return _VariantShaderCache.create(shader_name)


static func create_foil_rainbow_material() -> ShaderMaterial:
	return _FoilMaterials.create_rainbow_material()


static func create_foil_soft_shine_material() -> ShaderMaterial:
	return _FoilMaterials.create_soft_shine_material()


static func create_synth_pcb_board_material() -> ShaderMaterial:
	return _SynthMaterials.create_pcb_board_material()


static func create_synth_fiber_traffic_material() -> ShaderMaterial:
	return _SynthMaterials.create_fiber_traffic_material()


static func create_synth_fiber_deep_material() -> ShaderMaterial:
	return _SynthMaterials.create_fiber_deep_material()


## Compat aliases for older validation / tooling names.
static func create_synth_circuit_traces_material() -> ShaderMaterial:
	return create_synth_pcb_board_material()


static func create_synth_data_stream_material() -> ShaderMaterial:
	return create_synth_fiber_traffic_material()


static func create_synth_energy_pulse_material() -> ShaderMaterial:
	return create_synth_fiber_deep_material()


static func create_diamond_facets_material() -> ShaderMaterial:
	return _DiamondMaterials.create_facets_material()


static func create_diamond_reflection_material() -> ShaderMaterial:
	return _DiamondMaterials.create_reflection_material()


static func create_diamond_refraction_material() -> ShaderMaterial:
	return _DiamondMaterials.create_refraction_material()


static func create_diamond_dispersion_material() -> ShaderMaterial:
	return _DiamondMaterials.create_dispersion_material()


static func create_diamond_sparkle_material() -> ShaderMaterial:
	return _DiamondMaterials.create_sparkle_material()


## Legacy aliases — retired glow layer maps to internal reflection.
static func create_diamond_glow_material() -> ShaderMaterial:
	return create_diamond_reflection_material()


static func create_negative_invert_material() -> ShaderMaterial:
	return _NegativeMaterials.create_invert_material()


static func create_negative_edge_material() -> ShaderMaterial:
	return _NegativeMaterials.create_edge_material()


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
	var material := _FoilMaterials.create_named_shader_material(shader_key)
	if material:
		return material
	material = _SynthMaterials.create_named_shader_material(shader_key)
	if material:
		return material
	material = _DiamondMaterials.create_named_shader_material(shader_key)
	if material:
		return material
	material = _NegativeMaterials.create_named_shader_material(shader_key)
	if material:
		return material
	return create_variant_material(shader_key)


static func _get_procedural_variant_texture(procedural_key: String) -> Texture2D:
	var cache_key := "proc_%s" % procedural_key
	if _variant_texture_cache.has(cache_key):
		return _variant_texture_cache[cache_key]

	var texture: Texture2D = _FoilMaterials.build_procedural_texture(procedural_key)
	if texture == null:
		texture = _SynthMaterials.build_procedural_texture(procedural_key)
	if texture == null:
		push_warning("CardVisualLibrary: unknown procedural texture '%s'." % procedural_key)

	_variant_texture_cache[cache_key] = texture
	return texture


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
