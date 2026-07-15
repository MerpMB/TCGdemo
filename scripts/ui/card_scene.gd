class_name CardScene
extends Control
## Card orchestration only — rendering, animation, and interaction live in helpers.
##
## Transform ownership (layer-leak rules):
##   - Card root ONLY may receive position / global_position / rotation / scale /
##     modulate / z_index for motion.
##   - FlipPivot may ONLY change scale.x (horizontal flip).
##   - Protected render layers never receive movement transforms.
##   - FX (FoilShine, NegativeOverlay, DiamondGlow, RarityGlow, LegendarySpark,
##     RenderLayerContainer) may animate opacity, shader uniforms, or sweep only.


signal flipped(card_scene: CardScene)
signal card_pressed(card_scene: CardScene)
signal reveal_finished(card_scene: CardScene)


enum DisplayMode {
	PACK,
	GALLERY,
	PREVIEW,
}


@onready var _flip_pivot: Control = %FlipPivot
@onready var _back_face: Control = %BackFace
@onready var _back_texture: TextureRect = %BackTexture
@onready var _back_panel: Panel = %BackPanel
@onready var _front_face: Control = %FrontFace
@onready var _frame_texture: TextureRect = %FrameTexture
@onready var _frame_panel: Control = %FramePanel
@onready var _card_body: ColorRect = %CardBody
@onready var _art_texture: TextureRect = %ArtTexture
@onready var _render_layer_container: Control = %RenderLayerContainer
@onready var _rarity_glow: ColorRect = %RarityGlow
@onready var _negative_overlay: ColorRect = %NegativeOverlay
@onready var _foil_shine: ColorRect = %FoilShine
@onready var _alt_art_icon: ColorRect = %AltArtIcon
@onready var _diamond_glow: ColorRect = %DiamondGlow
@onready var _diamond_icon: ColorRect = %DiamondIcon
@onready var _legendary_spark: ColorRect = %LegendarySpark
@onready var _owned_count_badge: Label = %OwnedCountBadge
@onready var _flip_button: Button = %FlipButton
@onready var _audio_flip: AudioStreamPlayer = %AudioFlip
@onready var _audio_rare_reveal: AudioStreamPlayer = %AudioRareReveal
@onready var _audio_legendary_reveal: AudioStreamPlayer = %AudioLegendaryReveal

var _card_data: CardData
var _display_mode := DisplayMode.PACK
var _back_type := CardVisualLibrary.CardBackType.DEFAULT
var _is_revealed := false
var _pack_reveal_enabled := false
var _is_revealing := false

var _renderer := CardRenderer.new()
var _animation := CardAnimation.new()
var _interaction := CardInteraction.new()
var _layer_guard := CardLayerGuard.new()


func _ready() -> void:
	_bind_helpers()
	_animation.base_scale = scale
	_flip_button.pressed.connect(_on_flip_pressed)
	if not DisplayServer.is_touchscreen_available():
		mouse_entered.connect(_interaction.on_mouse_entered)
		mouse_exited.connect(_interaction.on_mouse_exited)
	gui_input.connect(_interaction.on_gui_input)
	_renderer.reset_variant_overlays()
	_renderer.show_face_down(false)
	call_deferred("_setup_flip_pivot_and_cache_rest")


func _bind_helpers() -> void:
	_renderer.bind(
		_art_texture, _card_body, _frame_texture, _frame_panel,
		_back_texture, _back_panel, _back_face, _front_face,
		_flip_pivot, _flip_button, _rarity_glow,
		_negative_overlay, _foil_shine, _alt_art_icon,
		_diamond_glow, _diamond_icon, _legendary_spark, _owned_count_badge,
		_render_layer_container
	)
	_renderer.host_size = size

	_animation.bind(
		self, _flip_pivot, _foil_shine, _negative_overlay,
		_diamond_glow, _art_texture, _legendary_spark,
		_audio_flip, _audio_rare_reveal, _audio_legendary_reveal
	)
	_animation.show_face_up = _renderer.show_face_up
	_animation.set_rarity_glow = _on_set_rarity_glow
	_animation.play_audio = _renderer.play_audio
	_animation.on_reveal_finished = _finish_reveal

	_interaction.bind(_animation, _emit_card_pressed)
	_layer_guard.bind(self, _flip_pivot)


