class_name CardData
extends Resource
## Catalog definition for a single card. Loaded from .tres files under resources/cards/.
## Runtime instances (owned copies) are created via duplicate_card().


enum Rarity {
	COMMON,
	RARE,
	EPIC,
	LEGENDARY,
}

enum Variant {
	NORMAL,
	FOIL,
	NEGATIVE,
	ALTERNATIVE_ART,
	DIAMOND,
	SYNTH,
}


const RARITY_COLORS: Dictionary = {
	Rarity.COMMON: Color(0.18, 0.72, 0.32),
	Rarity.RARE: Color(0.22, 0.48, 0.95),
	Rarity.EPIC: Color(0.62, 0.28, 0.82),
	Rarity.LEGENDARY: Color(0.95, 0.78, 0.18),
}

const RARITY_LABELS: Dictionary = {
	Rarity.COMMON: "Common",
	Rarity.RARE: "Rare",
	Rarity.EPIC: "Epic",
	Rarity.LEGENDARY: "Legendary",
}

const VARIANT_LABELS: Dictionary = {
	Variant.NORMAL: "Normal",
	Variant.FOIL: "Foil",
	Variant.NEGATIVE: "Negative",
	Variant.ALTERNATIVE_ART: "Alternative Art",
	Variant.DIAMOND: "Diamond",
	Variant.SYNTH: "Synth",
}


@export var card_id: String = ""
@export var display_name: String = ""
@export var card_set: String = "Core Set"
@export var description: String = ""
@export var rarity: Rarity = Rarity.COMMON
@export var variant: Variant = Variant.NORMAL
@export var frame: String = ""
@export var card_back: String = "default"
@export var artwork: Texture2D
@export var artist: String = ""
@export var flavor_text: String = ""
@export var tags: PackedStringArray = []
@export var future_stats: Dictionary = {}

## Assigned by CollectionManager when a card enters the player's collection.
var instance_id: String = ""


func duplicate_card() -> CardData:
	var copy := CardData.new()
	copy.card_id = card_id
	copy.display_name = display_name
	copy.card_set = card_set
	copy.description = description
	copy.rarity = rarity
	copy.variant = variant
	copy.frame = frame
	copy.card_back = card_back
	copy.artwork = artwork
	copy.artist = artist
	copy.flavor_text = flavor_text
	copy.tags = tags.duplicate()
	copy.future_stats = future_stats.duplicate()
	return copy


static func get_rarity_color(rarity_value: Rarity) -> Color:
	return RARITY_COLORS.get(rarity_value, Color.WHITE)


static func get_rarity_label(rarity_value: Rarity) -> String:
	return RARITY_LABELS.get(rarity_value, "Unknown")


static func get_variant_label(variant_value: Variant) -> String:
	return VARIANT_LABELS.get(variant_value, "Unknown")
