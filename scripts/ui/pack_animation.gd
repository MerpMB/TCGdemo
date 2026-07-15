class_name PackAnimation
extends RefCounted
## Pack-opening FX helpers (pack shake/open/explode sequence + legendary flash).
## Does not own scene nodes — host Control creates tweens.


static func run_pack_sequence(pack_scene: PackScene) -> void:
	if pack_scene == null:
		return
	pack_scene.shake()
	await pack_scene.shake_finished
	pack_scene.open()
	await pack_scene.open_finished
	pack_scene.explode()
	await pack_scene.explode_finished


static func play_legendary_flash(host: Node, screen_flash: ColorRect) -> void:
	screen_flash.color = Color(0.95, 0.78, 0.18, 0.0)
	screen_flash.show()
	var tween := host.create_tween()
	tween.tween_property(screen_flash, "color:a", 0.35, 0.08)
	tween.tween_property(screen_flash, "color:a", 0.0, 0.22)
	await tween.finished
	screen_flash.hide()
