extends CanvasLayer
## Runtime testing tools. Available globally via F1.


@onready var _generate_pack_button: Button = %GeneratePackButton
@onready var _give_random_button: Button = %GiveRandomButton
@onready var _give_common_button: Button = %GiveCommonButton
@onready var _give_rare_button: Button = %GiveRareButton
@onready var _give_epic_button: Button = %GiveEpicButton
@onready var _give_legendary_button: Button = %GiveLegendaryButton
@onready var _clear_collection_button: Button = %ClearCollectionButton
@onready var _reset_runtime_button: Button = %ResetRuntimeButton
@onready var _hide_button: Button = %HideButton


func _ready() -> void:
	_generate_pack_button.pressed.connect(_on_generate_pack_pressed)
	_give_random_button.pressed.connect(_on_give_random_pressed)
	_give_common_button.pressed.connect(func() -> void: _give_card_of_rarity(CardData.Rarity.COMMON))
	_give_rare_button.pressed.connect(func() -> void: _give_card_of_rarity(CardData.Rarity.RARE))
	_give_epic_button.pressed.connect(func() -> void: _give_card_of_rarity(CardData.Rarity.EPIC))
	_give_legendary_button.pressed.connect(func() -> void: _give_card_of_rarity(CardData.Rarity.LEGENDARY))
	_clear_collection_button.pressed.connect(_on_clear_collection_pressed)
	_reset_runtime_button.pressed.connect(_on_reset_runtime_pressed)
	_hide_button.pressed.connect(func() -> void: GameManager.hide_developer_panel())


func _on_generate_pack_pressed() -> void:
	var dev_pack := PackDatabase.get_pack(GameManager.selected_pack_id)
	if dev_pack:
		GameManager.set_selected_pack(dev_pack.pack_id)
	elif GameManager.selected_pack_id.is_empty():
		var packs := PackDatabase.get_all_packs()
		if not packs.is_empty():
			GameManager.set_selected_pack(packs[0].pack_id)
	GameManager.hide_developer_panel()
	GameManager.go_to_pack_hub()


func _on_give_random_pressed() -> void:
	var pack_config := _get_dev_pack_config()
	if pack_config == null:
		return
	var card := PackGenerator.generate_card(CardDatabase, pack_config)
	if card:
		CollectionManager.add_card(card)


func _give_card_of_rarity(rarity: CardData.Rarity) -> void:
	var pack_config := _get_dev_pack_config()
	if pack_config == null:
		return
	var card := PackGenerator.generate_card_of_rarity(CardDatabase, pack_config, rarity)
	if card:
		CollectionManager.add_card(card)


func _get_dev_pack_config() -> PackConfig:
	var dev_pack := PackDatabase.get_pack(GameManager.selected_pack_id)
	if dev_pack:
		return dev_pack
	var all_packs := PackDatabase.get_all_packs()
	if all_packs.is_empty():
		push_warning("DeveloperPanel: no PackConfig resources loaded.")
		return null
	return all_packs[0]


func _on_clear_collection_pressed() -> void:
	CollectionManager.clear_collection()


func _on_reset_runtime_pressed() -> void:
	CollectionManager.reset_runtime_data()
	PackInventoryManager.reset_runtime_data()
	GameManager.set_selected_pack("")
