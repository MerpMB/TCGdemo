extends SceneTree
## Headless validation — Diamond generic Photoshop overlay.

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
		"verify_diamond_material: OK — static Photoshop overlay, %d fixtures × %d modes × %d scales"
		% [ARTWORK_FIXTURES.size(), MODES.size(), SCALES.size()]
	)
	quit(0)


func _validate_layer_blueprint() -> bool:
	var layers: Array = CardVisualLibrary.get_variant_layers(CardData.Variant.DIAMOND)
	print("diamond_static: texture_layer_count=%d" % layers.size())
	if layers.size() != 1 or layers[0].layer_id != "diamond_overlay":
		push_error("Diamond must expose exactly one generic Photoshop texture layer.")
		return false
	return true
func _validate_materials() -> bool:
	var overlay := CardVisualLibrary.get_variant_overlay_texture(CardData.Variant.DIAMOND)
	if overlay == null:
		push_error("Diamond Photoshop overlay texture failed to load.")
		return false
	if overlay.get_width() < 1000 or overlay.get_height() < 1400:
		push_error("Diamond overlay texture resolution is too small.")
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

	if container.get_child_count() != 1:
		push_error(
			"[%s mode=%d scale=%.2f] Expected exactly one Diamond texture layer, got %d."
			% [label, mode, card_scale, container.get_child_count()]
		)
		scene.queue_free()
		return false
	var art := scene.get_node_or_null("%ArtTexture") as TextureRect
	var body := scene.get_node_or_null("%CardBody") as ColorRect
	var frame_texture := scene.get_node_or_null("%FrameTexture") as TextureRect
	var frame_panel := scene.get_node_or_null("%FramePanel") as Control
	if (art != null and art.material != null) or (body != null and body.material != null):
		push_error("[%s mode=%d scale=%.2f] Diamond must not use a source shader." % [label, mode, card_scale])
		scene.queue_free()
		return false
	if (frame_texture != null and frame_texture.material != null) or (frame_panel != null and frame_panel.material != null):
		push_error("[%s mode=%d scale=%.2f] Diamond frame must remain unshaded." % [label, mode, card_scale])
		scene.queue_free()
		return false
	var overlay_root := container.get_child(0) as Control
	var overlay := overlay_root.get_node_or_null("Texture") as TextureRect if overlay_root != null else null
	if overlay == null or overlay.texture == null or not overlay.visible:
		push_error("[%s mode=%d scale=%.2f] Generic Diamond texture overlay missing." % [label, mode, card_scale])
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
