class_name PackConfig
extends Resource
## Pack definition loaded from .tres files under resources/packs/.
## Drives generation weights, card pool filters, and pack opening presentation.
## PackGenerator reads rarity_weights / variant_weights only — no pack-id special cases.


@export var pack_id: String = ""
@export var display_name: String = ""
@export var cards_per_pack: int = 7
## Keys: CardData.Rarity int → weight float. Odds are fully defined here.
@export var rarity_weights: Dictionary = {}
## Keys: CardData.Variant int → weight float. Odds are fully defined here.
@export var variant_weights: Dictionary = {}
## If non-empty, only cards whose card_set is in this list are eligible.
@export var allowed_sets: PackedStringArray = []
## If non-empty, a card must have at least one of these tags to be eligible.
@export var allowed_tags: PackedStringArray = []
## Cards with any of these tags are never eligible for this pack.
@export var excluded_tags: PackedStringArray = []
## Hidden from shop / player-facing pack lists when true.
@export var debug_only: bool = false
## When false, pack is omitted from shop listings (e.g. debug packs).
@export var visible_in_shop: bool = true
@export var pack_scene: PackedScene
@export var pack_back: Texture2D
@export var pack_icon: Texture2D
## Full front artwork shown by the shared PackScene in the hub and opening flow.
@export var pack_art: Texture2D
@export var primary_color: Color = Color(0.28, 0.38, 0.72)
@export var accent_color: Color = Color(0.95, 0.78, 0.2)
@export var description: String = ""
