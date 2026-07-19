extends SceneTree
## Headless smoke test — every variant sets up CardScene without errors.

const CARD_SCENE := preload("res://scenes/Card.tscn")

const VARIANTS := [
	CardData.Variant.NORMAL,
	CardData.Variant.FOIL,
	CardData.Variant.NEGATIVE,
	CardData.Variant.ALTERNATIVE_ART,
	CardData.Variant.DIAMOND,
	CardData.Variant.SYNTH,
]

const MODES := [
	CardScene.DisplayMode.PACK,
	CardScene.DisplayMode.GALLERY,
	CardScene.DisplayMode.PREVIEW,
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var template := load("res://resources/cards/mage/mage_rookie_fire_mage.tres") as CardData
	if template == null:
		push_error("verify_variant_visuals: mage_rookie_fire_mage missing.")
		quit(1)
		return

	for variant in VARIANTS:
		for mode in MODES:
			var card := template.duplicate_card()
			card.variant = variant
			var scene := CARD_SCENE.instantiate() as CardScene
			root.add_child(scene)
			scene.setup(card, mode)
			scene.queue_free()

	print("verify_variant_visuals: OK — %d variants × %d modes" % [VARIANTS.size(), MODES.size()])
	quit(0)