func _setup_flip_pivot_and_cache_rest() -> void:
	_animation.setup_flip_pivot()
	_layer_guard.cache_rest()


func _process(delta: float) -> void:
	_layer_guard.assert_unmoved("process")
	_renderer.process_variant_idle(delta)


func setup(card_data: CardData, mode: DisplayMode = DisplayMode.PACK) -> void:
	_card_data = card_data
	_display_mode = mode
	_back_type = card_data.get_back_type() if card_data else CardVisualLibrary.CardBackType.DEFAULT
	_interaction.is_interactive = mode == DisplayMode.GALLERY
	_pack_reveal_enabled = false
	_is_revealing = false
	_is_revealed = mode != DisplayMode.PACK
	_renderer.host_size = size
	_renderer.apply(_card_data, _back_type)
	_configure_mode()


func set_pack_reveal_enabled(enabled: bool) -> void:
	_pack_reveal_enabled = enabled
	_flip_button.disabled = not enabled or _is_revealed


func is_revealed() -> bool:
	return _is_revealed


func get_card_data() -> CardData:
	return _card_data


func set_owned_count(count: int) -> void:
	_renderer.set_owned_count(count, _display_mode == DisplayMode.GALLERY)


func prepare_layout_scale(layout_scale: float) -> void:
	_animation.base_scale = Vector2.ONE * layout_scale


func get_layout_half_size() -> Vector2:
	return size * _animation.base_scale * 0.5


func play_arrival(from_global: Vector2, to_global: Vector2) -> void:
	_animation.play_arrival(from_global, to_global, get_layout_half_size())


func await_arrival(from_global: Vector2, to_global: Vector2) -> void:
	await _animation.await_arrival(from_global, to_global, get_layout_half_size())


func reveal_interactive() -> void:
	if _is_revealed or _is_revealing or _card_data == null:
		return
	_is_revealing = true
	_flip_button.disabled = true
	await _animation.play_pack_reveal(_card_data, false)


func reveal_instant() -> void:
	if _is_revealed or _card_data == null:
		return
	if _is_revealing:
		_animation.stop_all()
	_is_revealing = true
	_renderer.show_face_up()
	_flip_pivot.scale.x = 1.0
	_animation.play_variant_idle(_card_data)
	_finish_reveal(false)


func stop_presentation() -> void:
	_animation.stop_all()
	rotation = 0.0
	modulate.a = 1.0
	_legendary_spark.hide()


func _configure_mode() -> void:
	match _display_mode:
		DisplayMode.PACK:
			_flip_button.show()
			mouse_filter = Control.MOUSE_FILTER_IGNORE
			_owned_count_badge.hide()
			_renderer.show_face_down(_pack_reveal_enabled)
		DisplayMode.GALLERY:
			_flip_button.hide()
			mouse_filter = Control.MOUSE_FILTER_STOP
			_renderer.show_face_up()
			_animation.play_variant_idle(_card_data)
		DisplayMode.PREVIEW:
			_flip_button.hide()
			mouse_filter = Control.MOUSE_FILTER_IGNORE
			_owned_count_badge.hide()
			_renderer.show_face_up()
			scale = _animation.base_scale * 1.15
			_animation.play_variant_idle(_card_data)


func _on_flip_pressed() -> void:
	if not _pack_reveal_enabled or _is_revealed or _is_revealing:
		return
	reveal_interactive()


func _on_set_rarity_glow(alpha: float) -> void:
	_renderer.set_rarity_glow(_card_data, alpha)


func _finish_reveal(play_sound: bool = true) -> void:
	_is_revealed = true
	_is_revealing = false
	if play_sound:
		_renderer.play_audio(_audio_flip)
	_layer_guard.assert_unmoved("after_reveal")
	flipped.emit(self)
	reveal_finished.emit(self)


func _emit_card_pressed() -> void:
	card_pressed.emit(self)
