shader_type canvas_item;
render_mode blend_add;

uniform float time_scale : hint_range(0.05, 1.0) = 0.35;
uniform float intensity : hint_range(0.0, 1.0) = 0.26;

float twinkle(vec2 uv, float t, vec2 anchor, float seed) {
	float d = length(uv - anchor);
	float flicker = sin(t * (1.4 + seed * 0.3) + seed * 6.28) * 0.5 + 0.5;
	return smoothstep(0.04, 0.0, d) * flicker;
}

void fragment() {
	vec2 uv = UV;
	float t = TIME * time_scale;
	float breathe = sin(t * 0.85) * 0.5 + 0.5;
	float dist = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
	float edge = 1.0 - smoothstep(0.0, 0.08, dist);
	vec3 warm = vec3(1.0, 0.82, 0.38);
	vec3 deep = vec3(0.92, 0.62, 0.18);
	vec3 edge_glow = mix(deep, warm, breathe) * edge * (0.55 + breathe * 0.25);
	float s1 = twinkle(uv, t, vec2(0.24, 0.22), 1.1);
	float s2 = twinkle(uv, t + 2.0, vec2(0.72, 0.34), 2.7);
	float s3 = twinkle(uv, t + 4.1, vec2(0.48, 0.76), 4.3);
	vec3 spark = warm * (s1 + s2 * 0.8 + s3 * 0.7) * 0.55;
	float emissive = (edge * 0.35 + breathe * 0.08) * intensity;
	vec3 col = (edge_glow + spark) * intensity;
	float alpha = clamp(emissive + s1 * 0.35 + s2 * 0.25 + s3 * 0.2, 0.0, 0.55);
	COLOR = vec4(col, alpha);
}
