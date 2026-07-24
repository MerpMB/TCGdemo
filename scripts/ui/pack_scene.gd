class_name PackScene
extends Control
## Issue 24.1 — Physical wrapper peel (five-stage).
## Single update path:
##   TearController → progress → wrapper geometry → (detach) → finished
## No lighting, cavity, rarity, cards, or FX.

signal shake_finished
signal open_finished
signal explode_finished
signal tear_progress_changed(progress: float)
signal tear_completed

enum WrapperStage {
	CLOSED,
	PEELING,
	FULL_PEEL,
	DETACHING,
	FINISHED,
}

## Locked foundation defaults (Issue #33 approved feel). Tweaks use @export sliders;
## values are always clamped so casual edits cannot break the peel contract.
const FOUNDATION_TOP_SEAM_RATIO := 0.13
const FOUNDATION_PEEL_START := 0.04
const FOUNDATION_MIN_PEEL_WIDTH_RATIO := 0.04
const FOUNDATION_FULL_ATTACH_OPENING := 0.94
## <1 front-loads tear travel so ~40% and below feel a bit faster; 1.0 stays linear.
const FOUNDATION_EARLY_PACE_POWER := 0.82
const FOUNDATION_PEEL_ROT_START := 0.5
const FOUNDATION_PEEL_ROT_END := 1.12
const FOUNDATION_FULL_PEEL_HOLD := 0.55
## Keep visual tear locked to drag % (no laggy catch-up that desyncs the label).
const FOUNDATION_PROGRESS_CATCHUP_RATE := 10.0
const FOUNDATION_DETACH_DURATION := 0.6
const FOUNDATION_DETACH_DRIFT := Vector2(72.0, -140.0)
const FOUNDATION_DETACH_EXTRA_SPIN := 0.7
## First third of opening: rotation stays sticky (resistance) before free lift.
const FOUNDATION_ROT_DELAY := 0.33
## Ease-in power during the sticky phase (higher = more early resistance).
const FOUNDATION_ROT_RESISTANCE := 2.4
## Rotation reached by the end of the sticky phase, as a fraction of peel_rot_start.
const FOUNDATION_STICKY_ROT_FRACTION := 0.28
## Free-lift ease-out power after the sticky phase.
const FOUNDATION_FREE_LIFT_EASE := 1.55
## Soft foil curl along the peeled strip (bone-chain bend, not a rigid board).
const FOUNDATION_BEND_STRENGTH := 1.0
const BEND_BONE_COUNT := 5
## Early curl floor (radians) — grows linearly toward the end pose with peel %.
const FOUNDATION_BEND_FROM_PROGRESS := 0.55
## How strongly the strip aims at the pull cursor (1 = tip points at hand).
const FOUNDATION_CURSOR_AIM := 1.0
## Max joint fold — past vertical so the free tip can sit up-right of the hinge.
const FOUNDATION_BEND_MAX := 2.35
## Full-peel hold pose: strip hinged at top-right, free tip up-right (~45° diagonal).
const FOUNDATION_END_POSE_CURL := 2.2
## Curl eases linearly from this opening toward the end pose (no late skyrocket).
const FOUNDATION_END_POSE_START := 0.0
## Higher = sharper fold at the peel joint; free tip stays straighter.
const FOUNDATION_BEND_POWER := 3.4
## Kept for compatibility; linear end-pose blend owns late curl now.
const FOUNDATION_CURL_PEAK_AT := 0.45
const FOUNDATION_CURL_END_RELAX := 1.0
## Pixel overlap at the tear tip so strip + seal share foil (kills the hard joint seam).
const JOINT_OVERLAP_RATIO := 0.04
## Root peel angle folded into bone curl (hinge stays flat on the pack).
const ROOT_PEEL_INTO_CURL := 0.2
## Bone fold sign: positive = free end lifts UP above the pack (screenshots confirm).
const PEEL_FOLD_SIGN := 1.0
## Smooth foil curl toward target (kills mouse-noise / aim-threshold jitter).
const FOUNDATION_CURL_SMOOTH_FAST := 16.0
## Stronger smoothing while dragging slowly (tremor dominates intentional motion).
const FOUNDATION_CURL_SMOOTH_SLOW := 5.0
## Soft visual progress follow while dragging (avoids 1px peel-width stutter).
const FOUNDATION_PROGRESS_SMOOTH_FAST := 22.0
const FOUNDATION_PROGRESS_SMOOTH_SLOW := 9.0
## Aim angle deadzone (radians) — ignore tiny aim wobble while holding/slow pulling.
const AIM_ANGLE_DEADZONE := 0.045
## Aim latch distances (hysteresis so curl doesn't flicker on/off near the hinge).
const AIM_ENGAGE_DIST := 52.0
const AIM_RELEASE_DIST := 30.0

const FALLBACK_SPRITE_SIZE := Vector2(180.0, 240.0)
const TEAR_FINISH_VISUAL := 0.995

