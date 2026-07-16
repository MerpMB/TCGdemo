shader_type canvas_item;
render_mode blend_add, unshaded;

#include "synth_circuit_field.gdshaderinc"

// Layer 2 — nearly invisible idle PCB (cyan/teal only).
// Packets carry all the visual energy.

uniform float trace_strength : hint_range(0.0, 1.0) = 0.07;
uniform float edge_glow : hint_range(0.0, 0.5) = 0.008;

void fragment() {
	vec2 uv = UV;
	float traces = synth_trace_field(uv);
	float junctions = synth_junction_mask(uv);

	float idle = traces * 0.85 + junctions * 0.12;

	float edge = max(max(1.0 - uv.x, uv.x), max(1.0 - uv.y, uv.y));
	edge = smoothstep(0.94, 1.0, edge) * edge_glow * synth_region_mask(uv);

	vec3 col = synth_palette(0.08 + idle * 0.2);
	float alpha = clamp(idle * trace_strength + edge, 0.0, 0.10);
	COLOR = vec4(col * alpha * 0.9, alpha);
}
