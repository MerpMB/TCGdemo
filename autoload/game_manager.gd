extends Node
## Application flow: scene navigation, transitions, inspector overlay, and developer tools.


const SCENE_MAIN_MENU := "res://scenes/MainMenu.tscn"
const SCENE_PACK_HUB := "res://scenes/PackHub.tscn"
const SCENE_PACK_OPENING := "res://scenes/PackOpening.tscn"
const SCENE_COLLECTION := "res://scenes/Collection.tscn"
const SCENE_DECK_BUILDER := "res://scenes/DeckBuilder.tscn"
const SCENE_SETTINGS := "res://scenes/Settings.tscn"

const DEVELOPER_PANEL_SCENE := preload("res://scenes/DeveloperPanel.tscn")
const CARD_VIEWER_SCENE := preload("res://scenes/CardViewer.tscn")
const CARD_INSPECTION_SCENE := preload("res://scenes/CardInspection.tscn")

const FADE_DURATION := 0.15

var _fade_layer: CanvasLayer
var _fade_rect: ColorRect
var _developer_panel: CanvasLayer
var _card_viewer: CanvasLayer
var _card_inspection: CanvasLayer
var _is_transitioning := false
var selected_pack_id: String = ""
var _visual_warmup_done := false


func _ready() -> void:
	_setup_fade_overlay()
	_setup_developer_panel()
	_setup_card_viewer()
	_setup_card_inspection()
	## After other autoloads finish _ready (CardDatabase must exist for art prefetch).
	call_deferred("_warmup_visual_assets")


func _input(event: InputEvent) -> void:
	## Card Inspection owns keyboard/controller input for its entire visible lifetime.
	if _card_inspection and _card_inspection.is_modal_active():
		return
	if event.is_action_pressed("toggle_developer_panel"):
		toggle_developer_panel()


## Prefetch shaders, procedural maps, Synth bake, frames, and catalog art at boot
## so pack opening does not hitch on first Foil / Diamond / Synth / art resolve.
func _warmup_visual_assets() -> void:
	if _visual_warmup_done:
		return
	_visual_warmup_done = true

	## Let MainMenu mount one frame before the heavier CPU work.
	await get_tree().process_frame

	var materials: Array[ShaderMaterial] = CardVisualLibrary.warmup(CardDatabase)
	await _force_shader_gpu_compile(materials)


## Draw each warmed material once offscreen so the GPU compiles shaders now,
## not during the first pack-card fly-out.
func _force_shader_gpu_compile(materials: Array[ShaderMaterial]) -> void:
	if materials.is_empty():
		return

	var layer := CanvasLayer.new()
	layer.layer = -100
	layer.name = "VisualWarmupLayer"
	add_child(layer)

	var host := Control.new()
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.size = Vector2(8, 8)
	host.position = Vector2(-64, -64)
	layer.add_child(host)

	for material in materials:
		if material == null:
			continue
		var rect := ColorRect.new()
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.size = Vector2(4, 4)
		rect.color = Color.WHITE
		rect.material = material
		host.add_child(rect)

	## Two frames: one to submit draw, one to finish compile on most backends.
	await get_tree().process_frame
	await get_tree().process_frame

	layer.queue_free()
	print("GameManager: variant shader GPU compile pass finished.")


func go_to_main_menu() -> void:
	change_scene(SCENE_MAIN_MENU)


func go_to_pack_hub() -> void:
	change_scene(SCENE_PACK_HUB)


func go_to_pack_opening() -> void:
	change_scene(SCENE_PACK_OPENING)


func get_selected_pack() -> PackConfig:
	if not selected_pack_id.is_empty():
		var pack := PackDatabase.get_pack(selected_pack_id)
		if pack:
			return pack
	var hub_packs := PackDatabase.get_hub_packs()
	if not hub_packs.is_empty():
		return hub_packs[0]
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


func show_card_viewer(card_data: CardData) -> void:
	if _card_viewer == null:
		return
	_card_viewer.show_card(card_data)


func show_card_inspection(cards: Array[CardData], selected_index: int) -> void:
	if _card_inspection:
		_card_inspection.show_cards(cards, selected_index)

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


func _setup_card_inspection() -> void:
	_card_inspection = CARD_INSPECTION_SCENE.instantiate()
	_card_inspection.visible = false
	add_child(_card_inspection)

func _setup_card_viewer() -> void:
	_card_viewer = CARD_VIEWER_SCENE.instantiate()
	_card_viewer.visible = false
	add_child(_card_viewer)
