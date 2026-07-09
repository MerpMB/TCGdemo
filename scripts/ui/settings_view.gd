extends Control
## Placeholder settings screen for future framework options.


@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_back_button.pressed.connect(func() -> void: GameManager.go_to_main_menu())
