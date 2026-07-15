class_name VariantLayer
extends RefCounted
## One visual material element for idle card rendering. Populated by CardVisualLibrary only.


enum LayerType {
	TEXTURE,
	SHADER,
	COLOR,
	PARTICLES,
}


enum BlendMode {
	MIX,
	ADD,
	SUB,
	MUL,
}


enum AnimationType {
	STATIC,
	SCROLL,
	ROTATE,
	PULSE,
	SHIMMER,
}


var layer_id := ""
var type := LayerType.TEXTURE
var texture: Texture2D
var shader: Shader
var material: Material
var blend_mode := BlendMode.MIX
var opacity := 1.0
var tint := Color.WHITE
var z_order := 0
var uv_scale := Vector2.ONE
var scroll_direction := Vector2(1.0, 0.0)
var scroll_speed := 0.0
var rotation_speed := 0.0
var pulse_speed := 3.0
var parallax_strength := 0.0
## Visual height above artwork (0 = fixed to art). Scales global idle parallax offset.
var depth := 0.0
## Multiplier on depth for idle parallax (1.0 = default). Lets layers share one sheet feel.
var material_response := 1.0
var animation_type := AnimationType.STATIC
