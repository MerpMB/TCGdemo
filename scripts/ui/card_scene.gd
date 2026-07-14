class_name CardScene
extends Control
## Visual representation of a single card, used everywhere (pack, gallery, viewer).
##
## Responsibilities are grouped into clearly separated sections below:
##   - Rendering: artwork, frame, and variant overlays (all driven by CardData)
##   - Face state: front/back visibility
##   - Reveal animation: the pack flip, arrival, and rarity finish
##   - Input & interaction: taps, hover, click feedback
## All per-card visuals resolve from CardData; nothing is hardcoded per card.


signal flipped(card_scene: CardScene)
signal card_pressed(card_scene: CardScene)
signal reveal_finished(card_scene: CardScene)


enum DisplayMode {
	PACK,
	GALLERY,
	PREVIEW,
}


const HOVER_SCALE := 1.06
const CLICK_SCALE := 0.94
const ANIM_DURATION := 0.12
## Neutral opaque backing behind full-bleed artwork (prevents alpha wash-out).
const CARD_BODY_COLOR := Color(0.06, 0.07, 0.1, 1.0)


@onready var _flip_pivot: Control = %FlipPivot
@onready var _back_face: Control = %BackFace
@onready var _front_face: Control = %FrontFace
@onready var _frame_texture: TextureRect = %FrameTexture
@onready var _frame_panel: Control = %FramePanel
@onready var _card_body: ColorRect = %CardBody
@onready var _art_texture: TextureRect = %ArtTexture
@onready var _rarity_glow: ColorRect = %RarityGlow
@onready var _negative_overlay: ColorRect = %NegativeOverlay
@onready var _foil_shine: ColorRect = %FoilShine
@onready var _alt_art_icon: ColorRect = %AltArtIcon
@onready var _diamond_glow: ColorRect = %DiamondGlow
@onready var _diamond_icon: ColorRect = %DiamondIcon
@onready var _legendary_spark: ColorRect = %LegendarySpark
@onready var _flip_button: Button = %FlipButton
@onready var _audio_flip: AudioStreamPlayer = %AudioFlip
@onready var _audio_rare_reveal: AudioStreamPlayer = %AudioRareReveal
@onready var _audio_legendary_reveal: AudioStreamPlayer = %AudioLegendaryReveal

var _card_data: CardData
var _display_mode := DisplayMode.PACK
var _back_type := CardVisualLibrary.CardBackType.DEFAULT
var _is_revealed := false
var _is_interactive := false
var _pack_reveal_enabled := false
var _is_revealing := false
var _base_scale := Vector2.ONE
var _pivot_rest_position := Vector2.ZERO
var _motion_tween: Tween
var _variant_tween: Tween


func _ready() -> void:
	_base_scale = scale
	_pivot_rest_position = _flip_pivot.position
	_flip_button.pressed.connect(_on_flip_pressed)
	if not DisplayServer.is_touchscreen_available():
		mouse_entered.connect(_on_mouse_entered)
		mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)
	_reset_variant_overlays()
	_show_face_down()


func setup(card_data: CardData, mode: DisplayMode = DisplayMode.PACK) -> void:
	_card_data = card_data
	_display_mode = mode
	_back_type = card_data.get_back_type() if card_data else CardVisualLibrary.CardBackType.DEFAULT
	_is_interactive = mode == DisplayMode.GALLERY
	_pack_reveal_enabled = false
	_is_revealing = false
	_is_revealed = mode != DisplayMode.PACK
	_apply_card_data()
	_configure_mode()


func set_pack_reveal_enabled(enabled: bool) -> void:
	_pack_reveal_enabled = enabled
	_flip_button.disabled = not enabled or _is_revealed


func is_revealed() -> bool:
	return _is_revealed


func get_card_data() -> CardData:
	return _card_data


func prepare_layout_scale(layout_scale: float) -> void:
	_base_scale = Vector2.ONE * layout_scale


func get_layout_half_size() -> Vector2:
	return size * _base_scale * 0.5


func play_arrival(from_global: Vector2, to_global: Vector2) -> void:
	var half_size := get_layout_half_size()
	global_position = from_global - half_size
	scale = Vector2.ZERO
	rotation = randf_range(-0.35, 0.35)
	modulate.a = 0.0
	show()

	_kill_motion_tween()
	_motion_tween = create_tween()
	_motion_tween.set_parallel(true)
	_motion_tween.set_trans(Tween.TRANS_BACK)
	_motion_tween.set_ease(Tween.EASE_OUT)
	_motion_tween.tween_property(self, "global_position", to_global - half_size, 0.42)
	_motion_tween.tween_property(self, "scale", _base_scale, 0.42)
	_motion_tween.tween_property(self, "rotation", 0.0, 0.42)
	_motion_tween.tween_property(self, "modulate:a", 1.0, 0.2)


func await_arrival(from_global: Vector2, to_global: Vector2) -> void:
	play_arrival(from_global, to_global)
	if _motion_tween:
		await _motion_tween.finished