@export_group("Peel Tuning (24.1)")
## Fraction of pack height used as the top foil band.
@export_range(0.08, 0.22, 0.005) var top_seam_ratio: float = FOUNDATION_TOP_SEAM_RATIO
## Drag progress before the pack leaves the intact closed pose.
@export_range(0.0, 0.25, 0.01) var peel_start: float = FOUNDATION_PEEL_START
## Left-corner width when the tear first appears.
@export_range(0.02, 0.35, 0.01) var min_peel_width_ratio: float = FOUNDATION_MIN_PEEL_WIDTH_RATIO
## Opening amount at which the strip is fully peeled but still attached on the right.
@export_range(0.75, 0.99, 0.01) var full_attach_opening: float = FOUNDATION_FULL_ATTACH_OPENING
## Upward peel-back angle at the end of the sticky/resistance phase (radians).
@export_range(0.2, 1.0, 0.01) var peel_rot_start: float = FOUNDATION_PEEL_ROT_START
## Upward peel-back angle when fully peeled and still attached.
@export_range(0.6, 1.6, 0.01) var peel_rot_end: float = FOUNDATION_PEEL_ROT_END
## Opening fraction with delayed rotation (foil resists before lifting freely).
@export_range(0.15, 0.5, 0.01) var rot_delay: float = FOUNDATION_ROT_DELAY
## Sticky-phase ease-in power (1 = linear, higher = more resistance).
@export_range(1.0, 4.0, 0.05) var rot_resistance: float = FOUNDATION_ROT_RESISTANCE
## Foil softness — bend tracks peel % and cursor pull (higher = more follow).
@export_range(0.0, 1.5, 0.01) var bend_strength: float = FOUNDATION_BEND_STRENGTH
## How long the fully-peeled-attached pose is held before detach.
@export_range(0.2, 1.2, 0.01) var full_peel_hold: float = FOUNDATION_FULL_PEEL_HOLD
## How quickly visual progress catches drag progress.
@export_range(0.5, 12.0, 0.1) var progress_catchup_rate: float = FOUNDATION_PROGRESS_CATCHUP_RATE
@export_range(0.25, 1.2, 0.01) var detach_duration: float = FOUNDATION_DETACH_DURATION
@export var detach_drift: Vector2 = FOUNDATION_DETACH_DRIFT
@export_range(-1.5, 1.5, 0.01) var detach_extra_spin: float = FOUNDATION_DETACH_EXTRA_SPIN

@export_group("Pack Profile")
@export var profile_id: String = "starter"
@export var primary_color: Color = Color(0.28, 0.38, 0.72)
@export var accent_color: Color = Color(0.95, 0.78, 0.2)
@export var pack_art: Texture2D

@onready var _pack_sprite: Panel = %PackSprite
@onready var _pack_art: TextureRect = %PackArt
@onready var _top_flap_pivot: Control = %TopFlapPivot
@onready var _pack_flap: TextureRect = %PackFlap
@onready var _top_seal: TextureRect = %TopSeal
@onready var _pack_label: Label = %PackLabel
@onready var _animation_player: AnimationPlayer = %AnimationPlayer
@onready var _audio_open: AudioStreamPlayer = %AudioOpen

var _tear_controller := PackTearController.new()
var _manual_tear_enabled := false
var _finish_emitted := false
var _target_progress := 0.0
var _visual_progress := 0.0
var _sprite_rest_position := Vector2.ZERO
var _presentation_scale := 1.0
var _body_atlas: AtlasTexture
var _strip_atlas: AtlasTexture
var _seal_atlas: AtlasTexture
var _stage: WrapperStage = WrapperStage.CLOSED
var _detach_tween: Tween
var _strip_rest_position := Vector2.ZERO
var _full_peel_hold_remaining := -1.0
## Soft foil bones: nested from tear tip (hinge) toward the free left end.
var _bend_bones: Array[Control] = []
var _bend_rects: Array[TextureRect] = []
var _bend_atlases: Array[AtlasTexture] = []
var _curl_display := 0.0
var _aim_latched := false
var _aim_smoothed := -1.0
var _frame_delta := 0.0167
var _progress_speed := 0.0
var _prev_target_progress := 0.0


# ============================================================================
# Lifecycle
# ============================================================================

func _ready() -> void:
	_animation_player.animation_finished.connect(_on_animation_finished)
	gui_input.connect(_on_gui_input)
	_sprite_rest_position = _pack_sprite.position
	_pack_sprite.pivot_offset = _pack_sprite.size * 0.5
	_configure_wrapper_nodes()
	_clear_wrapper_materials()
	_cleanup_legacy_runtime_nodes()
	_apply_profile_colors()
	_reset_visual_state()


func _process(delta: float) -> void:
	_frame_delta = maxf(delta, 0.0001)
	if _stage == WrapperStage.DETACHING or _stage == WrapperStage.FINISHED:
		return

	## Hold the fully-peeled-attached pose so it is readable before detach.
	if _full_peel_hold_remaining >= 0.0:
		_full_peel_hold_remaining -= delta
		_apply_full_attached_pose()
		if _full_peel_hold_remaining <= 0.0:
			_full_peel_hold_remaining = -1.0
			_begin_detach()
		return

	if not _manual_tear_enabled:
		return
	_tick_progress(delta)
	_update_wrapper_from_progress(_visual_progress)
	if _tear_controller.is_complete and _visual_progress >= TEAR_FINISH_VISUAL:
		_begin_full_peel_hold()


