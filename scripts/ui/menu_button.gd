extends Button
## Menu button with lightweight hover color feedback.


@export var hover_modulate: Color = Color(1.12, 1.12, 1.18, 1.0)

var _base_modulate: Color = Color.WHITE
var _hover_tween: Tween


func _ready() -> void:
	_base_modulate = modulate
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _on_mouse_entered() -> void:
	_start_modulate_tween(hover_modulate)


func _on_mouse_exited() -> void:
	_start_modulate_tween(_base_modulate)


func _start_modulate_tween(target: Color) -> void:
	if _hover_tween and _hover_tween.is_valid():
		_hover_tween.kill()

	_hover_tween = create_tween()
	_hover_tween.tween_property(self, "modulate", target, 0.12)
