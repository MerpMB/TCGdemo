extends Control
## Gallery of unique collectibles the player owns.
## Exact duplicates (same card_id + variant) stack into one entry with an owned
## count badge. Different variants remain separate. Storage in CollectionManager
## is unchanged — stacking is view-only.


const CARD_SCENE := preload("res://scenes/Card.tscn")
const CARD_CELL_WIDTH := 148


@onready var _grid: GridContainer = %CardGrid
@onready var _scroll: ScrollContainer = %ScrollContainer
@onready var _empty_label: Label = %EmptyLabel
@onready var _count_label: Label = %CountLabel
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_back_button.pressed.connect(func() -> void: GameManager.go_to_main_menu())
	CollectionManager.collection_changed.connect(_refresh_collection)
	_refresh_collection()
	resized.connect(_update_grid_columns)
	_update_grid_columns()


func _refresh_collection() -> void:
	_clear_grid()

	var entries := _stack_unique_collectibles(
		_apply_view_filters(CollectionManager.get_collection())
	)
	_empty_label.visible = entries.is_empty()
	_count_label.text = "%d cards" % entries.size()

	for entry in entries:
		var card_scene := CARD_SCENE.instantiate() as CardScene
		card_scene.card_pressed.connect(_on_card_pressed)
		_grid.add_child(card_scene)
		card_scene.setup(entry.card, CardScene.DisplayMode.GALLERY)
		card_scene.set_owned_count(entry.count)
		card_scene.scale = Vector2.ONE


func _on_card_pressed(card_scene: CardScene) -> void:
	# CardViewer already exists — open the selected collectible.
	GameManager.show_card_viewer(card_scene.get_card_data())


## Stack exact duplicates only. Key = card_id + variant so Foil / Diamond / etc.
## remain separate gallery entries. Returns [{card: CardData, count: int}, ...]
## in first-seen order.
func _stack_unique_collectibles(cards: Array[CardData]) -> Array[Dictionary]:
	var order: Array[String] = []
	var stacks: Dictionary = {}

	for card in cards:
		if card == null:
			continue
		var key := _collectible_key(card)
		if stacks.has(key):
			stacks[key].count += 1
		else:
			stacks[key] = {"card": card, "count": 1}
			order.append(key)

	var entries: Array[Dictionary] = []
	for key in order:
		entries.append(stacks[key])
	return entries


func _collectible_key(card: CardData) -> String:
	return "%s:%d" % [card.card_id, int(card.variant)]


## Future hook (Phase 6+): search query and rarity/variant/favorite filters
## will be applied here. Currently a pass-through so the architecture is ready
## without changing behavior.
func _apply_view_filters(cards: Array[CardData]) -> Array[CardData]:
	return cards


func _clear_grid() -> void:
	for child in _grid.get_children():
		child.queue_free()


func _update_grid_columns() -> void:
	var available_width := _scroll.size.x
	if available_width <= 0.0:
		available_width = size.x
	var columns := maxi(1, int(available_width / CARD_CELL_WIDTH))
	_grid.columns = clampi(columns, 2, 4)
