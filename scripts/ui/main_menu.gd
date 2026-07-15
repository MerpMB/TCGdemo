extends Control
## Main menu — Pack Hub, Collection, Exit.


@onready var _open_pack_button: Button = %OpenPackButton
@onready var _collection_button: Button = %CollectionButton
@onready var _exit_button: Button = %ExitButton
@onready var _collection_count_label: Label = %CollectionCountLabel
@onready var _prompt_label: Label = %PromptLabel


func _ready() -> void:
	_open_pack_button.pressed.connect(GameManager.go_to_pack_hub)
	_collection_button.pressed.connect(func() -> void: GameManager.go_to_collection())
	_exit_button.pressed.connect(func() -> void: GameManager.quit_game())

	CollectionManager.collection_changed.connect(_update_collection_count)
	_update_collection_count()


func _update_collection_count() -> void:
	var count := CollectionManager.get_collection_count()
	_collection_count_label.text = "Collection: %d cards" % count
	if count == 0:
		_prompt_label.text = "You have a pack waiting — open it!"
	else:
		_prompt_label.text = "Open another pack to grow your collection."
