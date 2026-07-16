shader_type canvas_item;
render_mode blend_add, unshaded;

#include "diamond_common.gdshaderinc"

// Layer 3 — saturated dispersion fire on peak facets only (not card-wide fill).

uniform float dispersion_strength : hint_range(0.0, 1.5) = 0.72;
uniform float peak_gate : hint_range(0.0, 1.0) = 0.48;
uniform float saturation : hint_range(0.5, 2.0) = 1.35;
uniform float time_scale : hint_range(0.0, 0.2) = 0.035;
uniform vec2 light_dir = vec2(0.35, -0.75);

void fragment() {
	vec2 uv = UV;
	float crease;
	float id;
	vec2 n;
	vec2 cell;
	diamond_sample(uv, crease, id, n, cell);

	vec2 L = diamond_light_dir(light_dir, TIME * time_scale);
	float response = diamond_flake_response(id, n, L);
	float peak = diamond_specular_peak(id, n, L);
	// Tight gate — only the brightest facets get rainbow fire.
	float gate = smoothstep(peak_gate, 0.88, peak);
	gate *= smoothstep(0.35, 0.7, response);

	vec3 hot = diamond_holofoil(id * 2.3 + uv.x * 0.85 + peak);
	// Push chroma without lifting whole-card bloom.
	vec3 grey = vec3(dot(hot, vec3(0.299, 0.587, 0.114)));
	hot = mix(grey, hot, saturation);
	hot = mix(hot, vec3(1.0, 0.98, 0.96), peak * 0.18);

	float alpha = clamp(gate * dispersion_strength, 0.0, 0.70);
	COLOR = vec4(hot * alpha, alpha);
}
