shader_type canvas_item;
render_mode blend_add, unshaded;

#include "synth_v2_common.gdshaderinc"

// Synth V2 Layer — static PCB architecture (beautiful with animation disabled).
// Samples baked board map from SynthTopology.

uniform sampler2D board_map : source_color, filter_linear_mipmap;
uniform float trace_strength : hint_range(0.0, 1.0) = 0.085;
uniform float edge_glow : hint_range(0.0, 0.5) = 0.010;
uniform float junction_boost : hint_range(0.0, 2.0) = 1.15;
uniform float fiber_halo : hint_range(0.0, 2.0) = 0.85;

void fragment() {
	vec2 uv = UV;
	vec4 board = texture(board_map, uv);
	float traces = board.r;
	float junctions = board.g;
	float bloom = board.b;
	float core = board.a;

	// Fiber-optic idle: crisp copper/trace core + soft cyan halo + pad emphasis.
	float idle = core * 0.55 + traces * 0.70 + junctions * 0.42 * junction_boost;
	idle += bloom * 0.18 * fiber_halo;

	float edge = max(max(1.0 - uv.x, uv.x), max(1.0 - uv.y, uv.y));
	edge = smoothstep(0.93, 1.0, edge) * edge_glow;

	float tone = 0.10 + idle * 0.55 + junctions * 0.22;
	vec3 col = synth_palette(tone);
	// Slight cooler lift on junctions for readable hubs when static.
	col = mix(col, vec3(0.55, 0.92, 1.0), junctions * 0.35);

	float alpha = clamp(idle * trace_strength + edge, 0.0, 0.16);
	COLOR = vec4(col * alpha * 1.05, alpha);
}
