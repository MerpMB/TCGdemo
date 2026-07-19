extends Control
## Pack Hub — inventory display, pack selection, free claims, and opening owned packs.


const FALLBACK_PACK_SCENE := preload("res://scenes/Pack.tscn")


@onready var _selector_row: HBoxContainer = %SelectorRow
@onready var _preview_anchor: CenterContainer = %PreviewAnchor
@onready var _pack_name_label: Label = %PackNameLabel
@onready var _pack_description_label: Label = %PackDescriptionLabel
@onready var _owned_count_label: Label = %OwnedCountLabel
@onready var _status_label: Label = %StatusLabel
@onready var _open_pack_button: Button = %OpenPackButton
@onready var _claim_pack_button: Button = %ClaimPackButton
@onready var _back_button: Button = %BackButton


var _selected_pack: PackConfig
var _selector_buttons: Dictionary = {}
var _selector_group := ButtonGroup.new()
var _preview_scene: PackScene
var _is_opening := false


func _ready() -> void:
	_open_pack_button.pressed.connect(_on_open_pack_pressed)
	_claim_pack_button.pressed.connect(_on_claim_selected_pack)
	_back_button.pressed.connect(GameManager.go_to_main_menu)
	PackInventoryManager.inventory_changed.connect(_on_inventory_changed)

	_build_pack_selector()
	_select_initial_pack()


func _build_pack_selector() -> void:
	for child in _selector_row.get_children():
		child.queue_free()
	_selector_buttons.clear()
	_selector_group = ButtonGroup.new()

	for pack in PackDatabase.get_hub_packs():
		var button := Button.new()
		button.custom_minimum_size = Vector2(156, 52)
		button.toggle_mode = true
		button.button_group = _selector_group
		button.pressed.connect(_select_pack_by_id.bind(pack.pack_id))
		_selector_row.add_child(button)
		_selector_buttons[pack.pack_id] = button
		_update_selector_button(pack.pack_id)


func _select_initial_pack() -> void:
	var requested_pack := GameManager.get_selected_pack()
	if requested_pack and requested_pack.visible_in_shop and _selector_buttons.has(requested_pack.pack_id):
		_select_pack(requested_pack)
		return

	var hub_packs := PackDatabase.get_hub_packs()
	for pack in hub_packs:
		if _selector_buttons.has(pack.pack_id):
			_select_pack(pack)
			return

	_show_no_packs()


func _select_pack_by_id(pack_id: String) -> void:
	var pack := PackDatabase.get_pack(pack_id)
	if pack and pack.visible_in_shop:
		_select_pack(pack)


func _select_pack(pack: PackConfig) -> void:
	_selected_pack = pack
	GameManager.set_selected_pack(pack.pack_id)
	var button := _selector_buttons.get(pack.pack_id) as Button
	if button:
		button.set_pressed_no_signal(true)
	_refresh_selected_pack()


func _refresh_selected_pack() -> void:
	if _selected_pack == null:
		_show_no_packs()
		return

	var owned_count := PackInventoryManager.get_owned_count(_selected_pack.pack_id)
	_pack_name_label.text = _selected_pack.display_name
	_pack_description_label.text = _selected_pack.description
	_pack_description_label.visible = not _selected_pack.description.is_empty()
	_owned_count_label.text = "Owned: %d" % owned_count
	_open_pack_button.disabled = owned_count <= 0 or _is_opening
	_open_pack_button.text = "OPEN PACK" if owned_count > 0 else "NO PACKS OWNED"
	_status_label.text = (
		"Ready to open."
		if owned_count > 0
		else "Claim or acquire this pack before opening."
	)
	_refresh_preview()


func _refresh_preview() -> void:
	if _preview_scene and is_instance_valid(_preview_scene):
		_preview_anchor.remove_child(_preview_scene)
		_preview_scene.queue_free()
	_preview_scene = null

	if _selected_pack == null:
		return
	var packed_scene: PackedScene = (
		_selected_pack.pack_scene
		if _selected_pack.pack_scene
		else FALLBACK_PACK_SCENE
	)
	_preview_scene = packed_scene.instantiate() as PackScene
	_preview_anchor.add_child(_preview_scene)
	_preview_scene.setup_profile(
		_selected_pack.pack_id,
		_selected_pack.primary_color,
		_selected_pack.accent_color
	)


func _on_open_pack_pressed() -> void:
	if _is_opening or _selected_pack == null:
		return
	var pack_id := _selected_pack.pack_id
	_is_opening = true
	_open_pack_button.disabled = true
	GameManager.set_selected_pack(pack_id)
	GameManager.go_to_pack_opening()


func _on_claim_selected_pack() -> void:
	if _selected_pack == null:
		return
	PackInventoryManager.add_pack(_selected_pack.pack_id)
	_status_label.text = "Claimed +1 %s." % _selected_pack.display_name

func _on_inventory_changed(pack_id: String, _owned_count: int) -> void:
	_update_selector_button(pack_id)
	if _selected_pack and _selected_pack.pack_id == pack_id:
		_refresh_selected_pack()


func _update_selector_button(pack_id: String) -> void:
	var button := _selector_buttons.get(pack_id) as Button
	var pack := PackDatabase.get_pack(pack_id)
	if button == null or pack == null:
		return
	button.text = "%s ×%d" % [
		pack.display_name.trim_suffix(" Pack"),
		PackInventoryManager.get_owned_count(pack_id),
	]


func _show_no_packs() -> void:
	_pack_name_label.text = "No packs available"
	_pack_description_label.hide()
	_owned_count_label.text = "Owned: 0"
	_status_label.text = "No visible PackConfig resources are available."
	_open_pack_button.text = "NO PACKS"
	_open_pack_button.disabled = true
