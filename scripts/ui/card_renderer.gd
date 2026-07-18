class_name CardRenderer
extends RefCounted
## Applies CardData visuals onto CardScene node refs.
## Texture / StyleBox lookups go through CardVisualLibrary — no asset paths here.


const CARD_BODY_COLOR := Color(0.06, 0.07, 0.1, 1.0)


var art_texture: TextureRect
var card_body: ColorRect
var frame_texture: TextureRect
var frame_panel: Control
var back_texture: TextureRect
var back_panel: Panel
var back_face: Control
var front_face: Control
var flip_pivot: Control
var flip_button: Button
var rarity_glow: ColorRect
var negative_overlay: ColorRect
var foil_shine: ColorRect
var alt_art_icon: ColorRect
var diamond_glow: ColorRect
var diamond_icon: ColorRect
var legendary_spark: ColorRect
var owned_count_badge: Label
var render_layer_container: Control
## Host Control size (for foil reset). Set by CardScene.
var host_size := Vector2.ZERO

var _variant_renderer: VariantRenderer = VariantRenderer.new()


func bind(
	p_art: TextureRect,
	p_body: ColorRect,
	p_frame_tex: TextureRect,
	p_frame_panel: Control,
	p_back_tex: TextureRect,
	p_back_panel: Panel,
	p_back_face: Control,
	p_front_face: Control,
	p_flip_pivot: Control,
	p_flip_button: Button,
	p_glow: ColorRect,
	p_negative: ColorRect,
	p_foil: ColorRect,
	p_alt: ColorRect,
	p_diamond_glow: ColorRect,
	p_diamond_icon: ColorRect,
	p_spark: ColorRect,
	p_badge: Label,
	p_render_layer_container: Control
) -> void:
	art_texture = p_art
	card_body = p_body
	frame_texture = p_frame_tex
	frame_panel = p_frame_panel
	back_texture = p_back_tex
	back_panel = p_back_panel
	back_face = p_back_face
	front_face = p_front_face
	flip_pivot = p_flip_pivot
	flip_button = p_flip_button
	rarity_glow = p_glow
	negative_overlay = p_negative
	foil_shine = p_foil
	alt_art_icon = p_alt
	diamond_glow = p_diamond_glow
	diamond_icon = p_diamond_icon
	legendary_spark = p_spark
	owned_count_badge = p_badge
	render_layer_container = p_render_layer_container
	_variant_renderer.bind(render_layer_container, host_size)


func apply(card_data: CardData, back_type: CardVisualLibrary.CardBackType) -> void:
	if card_data == null:
		return
	apply_frame(card_data)
	apply_card_back(card_data, back_type)
	var rarity_color := CardData.get_rarity_color(card_data.rarity)
	apply_artwork(card_data)
	rarity_glow.color = Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.0)
	configure_variant_overlay(card_data)
	_variant_renderer.bind(render_layer_container, host_size)
	_variant_renderer.apply(card_data)


func process_variant_idle(delta: float) -> void:
	_variant_renderer.process_idle(delta)


func apply_frame(card_data: CardData) -> void:
	var frame := CardVisualLibrary.get_frame_texture(
		CardVisualLibrary.resolve_frame_key(card_data)
	)
	if frame != null:
		frame_texture.texture = frame
		frame_texture.visible = true
		frame_panel.visible = false
	else:
		frame_texture.texture = null
		frame_texture.visible = false
		frame_panel.visible = true
		frame_panel.add_theme_stylebox_override(
			"panel",
			CardVisualLibrary.get_frame_overlay_style(card_data.rarity)
		)


func apply_card_back(card_data: CardData, back_type: CardVisualLibrary.CardBackType) -> void:
	var back_name := card_data.card_back if card_data else ""
	var texture := CardVisualLibrary.get_card_back_texture(back_name)
	if texture != null:
		back_texture.texture = texture
		back_texture.visible = true
		back_panel.visible = false
	else:
		back_texture.texture = null
		back_texture.visible = false
		back_panel.visible = true
		back_panel.add_theme_stylebox_override(
			"panel",
			CardVisualLibrary.get_card_back_style(back_type)
		)


func apply_artwork(card_data: CardData) -> void:
	art_texture.material = null
	art_texture.modulate = Color.WHITE
	var texture := CardVisualLibrary.resolve_artwork(card_data)
	var has_art := texture != null
	art_texture.texture = texture
	art_texture.visible = has_art
	card_body.visible = not has_art
	if has_art:
		card_body.color = CARD_BODY_COLOR
	else:
		card_body.color = CardData.get_rarity_color(card_data.rarity)


func configure_variant_overlay(card_data: CardData) -> void:
	reset_variant_overlays()
	match card_data.variant:
		CardData.Variant.FOIL:
			pass
		CardData.Variant.NEGATIVE:
			_apply_negative_overlay()
		CardData.Variant.ALTERNATIVE_ART:
			pass
		CardData.Variant.DIAMOND:
			_apply_diamond_overlay()
		CardData.Variant.SYNTH:
			pass


func _apply_negative_overlay() -> void:
	art_texture.material = CardVisualLibrary.create_negative_invert_material()
	negative_overlay.material = CardVisualLibrary.create_negative_edge_material()
	negative_overlay.color = Color(1.0, 1.0, 1.0, 1.0)
	negative_overlay.visible = true


func _apply_diamond_overlay() -> void:
	## The PSD overlay is materialized by the generic VariantRenderer.
	pass

func reset_variant_overlays() -> void:
	card_body.material = null
	art_texture.material = null
	art_texture.modulate = Color.WHITE
	frame_texture.material = null
	frame_panel.material = null

	negative_overlay.material = null
	negative_overlay.color = Color(0.02, 0.02, 0.04, 0.55)
	negative_overlay.visible = false
	foil_shine.material = null
	foil_shine.visible = false
	alt_art_icon.material = null
	alt_art_icon.visible = false
	diamond_glow.material = null
	diamond_glow.visible = false
	diamond_icon.material = null
	diamond_icon.visible = false
	legendary_spark.visible = false
	foil_shine.position.x = -host_size.x
	_variant_renderer.reset()


func show_face_down(pack_reveal_enabled: bool) -> void:
	back_face.show()
	front_face.hide()
	flip_pivot.scale.x = 1.0
	flip_button.disabled = not pack_reveal_enabled


func show_face_up() -> void:
	back_face.hide()
	front_face.show()
	flip_button.disabled = true


func set_owned_count(count: int, gallery_mode: bool) -> void:
	if not gallery_mode or count < 1:
		owned_count_badge.hide()
		return
	owned_count_badge.text = "×%d" % count
	owned_count_badge.show()


func set_rarity_glow(card_data: CardData, alpha: float) -> void:
	if card_data == null:
		return
	var color := CardData.get_rarity_color(card_data.rarity)
	rarity_glow.color = Color(color.r, color.g, color.b, alpha)


func play_audio(player: AudioStreamPlayer) -> void:
	if player and player.stream:
		player.play()