# ============================================================================
# Public API
# ============================================================================

func setup_profile(id: String, primary: Color, accent: Color, art: Texture2D = null) -> void:
	profile_id = id
	primary_color = primary
	accent_color = accent
	pack_art = art
	if is_node_ready():
		_apply_profile_colors()
		_update_wrapper_from_progress(0.0)


func set_presentation_scale(scale_factor: float) -> void:
	_presentation_scale = maxf(scale_factor, 0.01)
	pivot_offset = size * 0.5
	scale = Vector2.ONE * _presentation_scale


func get_burst_origin() -> Vector2:
	return get_global_rect().get_center()


func get_open_top_origin() -> Vector2:
	return get_global_transform() * Vector2(
		_pack_sprite.size.x * 0.5, _pack_sprite.size.y * _seam_ratio()
	)


func get_physical_state() -> PackTearController.PhysicalState:
	match _stage:
		WrapperStage.FULL_PEEL:
			return PackTearController.PhysicalState.FULLY_OPEN
		WrapperStage.DETACHING:
			return PackTearController.PhysicalState.PEELING
		WrapperStage.FINISHED:
			return PackTearController.PhysicalState.FULLY_OPEN
		_:
			return _tear_controller.get_physical_state(_visual_progress)


func get_peel_progress() -> float:
	return _visual_progress


func get_wrapper_stage() -> WrapperStage:
	return _stage


## highest_rarity kept for API compatibility; unused in 24.1.
func enable_manual_tear(_highest_rarity: int = 0) -> void:
	_kill_detach_tween()
	_full_peel_hold_remaining = -1.0
	_stage = WrapperStage.CLOSED
	_manual_tear_enabled = true
	_finish_emitted = false
	_target_progress = 0.0
	_visual_progress = 0.0
	_curl_display = 0.0
	_aim_latched = false
	_aim_smoothed = -1.0
	_progress_speed = 0.0
	_prev_target_progress = 0.0
	_tear_controller.reset()
	_pack_flap.modulate = Color.WHITE
	mouse_filter = Control.MOUSE_FILTER_STOP
	_update_wrapper_from_progress(0.0)
	show()


func force_complete_tear() -> void:
	if _finish_emitted or _stage == WrapperStage.DETACHING or _stage == WrapperStage.FINISHED:
		return
	if _full_peel_hold_remaining >= 0.0:
		return
	_tear_controller.progress = 1.0
	_tear_controller.is_complete = true
	_target_progress = 1.0
	_visual_progress = 1.0
	_update_wrapper_from_progress(1.0)
	_begin_full_peel_hold()


func stop_presentation() -> void:
	_animation_player.stop()
	_kill_detach_tween()
	_full_peel_hold_remaining = -1.0
	_manual_tear_enabled = false
	_target_progress = 0.0
	_visual_progress = 0.0
	_tear_controller.reset()
	_stage = WrapperStage.CLOSED
	_finish_emitted = false
	_reset_visual_state()


func is_presentation_playing() -> bool:
	return (
		_manual_tear_enabled
		or _full_peel_hold_remaining >= 0.0
		or _stage == WrapperStage.DETACHING
	)


func begin_idle() -> void:
	_reset_visual_state()


## Compatibility alias used by verification scripts.
func _apply_physical_peel(progress: float) -> void:
	_update_wrapper_from_progress(progress)


## Restore Issue #33 approved peel feel after experimental slider tweaks.
func reset_peel_tuning_to_foundation() -> void:
	top_seam_ratio = FOUNDATION_TOP_SEAM_RATIO
	peel_start = FOUNDATION_PEEL_START
	min_peel_width_ratio = FOUNDATION_MIN_PEEL_WIDTH_RATIO
	full_attach_opening = FOUNDATION_FULL_ATTACH_OPENING
	peel_rot_start = FOUNDATION_PEEL_ROT_START
	peel_rot_end = FOUNDATION_PEEL_ROT_END
	rot_delay = FOUNDATION_ROT_DELAY
	rot_resistance = FOUNDATION_ROT_RESISTANCE
	bend_strength = FOUNDATION_BEND_STRENGTH
	full_peel_hold = FOUNDATION_FULL_PEEL_HOLD
	progress_catchup_rate = FOUNDATION_PROGRESS_CATCHUP_RATE
	detach_duration = FOUNDATION_DETACH_DURATION
	detach_drift = FOUNDATION_DETACH_DRIFT
	detach_extra_spin = FOUNDATION_DETACH_EXTRA_SPIN
	if is_node_ready():
		_update_wrapper_from_progress(_visual_progress)


func _seam_ratio() -> float:
	return clampf(top_seam_ratio, 0.08, 0.22)


func _peel_start() -> float:
	return clampf(peel_start, 0.0, 0.25)


func _min_peel_width_ratio() -> float:
	return clampf(min_peel_width_ratio, 0.02, 0.35)


func _full_attach_opening() -> float:
	return clampf(full_attach_opening, 0.75, 0.99)


func _peel_rot_start() -> float:
	return clampf(peel_rot_start, 0.2, 1.0)


