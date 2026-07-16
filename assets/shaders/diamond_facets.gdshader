shader_type canvas_item;
render_mode blend_add, unshaded;

#include "diamond_common.gdshaderinc"

// Layer 1 — calm confetti film body (most of the surface stays restrained).

uniform float plate_strength : hint_range(0.0, 1.5) = 0.42;
uniform float fresnel_strength : hint_range(0.0, 1.0) = 0.08;
uniform float clarity_veil : hint_range(0.0, 1.0) = 0.0;
uniform float seam_strength : hint_range(0.0, 0.2) = 0.0;
uniform float iridescence : hint_range(0.0, 1.0) = 0.92;
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

	vec3 film = diamond_confetti_shade(uv, id, n, L, response);
	float fresnel = diamond_fresnel_rim(uv) * fresnel_strength;

	// Calm body — less fill so hotspots from upper layers can pop.
	float energy = (0.18 + response * 0.55) * plate_strength + fresnel;
	float alpha = clamp(energy * iridescence, 0.0, 0.42);
	COLOR = vec4(film * alpha, alpha);
}
