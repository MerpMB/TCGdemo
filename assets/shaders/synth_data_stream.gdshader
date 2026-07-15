shader_type canvas_item;
render_mode blend_add, unshaded;

#include "synth_circuit_field.gdshaderinc"

// Layer 3 — few large iridescent signals (deliberate thoughts, not traffic noise).

uniform float stream_strength : hint_range(0.0, 1.0) = 0.62;
uniform float time_scale : hint_range(0.0, 1.5) = 0.48;
uniform float packet_speed : hint_range(0.2, 3.0) = 0.78;
uniform float packet_size : hint_range(0.02, 0.20) = 0.055;
uniform float body_length : hint_range(0.05, 0.45) = 0.18;
uniform float trail_length : hint_range(0.05, 0.60) = 0.28;
uniform float synapse_strength : hint_range(0.0, 1.5) = 0.55;
uniform float rainbow_strength : hint_range(0.0, 1.0) = 0.78;

float synth_thought_stream(
	vec2 uv,
	float t,
	float seed,
	float head_w,
	float body_w,
	float trail_w,
	inout vec3 tint_acc,
	inout float weight_acc
) {
	vec2 cell = floor(synth_grid_uv(uv));
	float road = synth_road_id(uv);

	// Sparse routes — most pathways stay quiet.
	float route_gate = step(0.68, synth_hash(cell + vec2(seed * 13.1, 2.7)));
	if (route_gate < 0.5) {
		return 0.0;
	}

	float phase = synth_hash(cell + vec2(seed * 7.3, 4.1));
	float speed_mul = 0.55 + synth_hash(cell + vec2(seed * 2.9, 9.7)) * 0.70;
	float spacing = 1.6 + synth_hash(cell + vec2(seed * 5.5, 1.3)) * 2.2;
	float bright_mul = 0.85 + synth_hash(cell + vec2(seed * 8.2, 15.0)) * 0.30;
	// Long quiet gaps between appearances.
	float life_period = 6.5 + synth_hash(cell + vec2(seed * 11.0, 17.0)) * 9.0;
	float life_phase = synth_hash(cell + vec2(seed * 3.1, 23.0));
	float len_mul = 0.90 + synth_hash(cell + vec2(seed * 6.4, 12.0)) * 0.35;

	float travel = synth_travel_coord(uv) / max(spacing, 0.001);
	float head = fract(t * packet_speed * speed_mul + phase + road * 0.41);
	float behind = fract(head - travel);

	float signal = synth_signal_profile(
		behind,
		head_w,
		body_w * len_mul,
		trail_w * len_mul
	);

	float junction = synth_junction_mask(uv);
	float near_head = exp(-(behind * behind) / max(head_w * head_w * 1.8, 0.0001));
	float synapse = junction * near_head * synapse_strength;

	float split = step(0.62, synth_hash(cell + vec2(seed * 19.0, 31.0)));
	float cross = synth_cross_travel_coord(uv);
	float cross_near = 1.0 - smoothstep(0.0, 0.14, abs(fract(cross) - 0.5));
	float branch = split * junction * near_head * cross_near * 0.40;

	// Active ~40% of life, then a clear pause before the next thought.
	float life = fract(t / life_period + life_phase + seed * 0.17);
	float envelope = smoothstep(0.0, 0.10, life) * (1.0 - smoothstep(0.38, 0.52, life));

	float energy = (signal * bright_mul + synapse + branch) * envelope * route_gate;

	// Rainbow travels with the packet (head + position along body).
	float hue = fract(head * 0.72 - behind * 1.15 + seed * 0.11 + road * 0.07);
	vec3 tint = mix(synth_palette(0.45), synth_iridescent(hue), rainbow_strength);
	tint_acc += tint * energy;
	weight_acc += energy;

	return energy;
}

void fragment() {
	vec2 uv = UV;
	float t = TIME * time_scale;
	// Soft path gives substantial glow thickness without filling the board.
	float path = max(synth_trace_core(uv), synth_trace_soft(uv) * 0.72);
	path = max(path, synth_junction_mask(uv) * 0.8);

	float signals = 0.0;
	vec3 tint_acc = vec3(0.0);
	float weight_acc = 0.0;
	vec3 col = vec3(0.0);
	float alpha = 0.0;

	if (path >= 0.012) {
		// Three large deliberate signals — not dense traffic.
		signals = max(signals, synth_thought_stream(uv, t, 0.0, packet_size, body_length, trail_length, tint_acc, weight_acc));
		signals = max(signals, synth_thought_stream(uv, t, 1.0, packet_size * 1.08, body_length * 1.12, trail_length * 1.05, tint_acc, weight_acc));
		signals = max(signals, synth_thought_stream(uv, t, 2.0, packet_size * 0.95, body_length * 0.92, trail_length * 1.18, tint_acc, weight_acc));

		signals *= path;
		col = weight_acc > 0.001 ? (tint_acc / weight_acc) : synth_palette(0.4);
		alpha = clamp(signals * stream_strength, 0.0, 0.70);
	}

	COLOR = vec4(col * alpha * 1.45, alpha);
}
