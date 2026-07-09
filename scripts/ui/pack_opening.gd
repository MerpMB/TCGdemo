extends Control
## Pack opening — auto-opens on entry, reveal cards, return to menu.


enum FlowState {
	PACK_ANIMATING,
	CARDS_ARRIVING,
	REVEALING,
	DONE,
}


const CARD_SCENE := preload("res://scenes/Card.tscn")
const FALLBACK_PACK_SCENE := preload("res://scenes/Pack.tscn")

const GRID_COLUMNS := 4
const CARD_SIZE := Vector2(140, 200)
const CARD_SPACING := Vector2(16, 16)


@onready var _pack_anchor: CenterContainer = %PackAnchor
@onready var _play_area: Control = %PlayArea
@onready var _card_fly_layer: Control = %CardFlyLayer
@onready var _card_grid_area: Control = %CardGridArea
@onready var _skip_button: Button = %SkipButton
@onready var _continue_button: Button = %ContinueButton
@onready var _status_label: Label = %StatusLabel
@onready var _screen_flash: ColorRect = %ScreenFlash

var _state := FlowState.PACK_ANIMATING
var _pack_scene: PackScene
var _pack_cards: Array[CardData] = []
var _card_scenes: Array[CardScene] = []
var _revealed_count := 0
var _cards_added := false


func _ready() -> void:
	_screen_flash.z_index = 100
	_skip_button.pressed.connect(_on_skip_pressed)
	_continue_button.pressed.connect(_on_continue_pressed)
	_continue_button.hide()
	_skip_button.hide()
	_prepare_and_open()


func _prepare_and_open() -> void:
	_clear_cards()
	var pack_config := GameManager.get_selected_pack()
	if pack_config == null:
		_status_label.text = "No pack available."
		return

	_pack_cards = PackGenerator.generate_pack(CardDatabase, pack_config)
	_revealed_count = 0
	_cards_added = false
	_spawn_pack_visual()
	_pack_anchor.show()
	_pack_anchor.custom_minimum_size = Vector2(0, 280)
	_play_area.hide()
	_status_label.text = "Opening your pack..."
	call_deferred("_run_opening_sequence")


func _spawn_pack_visual() -> void:
	_clear_pack_visual()
	var pack_config := GameManager.get_selected_pack()
	if pack_config == null:
		return

	var pack_packed: PackedScene = pack_config.pack_scene if pack_config.pack_scene else FALLBACK_PACK_SCENE
	_pack_scene = pack_packed.instantiate() as PackScene
	_pack_anchor.add_child(_pack_scene)
	_pack_scene.setup_profile(
		pack_config.pack_id,
		pack_config.primary_color,
		pack_config.accent_color
	)


func _clear_pack_visual() -> void:
	if _pack_scene and is_instance_valid(_pack_scene):
		_pack_scene.queue_free()
	_pack_scene = null


func _run_opening_sequence() -> void:
	_state = FlowState.PACK_ANIMATING
	await _run_pack_sequence()
	await _launch_cards_into_grid()
	_state = FlowState.REVEALING
	_enable_card_reveals()
	_status_label.text = "Tap each card to reveal (%d / %d)" % [_revealed_count, _pack_cards.size()]


func _run_pack_sequence() -> void:
	if _pack_scene == null:
		return

	_pack_scene.shake()
	await _pack_scene.shake_finished
	_pack_scene.open()
	await _pack_scene.open_finished
	_pack_scene.explode()
	await _pack_scene.explode_finished
	_clear_pack_visual()
	_pack_anchor.custom_minimum_size = Vector2.ZERO


func _launch_cards_into_grid() -> void:
	_state = FlowState.CARDS_ARRIVING
	_play_area.show()
	await get_tree().process_frame

	var burst_origin := _pack_anchor.global_position + _pack_anchor.size * 0.5
	var slot_positions := _calculate_slot_positions(_pack_cards.size())

	for index in _pack_cards.size():
		var card_scene := CARD_SCENE.instantiate() as CardScene
		card_scene.flipped.connect(_on_card_flipped)
		_card_fly_layer.add_child(card_scene)
		card_scene.setup(_pack_cards[index], CardScene.DisplayMode.PACK)
		card_scene.set_pack_reveal_enabled(false)
		_card_scenes.append(card_scene)
		await card_scene.await_arrival(burst_origin, slot_positions[index])


func _calculate_slot_positions(count: int) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var area_origin := _card_grid_area.global_position
	var area_size := _card_grid_area.size

	for index in count:
		var row := int(index / GRID_COLUMNS)
		var col := index % GRID_COLUMNS
		var cards_in_row := mini(GRID_COLUMNS, count - row * GRID_COLUMNS)
		var row_width := cards_in_row * CARD_SIZE.x + (cards_in_row - 1) * CARD_SPACING.x
		var x_offset := (area_size.x - row_width) * 0.5
		var local_center := Vector2(
			x_offset + col * (CARD_SIZE.x + CARD_SPACING.x) + CARD_SIZE.x * 0.5,
			row * (CARD_SIZE.y + CARD_SPACING.y) + CARD_SIZE.y * 0.5
		)
		positions.append(area_origin + local_center)

	return positions


func _enable_card_reveals() -> void:
	_skip_button.show()
	_skip_button.disabled = false
	for card_scene in _card_scenes:
		card_scene.set_pack_reveal_enabled(true)


func _on_card_flipped(_card_scene: CardScene) -> void:
	_revealed_count += 1
	_status_label.text = "Tap each card to reveal (%d / %d)" % [_revealed_count, _pack_cards.size()]

	var card_data := _card_scene.get_card_data()
	if card_data and card_data.rarity == CardData.Rarity.LEGENDARY:
		_play_legendary_flash()

	if _revealed_count >= _pack_cards.size():
		_finish_pack()


func _play_legendary_flash() -> void:
	_screen_flash.color = Color(0.95, 0.78, 0.18, 0.0)
	_screen_flash.show()
	var tween := create_tween()
	tween.tween_property(_screen_flash, "color:a", 0.35, 0.08)
	tween.tween_property(_screen_flash, "color:a", 0.0, 0.22)
	await tween.finished
	_screen_flash.hide()


func _finish_pack() -> void:
	if _state == FlowState.DONE:
		return

	_state = FlowState.DONE
	_skip_button.hide()

	if not _cards_added:
		CollectionManager.add_cards(_pack_cards)
		_cards_added = true

	_status_label.text = "%d cards added to your collection!" % _pack_cards.size()
	_continue_button.show()


func _on_skip_pressed() -> void:
	if _state != FlowState.REVEALING:
		return

	_skip_button.disabled = true
	for card_scene in _card_scenes:
		if not card_scene.is_revealed():
			card_scene.reveal_instant()


func _on_continue_pressed() -> void:
	GameManager.go_to_main_menu()


func _clear_cards() -> void:
	for card_scene in _card_scenes:
		if is_instance_valid(card_scene):
			card_scene.flipped.disconnect(_on_card_flipped)
			card_scene.queue_free()
	_card_scenes.clear()
	_pack_cards.clear()
