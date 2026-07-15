shader_type canvas_item;
render_mode blend_add, unshaded;

#include "synth_circuit_field.gdshaderinc"

// Layer 2 — idle neural PCB.
// Static faint illumination. The board does not breathe or pulse.

uniform float trace_strength : hint_range(0.0, 1.0) = 0.24;
uniform float edge_glow : hint_range(0.0, 0.5) = 0.015;

void fragment() {
	vec2 uv = UV;
	float traces = synth_trace_field(uv);
	float junctions = synth_junction_mask(uv);

	// Idle synapses stay barely lit — living standby, not animation.
	float idle = traces * 0.92 + junctions * 0.18;

	float edge = max(max(1.0 - uv.x, uv.x), max(1.0 - uv.y, uv.y));
	edge = smoothstep(0.92, 1.0, edge) * edge_glow * synth_region_mask(uv);

	vec3 col = synth_palette(0.12 + idle * 0.25);
	float alpha = clamp(idle * trace_strength + edge, 0.0, 0.26);
	COLOR = vec4(col * alpha * 1.1, alpha);
}
