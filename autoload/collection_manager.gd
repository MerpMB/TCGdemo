extends Node
## Runtime player collection and deck state.
## UI requests changes through these methods; it never mutates internal arrays directly.
## Emits signals so UI scenes can refresh without tight coupling.


signal collection_changed()
signal deck_changed()


const DECK_SIZE_LIMIT := 10


var _collection: Array[CardData] = []
var _deck: Array[CardData] = []
var _next_instance_id := 1


func add_card(card: CardData) -> CardData:
	var owned := card.duplicate_card()
	owned.instance_id = _create_instance_id()
	_collection.append(owned)
	collection_changed.emit()
	return owned


func add_cards(cards: Array[CardData]) -> void:
	for card in cards:
		add_card(card)


func remove_card_by_instance(instance_id: String) -> void:
	for index in range(_collection.size() - 1, -1, -1):
		if _collection[index].instance_id == instance_id:
			_remove_from_deck_by_instance(instance_id)
			_collection.remove_at(index)
			collection_changed.emit()
			return


func create_state_snapshot() -> Dictionary:
	var collection_copies: Array[CardData] = []
	for card in _collection:
		collection_copies.append(_copy_card_with_instance(card))

	var deck_instance_ids: PackedStringArray = []
	for card in _deck:
		deck_instance_ids.append(card.instance_id)

	return {
		"collection": collection_copies,
		"deck_instance_ids": deck_instance_ids,
		"next_instance_id": _next_instance_id,
	}


func restore_state_snapshot(snapshot: Dictionary) -> void:
	var restored_collection: Array[CardData] = []
	for card in snapshot.get("collection", []):
		if card is CardData:
			restored_collection.append(_copy_card_with_instance(card))

	_collection = restored_collection
	_next_instance_id = maxi(int(snapshot.get("next_instance_id", 1)), 1)
	_deck.clear()
	for instance_id in snapshot.get("deck_instance_ids", []):
		var owned := _get_card_by_instance(String(instance_id))
		if owned:
			_deck.append(owned)

	collection_changed.emit()
	deck_changed.emit()

func get_collection() -> Array[CardData]:
	return _collection.duplicate()


func get_collection_count() -> int:
	return _collection.size()


func clear_collection() -> void:
	_collection.clear()
	_deck.clear()
	collection_changed.emit()
	deck_changed.emit()


func add_to_deck(card: CardData) -> bool:
	if card == null or card.instance_id.is_empty():
		return false

	if _deck.size() >= DECK_SIZE_LIMIT:
		return false

	if not _owns_instance(card.instance_id):
		return false

	if _deck_has_instance(card.instance_id):
		return false

	_deck.append(card)
	deck_changed.emit()
	return true


func remove_from_deck(card: CardData) -> void:
	if card == null:
		return
	_remove_from_deck_by_instance(card.instance_id)


func get_deck() -> Array[CardData]:
	return _deck.duplicate()


func get_deck_count() -> int:
	return _deck.size()


func clear_deck() -> void:
	_deck.clear()
	deck_changed.emit()


func reset_runtime_data() -> void:
	_collection.clear()
	_deck.clear()
	_next_instance_id = 1
	collection_changed.emit()
	deck_changed.emit()


func _copy_card_with_instance(card: CardData) -> CardData:
	var copy := card.duplicate_card()
	copy.instance_id = card.instance_id
	return copy


func _get_card_by_instance(instance_id: String) -> CardData:
	for card in _collection:
		if card.instance_id == instance_id:
			return card
	return null

func _create_instance_id() -> String:
	var id := "inst_%06d" % _next_instance_id
	_next_instance_id += 1
	return id


func _owns_instance(instance_id: String) -> bool:
	for card in _collection:
		if card.instance_id == instance_id:
			return true
	return false


func _deck_has_instance(instance_id: String) -> bool:
	for card in _deck:
		if card.instance_id == instance_id:
			return true
	return false


func _remove_from_deck_by_instance(instance_id: String) -> void:
	for index in range(_deck.size() - 1, -1, -1):
		if _deck[index].instance_id == instance_id:
			_deck.remove_at(index)
			deck_changed.emit()
			return
