extends SceneTree

## Temporary visual QA harness: renders each supported variant side-by-side.

const CARD_SCENE := preload("res://scenes/Card.tscn")
const TEMPLATE_CARD := preload("res://resources/cards/mage/mage_rookie_fire_mage.tres")
const OUTPUT_PATH := "C:/tmp/tcgdemo_variant_visual_harness.png"
const CARD_SIZE := Vector2(240, 343)

const VARIANTS := [
	CardData.Variant.NORMAL,
	CardData.Variant.FOIL,
	CardData.Variant.NEGATIVE,
	CardData.Variant.ALTERNATIVE_ART,
	CardData.Variant.DIAMOND,
	CardData.Variant.SYNTH,
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1440, 960)
	var canvas := Control.new()
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(canvas)

	var background := ColorRect.new()
	background.color = Color("11151f")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(background)

	_add_label(canvas, "Variant Visual Harness", Vector2(52, 26), 32, Color("f3f5f8"))
	_add_label(canvas, "Rookie Fire Mage • Gallery presentation", Vector2(54, 68), 17, Color("9ea8b8"))

	for index in VARIANTS.size():
		var card_data := TEMPLATE_CARD.duplicate_card()
		card_data.variant = VARIANTS[index]
		var card := CARD_SCENE.instantiate() as CardScene
		card.size = CARD_SIZE
		card.position = Vector2(90 + (index % 3) * 470, 140 + (index / 3) * 410)
		canvas.add_child(card)
		card.setup(card_data, CardScene.DisplayMode.GALLERY)
		_add_label(canvas, CardData.get_variant_label(card_data.variant), card.position + Vector2(0, CARD_SIZE.y + 14), 21, Color("f3f5f8"))

	await create_timer(4.0).timeout
	var image := root.get_texture().get_image()
	var result := image.save_png(OUTPUT_PATH)
	if result != OK:
		push_error("verify_variant_visual_harness: failed to save image (%s)." % result)
		quit(1)
		return
	print("verify_variant_visual_harness: wrote %s" % OUTPUT_PATH)
	quit(0)


func _add_label(parent: Control, value: String, location: Vector2, font_size: int, color: Color) -> void:
	var label := Label.new()
	label.text = value
	label.position = location
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
