extends Node
## Application boundary for opening packs. UI receives a structured result and
## never coordinates generation, inventory, collection, or persistence itself.
## SaveManager is used strictly as the persistence dependency; transaction
## decisions and rollback remain in this application service.


const OpenPackResultData = preload("res://scripts/systems/open_pack_result.gd")

var _persistence_callback: Callable


func _ready() -> void:
	_persistence_callback = Callable(get_node("/root/SaveManager"), "save_game")


func open_pack(pack_id: String, rng: RandomNumberGenerator = null) -> Dictionary:
	if pack_id.is_empty():
		return OpenPackResultData.failure("invalid_request", "No pack was selected.")

	var pack_config := PackDatabase.get_pack(pack_id)
	if pack_config == null:
		return OpenPackResultData.failure("unknown_pack", "The selected pack no longer exists.", pack_id)

	if not PackInventoryManager.can_open_pack(pack_id):
		return OpenPackResultData.failure(
			"insufficient_inventory", "No %s packs are available." % pack_config.display_name, pack_id
		)

	var cards := PackGenerator.generate_pack(CardDatabase, pack_config, rng)
	if cards.size() != pack_config.cards_per_pack:
		return OpenPackResultData.failure(
			"generation_failed", "%s could not generate a complete pack." % pack_config.display_name, pack_id
		)

	var collection_snapshot := CollectionManager.create_state_snapshot()
	var inventory_snapshot := PackInventoryManager.get_owned_counts()
	CollectionManager.add_cards(cards)

	if not _persist_game():
		_rollback(collection_snapshot, inventory_snapshot)
		return OpenPackResultData.failure(
			"persistence_failed", "Your pack could not be saved. Nothing was changed.", pack_id
		)

	if not PackInventoryManager.consume_pack(pack_id):
		_rollback(collection_snapshot, inventory_snapshot)
		return OpenPackResultData.failure(
			"inventory_changed", "Pack inventory changed before the pack could be opened.", pack_id
		)

	return OpenPackResultData.success(pack_id, cards)


func set_persistence_callback_for_testing(callback: Callable) -> void:
	_persistence_callback = callback


func _persist_game() -> bool:
	if not _persistence_callback.is_valid():
		return false
	return _persistence_callback.call() == true


func _rollback(collection_snapshot: Dictionary, inventory_snapshot: Dictionary) -> void:
	CollectionManager.restore_state_snapshot(collection_snapshot)
	PackInventoryManager.apply_owned_counts(inventory_snapshot)
