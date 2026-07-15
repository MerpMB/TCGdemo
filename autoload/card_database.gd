extends Node
## Central registry of every card definition. Loads all CardData resources from resources/cards/.
## Owns pack pool filtering — PackGenerator never inspects sets/tags directly.


const CARDS_ROOT := "res://resources/cards"


var _cards_by_id: Dictionary = {}
var _cards_by_rarity: Dictionary = {}
var _cards_by_set: Dictionary = {}


func _ready() -> void:
	_load_all_cards()
	_print_load_summary()


func get_card(card_id: String) -> CardData:
	return _cards_by_id.get(card_id)


func get_cards_by_rarity(rarity: CardData.Rarity) -> Array[CardData]:
	var result: Array[CardData] = []

	if _cards_by_rarity.has(rarity):
		for card: CardData in _cards_by_rarity[rarity]:
			result.append(card)

	return result


func get_cards_by_set(card_set_name: String) -> Array[CardData]:
	var result: Array[CardData] = []

	if _cards_by_set.has(card_set_name):
		for card: CardData in _cards_by_set[card_set_name]:
			result.append(card)

	return result


func get_cards_with_tag(tag: String) -> Array[CardData]:
	var matches: Array[CardData] = []
	for card in _cards_by_id.values():
		if card.tags.has(tag):
			matches.append(card)
	return matches


func get_all_cards() -> Array[CardData]:
	var all_cards: Array[CardData] = []
	for card in _cards_by_id.values():
		all_cards.append(card)
	return all_cards


## Candidate pool for a pack. Applies PackConfig allowed_sets, allowed_tags,
## and excluded_tags. Empty filter arrays mean "no restriction" on that axis.
func get_cards_for_pack(pack_config: PackConfig) -> Array[CardData]:
	var pool: Array[CardData] = []
	if pack_config == null:
		push_warning("CardDatabase.get_cards_for_pack: pack_config is null.")
		return pool

	for card in _cards_by_id.values():
		if _card_matches_pack(card, pack_config):
			pool.append(card)
	return pool


func register_card(card: CardData) -> void:
	if card.card_id.is_empty():
		push_warning("CardDatabase: attempted to register a card with an empty id.")
		return

	if _cards_by_id.has(card.card_id):
		push_warning("CardDatabase: duplicate card_id '%s' — skipping." % card.card_id)
		return

	_cards_by_id[card.card_id] = card
	_add_to_rarity_bucket(card)
	_add_to_set_bucket(card)


func _card_matches_pack(card: CardData, pack_config: PackConfig) -> bool:
	if not pack_config.allowed_sets.is_empty():
		if not pack_config.allowed_sets.has(card.card_set):
			return false

	if not pack_config.allowed_tags.is_empty():
		if not _card_has_any_tag(card, pack_config.allowed_tags):
			return false

	if not pack_config.excluded_tags.is_empty():
		if _card_has_any_tag(card, pack_config.excluded_tags):
			return false

	return true


func _card_has_any_tag(card: CardData, tags: PackedStringArray) -> bool:
	for tag in tags:
		if card.tags.has(tag):
			return true
	return false


func _load_all_cards() -> void:
	_scan_cards_directory(CARDS_ROOT)


func _scan_cards_directory(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_warning("CardDatabase: could not open directory '%s'." % path)
		return

	for subdir in dir.get_directories():
		if subdir.begins_with("."):
			continue
		_scan_cards_directory(path + "/" + subdir)

	for file_name in dir.get_files():
		if not file_name.ends_with(".tres"):
			continue
		var resource_path := path + "/" + file_name
		var resource := load(resource_path)
		if resource is CardData:
			register_card(resource)
		else:
			push_warning("CardDatabase: '%s' is not a CardData resource." % resource_path)


func _add_to_rarity_bucket(card: CardData) -> void:
	if not _cards_by_rarity.has(card.rarity):
		_cards_by_rarity[card.rarity] = []
	var bucket: Array = _cards_by_rarity[card.rarity]
	if not bucket.has(card):
		bucket.append(card)


func _add_to_set_bucket(card: CardData) -> void:
	if card.card_set.is_empty():
		return
	if not _cards_by_set.has(card.card_set):
		_cards_by_set[card.card_set] = []
	var bucket: Array = _cards_by_set[card.card_set]
	if not bucket.has(card):
		bucket.append(card)


func _print_load_summary() -> void:
	print("Loaded Cards: %d" % _cards_by_id.size())
	for card_id in _cards_by_id.keys():
		var card: CardData = _cards_by_id[card_id]
		print("  - %s (%s)" % [card_id, card.display_name])
