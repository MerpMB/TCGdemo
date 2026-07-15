class_name CardAnimation
extends RefCounted
## Card motion and FX tweens. Host Control (Card root) is the only movement target
## besides FlipPivot.scale.x and allowed FX (FoilShine sweep, spark/glow opacity).


const HOVER_SCALE := 1.06
const CLICK_SCALE := 0.94
const ANIM_DURATION := 0.12


var host: Control
var flip_pivot: Control
var foil_shine: ColorRect
var negative_overlay: ColorRect
var diamond_glow: ColorRect
var art_texture: TextureRect
var legendary_spark: ColorRect
var audio_flip: AudioStreamPlayer
var audio_rare: AudioStreamPlayer
var audio_legendary: AudioStreamPlayer

var base_scale := Vector2.ONE
var motion_tween: Tween
var variant_tween: Tween

## Callables provided by CardScene orchestration.
var show_face_up: Callable
var set_rarity_glow: Callable
var play_audio: Callable
var on_reveal_finished: Callable


func bind(
	p_host: Control,
	p_flip_pivot: Control,
	p_foil: ColorRect,
	p_negative: ColorRect,
	p_diamond_glow: ColorRect,
	p_art: TextureRect,
	p_spark: ColorRect,
	p_audio_flip: AudioStreamPlayer,
	p_audio_rare: AudioStreamPlayer,
	p_audio_legendary: AudioStreamPlayer
) -> void:
	host = p_host
	flip_pivot = p_flip_pivot
	foil_shine = p_foil
	negative_overlay = p_negative
	diamond_glow = p_diamond_glow
	art_texture = p_art
	legendary_spark = p_spark
	audio_flip = p_audio_flip
	audio_rare = p_audio_rare
	audio_legendary = p_audio_legendary


func setup_flip_pivot() -> void:
	flip_pivot.pivot_offset = flip_pivot.size * 0.5


func play_arrival(from_global: Vector2, to_global: Vector2, half_size: Vector2) -> void:
	host.global_position = from_global - half_size
	host.scale = Vector2.ZERO
	host.rotation = randf_range(-0.35, 0.35)
	host.modulate.a = 0.0
	host.show()

	kill_motion_tween()
	motion_tween = host.create_tween()
	motion_tween.set_parallel(true)
	motion_tween.set_trans(Tween.TRANS_BACK)
	motion_tween.set_ease(Tween.EASE_OUT)
	motion_tween.tween_property(host, "global_position", to_global - half_size, 0.42)
	motion_tween.tween_property(host, "scale", base_scale, 0.42)
	motion_tween.tween_property(host, "rotation", 0.0, 0.42)
	motion_tween.tween_property(host, "modulate:a", 1.0, 0.2)


func await_arrival(from_global: Vector2, to_global: Vector2, half_size: Vector2) -> void:
	play_arrival(from_global, to_global, half_size)
	if motion_tween:
		await motion_tween.finished


func play_pack_reveal(card_data: CardData, instant: bool) -> void:
	var rarity := card_data.rarity
	var duration := 0.12 if instant else CardVisualLibrary.get_reveal_duration(rarity)
	var lift := 0.0 if instant else CardVisualLibrary.get_reveal_lift(rarity)
	var rest_y := host.position.y

	kill_motion_tween()
	if flip_pivot.pivot_offset != flip_pivot.size * 0.5:
		flip_pivot.pivot_offset = flip_pivot.size * 0.5

	motion_tween = host.create_tween()
	motion_tween.tween_property(host, "position:y", rest_y + lift, duration * 0.35)

	if not instant and rarity >= CardData.Rarity.RARE and set_rarity_glow.is_valid():
		motion_tween.parallel().tween_method(
			set_rarity_glow,
			0.0,
			CardVisualLibrary.get_reveal_glow_alpha(rarity),
			duration
		)

	motion_tween.tween_property(flip_pivot, "scale:x", 0.0, duration * 0.45)
	await motion_tween.finished

	if show_face_up.is_valid():
		show_face_up.call()
	flip_pivot.scale.x = 0.0

	motion_tween = host.create_tween()
	motion_tween.tween_property(flip_pivot, "scale:x", 1.0, duration * 0.45)
	motion_tween.parallel().tween_property(host, "position:y", rest_y, duration * 0.45)
	await motion_tween.finished

	host.position.y = rest_y

	if not instant:
		await play_rarity_finish(rarity)

	play_variant_idle(card_data)
	if on_reveal_finished.is_valid():
		on_reveal_finished.call()