func reveal_interactive() -> void:
	if _is_revealed or _is_revealing or _card_data == null:
		return
	await _play_pack_reveal(false)


func reveal_instant() -> void:
	if _is_revealed or _card_data == null:
		return

	if _is_revealing:
		_kill_motion_tween()

	_is_revealing = true
	_show_face_up()
	_flip_pivot.scale.x = 1.0
	_flip_pivot.position = _pivot_rest_position
	_play_variant_idle()
	_finish_reveal()


func _configure_mode() -> void:
	match _display_mode:
		DisplayMode.PACK:
			_flip_button.show()
			mouse_filter = Control.MOUSE_FILTER_IGNORE
			_show_face_down()
		DisplayMode.GALLERY:
			_flip_button.hide()
			mouse_filter = Control.MOUSE_FILTER_STOP
			_show_face_up()
			_play_variant_idle()
		DisplayMode.PREVIEW:
			_flip_button.hide()
			mouse_filter = Control.MOUSE_FILTER_IGNORE
			_show_face_up()
			scale = _base_scale * 1.15
			_play_variant_idle()


# ---------------------------------------------------------------------------
# Rendering — artwork, frame, and variant overlays (all resolved from CardData)
# ---------------------------------------------------------------------------

func _apply_card_data() -> void:
	if _card_data == null:
		return

	_apply_frame()
	_back_face.add_theme_stylebox_override(
		"panel",
		CardVisualLibrary.get_card_back_style(_back_type)
	)

	var rarity_color := CardData.get_rarity_color(_card_data.rarity)
	_apply_artwork()
	_rarity_glow.color = Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.0)

	_configure_variant_overlay()


## Frame overlay is data-driven via CardData.get_frame_key(). If production frame
## art exists (assets/frames/<key>.png) it is used; otherwise we fall back to the
## procedural rarity border so the card always renders. No hardcoded textures.
func _apply_frame() -> void:
	var frame := CardVisualLibrary.get_frame_texture(_card_data.get_frame_key())
	if frame != null:
		_frame_texture.texture = frame
		_frame_texture.visible = true
		_frame_panel.visible = false
	else:
		_frame_texture.texture = null
		_frame_texture.visible = false
		_frame_panel.visible = true
		_frame_panel.add_theme_stylebox_override(
			"panel",
			CardVisualLibrary.get_frame_overlay_style(_card_data.rarity)
		)


## Full-bleed artwork is the bottom layer of the front face. The opaque CardBody
## sits behind the front so any alpha in the artwork blends over a neutral dark
## base (never a bright rarity color), preventing washed-out artwork. When a
## card has no artwork, the body falls back to the rarity color.
func _apply_artwork() -> void:
	var has_art := _card_data.artwork != null
	_art_texture.texture = _card_data.artwork
	_art_texture.visible = has_art
	if has_art:
		_card_body.color = CARD_BODY_COLOR
	else:
		_card_body.color = CardData.get_rarity_color(_card_data.rarity)


func _configure_variant_overlay() -> void:
	_reset_variant_overlays()

	match _card_data.variant:
		CardData.Variant.FOIL:
			_foil_shine.visible = true
		CardData.Variant.NEGATIVE:
			_negative_overlay.visible = true
		CardData.Variant.ALTERNATIVE_ART:
			_alt_art_icon.visible = true
		CardData.Variant.DIAMOND:
			_diamond_glow.visible = true
			_diamond_icon.visible = true


func _reset_variant_overlays() -> void:
	_negative_overlay.visible = false
	_foil_shine.visible = false
	_alt_art_icon.visible = false
	_diamond_glow.visible = false
	_diamond_icon.visible = false
	_legendary_spark.visible = false
	_foil_shine.position.x = -size.x


# ---------------------------------------------------------------------------
# Face state
# ---------------------------------------------------------------------------

func _show_face_down() -> void:
	_back_face.show()
	_front_face.hide()
	_flip_pivot.scale.x = 1.0
	_flip_button.disabled = not _pack_reveal_enabled


func _show_face_up() -> void:
	_back_face.hide()
	_front_face.show()
	_flip_button.disabled = true


# ---------------------------------------------------------------------------
# Reveal animation
# ---------------------------------------------------------------------------

func _on_flip_pressed() -> void:
	if not _pack_reveal_enabled or _is_revealed or _is_revealing:
		return
	reveal_interactive()


