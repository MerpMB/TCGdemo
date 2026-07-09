extends Control
## Scrollable list of every card the player has obtained.


const CARD_SCENE := preload("res://scenes/Card.tscn")
const CARD_CELL_WIDTH := 156


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

	var cards := CollectionManager.get_collection()
	_empty_label.visible = cards.is_empty()
	_count_label.text = "%d cards" % cards.size()

	for card_data in cards:
		var card_scene := CARD_SCENE.instantiate() as CardScene
		_grid.add_child(card_scene)
		card_scene.setup(card_data, CardScene.DisplayMode.PREVIEW)
		card_scene.scale = Vector2.ONE


func _clear_grid() -> void:
	for child in _grid.get_children():
		child.queue_free()


func _update_grid_columns() -> void:
	var available_width := _scroll.size.x
	if available_width <= 0.0:
		available_width = size.x
	_grid.columns = maxi(1, int(available_width / CARD_CELL_WIDTH))
