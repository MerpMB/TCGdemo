// DEPRECATED — Synth V1. Replaced by synth_pcb_board.gdshader + SynthTopology bake.
// Kept for reference only; CardVisualLibrary no longer loads this file.
shader_type canvas_item;
render_mode blend_add, unshaded;

#include "synth_circuit_field.gdshaderinc"

uniform float trace_strength : hint_range(0.0, 1.0) = 0.07;
uniform float edge_glow : hint_range(0.0, 0.5) = 0.008;

void fragment() {
	vec2 uv = UV;
	float traces = synth_trace_field(uv);
	float junctions = synth_junction_mask(uv);
	float idle = traces * 0.82 + junctions * 0.28;
	float edge = max(max(1.0 - uv.x, uv.x), max(1.0 - uv.y, uv.y));
	edge = smoothstep(0.94, 1.0, edge) * edge_glow;
	vec3 col = synth_palette(0.08 + idle * 0.22 + junctions * 0.15);
	float alpha = clamp(idle * trace_strength + edge, 0.0, 0.11);
	COLOR = vec4(col * alpha * 0.95, alpha);
}

