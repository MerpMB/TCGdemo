extends Control
## Issue 24.1 — Physical wrapper peel review flow.
## Opens a pack transactionally, then only runs the peel.
## No lighting, rarity shine, card release, or reveal (later issues).


enum FlowState {
	TEARING,
	DONE,
}


const FALLBACK_PACK_SCENE := preload("res://scenes/Pack.tscn")
const PACK_OPENING_DISPLAY_SCALE := 2.2
const PACK_HOST_SIZE := Vector2(440.0, 600.0)


@onready var _background: ColorRect = $Background
@onready var _pack_anchor: CenterContainer = %PackAnchor
@onready var _play_area: Control = %PlayArea
@onready var _release_layer: Control = %ReleaseLayer
@onready var _footer: VBoxContainer = %Footer
@onready var _skip_button: Button = %SkipButton
@onready var _reveal_all_button: Button = %RevealAllButton
@onready var _result_actions: HBoxContainer = %ResultActions
@onready var _exit_button: Button = %ExitButton
@onready var _continue_button: Button = %ContinueButton
@onready var _status_label: Label = %StatusLabel

var _state := FlowState.TEARING
var _pack_scene: PackScene
var _pack_host: Control
var _pack_cards: Array[CardData] = []
var _skip_requested := false


func _ready() -> void:
	if _background:
		_background.color = Color(0.07, 0.08, 0.10, 1.0)
	_skip_button.pressed.connect(_on_skip_pressed)
	_exit_button.pressed.connect(_on_exit_pressed)
	_continue_button.pressed.connect(_on_continue_pressed)
	_hide_result_actions()
	_skip_button.hide()
	_reveal_all_button.hide()
	_play_area.hide()
	_release_layer.hide()
	_footer.hide()
	_prepare_and_open()


func _prepare_and_open() -> void:
	_hide_result_actions()
	_skip_button.hide()
	_skip_button.disabled = false
	_reveal_all_button.hide()
	_skip_requested = false
	_state = FlowState.TEARING
	_pack_cards.clear()
	_show_pack_stage()

	var pack_config := GameManager.get_selected_pack()
	if pack_config == null:
		_status_label.text = "No pack available."
		_show_result_actions()
		return

	## Keep transactional open — cards are saved, but 24.1 does not release them visually.
	var open_result := OpenPackService.call("open_pack", pack_config.pack_id) as Dictionary
	if not open_result.succeeded:
		_status_label.text = open_result.message
		_show_result_actions()
		return

	_pack_cards = open_result.cards
	_spawn_pack_visual()
	_status_label.text = "24.1 Peel — drag across the top seam."
	_skip_button.show()
	call_deferred("_begin_manual_tear")


func _spawn_pack_visual() -> void:
	_clear_pack_visual()
	var pack_config := GameManager.get_selected_pack()
	if pack_config == null:
		return
	var pack_packed: PackedScene = (
		pack_config.pack_scene if pack_config.pack_scene else FALLBACK_PACK_SCENE
	)
	_pack_host = Control.new()
	_pack_host.name = "PackPresentationHost"
	_pack_host.custom_minimum_size = PACK_HOST_SIZE
	_pack_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pack_anchor.add_child(_pack_host)
	_pack_scene = pack_packed.instantiate() as PackScene
	_pack_host.add_child(_pack_scene)
	_pack_scene.setup_profile(
		pack_config.pack_id,
		pack_config.primary_color,
		pack_config.accent_color,
		pack_config.pack_art
	)
	_pack_scene.set_presentation_scale(PACK_OPENING_DISPLAY_SCALE)
	_pack_scene.position = (PACK_HOST_SIZE - Vector2(180, 250)) * 0.5
	_pack_scene.tear_completed.connect(_on_pack_torn)
	_pack_scene.tear_progress_changed.connect(_on_tear_progress_changed)
	call_deferred("_recenter_pack")


func _recenter_pack() -> void:
	if _pack_scene == null or not is_instance_valid(_pack_scene) or _pack_host == null:
		return
	_pack_scene.position = (PACK_HOST_SIZE - _pack_scene.size) * 0.5


