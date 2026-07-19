extends SceneTree
## Headless round-trip test using an isolated user:// save path.


const TEST_SAVE_PATH := "user://verify_foundation_save.json"
const TEST_TEMP_PATH := "user://verify_foundation_save.tmp"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var collection := root.get_node("CollectionManager")
	var inventory := root.get_node("PackInventoryManager")
	var database := root.get_node("CardDatabase")
	var save_manager := root.get_node("SaveManager")
	var game_manager := root.get_node("GameManager")
	collection.call("reset_runtime_data")
	inventory.call("reset_runtime_data")
	save_manager.call("set_storage_paths_for_testing", TEST_SAVE_PATH, TEST_TEMP_PATH)
	save_manager.call("delete_save")

	var template := database.call("get_card", "mage_rookie_fire_mage") as CardData
	if template == null:
		_fail("fixture card is missing.")
		return
	var owned := collection.call("add_card", template) as CardData
	collection.call("add_to_deck", owned)
	inventory.call("add_pack", "knight_pack", 3)
	save_manager.call("apply_player_statistics", {"packs_opened": 7})
	save_manager.call("apply_settings", {"music_enabled": false})
	game_manager.call("set_selected_pack", "knight_pack")

	if not save_manager.call("save_game"):
		_fail("serialization failed.")
		return
	collection.call("reset_runtime_data")
	inventory.call("reset_runtime_data")
	save_manager.call("apply_player_statistics", {})
	save_manager.call("apply_settings", {})
	game_manager.call("set_selected_pack", "")

	if not save_manager.call("load_game"):
		_fail("deserialization failed.")
		return
	var restored_cards := collection.call("get_collection") as Array
	if restored_cards.size() != 1 or (restored_cards[0] as CardData).instance_id != owned.instance_id:
		_fail("card instance IDs did not round-trip.")
		return
	if int(collection.call("get_deck_count")) != 1:
		_fail("deck instance IDs did not round-trip.")
		return
	if int(inventory.call("get_owned_count", "knight_pack")) != 3:
		_fail("inventory did not round-trip.")
		return
	if save_manager.call("get_player_statistics").get("packs_opened") != 7:
		_fail("player statistics did not round-trip.")
		return
	if save_manager.call("get_settings").get("music_enabled") != false:
		_fail("settings did not round-trip.")
		return
	if String(game_manager.get("selected_pack_id")) != "knight_pack":
		_fail("selected pack did not round-trip.")
		return

	save_manager.call("delete_save")
	save_manager.call("reset_storage_paths")
	print("verify_save_system: OK - versioned save round-trip.")
	quit(0)


func _fail(message: String) -> void:
	push_error("verify_save_system: %s" % message)
	quit(1)