func play_rarity_finish(rarity: CardData.Rarity) -> void:
	match rarity:
		CardData.Rarity.RARE, CardData.Rarity.EPIC:
			_play(audio_rare)
			kill_motion_tween()
			motion_tween = host.create_tween()
			motion_tween.tween_property(host, "scale", base_scale * 1.08, 0.12)
			motion_tween.tween_property(host, "scale", base_scale, 0.14)
			await motion_tween.finished
		CardData.Rarity.LEGENDARY:
			_play(audio_legendary)
			legendary_spark.visible = true
			legendary_spark.modulate.a = 0.0
			kill_motion_tween()
			motion_tween = host.create_tween()
			motion_tween.set_parallel(true)
			motion_tween.tween_property(host, "scale", base_scale * 1.16, 0.18)
			motion_tween.tween_property(legendary_spark, "modulate:a", 0.85, 0.12)
			await motion_tween.finished
			motion_tween = host.create_tween()
			motion_tween.tween_property(host, "scale", base_scale, 0.2)
			motion_tween.parallel().tween_property(legendary_spark, "modulate:a", 0.0, 0.2)
			await motion_tween.finished
			legendary_spark.visible = false


func play_variant_idle(card_data: CardData) -> void:
	kill_variant_tween()

	if card_data == null:
		return

	match card_data.variant:
		CardData.Variant.FOIL:
			_start_foil_idle()
		CardData.Variant.NEGATIVE:
			_start_negative_idle()
		CardData.Variant.DIAMOND:
			_start_diamond_idle()


func kill_variant_tween() -> void:
	if variant_tween and variant_tween.is_valid():
		variant_tween.kill()
	variant_tween = null


func _start_foil_idle() -> void:
	if foil_shine == null or not foil_shine.visible:
		return
	var material := foil_shine.material as ShaderMaterial
	if material == null:
		return
	material.set_shader_parameter("sweep", -0.25)
	variant_tween = host.create_tween().set_loops()
	variant_tween.tween_method(
		func(value: float) -> void:
			if material:
				material.set_shader_parameter("sweep", value),
		-0.25,
		1.25,
		CardVisualLibrary.FOIL_SWEEP_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	variant_tween.tween_interval(CardVisualLibrary.FOIL_SWEEP_PAUSE)


func _start_negative_idle() -> void:
	var edge_material := negative_overlay.material as ShaderMaterial if negative_overlay else null
	var art_material := art_texture.material as ShaderMaterial if art_texture else null
	if edge_material == null and art_material == null:
		return
	variant_tween = host.create_tween().set_loops()
	variant_tween.tween_method(
		func(value: float) -> void:
			if edge_material:
				edge_material.set_shader_parameter("pulse", value)
			if art_material:
				art_material.set_shader_parameter("pulse", value),
		0.0,
		1.0,
		CardVisualLibrary.NEGATIVE_PULSE_DURATION * 0.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	variant_tween.tween_method(
		func(value: float) -> void:
			if edge_material:
				edge_material.set_shader_parameter("pulse", value)
			if art_material:
				art_material.set_shader_parameter("pulse", value),
		1.0,
		0.0,
		CardVisualLibrary.NEGATIVE_PULSE_DURATION * 0.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _start_diamond_idle() -> void:
	if diamond_glow == null or not diamond_glow.visible:
		return
	diamond_glow.modulate = Color(1.0, 1.0, 1.0, 0.88)
	variant_tween = host.create_tween().set_loops()
	variant_tween.tween_property(diamond_glow, "modulate:a", 1.0, 1.6) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	variant_tween.tween_property(diamond_glow, "modulate:a", 0.82, 1.9) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func play_click() -> void:
	kill_motion_tween()
	motion_tween = host.create_tween()
	motion_tween.tween_property(host, "scale", base_scale * CLICK_SCALE, ANIM_DURATION * 0.5)
	motion_tween.tween_property(host, "scale", base_scale * HOVER_SCALE, ANIM_DURATION * 0.5)


func tween_scale(target: Vector2) -> void:
	kill_motion_tween()
	motion_tween = host.create_tween()
	motion_tween.tween_property(host, "scale", target, ANIM_DURATION)


func tween_hover_in() -> void:
	tween_scale(base_scale * HOVER_SCALE)


func tween_hover_out() -> void:
	tween_scale(base_scale)


func kill_motion_tween() -> void:
	if motion_tween and motion_tween.is_valid():
		motion_tween.kill()


func _play(player: AudioStreamPlayer) -> void:
	if play_audio.is_valid():
		play_audio.call(player)
	elif player and player.stream:
		player.play()
