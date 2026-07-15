shader_type canvas_item;
render_mode blend_add, unshaded;

#include "synth_circuit_field.gdshaderinc"

// Layer 2 — idle glowing light-roads (Tron city grid from above).

uniform float trace_strength : hint_range(0.0, 1.0) = 0.38;
uniform float time_scale : hint_range(0.0, 0.2) = 0.04;
uniform float edge_glow : hint_range(0.0, 0.5) = 0.04;

void fragment() {
	vec2 uv = UV;
	float t = TIME * time_scale;

	float traces = synth_trace_field(uv);
	// Very slow idle breathe — powered roads, not flashing.
	float breathe = 0.90 + 0.10 * sin(t * 1.4 + synth_path_coord(uv) * 3.0);
	traces *= breathe;

	// Subtle corner accent only — not a full neon picture frame.
	float edge = max(max(1.0 - uv.x, uv.x), max(1.0 - uv.y, uv.y));
	edge = smoothstep(0.88, 1.0, edge) * edge_glow * synth_region_mask(uv);

	vec3 col = synth_palette(0.2 + traces * 0.35);
	float alpha = clamp(traces * trace_strength + edge, 0.0, 0.34);
	COLOR = vec4(col * alpha * 1.2, alpha);
}
