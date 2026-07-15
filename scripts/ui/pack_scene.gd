class_name PackScene
extends Control
## Reusable pack presentation object. Owns pack animations and audio placeholders.
## PackOpening orchestrates timing via finished signals — no hardcoded delays there.


signal shake_finished
signal open_finished
signal explode_finished


@export var profile_id: String = "starter"
@export var primary_color: Color = Color(0.28, 0.38, 0.72)
@export var accent_color: Color = Color(0.95, 0.78, 0.2)


@onready var _pack_sprite: Panel = %PackSprite
@onready var _pack_label: Label = %PackLabel
@onready var _glow: ColorRect = %Glow
@onready var _animation_player: AnimationPlayer = %AnimationPlayer
@onready var _audio_shake: AudioStreamPlayer = %AudioShake
@onready var _audio_open: AudioStreamPlayer = %AudioOpen
@onready var _audio_explode: AudioStreamPlayer = %AudioExplode


func _ready() -> void:
	_animation_player.animation_finished.connect(_on_animation_finished)
	_apply_profile_colors()
	_reset_visual_state()


func setup_profile(id: String, primary: Color, accent: Color) -> void:
	profile_id = id
	primary_color = primary
	accent_color = accent
	_apply_profile_colors()


func get_burst_origin() -> Vector2:
	return global_position + size * 0.5


func shake() -> void:
	_play_audio(_audio_shake)
	_animation_player.play("shake")


func open() -> void:
	_play_audio(_audio_open)
	_glow.visible = true
	_animation_player.play("open")


func explode() -> void:
	_play_audio(_audio_explode)
	_animation_player.play("explode")


func is_presentation_playing() -> bool:
	return _animation_player.is_playing()


func stop_presentation() -> void:
	_animation_player.stop()
	_audio_shake.stop()
	_audio_open.stop()
	_audio_explode.stop()
	_glow.hide()
	_pack_sprite.rotation = 0.0


func _apply_profile_colors() -> void:
	var sprite_style := StyleBoxFlat.new()
	sprite_style.bg_color = primary_color
	sprite_style.border_color = accent_color
	sprite_style.border_width_left = 4
	sprite_style.border_width_top = 4
	sprite_style.border_width_right = 4
	sprite_style.border_width_bottom = 4
	sprite_style.corner_radius_top_left = 12
	sprite_style.corner_radius_top_right = 12
	sprite_style.corner_radius_bottom_right = 12
	sprite_style.corner_radius_bottom_left = 12
	_pack_sprite.add_theme_stylebox_override("panel", sprite_style)
	_glow.color = Color(accent_color.r, accent_color.g, accent_color.b, 0.0)
	_pack_label.text = profile_id.capitalize()


func _reset_visual_state() -> void:
	_pack_sprite.modulate = Color.WHITE
	_pack_sprite.scale = Vector2.ONE
	_pack_sprite.rotation = 0.0
	_glow.visible = false
	_glow.modulate = Color(1, 1, 1, 0)
	show()


func _on_animation_finished(animation_name: StringName) -> void:
	match animation_name:
		"shake":
			shake_finished.emit()
		"open":
			open_finished.emit()
		"explode":
			explode_finished.emit()


func _play_audio(player: AudioStreamPlayer) -> void:
	if player.stream:
		player.play()