func _peel_rot_end() -> float:
	return maxf(clampf(peel_rot_end, 0.6, 1.6), _peel_rot_start() + 0.15)


func _rot_delay() -> float:
	return clampf(rot_delay, 0.15, 0.5)


func _rot_resistance() -> float:
	return clampf(rot_resistance, 1.0, 4.0)


func _bend_strength() -> float:
	return clampf(bend_strength, 0.0, 1.5)


## Cursor aim: radians of upward fold so the free tip points at the pull hand.
## Only while actively dragging — idle mouse must not change the peel pose.
## Returns < 0 when there is no usable aim (verify / not dragging).
func _cursor_aim_radians(peel_w: float, seam_height: float) -> float:
	if not _manual_tear_enabled or not is_inside_tree():
		_aim_latched = false
		_aim_smoothed = -1.0
		return -1.0
	if not _tear_controller.is_tracking:
		_aim_latched = false
		_aim_smoothed = -1.0
		return -1.0
	if _top_flap_pivot == null or not _top_flap_pivot.visible:
		_aim_latched = false
		_aim_smoothed = -1.0
		return -1.0
	## Hinge sits at the tear tip (right end of the peeled strip).
	var hinge := Vector2(peel_w, seam_height)
	var mouse := _top_flap_pivot.get_local_mouse_position()
	var delta := mouse - hinge
	var dist := delta.length()
	## Hysteresis: engage/release at different distances so aim doesn't flicker.
	if _aim_latched:
		if dist < AIM_RELEASE_DIST:
			_aim_latched = false
			_aim_smoothed = -1.0
			return -1.0
	elif dist < AIM_ENGAGE_DIST:
		return -1.0
	else:
		_aim_latched = true
	## Rest strip points left from the hinge. Godot CCW-to-up is negative;
	## our +PEEL_FOLD_SIGN lifts up, so invert.
	var lift := clampf(-Vector2.LEFT.angle_to(delta), 0.0, FOUNDATION_BEND_MAX)
	## Deadzone + smooth: slow pulls wobble the angle every frame otherwise.
	if _aim_smoothed < 0.0:
		_aim_smoothed = lift
	elif absf(lift - _aim_smoothed) <= AIM_ANGLE_DEADZONE:
		lift = _aim_smoothed
	else:
		var aim_blend := 1.0 - exp(-8.0 * _frame_delta)
		_aim_smoothed = lerpf(_aim_smoothed, lift, clampf(aim_blend, 0.0, 1.0))
		lift = _aim_smoothed
	_aim_smoothed = lift
	return lift


## Mid-peel pull is strong; near the end settle to a lifted resting fold (still UP, not sagging).
func _curl_envelope(opening: float) -> float:
	var o := clampf(opening, 0.0, 1.0)
	var peak := clampf(FOUNDATION_CURL_PEAK_AT, 0.2, 0.85)
	if o <= peak:
		return smoothstep(0.0, peak, o)
	var t := (o - peak) / maxf(1.0 - peak, 0.001)
	return lerpf(1.0, FOUNDATION_CURL_END_RELAX, smoothstep(0.0, 1.0, t))


## Target foil curl before smoothing.
func _target_strip_curl(opening: float, peel_rot: float, peel_w: float, seam_height: float) -> float:
	var strength := _bend_strength()
	var o := clampf(opening, 0.0, 1.0)
	var early := (
		o * FOUNDATION_BEND_FROM_PROGRESS + absf(peel_rot) * ROOT_PEEL_INTO_CURL
	) * strength
	var end_pose := clampf(FOUNDATION_END_POSE_CURL, 1.2, FOUNDATION_BEND_MAX) * maxf(strength, 0.75)
	var end_start := clampf(FOUNDATION_END_POSE_START, 0.0, 0.85)
	var t := 0.0
	if o > end_start:
		t = (o - end_start) / maxf(1.0 - end_start, 0.001)
	var curl := lerpf(early, end_pose, clampf(t, 0.0, 1.0))

	## Idle cursor / hover must not reshape the strip — only an active drag pull.
	var aim := _cursor_aim_radians(peel_w, seam_height)
	if aim >= 0.0:
		var follow := aim * FOUNDATION_CURSOR_AIM * maxf(strength, 0.75)
		curl = maxf(curl, follow)
	return minf(curl, FOUNDATION_BEND_MAX)


## Smoothed foil curl — pulls harder filter when drag is slow (tremor dominates).
func _total_strip_curl(opening: float, peel_rot: float, peel_w: float, seam_height: float) -> float:
	var target := _target_strip_curl(opening, peel_rot, peel_w, seam_height)
	if not _manual_tear_enabled or _stage == WrapperStage.FULL_PEEL:
		_curl_display = target
		return target
	var speed_t := clampf(_progress_speed / 0.4, 0.0, 1.0)
	var rate := lerpf(FOUNDATION_CURL_SMOOTH_SLOW, FOUNDATION_CURL_SMOOTH_FAST, speed_t)
	var blend := 1.0 - exp(-rate * _frame_delta)
	_curl_display = lerpf(_curl_display, target, clampf(blend, 0.0, 1.0))
	return _curl_display


