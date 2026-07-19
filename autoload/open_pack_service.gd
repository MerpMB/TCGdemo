extends Node
## Application boundary for opening packs. UI receives an OpenPackResult and
## never coordinates generation, inventory, or collection mutations itself.
##
## This first version centralizes the existing happy path. Transactional state
## snapshots and persistence rollback are added in the next foundation commit.


const OpenPackResultData = preload("res://scripts/systems/open_pack_result.gd")

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

	if not PackInventoryManager.consume_pack(pack_id):
		return OpenPackResultData.failure(
			"inventory_changed", "Pack inventory changed before the pack could be opened.", pack_id
		)

	CollectionManager.add_cards(cards)
	return OpenPackResultData.success(pack_id, cards)
