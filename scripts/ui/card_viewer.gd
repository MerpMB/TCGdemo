extends CanvasLayer
## Full-screen viewer to appreciate a single card.
## Reuses CardScene so artwork, rarity frame, and variant effects match gameplay.
## Presentation only — shows no description, stats, flavor text, artist, or metadata.


const CARD_SCENE := preload("res://scenes/Card.tscn")
const CARD_BASE_SIZE := Vector2(140, 200)
const ANIM_DURATION := 0.2
const DIM_ALPHA := 0.82
const OPEN_START_FACTOR := 0.7


@onready var _dimmer: ColorRect = %Dimmer
@onready var _card_holder: CenterContainer = %CardHolder
@onready var _close_button: Button = %CloseButton

var _card_scene: CardScene
var _tween: Tween
var _target_scale := 1.0
var _is_open := false


func _ready() -> void:
	_close_button.pressed.connect(hide_viewer)
	_dimmer.gui_input.connect(_on_dimmer_input)
	get_viewport().size_changed.connect(_on_viewport_resized)
	_hide_immediate()


func show_card(card_data: CardData) -> void:
	if card_data == null:
		return

	_ensure_card_scene()
	_card_scene.setup(card_data, CardScene.DisplayMode.PREVIEW)
	_card_scene.pivot_offset = CARD_BASE_SIZE * 0.5

	visible = true
	_is_open = true
	_target_scale = _compute_target_scale()

	_kill_tween()
	_dimmer.color = Color(0.0, 0.0, 0.0, 0.0)
	_card_scene.scale = Vector2.ONE * (_target_scale * OPEN_START_FACTOR)
	_card_scene.modulate.a = 0.0

	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(_dimmer, "color:a", DIM_ALPHA, ANIM_DURATION)
	_tween.tween_property(_card_scene, "scale", Vector2.ONE * _target_scale, ANIM_DURATION) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_card_scene, "modulate:a", 1.0, ANIM_DURATION * 0.8)


func hide_viewer() -> void:
	if not _is_open:
		return
	_is_open = false

	_kill_tween()
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(_dimmer, "color:a", 0.0, ANIM_DURATION)
	_tween.tween_property(_card_scene, "scale", Vector2.ONE * (_target_scale * OPEN_START_FACTOR), ANIM_DURATION) \
		.set_ease(Tween.EASE_IN)
	_tween.tween_property(_card_scene, "modulate:a", 0.0, ANIM_DURATION)
	await _tween.finished

	if not _is_open:
		visible = false


func _hide_immediate() -> void:
	_is_open = false
	visible = false
	_dimmer.color = Color(0.0, 0.0, 0.0, 0.0)


func _ensure_card_scene() -> void:
	if _card_scene and is_instance_valid(_card_scene):
		return
	_card_scene = CARD_SCENE.instantiate() as CardScene
	_card_scene.custom_minimum_size = CARD_BASE_SIZE
	_card_holder.add_child(_card_scene)


func _compute_target_scale() -> float:
	var viewport_size := get_viewport().get_visible_rect().size
	var scale_w := (viewport_size.x * 0.86) / CARD_BASE_SIZE.x
	var scale_h := (viewport_size.y * 0.72) / CARD_BASE_SIZE.y
	return maxf(1.0, minf(scale_w, scale_h))


func _on_viewport_resized() -> void:
	if not _is_open or _card_scene == null:
		return
	_target_scale = _compute_target_scale()
	_card_scene.pivot_offset = CARD_BASE_SIZE * 0.5
	_card_scene.scale = Vector2.ONE * _target_scale


func _on_dimmer_input(event: InputEvent) -> void:
	if _is_press_event(event):
		hide_viewer()


func _is_press_event(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return event.pressed
	if event is InputEventMouseButton:
		return event.pressed
	return false


func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()


# ---------------------------------------------------------------------------
# Future-ready hooks (Phase 6+). Intentionally not implemented.
# The viewer stays art-only; favorites, artist, description, lore, and flavor
# text can be layered on later as optional overlays without touching CardScene
# or the open/close flow. `get_active_card()` is the entry point for that data.
# ---------------------------------------------------------------------------

func get_active_card() -> CardData:
	if _card_scene and is_instance_valid(_card_scene):
		return _card_scene.get_card_data()
	return null


func toggle_favorite() -> void:
	pass
