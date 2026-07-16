// DEPRECATED — Diamond V1 replaced this with diamond_reflection.gdshader.
shader_type canvas_item;
render_mode blend_add, unshaded;

uniform float time_scale : hint_range(0.1, 3.0) = 1.1;
uniform float intensity : hint_range(0.0, 1.0) = 0.18;

void fragment() {
	COLOR = vec4(0.0);
}