## Reveal flip. The card moves as one unit: the vertical "lift" is applied to
## the card root (self) so its clip rect travels with the artwork/frame and
## nothing is clipped at the top. Only the flip's horizontal squash uses the
## FlipPivot, which carries both faces together (art and frame never desync).
## The lift always settles back to the exact rest position.
func _play_pack_reveal(instant: bool) -> void:
	_is_revealing = true
	_flip_button.disabled = true

	var rarity := _card_data.rarity
	var duration := 0.12 if instant else CardVisualLibrary.get_reveal_duration(rarity)
	var lift := 0.0 if instant else CardVisualLibrary.get_reveal_lift(rarity)
	var rest_y := position.y

	_kill_motion_tween()
	_flip_pivot.position = _pivot_rest_position
	_flip_pivot.pivot_offset = _flip_pivot.size * 0.5

	_motion_tween = create_tween()
	_motion_tween.tween_property(self, "position:y", rest_y + lift, duration * 0.35)

	if not instant and rarity >= CardData.Rarity.RARE:
		_motion_tween.parallel().tween_method(_set_rarity_glow, 0.0, CardVisualLibrary.get_reveal_glow_alpha(rarity), duration)

	_motion_tween.tween_property(_flip_pivot, "scale:x", 0.0, duration * 0.45)
	await _motion_tween.finished

	_show_face_up()
	_flip_pivot.scale.x = 0.0

	_motion_tween = create_tween()
	_motion_tween.tween_property(_flip_pivot, "scale:x", 1.0, duration * 0.45)
	_motion_tween.parallel().tween_property(self, "position:y", rest_y, duration * 0.45)
	await _motion_tween.finished

	position.y = rest_y

	if not instant:
		await _play_rarity_finish(rarity)

	_play_variant_idle()
	_finish_reveal()


func _play_rarity_finish(rarity: CardData.Rarity) -> void:
	match rarity:
		CardData.Rarity.RARE, CardData.Rarity.EPIC:
			_play_audio(_audio_rare_reveal)
			_kill_motion_tween()
			_motion_tween = create_tween()
			_motion_tween.tween_property(self, "scale", _base_scale * 1.08, 0.12)
			_motion_tween.tween_property(self, "scale", _base_scale, 0.14)
			await _motion_tween.finished
		CardData.Rarity.LEGENDARY:
			_play_audio(_audio_legendary_reveal)
			_legendary_spark.visible = true
			_legendary_spark.modulate.a = 0.0
			_kill_motion_tween()
			_motion_tween = create_tween()
			_motion_tween.set_parallel(true)
			_motion_tween.tween_property(self, "scale", _base_scale * 1.16, 0.18)
			_motion_tween.tween_property(_legendary_spark, "modulate:a", 0.85, 0.12)
			await _motion_tween.finished
			_motion_tween = create_tween()
			_motion_tween.tween_property(self, "scale", _base_scale, 0.2)
			_motion_tween.parallel().tween_property(_legendary_spark, "modulate:a", 0.0, 0.2)
			await _motion_tween.finished
			_legendary_spark.visible = false


func _finish_reveal() -> void:
	_is_revealed = true
	_is_revealing = false
	_play_audio(_audio_flip)
	flipped.emit(self)
	reveal_finished.emit(self)


func _play_variant_idle() -> void:
	if _variant_tween and _variant_tween.is_valid():
		_variant_tween.kill()

	if _card_data == null:
		return

	if _card_data.variant == CardData.Variant.FOIL and _foil_shine.visible:
		_foil_shine.position.x = -size.x * 0.6
		_variant_tween = create_tween().set_loops()
		_variant_tween.tween_property(_foil_shine, "position:x", size.x * 1.2, 1.4)
		_variant_tween.tween_interval(0.8)


func _set_rarity_glow(alpha: float) -> void:
	if _card_data == null:
		return
	var color := CardData.get_rarity_color(_card_data.rarity)
	_rarity_glow.color = Color(color.r, color.g, color.b, alpha)


# ---------------------------------------------------------------------------
# Input & interaction
# ---------------------------------------------------------------------------

func _on_mouse_entered() -> void:
	if not _is_interactive:
		return
	_tween_scale(_base_scale * HOVER_SCALE)


func _on_mouse_exited() -> void:
	if not _is_interactive:
		return
	_tween_scale(_base_scale)


func _on_gui_input(event: InputEvent) -> void:
	if not _is_interactive:
		return

	if _is_press_event(event):
		_play_click_animation()
		card_pressed.emit(self)


func _is_press_event(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return event.pressed
	if event is InputEventMouseButton:
		return event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	return false


func _play_click_animation() -> void:
	_kill_motion_tween()
	_motion_tween = create_tween()
	_motion_tween.tween_property(self, "scale", _base_scale * CLICK_SCALE, ANIM_DURATION * 0.5)
	_motion_tween.tween_property(self, "scale", _base_scale * HOVER_SCALE, ANIM_DURATION * 0.5)


func _tween_scale(target: Vector2) -> void:
	_kill_motion_tween()
	_motion_tween = create_tween()
	_motion_tween.tween_property(self, "scale", target, ANIM_DURATION)


func _kill_motion_tween() -> void:
	if _motion_tween and _motion_tween.is_valid():
		_motion_tween.kill()


func _play_audio(player: AudioStreamPlayer) -> void:
	if player.stream:
		player.play()
