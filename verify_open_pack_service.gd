extends SceneTree
## Headless transaction regression for the OpenPackService boundary.


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var collection_manager := root.get_node("CollectionManager")
	var inventory_manager := root.get_node("PackInventoryManager")
	var pack_database := root.get_node("PackDatabase")
	var open_pack_service := root.get_node("OpenPackService")

	collection_manager.call("reset_runtime_data")
	inventory_manager.call("reset_runtime_data")
	var pack := pack_database.call("get_pack", "starter_pack") as PackConfig
	if pack == null:
		_fail("starter_pack is missing.")
		return

	var starting_inventory := int(inventory_manager.call("get_owned_count", pack.pack_id))
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260719
	var result := open_pack_service.call("open_pack", pack.pack_id, rng) as Dictionary
	if not result.succeeded:
		_fail("expected success, got %s." % result.error_code)
		return
	if result.cards.size() != pack.cards_per_pack:
		_fail("generated an incomplete pack.")
		return
	if int(inventory_manager.call("get_owned_count", pack.pack_id)) != starting_inventory - 1:
		_fail("inventory was not consumed exactly once.")
		return
	if int(collection_manager.call("get_collection_count")) != pack.cards_per_pack:
		_fail("collection was not granted exactly once.")
		return

	var first_owned := collection_manager.call("get_collection")[0] as CardData
	if not collection_manager.call("add_to_deck", first_owned):
		_fail("could not create a deck fixture.")
		return
	var inventory_before_failure := int(inventory_manager.call("get_owned_count", pack.pack_id))
	var collection_before_failure := int(collection_manager.call("get_collection_count"))
	var deck_before_failure := int(collection_manager.call("get_deck_count"))
	open_pack_service.call("set_persistence_callback_for_testing", Callable(self, "_fail_persistence"))

	var failed_result := open_pack_service.call("open_pack", pack.pack_id, rng) as Dictionary
	if failed_result.succeeded or failed_result.error_code != "persistence_failed":
		_fail("persistence failure must return a structured failure.")
		return
	if int(inventory_manager.call("get_owned_count", pack.pack_id)) != inventory_before_failure:
		_fail("rollback did not restore inventory.")
		return
	if int(collection_manager.call("get_collection_count")) != collection_before_failure:
		_fail("rollback did not restore collection.")
		return
	if int(collection_manager.call("get_deck_count")) != deck_before_failure:
		_fail("rollback did not restore deck references.")
		return

	var rejected := open_pack_service.call("open_pack", "missing_pack") as Dictionary
	if rejected.succeeded or rejected.error_code != "unknown_pack":
		_fail("invalid requests must return a structured failure.")
		return

	print("verify_open_pack_service: OK - transaction success and rollback.")
	quit(0)


func _fail_persistence() -> bool:
	return false


func _fail(message: String) -> void:
	push_error("verify_open_pack_service: %s" % message)
	quit(1)
