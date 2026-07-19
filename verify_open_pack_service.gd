extends SceneTree
const OpenPackResultData = preload("res://scripts/systems/open_pack_result.gd")
## Headless service-boundary regression test. Transaction rollback coverage is
## added with the transactional service implementation.


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var collection_manager := root.get_node('CollectionManager')
	var inventory_manager := root.get_node('PackInventoryManager')
	var pack_database := root.get_node('PackDatabase')
	var open_pack_service := root.get_node('OpenPackService')
	collection_manager.call("reset_runtime_data")
	inventory_manager.call("reset_runtime_data")

	var pack := pack_database.call("get_pack", "starter_pack") as PackConfig
	if pack == null:
		push_error("verify_open_pack_service: starter_pack is missing.")
		quit(1)
		return

	var before_inventory := int(inventory_manager.call("get_owned_count", pack.pack_id))
	var before_collection := int(collection_manager.call("get_collection_count"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260719
	var result := open_pack_service.call("open_pack", pack.pack_id, rng) as Dictionary
	if not result.succeeded:
		push_error("verify_open_pack_service: expected success, got %s." % result.error_code)
		quit(1)
		return
	if result.cards.size() != pack.cards_per_pack:
		push_error("verify_open_pack_service: generated an incomplete pack.")
		quit(1)
		return
	if int(inventory_manager.call("get_owned_count", pack.pack_id)) != before_inventory - 1:
		push_error("verify_open_pack_service: inventory was not consumed exactly once.")
		quit(1)
		return
	if int(collection_manager.call("get_collection_count")) != before_collection + pack.cards_per_pack:
		push_error("verify_open_pack_service: collection was not granted exactly once.")
		quit(1)
		return

	var rejected := open_pack_service.call("open_pack", "missing_pack") as Dictionary
	if rejected.succeeded or rejected.error_code != "unknown_pack":
		push_error("verify_open_pack_service: invalid requests must return a structured failure.")
		quit(1)
		return
	if int(inventory_manager.call("get_owned_count", pack.pack_id)) != before_inventory - 1:
		push_error("verify_open_pack_service: rejected request mutated inventory.")
		quit(1)
		return

	print("verify_open_pack_service: OK ? service owns the open-pack happy path.")
	quit(0)
