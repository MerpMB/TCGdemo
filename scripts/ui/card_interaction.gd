class_name CardInteraction
extends RefCounted
## Gallery/preview input: hover scale and press detection.
## Does not touch render layers — forwards motion to CardAnimation.


var is_interactive := false
var animation: CardAnimation
var on_pressed: Callable


func bind(p_animation: CardAnimation, p_on_pressed: Callable) -> void:
	animation = p_animation
	on_pressed = p_on_pressed


func on_mouse_entered() -> void:
	if not is_interactive or animation == null:
		return
	animation.tween_hover_in()


func on_mouse_exited() -> void:
	if not is_interactive or animation == null:
		return
	animation.tween_hover_out()


func on_gui_input(event: InputEvent) -> void:
	if not is_interactive:
		return
	if _is_press_event(event):
		if animation:
			animation.play_click()
		if on_pressed.is_valid():
			on_pressed.call()


func _is_press_event(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return event.pressed
	if event is InputEventMouseButton:
		return event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	return false
