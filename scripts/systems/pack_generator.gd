class_name PackGenerator
extends RefCounted
## Generates pack contents from PackConfig and CardDatabase. No UI dependencies.
## Never inspects card sets/tags — always asks CardDatabase.get_cards_for_pack().


static func generate_pack(
	database: Node,
	pack_config: PackConfig,
	rng: RandomNumberGenerator = null
) -> Array[CardData]:
	if pack_config == null:
		push_warning("PackGenerator: pack_config is null.")
		return []
	if pack_config.rarity_weights.is_empty() or pack_config.variant_weights.is_empty():
		push_warning(
			"PackGenerator: pack '%s' has empty rarity_weights or variant_weights."
			% pack_config.pack_id
		)
		return []

	var pack: Array[CardData] = []
	var random := _get_rng(rng)
	var pool: Array[CardData] = database.get_cards_for_pack(pack_config)
	if pool.is_empty():
		push_warning(
			"PackGenerator: empty candidate pool for pack '%s'."
			% pack_config.pack_id
		)
		return pack

	for _slot in pack_config.cards_per_pack:
		var card := _generate_card_from_pool(
			pool,
			pack_config.rarity_weights,
			pack_config.variant_weights,
			random
		)
		if card:
			pack.append(card)

	return pack


static func generate_card(
	database: Node,
	pack_config: PackConfig,
	rng: RandomNumberGenerator = null
) -> CardData:
	if pack_config == null:
		push_warning("PackGenerator: pack_config is null.")
		return null
	if pack_config.rarity_weights.is_empty() or pack_config.variant_weights.is_empty():
		push_warning("PackGenerator: rarity_weights or variant_weights is empty.")
		return null

	var pool: Array[CardData] = database.get_cards_for_pack(pack_config)
	if pool.is_empty():
		push_warning(
			"PackGenerator: empty candidate pool for pack '%s'."
			% pack_config.pack_id
		)
		return null

	return _generate_card_from_pool(
		pool,
		pack_config.rarity_weights,
		pack_config.variant_weights,
		_get_rng(rng)
	)


static func generate_card_of_rarity(
	database: Node,
	pack_config: PackConfig,
	rarity: CardData.Rarity,
	rng: RandomNumberGenerator = null
) -> CardData:
	if pack_config == null:
		push_warning("PackGenerator: pack_config is null.")
		return null
	if pack_config.variant_weights.is_empty():
		push_warning("PackGenerator: variant_weights is empty.")
		return null

	var random := _get_rng(rng)
	var pool: Array[CardData] = database.get_cards_for_pack(pack_config)
	var template := _pick_random_card_for_rarity(pool, rarity, random)
	if template == null:
		return null

	var pulled_card := template.duplicate_card()
	pulled_card.variant = _roll_weighted_enum(
		pack_config.variant_weights,
		random
	) as CardData.Variant
	return pulled_card


static func _generate_card_from_pool(
	pool: Array[CardData],
	rarity_weights: Dictionary,
	variant_weights: Dictionary,
	rng: RandomNumberGenerator
) -> CardData:
	var rarity := _roll_weighted_enum(rarity_weights, rng) as CardData.Rarity
	var variant := _roll_weighted_enum(variant_weights, rng) as CardData.Variant
	var template := _pick_random_card_for_rarity(pool, rarity, rng)

	if template == null:
		push_warning(
			"PackGenerator: no card found for rarity %s in pack pool."
			% CardData.get_rarity_label(rarity)
		)
		return null

	var pulled_card := template.duplicate_card()
	pulled_card.variant = variant
	return pulled_card


static func _get_rng(rng: RandomNumberGenerator) -> RandomNumberGenerator:
	var random := rng if rng else RandomNumberGenerator.new()
	if rng == null:
		random.randomize()
	return random


## Picks from the pack candidate pool only — never queries sets/tags.
static func _pick_random_card_for_rarity(
	pool: Array[CardData],
	rarity: CardData.Rarity,
	rng: RandomNumberGenerator
) -> CardData:
	var rarity_pool: Array[CardData] = []
	for card in pool:
		if card.rarity == rarity:
			rarity_pool.append(card)

	if rarity_pool.is_empty():
		return null

	return rarity_pool[rng.randi_range(0, rarity_pool.size() - 1)]


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
