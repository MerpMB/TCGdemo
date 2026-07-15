shader_type canvas_item;
render_mode blend_add;

uniform float time_scale : hint_range(0.1, 3.0) = 1.35;
uniform float intensity : hint_range(0.0, 1.0) = 0.3;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float crystal_glint(vec2 uv, vec2 anchor, float t) {
	float d = length(uv - anchor);
	float gate = step(0.82, sin(t * 4.5 + hash21(anchor) * 12.0) * 0.5 + 0.5);
	return smoothstep(0.028, 0.0, d) * gate;
}

void fragment() {
	vec2 uv = UV;
	float t = TIME * time_scale;
	float s = 0.0;
	s += crystal_glint(uv, vec2(0.18, 0.24), t);
	s += crystal_glint(uv, vec2(0.76, 0.19), t + 1.3);
	s += crystal_glint(uv, vec2(0.52, 0.58), t + 2.8);
	s += crystal_glint(uv, vec2(0.22, 0.78), t + 0.7);
	s += crystal_glint(uv, vec2(0.84, 0.72), t + 3.6);
	vec3 crisp = vec3(0.88, 0.96, 1.0);
	float alpha = s * intensity;
	COLOR = vec4(crisp * alpha, alpha);
}
