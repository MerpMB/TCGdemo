shader_type canvas_item;
render_mode blend_add, unshaded;

#include "synth_circuit_field.gdshaderinc"

// Layer 4 — slow heartbeat energy wave traveling the road network.

uniform float pulse_strength : hint_range(0.0, 1.0) = 0.42;
uniform float time_scale : hint_range(0.0, 0.2) = 0.05;
uniform float pulse_interval : hint_range(2.0, 12.0) = 5.5;
uniform float pulse_width : hint_range(0.05, 0.4) = 0.16;

void fragment() {
	vec2 uv = UV;
	float t = TIME * time_scale;
	float core = synth_trace_core(uv);
	float glow = synth_trace_field(uv);

	float cycle = fract(t / max(pulse_interval, 0.001));
	float wave_pos = cycle * 1.35 - 0.1;
	float path = uv.x * 0.75 + uv.y * 0.35 + synth_path_coord(uv) * 0.15;
	float d = abs(path - wave_pos);
	float pulse = 1.0 - smoothstep(pulse_width, pulse_width * 0.35, d);
	pulse = pow(pulse, 1.55);
	float tail = exp(-max(cycle - 0.55, 0.0) * 6.0);
	pulse *= mix(1.0, 0.55, tail);

	// Brighten roads + soft glow as the wave passes — no explosions.
	float brighten = pulse * mix(glow * 0.45, core, 0.7);
	vec3 col = synth_palette(0.65 + pulse * 0.35);
	float alpha = clamp(brighten * pulse_strength, 0.0, 0.48);
	COLOR = vec4(col * alpha * 1.3, alpha);
}
