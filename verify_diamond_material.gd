extends SceneTree
## Headless validation — Diamond V1 crystal MATERIAL hierarchy.

const CARD_SCENE := preload("res://scenes/Card.tscn")

const ARTWORK_FIXTURES := [
	{"id": "common_001", "label": "busy_art"},
	{"id": "legendary_001", "label": "bright_art"},
	{"id": "common_006", "label": "minimal_art"},
]

const MODES := [
	CardScene.DisplayMode.PACK,
	CardScene.DisplayMode.GALLERY,
	CardScene.DisplayMode.PREVIEW,
]

const SCALES := [0.55, 1.0]

const EXPECTED_DEPTHS := {
	"crystal_plate": 0.05,
	"facet_specular": 0.12,
	"dispersion_peaks": 0.16,
	"optical_sparkle": 0.22,
}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not _validate_layer_blueprint():
		quit(1)
		return

	if not _validate_materials():
		quit(1)
		return

	for fixture in ARTWORK_FIXTURES:
		for mode in MODES:
			for card_scale in SCALES:
				var ok := await _validate_spawn(fixture["id"], fixture["label"], mode, card_scale)
				if not ok:
					quit(1)
					return

	print(
		"verify_diamond_material: OK — Diamond V1 material, %d fixtures × %d modes × %d scales"
		% [ARTWORK_FIXTURES.size(), MODES.size(), SCALES.size()]
	)
	quit(0)


func _validate_layer_blueprint() -> bool:
	var layers: Array = CardVisualLibrary.get_variant_layers(CardData.Variant.DIAMOND)
	var ids: PackedStringArray = PackedStringArray()
	var depths: Dictionary = {}
	for layer in layers:
		ids.append(layer.layer_id)
		depths[layer.layer_id] = layer.depth

	print("diamond_layers: count=%d ids=%s" % [layers.size(), ", ".join(ids)])

	if layers.size() < 4:
		push_error("Expected at least 4 diamond layers, got %d." % layers.size())
		return false

	for layer_id in EXPECTED_DEPTHS.keys():
		if not depths.has(layer_id):
			push_error("Missing diamond layer '%s'." % layer_id)
			return false
		if not is_equal_approx(float(depths[layer_id]), float(EXPECTED_DEPTHS[layer_id])):
			push_error(
				"Diamond layer '%s' depth %.3f != expected %.3f."
				% [layer_id, depths[layer_id], EXPECTED_DEPTHS[layer_id]]
			)
			return false

	if float(depths["crystal_plate"]) >= float(depths["facet_specular"]):
		push_error("Crystal plate depth must be below facet specular.")
		return false
	if float(depths["facet_specular"]) >= float(depths["dispersion_peaks"]):
		push_error("Facet specular depth must be below dispersion.")
		return false
	if float(depths["dispersion_peaks"]) >= float(depths["optical_sparkle"]):
		push_error("Dispersion depth must be below optical sparkle.")
		return false

	return true


func _validate_materials() -> bool:
	var plate := CardVisualLibrary.create_diamond_facets_material()
	var specular := CardVisualLibrary.create_diamond_reflection_material()
	var refraction := CardVisualLibrary.create_diamond_refraction_material()
	var dispersion := CardVisualLibrary.create_diamond_dispersion_material()
	var sparkle := CardVisualLibrary.create_diamond_sparkle_material()
	if plate == null or specular == null or refraction == null or dispersion == null or sparkle == null:
		push_error("Diamond V1 materials failed to build.")
		return false

	# Confetti film: seams stay at zero (boundaries from color only).
	var seam := float(plate.get_shader_parameter("seam_strength"))
	if seam > 0.01:
		push_error("Diamond seam_strength must stay ~0 for confetti foil (got %.3f)." % seam)
		return false

	var plate_s := float(plate.get_shader_parameter("plate_strength"))
	var refl_s := float(specular.get_shader_parameter("reflection_strength"))
	if refl_s <= plate_s:
		push_error("Facet specular must dominate plate strength (material hierarchy).")
		return false

	if float(refraction.get_shader_parameter("warp_strength")) > 0.0001:
		push_error("Diamond warp_strength must be 0 (no art distortion).")
		return false

	var disp_time := float(dispersion.get_shader_parameter("time_scale"))
	if disp_time > 0.08:
		push_error("Diamond dispersion time_scale too high (%.3f)." % disp_time)
		return false

	return true


func _validate_spawn(card_id: String, label: String, mode: CardScene.DisplayMode, card_scale: float) -> bool:
	var path := "res://resources/cards/core/%s.tres" % card_id
	var template := load(path) as CardData
	if template == null:
		push_error("Fixture card missing: %s" % path)
		return false

	var card := template.duplicate_card()
	card.variant = CardData.Variant.DIAMOND
	var scene := CARD_SCENE.instantiate() as CardScene
	root.add_child(scene)
	scene.scale = Vector2.ONE * card_scale
	scene.setup(card, mode)

	for _i in 6:
		await process_frame

	var container := scene.get_node_or_null("%RenderLayerContainer") as Control
	if container == null:
		push_error("[%s mode=%d scale=%.2f] RenderLayerContainer missing" % [label, mode, card_scale])
		scene.queue_free()
		return false

	if container.get_child_count() < 4:
		push_error(
			"[%s mode=%d scale=%.2f] Expected 4+ diamond layer nodes, got %d."
			% [label, mode, card_scale, container.get_child_count()]
		)
		scene.queue_free()
		return false

	var art := scene.get_node_or_null("%ArtTexture") as TextureRect
	if art != null and art.material != null:
		push_error("[%s mode=%d scale=%.2f] Diamond must not distort artwork." % [label, mode, card_scale])
		scene.queue_free()
		return false

	var legacy_glow := scene.get_node_or_null("%DiamondGlow") as CanvasItem
	var legacy_icon := scene.get_node_or_null("%DiamondIcon") as CanvasItem
	if legacy_glow != null and legacy_glow.visible:
		push_error("[%s] Legacy DiamondGlow must be hidden." % label)
		scene.queue_free()
		return false
	if legacy_icon != null and legacy_icon.visible:
		push_error("[%s] Legacy DiamondIcon must be hidden." % label)
		scene.queue_free()
		return false

	scene.queue_free()
	return true
