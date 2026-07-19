shader_type canvas_item;

// Clips only the corners while preserving the surface color output.
uniform float corner_radius : hint_range(0.0, 0.25, 0.001) = 0.045;


void fragment() {
	vec2 centered_uv = UV - vec2(0.5);
	vec2 inner_bounds = vec2(0.5 - corner_radius);
	float corner_distance = length(max(abs(centered_uv) - inner_bounds, vec2(0.0)));
	if (corner_distance > corner_radius) {
		discard;
	}
}