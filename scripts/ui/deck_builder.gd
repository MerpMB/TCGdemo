extends Control
## Split-view deck builder. Requests collection/deck changes through CollectionManager.


const CARD_SCENE := preload("res://scenes/Card.tscn")
const CARD_CELL_WIDTH := 156


@onready var _collection_grid: GridContainer = %CollectionGrid
@onready var _deck_grid: GridContainer = %DeckGrid
@onready var _collection_scroll: ScrollContainer = %CollectionScroll
@onready var _deck_scroll: ScrollContainer = %DeckScroll
@onready var _deck_size_label: Label = %DeckSizeLabel
@onready var _save_deck_button: Button = %SaveDeckButton
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_back_button.pressed.connect(func() -> void: GameManager.go_to_main_menu())
	_save_deck_button.pressed.connect(_on_save_deck_pressed)

	CollectionManager.collection_changed.connect(_refresh_collection)
	CollectionManager.deck_changed.connect(_refresh_deck)

	_refresh_collection()
	_refresh_deck()
	resized.connect(_update_grid_columns)
	_update_grid_columns()


func _refresh_collection() -> void:
	_clear_grid(_collection_grid)

	for card_data in CollectionManager.get_collection():
		var card_scene := CARD_SCENE.instantiate() as CardScene
		card_scene.card_pressed.connect(_on_collection_card_pressed)
		_collection_grid.add_child(card_scene)
		card_scene.setup(card_data, CardScene.DisplayMode.GALLERY)


func _refresh_deck() -> void:
	_clear_grid(_deck_grid)

	for card_data in CollectionManager.get_deck():
		var card_scene := CARD_SCENE.instantiate() as CardScene
		card_scene.card_pressed.connect(_on_deck_card_pressed)
		_deck_grid.add_child(card_scene)
		card_scene.setup(card_data, CardScene.DisplayMode.GALLERY)

	_update_deck_label()


func _clear_grid(grid: GridContainer) -> void:
	for child in grid.get_children():
		child.queue_free()


func _update_deck_label() -> void:
	_deck_size_label.text = "Deck: %d / %d" % [
		CollectionManager.get_deck_count(),
		CollectionManager.DECK_SIZE_LIMIT,
	]


func _update_grid_columns() -> void:
	var half_width := _collection_scroll.size.x
	if half_width <= 0.0:
		half_width = size.x * 0.5

	var columns := maxi(1, int(half_width / CARD_CELL_WIDTH))
	_collection_grid.columns = columns
	_deck_grid.columns = columns


func _on_collection_card_pressed(card_scene: CardScene) -> void:
	var card_data := card_scene.get_card_data()
	if CollectionManager.add_to_deck(card_data):
		return
	_update_deck_label()


func _on_deck_card_pressed(card_scene: CardScene) -> void:
	CollectionManager.remove_from_deck(card_scene.get_card_data())


func _on_save_deck_pressed() -> void:
	# Placeholder for future SaveManager integration.
	pass