func _joint_overlap_px(width: float, peel_w: float) -> float:
	return minf(width * JOINT_OVERLAP_RATIO, maxf(peel_w * 0.22, 2.0))


func _full_peel_hold() -> float:
	return clampf(full_peel_hold, 0.2, 1.2)


func _progress_catchup_rate() -> float:
	return clampf(progress_catchup_rate, 0.5, 12.0)


func _detach_duration() -> float:
	return clampf(detach_duration, 0.25, 1.2)


func _detach_drift() -> Vector2:
	## Keep detach flying up/back; never allow a downward "fold onto pack" drift.
	var drift := detach_drift
	if drift.y > -40.0:
		drift.y = FOUNDATION_DETACH_DRIFT.y
	return drift


func _detach_extra_spin() -> float:
	## Keep detach spin in the upward peel direction (same sign as PEEL_FOLD_SIGN).
	var spin := clampf(detach_extra_spin, -1.5, 1.5)
	if spin * PEEL_FOLD_SIGN < 0.0:
		spin = absf(spin) * PEEL_FOLD_SIGN
	return spin


## Rotation vs opening: sticky first third, then freer lift (not a linear rigid board).
func _peel_rotation_for_opening(opening: float) -> float:
	var o := clampf(opening, 0.0, 1.0)
	var delay := _rot_delay()
	var rot_start := _peel_rot_start()
	var rot_end := _peel_rot_end()
	var sticky_cap := rot_start * FOUNDATION_STICKY_ROT_FRACTION
	if o <= delay:
		var t := o / maxf(delay, 0.001)
		var sticky := pow(t, _rot_resistance())
		return lerpf(0.0, sticky_cap, sticky)
	var t2 := (o - delay) / maxf(1.0 - delay, 0.001)
	var free_t := 1.0 - pow(1.0 - t2, FOUNDATION_FREE_LIFT_EASE)
	return lerpf(sticky_cap, rot_end, free_t)


# ============================================================================
# Progress (TearController → smoothed progress)
# ============================================================================

func _on_gui_input(event: InputEvent) -> void:
	if not _manual_tear_enabled or _stage == WrapperStage.DETACHING:
		return
	if _full_peel_hold_remaining >= 0.0:
		return
	var changed := false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if _tear_controller.begin(event.position, size):
				grab_click_focus()
				accept_event()
			return
		_tear_controller.end()
		accept_event()
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			if _tear_controller.begin(event.position, size):
				accept_event()
			return
		_tear_controller.end()
		accept_event()
		return
	if event is InputEventMouseMotion:
		changed = _tear_controller.update(event.position, size)
	elif event is InputEventScreenDrag:
		changed = _tear_controller.update(event.position, size)
	if changed:
		_target_progress = _tear_controller.progress
		tear_progress_changed.emit(_target_progress)
		accept_event()


func _tick_progress(delta: float) -> void:
	## Track how fast the drag % is changing (slow pulls need heavier smoothing).
	_progress_speed = absf(_target_progress - _prev_target_progress) / maxf(delta, 0.0001)
	_prev_target_progress = _target_progress
	if _tear_controller.is_tracking:
		## Soft follow — hard lockstep made slow 1px advances look like peel-width jitter.
		var speed_t := clampf(_progress_speed / 0.4, 0.0, 1.0)
		var rate := lerpf(
			FOUNDATION_PROGRESS_SMOOTH_SLOW, FOUNDATION_PROGRESS_SMOOTH_FAST, speed_t
		)
		var blend := 1.0 - exp(-rate * delta)
		_visual_progress = lerpf(_visual_progress, _target_progress, clampf(blend, 0.0, 1.0))
		## Never lag too far behind an intentional drag.
		if _target_progress - _visual_progress > 0.06:
			_visual_progress = _target_progress - 0.06
		return
	_visual_progress = move_toward(
		_visual_progress, _target_progress, delta * _progress_catchup_rate()
	)


# ============================================================================
# Wrapper geometry (Frames 1–3)
# ============================================================================

func _update_wrapper_from_progress(progress: float) -> void:
	if not is_node_ready():
		return
	if _stage == WrapperStage.DETACHING or _stage == WrapperStage.FINISHED:
		return
	if _full_peel_hold_remaining >= 0.0:
		return

	var metrics := _compute_peel_metrics(progress)
	_reset_pack_sprite_transform()

	if metrics.opening < 0.001:
		_stage = WrapperStage.CLOSED
		_apply_closed_wrapper()
		return
	if pack_art == null:
		return

	_ensure_atlases()
	_apply_body_geometry(metrics)
	if metrics.is_full_attached:
		_stage = WrapperStage.FULL_PEEL
		_apply_peel_strip(metrics, true)
	else:
		_stage = WrapperStage.PEELING
		_apply_peel_strip(metrics, false)


