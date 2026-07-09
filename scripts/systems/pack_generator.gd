class_name PackGenerator
extends RefCounted
## Generates pack contents from PackConfig and CardDatabase. No UI dependencies.


static func generate_pack(
	database: Node,
	pack_config: PackConfig,
	rng: RandomNumberGenerator = null
) -> Array[CardData]:
	if pack_config == null:
		push_warning("PackGenerator: pack_config is null.")
		return []

	var pack: Array[CardData] = []
	var random := _get_rng(rng)

	for _slot in pack_config.cards_per_pack:
		var card := generate_card(
			database,
			pack_config.rarity_weights,
			pack_config.variant_weights,
			random
		)
		if card:
			pack.append(card)

	return pack


static func generate_card(
	database: Node,
	rarity_weights: Dictionary,
	variant_weights: Dictionary,
	rng: RandomNumberGenerator = null
) -> CardData:
	if rarity_weights.is_empty() or variant_weights.is_empty():
		push_warning("PackGenerator: rarity_weights or variant_weights is empty.")
		return null

	var random := _get_rng(rng)
	var rarity := _roll_weighted_enum(rarity_weights, random) as CardData.Rarity
	var variant := _roll_weighted_enum(variant_weights, random) as CardData.Variant
	var template := _pick_random_card_for_rarity(database, rarity, random)

	if template == null:
		push_warning("PackGenerator: no card found for rarity %s." % CardData.get_rarity_label(rarity))
		return null

	var pulled_card := template.duplicate_card()
	pulled_card.variant = variant
	return pulled_card


static func generate_card_of_rarity(
	database: Node,
	rarity: CardData.Rarity,
	variant_weights: Dictionary,
	rng: RandomNumberGenerator = null
) -> CardData:
	if variant_weights.is_empty():
		push_warning("PackGenerator: variant_weights is empty.")
		return null

	var random := _get_rng(rng)
	var template := _pick_random_card_for_rarity(database, rarity, random)

	if template == null:
		return null

	var pulled_card := template.duplicate_card()
	pulled_card.variant = _roll_weighted_enum(variant_weights, random) as CardData.Variant
	return pulled_card


static func _get_rng(rng: RandomNumberGenerator) -> RandomNumberGenerator:
	var random := rng if rng else RandomNumberGenerator.new()
	if rng == null:
		random.randomize()
	return random


static func _pick_random_card_for_rarity(
	database: Node,
	rarity: CardData.Rarity,
	rng: RandomNumberGenerator
) -> CardData:
	var pool: Array[CardData] = database.get_cards_by_rarity(rarity)
	if pool.is_empty():
		return null

	return pool[rng.randi_range(0, pool.size() - 1)]


static func _roll_weighted_enum(weights: Dictionary, rng: RandomNumberGenerator) -> int:
	var total_weight := 0.0
	for weight in weights.values():
		total_weight += float(weight)

	if total_weight <= 0.0:
		return weights.keys()[0]

	var roll := rng.randf() * total_weight
	var cumulative := 0.0

	for key in weights.keys():
		cumulative += float(weights[key])
		if roll <= cumulative:
			return key

	return weights.keys().back()
