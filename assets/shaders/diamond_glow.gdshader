shader_type canvas_item;
render_mode blend_add;

uniform float time_scale : hint_range(0.1, 3.0) = 1.0;
uniform float intensity : hint_range(0.0, 1.0) = 0.22;

float sparkle(vec2 uv, float t, float seed) {
	vec2 p = uv * vec2(9.0 + seed, 11.0 + seed);
	float flicker = sin(t * (2.1 + seed) + dot(p, vec2(1.7, 2.3))) * 0.5 + 0.5;
	float cell = fract(sin(dot(floor(p), vec2(127.1, 311.7)) + seed) * 43758.5453);
	return smoothstep(0.92, 1.0, cell) * flicker;
}

void fragment() {
	vec2 uv = UV;
	float t = TIME * time_scale;
	float facet = abs(sin((uv.x + uv.y) * 14.0 + t * 0.6));
	facet *= abs(cos((uv.x - uv.y) * 11.0 - t * 0.45));
	vec3 cool = vec3(0.72, 0.88, 1.0);
	vec3 ice = vec3(0.9, 0.96, 1.0);
	float tw1 = sparkle(uv, t, 1.3);
	float tw2 = sparkle(uv, t + 1.7, 4.1);
	float glow = (facet * 0.35 + tw1 * 0.9 + tw2 * 0.7) * intensity;
	vec3 col = mix(cool, ice, tw1) * glow;
	COLOR = vec4(col, glow * 0.65);
}