func _compute_peel_metrics(progress: float) -> Dictionary:
	var p := clampf(progress, 0.0, 1.0)
	var start := _peel_start()
	var opening := clampf((p - start) / maxf(1.0 - start, 0.001), 0.0, 1.0)
	## Mild ease-out: early % covers a bit more seal; end still lands at full width.
	var paced := _paced_opening(opening)
	var sprite_size := _pack_sprite.size
	if sprite_size.x < 1.0 or sprite_size.y < 1.0:
		sprite_size = FALLBACK_SPRITE_SIZE
	var seam_height := sprite_size.y * _seam_ratio()
	var width: float = sprite_size.x
	## Tear tip travels left → right (paced so low % feels slightly quicker).
	var peel_width := width * paced
	if opening > 0.0:
		## Tiny visible tip only — avoid the old big jump that made early peel feel stuck.
		peel_width = maxf(peel_width, width * _min_peel_width_ratio())
	var is_full_attached := opening >= _full_attach_opening()
	if is_full_attached:
		peel_width = width
	var peel_rot := _peel_rotation_for_opening(paced)
	if is_full_attached:
		peel_rot = _peel_rot_end()
	return {
		"progress": p,
		"opening": paced,
		"seam_height": seam_height,
		"width": width,
		"height": sprite_size.y,
		"peel_width": peel_width,
		"peel_rotation": peel_rot,
		"is_full_attached": is_full_attached,
	}


## Front-load tear travel a little under ~40%; identity at 0 and 1.
func _paced_opening(opening: float) -> float:
	var o := clampf(opening, 0.0, 1.0)
	if o <= 0.0:
		return 0.0
	return pow(o, FOUNDATION_EARLY_PACE_POWER)


func _reset_pack_sprite_transform() -> void:
	## Body never distorts — only the foil strip moves.
	_pack_sprite.position = _sprite_rest_position
	_pack_sprite.scale = Vector2.ONE
	_pack_sprite.rotation = 0.0


func _apply_closed_wrapper() -> void:
	## Frame 1 — intact pack, seal attached, no gap.
	_curl_display = 0.0
	_aim_latched = false
	_aim_smoothed = -1.0
	if pack_art:
		_pack_art.texture = pack_art
		_pack_art.position = Vector2.ZERO
		_pack_art.size = _pack_sprite.size
		_pack_art.show()
	_top_seal.hide()
	_top_flap_pivot.hide()
	_reset_bend_bones()
	_pack_flap.hide()
	_pack_flap.modulate = Color.WHITE


func _apply_body_geometry(metrics: Dictionary) -> void:
	## Stationary pack body (lower portion). Top strip is separate.
	var source := _source_size()
	var seam := _seam_ratio()
	_body_atlas.region = Rect2(0.0, source.y * seam, source.x, source.y * (1.0 - seam))
	if _pack_art.texture != _body_atlas:
		_pack_art.texture = _body_atlas
	_pack_art.position = Vector2(0.0, metrics.seam_height)
	_pack_art.size = Vector2(metrics.width, metrics.height - metrics.seam_height)
	_pack_art.show()


func _apply_peel_strip(metrics: Dictionary, full_attached: bool) -> void:
	## Peeled segment = left → tear tip. Soft bone chain curls the free end.
	## Hinge bone stays flat on the pack so the joint with TopSeal looks continuous.
	var source := _source_size()
	var width: float = metrics.width
	var seam_height: float = metrics.seam_height
	var peel_w: float = metrics.peel_width
	var peel_rot: float = metrics.peel_rotation
	var opening: float = metrics.opening
	var seam := _seam_ratio()

	var peel_src_w := source.x * (peel_w / maxf(width, 0.001))
	var seam_src_h := source.y * seam
	var overlap := _joint_overlap_px(width, peel_w)
	var overlap_src := source.x * (overlap / maxf(width, 0.001))

	_ensure_bend_bones()
	## Legacy single flap stays hidden; bones own the strip draw.
	_pack_flap.hide()
	_pack_flap.modulate = Color.WHITE

	_top_flap_pivot.visible = true
	_top_flap_pivot.z_index = 5
	_top_flap_pivot.position = Vector2.ZERO
	_top_flap_pivot.size = Vector2(peel_w, seam_height)
	_top_flap_pivot.pivot_offset = Vector2(peel_w, seam_height)
	## Keep the tear-tip hinge coplanar with the unpeeled seal (no hard V-gap).
	_top_flap_pivot.rotation = 0.0
	_top_flap_pivot.scale = Vector2.ONE
	_top_flap_pivot.modulate = Color.WHITE
	_strip_rest_position = _top_flap_pivot.position

	_layout_bend_bones(peel_w, seam_height, peel_src_w, seam_src_h, peel_rot, opening)

	if full_attached or peel_w >= width - 0.5:
		_top_seal.hide()
		return

	## Unpeeled seal underlaps the hinge bone so foil textures meet seamlessly.
	var seal_start := maxf(peel_w - overlap, 0.0)
	var seal_src_start := maxf(peel_src_w - overlap_src, 0.0)
	_seal_atlas.region = Rect2(seal_src_start, 0.0, source.x - seal_src_start, seam_src_h)
	if _top_seal.texture != _seal_atlas:
		_top_seal.texture = _seal_atlas
	_top_seal.z_index = 4
	_top_seal.position = Vector2(seal_start, 0.0)
	_top_seal.size = Vector2(width - seal_start, seam_height)
	_top_seal.rotation = 0.0
	_top_seal.modulate = Color.WHITE
	_top_seal.show()


