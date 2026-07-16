shader_type canvas_item;
render_mode blend_add, unshaded;

#include "diamond_common.gdshaderinc"

// Layer 4 — tiny point sparkles + micro twinkle (jewelry glints, not glitter spam).

uniform float sparkle_strength : hint_range(0.0, 1.0) = 0.42;
uniform float time_scale : hint_range(0.0, 1.0) = 0.22;
uniform float sparkle_size : hint_range(0.003, 0.05) = 0.007;
uniform vec2 light_dir = vec2(0.35, -0.75);

float diamond_point(vec2 uv, vec2 anchor, float t, float seed) {
	float d = length(uv - anchor);
	// Micro twinkle — staggered, mostly off.
	float twinkle = sin(t * (2.1 + seed * 0.7) + seed * 11.0) * 0.5 + 0.5;
	float gate = smoothstep(0.78, 0.94, twinkle);
	float core = smoothstep(sparkle_size, 0.0, d);
	float halo = smoothstep(sparkle_size * 2.1, 0.0, d) * 0.28;
	return (core + halo) * gate;
}

float diamond_star(vec2 uv, vec2 anchor, float t, float seed) {
	vec2 d = uv - anchor;
	float r = length(d);
	float phase = sin(t * 1.15 + seed * 8.0) * 0.5 + 0.5;
	float gate = smoothstep(0.88, 0.97, phase);
	float core = smoothstep(sparkle_size * 0.7, 0.0, r);
	float arm_h = smoothstep(sparkle_size * 2.4, 0.0, abs(d.x)) * smoothstep(sparkle_size * 0.35, 0.0, abs(d.y));
	float arm_v = smoothstep(sparkle_size * 2.4, 0.0, abs(d.y)) * smoothstep(sparkle_size * 0.35, 0.0, abs(d.x));
	return (core + max(arm_h, arm_v) * 0.7) * gate;
}

void fragment() {
	vec2 uv = UV;
	float t = TIME * time_scale;

	float crease;
	float id;
	vec2 n;
	vec2 cell;
	diamond_sample(uv, crease, id, n, cell);

	vec2 L = diamond_light_dir(light_dir, t * 0.12);
	float peak = diamond_specular_peak(id, n, L);
	float peak_gate = smoothstep(0.35, 0.75, peak);

	float s = 0.0;
	// Tiny point field — sparse jewelry glints.
	s += diamond_point(uv, vec2(0.14, 0.18), t, 0.1);
	s += diamond_point(uv, vec2(0.38, 0.12), t, 0.4);
	s += diamond_point(uv, vec2(0.62, 0.20), t, 0.8);
	s += diamond_point(uv, vec2(0.86, 0.16), t, 1.2);
	s += diamond_point(uv, vec2(0.22, 0.42), t, 1.6);
	s += diamond_point(uv, vec2(0.52, 0.38), t, 2.0);
	s += diamond_point(uv, vec2(0.78, 0.46), t, 2.4);
	s += diamond_point(uv, vec2(0.18, 0.68), t, 2.8);
	s += diamond_point(uv, vec2(0.44, 0.72), t, 3.2);
	s += diamond_point(uv, vec2(0.70, 0.64), t, 3.6);
	s += diamond_point(uv, vec2(0.88, 0.78), t, 4.0);
	s += diamond_point(uv, vec2(0.32, 0.88), t, 4.4);
	s += diamond_point(uv, vec2(0.58, 0.92), t, 4.8);
	// A couple of rare star accents.
	s += diamond_star(uv, vec2(0.26, 0.30), t, 0.3) * 0.85;
	s += diamond_star(uv, vec2(0.74, 0.58), t, 1.1) * 0.85;

	s *= mix(0.2, 1.0, peak_gate);

	float alpha = clamp(s * sparkle_strength, 0.0, 0.85);
	COLOR = vec4(vec3(1.0) * alpha, alpha);
}
