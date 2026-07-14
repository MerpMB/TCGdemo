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

const BASE_CARD_SIZE := Vector2(140, 200)
const GRID_COLUMNS := 4
const GRID_SPACING := 12.0
const INNER_PADDING := 8.0
## Extra reserved space so the grid never overlaps the header/footer.
const HEADER_GAP := 20.0
const FOOTER_GAP := 16.0


@onready var _pack_anchor: CenterContainer = %PackAnchor
@onready var _play_area: Control = %PlayArea
@onready var _card_fly_layer: Control = %CardFlyLayer
@onready var _footer: VBoxContainer = %Footer
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
var _layout_scale := 1.0


func _ready() -> void:
	_screen_flash.z_index = 100
	_skip_button.pressed.connect(_on_skip_pressed)
	_continue_button.pressed.connect(_on_continue_pressed)
	_continue_button.hide()
	_skip_button.hide()
	resized.connect(_on_viewport_resized)
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
	_show_pack_stage()
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


func _show_pack_stage() -> void:
	_pack_anchor.show()
	_pack_anchor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_play_area.hide()
	_play_area.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_footer.hide()


func _show_card_stage() -> void:
	_pack_anchor.hide()
	_pack_anchor.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_play_area.show()
	_play_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_footer.show()


func _launch_cards_into_grid() -> void:
	_state = FlowState.CARDS_ARRIVING
	_show_card_stage()
	await _await_layout_ready()

	var burst_origin := _get_pack_burst_origin()
	var layout := _compute_card_layout(_pack_cards.size())
	_layout_scale = layout.card_scale
	var slot_centers: Array[Vector2] = layout.centers

	for index in _pack_cards.size():
		var card_scene := CARD_SCENE.instantiate() as CardScene
		card_scene.flipped.connect(_on_card_flipped)
		_card_fly_layer.add_child(card_scene)
		card_scene.setup(_pack_cards[index], CardScene.DisplayMode.PACK)
		_prepare_card_for_layout(card_scene, _layout_scale)
		card_scene.set_pack_reveal_enabled(false)
		_card_scenes.append(card_scene)
		var global_center := _card_fly_layer.global_position + slot_centers[index]
		await card_scene.await_arrival(burst_origin, global_center)
		_apply_card_slot_position(card_scene, slot_centers[index], _layout_scale)


func _get_pack_burst_origin() -> Vector2:
	if _pack_anchor.visible:
		return _pack_anchor.global_position + _pack_anchor.size * 0.5
	return _play_area.get_global_rect().get_center()


func _await_layout_ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame


## Playable grid rect = the fly layer (already sized by the container to the
## space between header and footer) minus safe margins plus extra header/footer
## breathing room. The grid is centered inside whatever remains.
func _get_usable_card_area() -> Rect2:
	var rect := _card_fly_layer.get_rect()
	rect.position.x += INNER_PADDING
	rect.position.y += HEADER_GAP
	rect.size.x -= INNER_PADDING * 2.0
	rect.size.y -= (HEADER_GAP + FOOTER_GAP)
	rect.size.x = maxf(rect.size.x, 0.0)
	rect.size.y = maxf(rect.size.y, 0.0)
	return rect


func _scaled_card_size(card_scale: float) -> Vector2:
	return BASE_CARD_SIZE * card_scale


func _scaled_card_half_size(card_scale: float) -> Vector2:
	return _scaled_card_size(card_scale) * 0.5


func _measure_grid_size(columns: int, rows: int, card_size: Vector2) -> Vector2:
	return Vector2(
		columns * card_size.x + (columns - 1) * GRID_SPACING,
		rows * card_size.y + (rows - 1) * GRID_SPACING,
	)


func _resolve_card_scale(columns: int, rows: int, available: Rect2) -> float:
	var full_grid_size := _measure_grid_size(columns, rows, BASE_CARD_SIZE)
	if full_grid_size.x <= available.size.x and full_grid_size.y <= available.size.y:
		return 1.0

	var scale_x := available.size.x / full_grid_size.x if full_grid_size.x > 0.0 else 1.0
	var scale_y := available.size.y / full_grid_size.y if full_grid_size.y > 0.0 else 1.0
	return minf(minf(scale_x, scale_y), 1.0)


func _prepare_card_for_layout(card_scene: CardScene, card_scale: float) -> void:
	card_scene.custom_minimum_size = BASE_CARD_SIZE
	card_scene.size = BASE_CARD_SIZE
	card_scene.prepare_layout_scale(card_scale)


func _apply_card_slot_position(card_scene: CardScene, center_local: Vector2, card_scale: float) -> void:
	_prepare_card_for_layout(card_scene, card_scale)
	card_scene.position = center_local - _scaled_card_half_size(card_scale)
	card_scene.scale = Vector2.ONE * card_scale


func _calculate_slot_positions(count: int) -> Array[Vector2]:
	var layout := _compute_card_layout(count)
	_layout_scale = layout.card_scale
	return layout.centers


func _compute_card_layout(count: int) -> Dictionary:
	var available := _get_usable_card_area()
	var columns := _resolve_grid_columns(count, available.size.x)
	var rows := int(ceil(float(count) / float(columns)))

	var card_scale := _resolve_card_scale(columns, rows, available)
	var card_size := _scaled_card_size(card_scale)
	var grid_size := _measure_grid_size(columns, rows, card_size)

	var origin := available.position + (available.size - grid_size) * 0.5
	origin.x = clampf(origin.x, available.position.x, maxf(available.position.x, available.position.x + available.size.x - grid_size.x))
	origin.y = maxf(origin.y, available.position.y)

	var centers: Array[Vector2] = []

	for index in count:
		var row := int(index / columns)
		var col := index % columns
		var cards_in_row := mini(columns, count - row * columns)
		var row_width := cards_in_row * card_size.x + (cards_in_row - 1) * GRID_SPACING
		var row_offset_x := (grid_size.x - row_width) * 0.5
		var center := origin + Vector2(
			row_offset_x + col * (card_size.x + GRID_SPACING) + card_size.x * 0.5,
			row * (card_size.y + GRID_SPACING) + card_size.y * 0.5,
		)
		centers.append(center)

	return {
		"card_scale": card_scale,
		"centers": centers,
	}


func _resolve_grid_columns(count: int, available_width: float) -> int:
	var preferred := GRID_COLUMNS if count > GRID_COLUMNS else count
	var max_fit := int((available_width + GRID_SPACING) / (BASE_CARD_SIZE.x + GRID_SPACING))
	return clampi(mini(preferred, max_fit), 1, count)


func _reposition_cards_in_grid() -> void:
	if _card_scenes.is_empty() or not _play_area.visible:
		return

	var centers := _calculate_slot_positions(_card_scenes.size())
	for index in _card_scenes.size():
		_apply_card_slot_position(_card_scenes[index], centers[index], _layout_scale)


func _on_viewport_resized() -> void:
	if _state == FlowState.CARDS_ARRIVING or _state == FlowState.REVEALING or _state == FlowState.DONE:
		_reposition_cards_in_grid()


func _enable_card_reveals() -> void:
	_skip_button.show()
	_skip_button.disabled = false
	for card_scene in _card_scenes:
		card_scene.set_pack_reveal_enabled(true)
	await _await_layout_ready()
	_reposition_cards_in_grid()


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
	await _await_layout_ready()
	_reposition_cards_in_grid()


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