func _ensure_bend_bones() -> void:
	## Rebuild if bone count changed between foundation tweaks.
	if _bend_bones.size() == BEND_BONE_COUNT:
		return
	for bone in _bend_bones:
		if is_instance_valid(bone):
			bone.queue_free()
	_bend_bones.clear()
	_bend_rects.clear()
	_bend_atlases.clear()
	var parent: Control = _top_flap_pivot
	for i in BEND_BONE_COUNT:
		var bone := Control.new()
		bone.name = "BendBone%d" % i
		bone.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bone.set_anchors_preset(Control.PRESET_TOP_LEFT)
		parent.add_child(bone)
		var rect := TextureRect.new()
		rect.name = "BendRect%d" % i
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.set_anchors_preset(Control.PRESET_TOP_LEFT)
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_SCALE
		bone.add_child(rect)
		var atlas := AtlasTexture.new()
		_bend_bones.append(bone)
		_bend_rects.append(rect)
		_bend_atlases.append(atlas)
		parent = bone


func _layout_bend_bones(
	peel_w: float,
	seam_height: float,
	peel_src_w: float,
	seam_src_h: float,
	peel_rot: float,
	opening: float
) -> void:
	var n := BEND_BONE_COUNT
	var seg_w := peel_w / float(n)
	var seg_src := peel_src_w / float(n)
	var curl := _total_strip_curl(opening, peel_rot, peel_w, seam_height)
	## Positive fold lifts the free end up/back above the pack (green-line pose).
	var peel_sign := PEEL_FOLD_SIGN

	for i in n:
		var bone := _bend_bones[i]
		var rect := _bend_rects[i]
		var atlas := _bend_atlases[i]
		bone.visible = true
		bone.size = Vector2(maxf(seg_w, 1.0), seam_height)
		bone.pivot_offset = Vector2(bone.size.x, seam_height)
		if i == 0:
			## Flush overlap with TopSeal — continuous foil at the tear tip.
			bone.position = Vector2(peel_w - seg_w, 0.0)
			bone.rotation = 0.0
		else:
			## Child extends left; fold is hinge-weighted (max bend at joint, taut tip).
			bone.position = Vector2(-seg_w, 0.0)
			var prev_cum := _hinge_fold_cum(i - 1, n)
			var curr_cum := _hinge_fold_cum(i, n)
			bone.rotation = peel_sign * curl * (curr_cum - prev_cum)
		bone.scale = Vector2.ONE

		## Atlas slices right→left match hinge→tip bone order.
		var src_x := peel_src_w - seg_src * float(i + 1)
		atlas.atlas = pack_art
		atlas.region = Rect2(src_x, 0.0, seg_src, seam_src_h)
		rect.texture = atlas
		rect.position = Vector2.ZERO
		rect.size = bone.size
		rect.modulate = Color.WHITE
		rect.show()


## Cumulative fold from joint → tip: most bend at the peel front, tip stays straight.
func _hinge_fold_cum(i: int, n: int) -> float:
	if n <= 1:
		return 1.0
	var t := clampf(float(i) / float(n - 1), 0.0, 1.0)
	return 1.0 - pow(1.0 - t, FOUNDATION_BEND_POWER)


func _reset_bend_bones() -> void:
	for bone in _bend_bones:
		if is_instance_valid(bone):
			bone.rotation = 0.0
			bone.hide()
	_top_flap_pivot.modulate = Color.WHITE
	_pack_flap.modulate = Color.WHITE


func _apply_full_attached_pose() -> void:
	## Frame 3 — entire strip peeled back, still hinged on the far right.
	var metrics := _compute_peel_metrics(1.0)
	_reset_pack_sprite_transform()
	_ensure_atlases()
	_apply_body_geometry(metrics)
	_stage = WrapperStage.FULL_PEEL
	_curl_display = clampf(FOUNDATION_END_POSE_CURL, 1.2, FOUNDATION_BEND_MAX)
	_apply_peel_strip(metrics, true)


func _begin_full_peel_hold() -> void:
	if _finish_emitted or _stage == WrapperStage.DETACHING or _stage == WrapperStage.FINISHED:
		return
	if _full_peel_hold_remaining >= 0.0:
		return
	_manual_tear_enabled = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_full_peel_hold_remaining = _full_peel_hold()
	_apply_full_attached_pose()


# ============================================================================
# Detach (Frame 4) → Finished (Frame 5)
# ============================================================================

func _begin_detach() -> void:
	if _stage == WrapperStage.DETACHING or _stage == WrapperStage.FINISHED or _finish_emitted:
		return

	_manual_tear_enabled = false
	_full_peel_hold_remaining = -1.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage = WrapperStage.DETACHING

	## Start from the held attached pose, then break free.
	_apply_full_attached_pose()
	_stage = WrapperStage.DETACHING

	_kill_detach_tween()
	_detach_tween = create_tween()
	_detach_tween.set_parallel(true)
	_detach_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var start_pos := _top_flap_pivot.position
	var start_rot := _top_flap_pivot.rotation
	var drift := _detach_drift()
	var duration := _detach_duration()
	_detach_tween.tween_property(_top_flap_pivot, "position", start_pos + drift, duration)
	_detach_tween.tween_property(
		_top_flap_pivot, "rotation", start_rot + _detach_extra_spin(), duration
	)
	_detach_tween.tween_property(_top_flap_pivot, "modulate:a", 0.0, duration)
	_detach_tween.chain().tween_callback(_on_detach_finished)


