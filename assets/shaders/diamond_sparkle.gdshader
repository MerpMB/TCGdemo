shader_type canvas_item;
render_mode blend_add;

uniform float time_scale : hint_range(0.1, 3.0) = 1.0;
uniform float intensity : hint_range(0.0, 1.0) = 0.35;

float point_sparkle(vec2 uv, vec2 anchor, float t) {
	float d = length(uv - anchor);
	float pulse = sin(t * 3.2 + anchor.x * 20.0) * 0.5 + 0.5;
	return smoothstep(0.035, 0.0, d) * pulse;
}

void fragment() {
	vec2 uv = UV;
	float t = TIME * time_scale;
	float s = 0.0;
	s += point_sparkle(uv, vec2(0.22, 0.18), t);
	s += point_sparkle(uv, vec2(0.78, 0.26), t + 1.1);
	s += point_sparkle(uv, vec2(0.55, 0.62), t + 2.4);
	s += point_sparkle(uv, vec2(0.18, 0.74), t + 0.6);
	s += point_sparkle(uv, vec2(0.84, 0.81), t + 1.9);
	vec3 ice = vec3(0.82, 0.94, 1.0);
	float alpha = s * intensity;
	COLOR = vec4(ice * alpha, alpha);
}
