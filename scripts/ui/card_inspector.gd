extends CanvasLayer
## Popup inspector for a single owned card. Reads from CardData only.


const CARD_SCENE := preload("res://scenes/Card.tscn")


@onready var _dimmer: ColorRect = %Dimmer
@onready var _panel: PanelContainer = %Panel
@onready var _preview_slot: CenterContainer = %PreviewSlot
@onready var _name_label: Label = %NameLabel
@onready var _id_label: Label = %IdLabel
@onready var _rarity_label: Label = %RarityLabel
@onready var _variant_label: Label = %VariantLabel
@onready var _set_label: Label = %SetLabel
@onready var _description_label: Label = %DescriptionLabel
@onready var _close_button: Button = %CloseButton

var _preview_card: CardScene


func _ready() -> void:
	_close_button.pressed.connect(hide_inspector)
	_dimmer.gui_input.connect(_on_dimmer_input)
	_preview_card = CARD_SCENE.instantiate() as CardScene
	_preview_slot.add_child(_preview_card)
	hide_inspector()


func show_card(card_data: CardData) -> void:
	if card_data == null:
		return

	_preview_card.setup(card_data, CardScene.DisplayMode.PREVIEW)
	_name_label.text = card_data.display_name
	_id_label.text = "ID: %s" % card_data.card_id
	_rarity_label.text = "Rarity: %s" % CardData.get_rarity_label(card_data.rarity)
	_variant_label.text = "Variant: %s" % CardData.get_variant_label(card_data.variant)
	_set_label.text = "Set: %s" % card_data.card_set
	_description_label.text = card_data.description

	visible = true
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.92, 0.92)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_panel, "modulate:a", 1.0, 0.18)
	tween.tween_property(_panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)


func hide_inspector() -> void:
	visible = false


func _on_dimmer_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		hide_inspector()
