shader_type canvas_item;
render_mode blend_add;

uniform float edge_strength : hint_range(0.0, 1.0) = 0.12;
uniform float pulse : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 uv = UV;
	float dist = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
	float edge = 1.0 - smoothstep(0.0, 0.055, dist);
	float breathe = 0.82 + pulse * 0.18;
	vec3 fringe = vec3(0.55, 0.18, 0.72) * edge * edge_strength * breathe;
	float cyan = edge * edge_strength * 0.35 * breathe;
	fringe += vec3(0.1, 0.45, 0.55) * cyan;
	float alpha = edge * edge_strength * 0.35 * breathe;
	COLOR = vec4(fringe, alpha);
}
