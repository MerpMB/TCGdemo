extends CanvasLayer
## Stage 1 premium card display. Card rendering remains entirely in CardScene.

const CARD_SCENE := preload("res://scenes/Card.tscn")
const CARD_BASE_SIZE := Vector2(140, 200)
const OPEN_DURATION := 0.36

@onready var _dimmer: ColorRect = %Dimmer
@onready var _shadow: ColorRect = %CardShadow
@onready var _holder: CenterContainer = %CardHolder
@onready var _info: VBoxContainer = %Info
@onready var _name_label: Label = %NameLabel
@onready var _details_label: Label = %DetailsLabel
@onready var _artist_label: Label = %ArtistLabel
@onready var _flavor_label: Label = %FlavorLabel
@onready var _favorite_button: Button = %FavoriteButton
@onready var _previous_button: Button = %PreviousButton
@onready var _next_button: Button = %NextButton
@onready var _back_button: Button = %BackButton

var _cards: Array[CardData] = []
var _index := 0
var _card_scene: CardScene
var _tween: Tween
var _presentation_scale := 1.0

func _ready() -> void:
	_dimmer.gui_input.connect(_on_dimmer_gui_input)
	_back_button.pressed.connect(hide_inspection)
	_previous_button.pressed.connect(func(): _navigate(-1))
	_next_button.pressed.connect(func(): _navigate(1))
	_favorite_button.pressed.connect(_toggle_favorite)
	_info.modulate.a = 0.0

func is_modal_active() -> bool:
	return visible


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouse or event is InputEventScreenTouch or event is InputEventScreenDrag:
		return
	if event.is_action_pressed("ui_cancel"):
		hide_inspection()
	elif event.is_action_pressed("ui_left"):
		_navigate(-1)
	elif event.is_action_pressed("ui_right"):
		_navigate(1)
	get_viewport().set_input_as_handled()


func _on_dimmer_gui_input(_event: InputEvent) -> void:
	## The full-screen Dimmer is the modal pointer shield behind all inspector controls.
	_dimmer.accept_event()

func _process(delta: float) -> void:
	if not visible: return
	var mouse_x := get_viewport().get_mouse_position().x
	var width := get_viewport().get_visible_rect().size.x
	_previous_button.modulate.a = move_toward(_previous_button.modulate.a, 1.0 if mouse_x < 92.0 else 0.22, delta * 4.0)
	_next_button.modulate.a = move_toward(_next_button.modulate.a, 1.0 if mouse_x > width - 92.0 else 0.22, delta * 4.0)

func show_cards(cards: Array[CardData], selected_index: int) -> void:
	_cards = cards.duplicate()
	if _cards.is_empty(): return
	visible = true
	_presentation_scale = _target_scale()
	_show_index(clampi(selected_index, 0, _cards.size() - 1))
	_dimmer.color.a = 0.0
	_shadow.modulate.a = 0.0
	_info.modulate.a = 0.0
	_card_scene.scale = Vector2.ONE * (_presentation_scale * 0.82)
	_card_scene.modulate.a = 0.0
	_kill_tween()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(_dimmer, "color:a", 0.92, OPEN_DURATION)
	_tween.tween_property(_shadow, "modulate:a", 1.0, OPEN_DURATION)
	_tween.tween_property(_card_scene, "modulate:a", 1.0, OPEN_DURATION * 0.72)
	_tween.tween_property(_card_scene, "scale", Vector2.ONE * _presentation_scale, OPEN_DURATION).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_info, "modulate:a", 1.0, 0.22).set_delay(0.18)

func hide_inspection() -> void:
	_kill_tween()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(_info, "modulate:a", 0.0, 0.12)
	_tween.tween_property(_dimmer, "color:a", 0.0, 0.24)
	_tween.tween_property(_shadow, "modulate:a", 0.0, 0.18)
	if _card_scene:
		_tween.tween_property(_card_scene, "modulate:a", 0.0, 0.16)
		_tween.tween_property(_card_scene, "scale", Vector2.ONE * (_presentation_scale * 0.86), 0.24)
	await _tween.finished
	visible = false

func _navigate(direction: int) -> void:
	var next_index := clampi(_index + direction, 0, _cards.size() - 1)
	if next_index == _index:
		return
	_kill_tween()
	_tween = create_tween()
	_tween.tween_property(_card_scene, "modulate:a", 0.0, 0.10)
	await _tween.finished
	_show_index(next_index)
	_card_scene.modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(_card_scene, "modulate:a", 1.0, 0.14)

func _show_index(index: int) -> void:
	_index = clampi(index, 0, _cards.size() - 1)
	if _card_scene == null:
		_card_scene = CARD_SCENE.instantiate()
		_card_scene.custom_minimum_size = CARD_BASE_SIZE
		_holder.add_child(_card_scene)
	var card := _cards[_index]
	_card_scene.setup(card, CardScene.DisplayMode.PREVIEW)
	_card_scene.pivot_offset = CARD_BASE_SIZE * 0.5
	_card_scene.scale = Vector2.ONE * _presentation_scale
	call_deferred("_restore_presentation_scale")
	_name_label.text = card.display_name
	_details_label.text = "%s  •  %s  •  %s" % [card.card_set, CardData.get_rarity_label(card.rarity), CardData.get_variant_label(card.variant)]
	_artist_label.text = "Artist: %s" % (card.artist if not card.artist.is_empty() else "Unknown")
	_flavor_label.text = card.flavor_text
	_favorite_button.text = "★ Favorited" if card.is_favorite else "☆ Favorite"
	_previous_button.disabled = _index == 0
	_next_button.disabled = _index == _cards.size() - 1

func _toggle_favorite() -> void:
	var card := _cards[_index]
	var collection_manager := get_node_or_null("/root/CollectionManager")
	var save_manager := get_node_or_null("/root/SaveManager")
	if collection_manager and collection_manager.set_card_favorite(card.instance_id, not card.is_favorite):
		if save_manager:
			save_manager.save_game()
		_show_index(_index)

func _restore_presentation_scale() -> void:
	if _card_scene and visible:
		_card_scene.scale = Vector2.ONE * _presentation_scale


func _target_scale() -> float:
	var viewport := get_viewport().get_visible_rect().size
	return maxf(1.3, minf((viewport.x * 0.78) / CARD_BASE_SIZE.x, (viewport.y * 0.70) / CARD_BASE_SIZE.y))

func _kill_tween() -> void:
	if _tween and _tween.is_valid(): _tween.kill()