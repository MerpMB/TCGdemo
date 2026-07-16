shader_type canvas_item;
render_mode blend_add, unshaded;

#include "diamond_common.gdshaderinc"

// Layer 2 — jewelry specular: bright white peaks + local rainbow fire on hot facets.

uniform float reflection_strength : hint_range(0.0, 1.5) = 0.88;
uniform float body_strength : hint_range(0.0, 1.0) = 0.28;
uniform float rim_strength : hint_range(0.0, 1.0) = 0.06;
uniform float iridescence : hint_range(0.0, 1.0) = 1.0;
uniform float specular_white : hint_range(0.0, 2.0) = 1.15;
uniform float fire_strength : hint_range(0.0, 1.5) = 0.55;
uniform float time_scale : hint_range(0.0, 0.2) = 0.04;
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

	// Soft body stays modest; peaks carry the luxury punch.
	float body = response * body_strength * 0.85;
	float spec = pow(peak, 0.85) * (1.15 + crease * 0.4);
	float rim = diamond_fresnel_rim(uv) * rim_strength * 0.25;

	float energy = (body + spec * specular_white) * reflection_strength + rim;

	vec3 film = diamond_confetti_shade(uv, id, n, L, response + peak);
	// Local rainbow fire — only on high-energy facets.
	float fire_gate = smoothstep(0.42, 0.82, peak);
	vec3 fire = diamond_holofoil(id * 2.4 + uv.x * 0.9 + peak * 0.5);
	fire = mix(fire, fire * vec3(1.15, 1.05, 1.2), 0.35);
	vec3 col = mix(film, fire, fire_gate * fire_strength);
	// White specular catch — jewelry highlight.
	col = mix(col, vec3(1.0, 0.99, 0.97), clamp(peak * specular_white, 0.0, 1.0) * 0.72);
	col = mix(diamond_ice_white(0.55), col, iridescence);

	float alpha = clamp(energy, 0.0, 0.88);
	COLOR = vec4(col * alpha, alpha);
}
