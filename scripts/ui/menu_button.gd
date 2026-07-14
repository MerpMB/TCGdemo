extends Button
## Menu button with press feedback for touch and pointer devices.


@export var hover_modulate: Color = Color(1.12, 1.12, 1.18, 1.0)
@export var press_modulate: Color = Color(0.92, 0.92, 0.96, 1.0)

var _base_modulate: Color = Color.WHITE
var _feedback_tween: Tween


func _ready() -> void:
	_base_modulate = modulate
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	if not DisplayServer.is_touchscreen_available():
		mouse_entered.connect(_on_mouse_entered)
		mouse_exited.connect(_on_mouse_exited)


func _on_mouse_entered() -> void:
	_start_modulate_tween(hover_modulate)


func _on_mouse_exited() -> void:
	_start_modulate_tween(_base_modulate)


func _on_button_down() -> void:
	_start_modulate_tween(press_modulate)


func _on_button_up() -> void:
	if DisplayServer.is_touchscreen_available():
		_start_modulate_tween(_base_modulate)
	elif not is_hovered():
		_start_modulate_tween(_base_modulate)


func _start_modulate_tween(target: Color) -> void:
	if _feedback_tween and _feedback_tween.is_valid():
		_feedback_tween.kill()

	_feedback_tween = create_tween()
	_feedback_tween.tween_property(self, "modulate", target, 0.12)