func _clear_pack_visual() -> void:
	if _pack_scene and is_instance_valid(_pack_scene):
		if _pack_scene.tear_progress_changed.is_connected(_on_tear_progress_changed):
			_pack_scene.tear_progress_changed.disconnect(_on_tear_progress_changed)
		if _pack_scene.tear_completed.is_connected(_on_pack_torn):
			_pack_scene.tear_completed.disconnect(_on_pack_torn)
	if _pack_host and is_instance_valid(_pack_host):
		_pack_host.queue_free()
	elif _pack_scene and is_instance_valid(_pack_scene):
		_pack_scene.queue_free()
	_pack_host = null
	_pack_scene = null


func _begin_manual_tear() -> void:
	_state = FlowState.TEARING
	if _pack_scene == null or not is_instance_valid(_pack_scene):
		return
	_recenter_pack()
	_pack_scene.begin_idle()
	await get_tree().create_timer(0.2).timeout
	if _skip_requested or _state != FlowState.TEARING:
		return
	if _pack_scene and is_instance_valid(_pack_scene):
		_pack_scene.enable_manual_tear()
		_status_label.text = "Drag horizontally across the top seam to peel."


func _on_tear_progress_changed(progress: float) -> void:
	if _state != FlowState.TEARING:
		return
	var physical_state := (
		_pack_scene.get_physical_state()
		if _pack_scene and is_instance_valid(_pack_scene)
		else PackTearController.PhysicalState.CLOSED
	)
	match physical_state:
		PackTearController.PhysicalState.CLOSED:
			_status_label.text = "Drag across the top seam."
		PackTearController.PhysicalState.TENSION:
			_status_label.text = "Starting the tear..."
		PackTearController.PhysicalState.TINY_RIP:
			_status_label.text = "Tiny rip — keep dragging."
		PackTearController.PhysicalState.GROWING_TEAR:
			_status_label.text = "Peeling... %.0f%%" % (progress * 100.0)
		PackTearController.PhysicalState.PEELING:
			_status_label.text = "Flap lifting... %.0f%%" % (progress * 100.0)
		PackTearController.PhysicalState.FULLY_OPEN:
			_status_label.text = "Peel complete."


func _on_pack_torn() -> void:
	if _state != FlowState.TEARING or _skip_requested:
		return
	## 24.1 stops here — no light, no cards.
	_state = FlowState.DONE
	_skip_button.hide()
	_status_label.text = "24.1 peel complete — visually approve before 24.2."
	_show_result_actions()


func _show_pack_stage() -> void:
	_release_layer.hide()
	_pack_anchor.show()
	_pack_anchor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_play_area.hide()
	_footer.hide()


func _show_result_actions() -> void:
	_footer.show()
	_result_actions.show()
	_reveal_all_button.hide()
	_exit_button.show()
	_exit_button.text = "Exit to Pack Hub"
	_exit_button.custom_minimum_size.y = 52.0
	_exit_button.disabled = false
	if _has_remaining_selected_packs():
		_continue_button.show()
		_continue_button.text = "Peel Another"
		_continue_button.disabled = false
	else:
		_continue_button.hide()


func _has_remaining_selected_packs() -> bool:
	var pack_config := GameManager.get_selected_pack()
	return pack_config != null and PackInventoryManager.can_open_pack(pack_config.pack_id)


func _hide_result_actions() -> void:
	_result_actions.hide()
	_exit_button.hide()
	_continue_button.hide()
	_exit_button.disabled = false
	_continue_button.disabled = false


func _on_skip_pressed() -> void:
	if _state != FlowState.TEARING or _skip_requested:
		return
	if _pack_scene and is_instance_valid(_pack_scene):
		_skip_button.disabled = true
		_skip_button.hide()
		_status_label.text = "Finishing peel..."
		_pack_scene.force_complete_tear()


func _on_continue_pressed() -> void:
	if _state != FlowState.DONE:
		return
	if not _has_remaining_selected_packs():
		_show_result_actions()
		return
	_continue_button.disabled = true
	_exit_button.disabled = true
	_prepare_and_open()


func _on_exit_pressed() -> void:
	GameManager.go_to_pack_hub()
