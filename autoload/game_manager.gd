extends Node
## Application flow: scene navigation, transitions, inspector overlay, and developer tools.


const SCENE_MAIN_MENU := "res://scenes/MainMenu.tscn"
const SCENE_PACK_OPENING := "res://scenes/PackOpening.tscn"
const SCENE_COLLECTION := "res://scenes/Collection.tscn"
const SCENE_DECK_BUILDER := "res://scenes/DeckBuilder.tscn"
const SCENE_SETTINGS := "res://scenes/Settings.tscn"

const DEVELOPER_PANEL_SCENE := preload("res://scenes/DeveloperPanel.tscn")
const CARD_INSPECTOR_SCENE := preload("res://scenes/CardInspector.tscn")

const FADE_DURATION := 0.15

var _fade_layer: CanvasLayer
var _fade_rect: ColorRect
var _developer_panel: CanvasLayer
var _card_inspector: CanvasLayer
var _is_transitioning := false
var selected_pack_id: String = ""


func _ready() -> void:
	_setup_fade_overlay()
	_setup_developer_panel()
	_setup_card_inspector()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_developer_panel"):
		toggle_developer_panel()


func go_to_main_menu() -> void:
	change_scene(SCENE_MAIN_MENU)


func go_to_pack_opening() -> void:
	change_scene(SCENE_PACK_OPENING)


func get_selected_pack() -> PackConfig:
	if not selected_pack_id.is_empty():
		var pack := PackDatabase.get_pack(selected_pack_id)
		if pack:
			return pack
	var all_packs := PackDatabase.get_all_packs()
	if all_packs.is_empty():
		return null
	return all_packs[0]


func set_selected_pack(pack_id: String) -> void:
	selected_pack_id = pack_id


func go_to_collection() -> void:
	change_scene(SCENE_COLLECTION)


func go_to_deck_builder() -> void:
	change_scene(SCENE_DECK_BUILDER)


func go_to_settings() -> void:
	change_scene(SCENE_SETTINGS)


func quit_game() -> void:
	get_tree().quit()


func change_scene(scene_path: String) -> void:
	if _is_transitioning:
		return

	_is_transitioning = true
	var tween := create_tween()
	tween.tween_property(_fade_rect, "color:a", 1.0, FADE_DURATION)
	await tween.finished

	get_tree().change_scene_to_file(scene_path)

	await get_tree().process_frame
	var fade_in := create_tween()
	fade_in.tween_property(_fade_rect, "color:a", 0.0, FADE_DURATION)
	await fade_in.finished
	_is_transitioning = false


func show_card_inspector(card_data: CardData) -> void:
	if _card_inspector == null:
		return
	_card_inspector.show_card(card_data)


func toggle_developer_panel() -> void:
	if _developer_panel == null:
		return
	_developer_panel.visible = not _developer_panel.visible


func hide_developer_panel() -> void:
	if _developer_panel:
		_developer_panel.visible = false


func _setup_fade_overlay() -> void:
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 100
	add_child(_fade_layer)

	_fade_rect = ColorRect.new()
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	_fade_layer.add_child(_fade_rect)


func _setup_developer_panel() -> void:
	_developer_panel = DEVELOPER_PANEL_SCENE.instantiate()
	_developer_panel.visible = false
	add_child(_developer_panel)


func _setup_card_inspector() -> void:
	_card_inspector = CARD_INSPECTOR_SCENE.instantiate()
	_card_inspector.visible = false
	add_child(_card_inspector)