func _on_detach_finished() -> void:
	## Frame 5 — strip gone, pack body remains open, animation stops.
	_stage = WrapperStage.FINISHED
	_top_flap_pivot.hide()
	_top_flap_pivot.position = _strip_rest_position
	_top_flap_pivot.rotation = 0.0
	_top_flap_pivot.modulate = Color.WHITE
	_reset_bend_bones()
	_pack_flap.modulate = Color.WHITE
	_finish_emitted = true
	_play_audio(_audio_open)
	tear_completed.emit()


func _kill_detach_tween() -> void:
	if _detach_tween and _detach_tween.is_valid():
		_detach_tween.kill()
	_detach_tween = null


# ============================================================================
# Materials / atlas helpers
# ============================================================================

func _configure_wrapper_nodes() -> void:
	_pack_art.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_top_seal.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_top_flap_pivot.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_pack_flap.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_pack_art.stretch_mode = TextureRect.STRETCH_SCALE
	_top_seal.stretch_mode = TextureRect.STRETCH_SCALE
	_pack_flap.stretch_mode = TextureRect.STRETCH_SCALE


func _clear_wrapper_materials() -> void:
	_pack_art.material = null
	_top_seal.material = null
	_pack_flap.material = null
	for rect in _bend_rects:
		if is_instance_valid(rect):
			rect.material = null


func _apply_profile_colors() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	_pack_sprite.add_theme_stylebox_override("panel", style)
	_pack_label.text = profile_id.capitalize()
	_invalidate_atlases()
	_clear_wrapper_materials()
	if pack_art:
		_pack_art.show()
		_pack_label.hide()
	else:
		_pack_art.hide()
		_top_seal.hide()
		_pack_flap.hide()
		_reset_bend_bones()
		_pack_label.show()


func _invalidate_atlases() -> void:
	_body_atlas = null
	_strip_atlas = null
	_seal_atlas = null


func _ensure_atlases() -> void:
	if pack_art == null:
		return
	if _body_atlas == null or _body_atlas.atlas != pack_art:
		_body_atlas = AtlasTexture.new()
		_body_atlas.atlas = pack_art
	if _strip_atlas == null or _strip_atlas.atlas != pack_art:
		_strip_atlas = AtlasTexture.new()
		_strip_atlas.atlas = pack_art
	if _seal_atlas == null or _seal_atlas.atlas != pack_art:
		_seal_atlas = AtlasTexture.new()
		_seal_atlas.atlas = pack_art


func _source_size() -> Vector2:
	return pack_art.get_size() if pack_art else Vector2(1.0, 1.0)


func _cleanup_legacy_runtime_nodes() -> void:
	var leftover := _pack_sprite.get_node_or_null("BackWrapper")
	if leftover:
		leftover.queue_free()


func _reset_visual_state() -> void:
	_kill_detach_tween()
	_full_peel_hold_remaining = -1.0
	_curl_display = 0.0
	_aim_latched = false
	_aim_smoothed = -1.0
	_progress_speed = 0.0
	_prev_target_progress = 0.0
	_stage = WrapperStage.CLOSED
	_finish_emitted = false
	modulate = Color.WHITE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pack_sprite.modulate = Color.WHITE
	_pack_sprite.scale = Vector2.ONE
	_pack_sprite.rotation = 0.0
	_pack_sprite.position = _sprite_rest_position
	_pack_flap.modulate = Color.WHITE
	_top_flap_pivot.modulate = Color.WHITE
	_top_flap_pivot.rotation = 0.0
	_top_flap_pivot.position = Vector2.ZERO
	_top_seal.rotation = 0.0
	_top_seal.modulate = Color.WHITE
	_reset_bend_bones()
	_cleanup_legacy_runtime_nodes()
	_update_wrapper_from_progress(0.0)
	show()


# ============================================================================
# Audio / animation callbacks
# ============================================================================

func _on_animation_finished(animation_name: StringName) -> void:
	match animation_name:
		"shake":
			shake_finished.emit()
		"open":
			open_finished.emit()
		"explode":
			explode_finished.emit()


func _play_audio(player: AudioStreamPlayer) -> void:
	if player and player.stream:
		player.play()


# ============================================================================
# Legacy API (orphan PackAnimation / PackPresentationDirector)
# ============================================================================

func shake() -> void:
	pass


func open() -> void:
	pass


func explode() -> void:
	force_complete_tear()


func build_energy() -> void:
	pass


func fracture() -> void:
	pass


func burst() -> void:
	force_complete_tear()


func prepare_cinematic(_highest_rarity: int = 0) -> void:
	enable_manual_tear(_highest_rarity)


func play_energy_build() -> void:
	pass


func play_crack() -> void:
	pass


func play_burst() -> void:
	force_complete_tear()


func get_presentation_accent() -> Color:
	return accent_color


func get_rarity_light_color() -> Color:
	return accent_color
