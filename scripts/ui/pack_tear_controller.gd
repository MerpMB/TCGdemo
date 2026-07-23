class_name PackTearController
extends RefCounted
## Top-seal drag for a physical foil tear.
## Progress is how far across the sealed edge the tear tip has traveled.


enum PhysicalState {
	CLOSED,
	TENSION,
	TINY_RIP,
	GROWING_TEAR,
	PEELING,
	FULLY_OPEN,
}


## Must start anywhere inside the top sealed band.
const START_BAND_RATIO := 0.30
## Drag distance across the pack to fully open.
const REQUIRED_TRAVEL_RATIO := 0.72
const COMPLETE_THRESHOLD := 0.96

var progress := 0.0
var is_tracking := false
var is_complete := false
var drag_direction := 1.0
var _start_position := Vector2.ZERO
var _start_progress := 0.0


func reset() -> void:
	progress = 0.0
	is_tracking = false
	is_complete = false
	drag_direction = 1.0


func begin(local_position: Vector2, pack_size: Vector2) -> bool:
	if is_complete or pack_size.x <= 0.0 or pack_size.y <= 0.0:
		return false
	if local_position.y > pack_size.y * START_BAND_RATIO:
		return false
	is_tracking = true
	_start_position = local_position
	_start_progress = progress
	return true


func update(local_position: Vector2, pack_size: Vector2) -> bool:
	if not is_tracking or is_complete or pack_size.x <= 0.0:
		return false
	## Tear only advances forward across the seal (no reverse healing).
	var horizontal_delta := maxf(local_position.x - _start_position.x, 0.0)
	drag_direction = 1.0
	var travel := horizontal_delta / (pack_size.x * REQUIRED_TRAVEL_RATIO)
	var next_progress := maxf(progress, minf(1.0, _start_progress + travel))
	if next_progress == progress:
		return false
	progress = next_progress
	if progress >= COMPLETE_THRESHOLD:
		progress = 1.0
		is_complete = true
		is_tracking = false
	return true


func end() -> void:
	is_tracking = false


func get_physical_state(visual_progress: float) -> PhysicalState:
	if visual_progress <= 0.01:
		return PhysicalState.CLOSED
	if visual_progress < 0.12:
		return PhysicalState.TENSION
	if visual_progress < 0.28:
		return PhysicalState.TINY_RIP
	if visual_progress < 0.62:
		return PhysicalState.GROWING_TEAR
	if visual_progress < 0.97:
		return PhysicalState.PEELING
	return PhysicalState.FULLY_OPEN
