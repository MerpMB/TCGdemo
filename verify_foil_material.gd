extends SceneTree
## Headless validation — production foil material across artwork, modes, and scales.

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


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not _validate_layer_blueprint():
		quit(1)
		return

	for fixture in ARTWORK_FIXTURES:
		for mode in MODES:
			for card_scale in SCALES:
				var ok := await _validate_spawn(fixture["id"], fixture["label"], mode, card_scale)
				if not ok:
					quit(1)
					return

	print("verify_foil_material: OK — %d fixtures × %d modes × %d scales"
		% [ARTWORK_FIXTURES.size(), MODES.size(), SCALES.size()])
	quit(0)


func _validate_layer_blueprint() -> bool:
	var layers: Array = CardVisualLibrary.get_variant_layers(CardData.Variant.FOIL)
	var ids: PackedStringArray = PackedStringArray()
	var depths: Dictionary = {}
	var responses: Dictionary = {}
	for layer in layers:
		ids.append(layer.layer_id)
		depths[layer.layer_id] = layer.depth
		responses[layer.layer_id] = layer.material_response

	print("foil_layers: count=%d ids=%s" % [layers.size(), ", ".join(ids)])

	if layers.size() < 5:
		push_error("Expected at least 5 foil layers, got %d." % layers.size())
		return false

	var expected_depths := {
		"micro_grain": 0.02,
		"foil_rainbow": 0.08,
		"large_shine": 0.15,
		"fine_glitter": 0.25,
		"tiny_sparkle": 0.35,
	}
	for layer_id in expected_depths.keys():
		if not depths.has(layer_id):
			push_error("Missing foil layer '%s'." % layer_id)
			return false
		if not is_equal_approx(float(depths[layer_id]), float(expected_depths[layer_id])):
			push_error(
				"Foil layer '%s' depth %.3f != expected %.3f."
				% [layer_id, depths[layer_id], expected_depths[layer_id]]
			)
			return false

	var idle_offset := Vector2(-CardVisualLibrary.PARALLAX_DISTANCE, 0.0)
	var grain_px := absf(idle_offset.x * float(depths["micro_grain"]))
	var rainbow_px := absf(idle_offset.x * float(depths["foil_rainbow"]))
	var sparkle_px := absf(idle_offset.x * float(depths["tiny_sparkle"]))
	print("foil_parallax_theory: grain=%.3f rainbow=%.3f sparkle=%.3f" % [grain_px, rainbow_px, sparkle_px])
	if sparkle_px <= rainbow_px or rainbow_px <= grain_px:
		push_error("Depth parallax ordering failed.")
		return false

	var glitter_eff := float(depths["fine_glitter"]) * float(responses["fine_glitter"])
	var sparkle_eff := float(depths["tiny_sparkle"]) * float(responses["tiny_sparkle"])
	print("foil_effective_motion: glitter=%.3f sparkle=%.3f" % [glitter_eff, sparkle_eff])
	if sparkle_eff > glitter_eff * 1.05:
		push_error("Sparkles float above glitter sheet — cohesion failed.")
		return false

	return true


func _validate_spawn(card_id: String, label: String, mode: CardScene.DisplayMode, card_scale: float) -> bool:
	var path := "res://resources/cards/core/%s.tres" % card_id
	var template := load(path) as CardData
	if template == null:
		push_error("Fixture card missing: %s" % path)
		return false

	var card := template.duplicate_card()
	card.variant = CardData.Variant.FOIL
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

	if container.get_child_count() < 5:
		push_error(
			"[%s mode=%d scale=%.2f] Expected 5+ layer nodes, got %d."
			% [label, mode, card_scale, container.get_child_count()]
		)
		scene.queue_free()
		return false

	var legacy_foil := scene.get_node_or_null("%FoilShine") as ColorRect
	if legacy_foil != null and legacy_foil.visible:
		push_error("[%s mode=%d scale=%.2f] Legacy FoilShine must stay hidden." % [label, mode, card_scale])
		scene.queue_free()
		return false

	scene.queue_free()
	return true
