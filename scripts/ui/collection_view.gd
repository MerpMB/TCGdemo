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
@onready var _sort_option: OptionButton = %SortOption
var _inspection_cards: Array[CardData] = []
var _sort_mode := CollectionManager.CollectionSort.RECENTLY_OBTAINED


func _ready() -> void:
	_back_button.pressed.connect(func() -> void: GameManager.go_to_main_menu())
	CollectionManager.collection_changed.connect(_refresh_collection)
	_sort_option.item_selected.connect(_on_sort_selected)
	_populate_sort_options()
	_refresh_collection()
	resized.connect(_update_grid_columns)
	_update_grid_columns()


func _populate_sort_options() -> void:
	for label in ["Recently Obtained", "Oldest", "Name", "Rarity", "Variant", "Favorites First", "Set"]:
		_sort_option.add_item(label)
	_sort_option.select(int(_sort_mode))


func _on_sort_selected(index: int) -> void:
	_sort_mode = index as CollectionManager.CollectionSort
	_refresh_collection()

func _refresh_collection() -> void:
	_clear_grid()

	var entries := _stack_unique_collectibles(
		_apply_view_filters(CollectionManager.get_sorted_collection(_sort_mode))
	)
	_inspection_cards.clear()
	for entry in entries:
		_inspection_cards.append(entry.card)

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
	var selected_index := _inspection_cards.find(card_scene.get_card_data())
	GameManager.show_card_inspection(_inspection_cards, selected_index)


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
