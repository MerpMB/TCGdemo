class_name CardLayerGuard
extends RefCounted
## Debug-only layer-leak detection. Protected render layers must keep rest transforms.


const PROTECTED_LAYER_PATHS := [
	"FlipPivot/BackFace",
	"FlipPivot/BackFace/BackTexture",
	"FlipPivot/FrontFace",
	"FlipPivot/FrontFace/ArtTexture",
	"FlipPivot/FrontFace/RenderLayerContainer",
	"FlipPivot/FrontFace/FrameTexture",
	"FlipPivot/FrontFace/FramePanel",
	"FlipPivot/FrontFace/LegacyVariantFx",
	"FlipPivot/FrontFace/LegendarySpark",
]


var host: Node
var flip_pivot: Control
var layer_rest: Dictionary = {}
var flip_pivot_rest_position := Vector2.ZERO
var flip_pivot_rest_rotation := 0.0


func bind(p_host: Node, p_flip_pivot: Control) -> void:
	host = p_host
	flip_pivot = p_flip_pivot


func cache_rest() -> void:
	if not OS.is_debug_build():
		return
	layer_rest.clear()
	flip_pivot_rest_position = flip_pivot.position
	flip_pivot_rest_rotation = flip_pivot.rotation
	for path in PROTECTED_LAYER_PATHS:
		var control := host.get_node_or_null(path) as Control
		if control == null:
			push_error("CardLayerGuard: protected layer missing at '%s'." % path)
			continue
		layer_rest[path] = {
			"position": control.position,
			"rotation": control.rotation,
			"scale": control.scale,
		}


func assert_unmoved(context: String) -> void:
	if not OS.is_debug_build() or layer_rest.is_empty():
		return

	if (
		not is_equal_approx(flip_pivot.position.x, flip_pivot_rest_position.x)
		or not is_equal_approx(flip_pivot.position.y, flip_pivot_rest_position.y)
	):
		push_error(
			"CardScene layer leak [%s]: FlipPivot.position drifted to %s (rest %s). Only scale.x is allowed."
			% [context, flip_pivot.position, flip_pivot_rest_position]
		)
	if not is_equal_approx(flip_pivot.rotation, flip_pivot_rest_rotation):
		push_error(
			"CardScene layer leak [%s]: FlipPivot.rotation drifted to %s (rest %s)."
			% [context, flip_pivot.rotation, flip_pivot_rest_rotation]
		)

	for path in layer_rest.keys():
		var control := host.get_node_or_null(path) as Control
		if control == null:
			continue
		var rest: Dictionary = layer_rest[path]
		var rest_pos: Vector2 = rest["position"]
		var rest_rot: float = rest["rotation"]
		var rest_scale: Vector2 = rest["scale"]
		if (
			not is_equal_approx(control.position.x, rest_pos.x)
			or not is_equal_approx(control.position.y, rest_pos.y)
		):
			push_error(
				"CardScene layer leak [%s]: %s.position drifted to %s (rest %s)."
				% [context, path, control.position, rest_pos]
			)
		if not is_equal_approx(control.rotation, rest_rot):
			push_error(
				"CardScene layer leak [%s]: %s.rotation drifted to %s (rest %s)."
				% [context, path, control.rotation, rest_rot]
			)
		if (
			not is_equal_approx(control.scale.x, rest_scale.x)
			or not is_equal_approx(control.scale.y, rest_scale.y)
		):
			push_error(
				"CardScene layer leak [%s]: %s.scale drifted to %s (rest %s)."
				% [context, path, control.scale, rest_scale]
			)
