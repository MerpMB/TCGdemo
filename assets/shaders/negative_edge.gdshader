shader_type canvas_item;
render_mode blend_add;

uniform float time_scale : hint_range(0.05, 1.0) = 0.28;
uniform float edge_strength : hint_range(0.0, 1.0) = 0.14;

void fragment() {
	vec2 uv = UV;
	float dist = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
	float edge = 1.0 - smoothstep(0.0, 0.06, dist);
	float pulse = sin(TIME * time_scale) * 0.5 + 0.5;
	float breathe = 0.78 + pulse * 0.22;
	vec3 violet = vec3(0.48, 0.12, 0.62);
	vec3 cyan = vec3(0.08, 0.38, 0.48);
	vec3 fringe = mix(violet, cyan, pulse * 0.45) * edge * edge_strength * breathe;
	float alpha = edge * edge_strength * 0.38 * breathe;
	COLOR = vec4(fringe, alpha);
}
