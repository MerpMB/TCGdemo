class_name PackAnimation
extends RefCounted
## Pack-opening FX helpers (pack shake/open/explode sequence + legendary flash).
## Does not own scene nodes — host Control creates tweens.


static func run_pack_sequence(pack_scene: PackScene, is_cancelled: Callable = Callable()) -> void:
	if pack_scene == null:
		return
	pack_scene.shake()
	await _await_presentation(pack_scene, is_cancelled)
	if _is_cancelled(is_cancelled) or not is_instance_valid(pack_scene):
		return
	pack_scene.open()
	await _await_presentation(pack_scene, is_cancelled)
	if _is_cancelled(is_cancelled) or not is_instance_valid(pack_scene):
		return
	pack_scene.explode()
	await _await_presentation(pack_scene, is_cancelled)


static func _await_presentation(pack_scene: PackScene, is_cancelled: Callable) -> void:
	while is_instance_valid(pack_scene) and pack_scene.is_presentation_playing():
		if _is_cancelled(is_cancelled):
			return
		await pack_scene.get_tree().process_frame


static func _is_cancelled(callback: Callable) -> bool:
	return callback.is_valid() and callback.call()


static func play_legendary_flash(host: Node, screen_flash: ColorRect) -> Tween:
	screen_flash.color = Color(0.95, 0.78, 0.18, 0.0)
	screen_flash.show()
	var tween := host.create_tween()
	tween.tween_property(screen_flash, "color:a", 0.35, 0.08)
	tween.tween_property(screen_flash, "color:a", 0.0, 0.22)
	tween.finished.connect(screen_flash.hide)
	return tween
