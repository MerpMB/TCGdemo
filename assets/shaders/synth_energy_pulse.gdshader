shader_type canvas_item;
render_mode blend_add, unshaded;

#include "synth_circuit_field.gdshaderinc"

// Layer 4 — rare deep signals (very sparse). Supports quiet moments.

uniform float pulse_strength : hint_range(0.0, 1.0) = 0.28;
uniform float time_scale : hint_range(0.0, 1.0) = 0.26;
uniform float packet_speed : hint_range(0.1, 2.0) = 0.48;
uniform float packet_size : hint_range(0.02, 0.20) = 0.06;
uniform float body_length : hint_range(0.06, 0.50) = 0.22;
uniform float trail_length : hint_range(0.08, 0.70) = 0.34;
uniform float synapse_strength : hint_range(0.0, 1.5) = 0.40;
uniform float rainbow_strength : hint_range(0.0, 1.0) = 0.70;

float synth_deep_thought(
	vec2 uv,
	float t,
	float seed,
	inout vec3 tint_acc,
	inout float weight_acc
) {
	vec2 cell = floor(synth_grid_uv(uv));
	float road = synth_road_id(uv);

	float route_gate = step(0.78, synth_hash(cell + vec2(seed * 19.0, 8.3)));
	if (route_gate < 0.5) {
		return 0.0;
	}

	float phase = synth_hash(cell + vec2(seed * 4.7, 14.2));
	float speed_mul = 0.40 + synth_hash(cell + vec2(seed * 6.1, 2.2)) * 0.65;
	float spacing = 2.0 + synth_hash(cell + vec2(seed * 8.8, 6.6)) * 2.4;
	float bright_mul = 0.70 + synth_hash(cell + vec2(seed * 9.4, 18.0)) * 0.35;
	float life_period = 9.0 + synth_hash(cell + vec2(seed * 12.0, 21.0)) * 12.0;
	float life_phase = synth_hash(cell + vec2(seed * 1.9, 29.0));
	float len_mul = 0.95 + synth_hash(cell + vec2(seed * 7.7, 10.0)) * 0.30;

	float travel = synth_travel_coord(uv) / max(spacing, 0.001);
	float head = fract(t * packet_speed * speed_mul + phase + road * 0.59);
	float behind = fract(head - travel);

	float signal = synth_signal_profile(
		behind,
		packet_size,
		body_length * len_mul,
		trail_length * len_mul
	);

	float junction = synth_junction_mask(uv);
	float near_head = exp(-(behind * behind) / max(packet_size * packet_size * 2.2, 0.0001));
	float synapse = junction * near_head * synapse_strength;
	float afterglow = junction * exp(-behind / max(trail_length * 1.4, 0.001)) * 0.25;
	afterglow *= step(behind, trail_length * 2.5);

	float life = fract(t / life_period + life_phase + seed * 0.23);
	float envelope = smoothstep(0.0, 0.12, life) * (1.0 - smoothstep(0.34, 0.48, life));

	float energy = (signal * bright_mul + synapse + afterglow) * envelope * route_gate;

	float hue = fract(head * 0.55 - behind * 1.05 + seed * 0.19 + road * 0.13);
	vec3 tint = mix(synth_palette(0.35), synth_iridescent(hue), rainbow_strength);
	tint_acc += tint * energy;
	weight_acc += energy;

	return energy;
}

void fragment() {
	vec2 uv = UV;
	float t = TIME * time_scale;
	float path = max(synth_trace_core(uv), synth_trace_soft(uv) * 0.65);
	path = max(path, synth_junction_mask(uv) * 0.75);

	float signals = 0.0;
	vec3 tint_acc = vec3(0.0);
	float weight_acc = 0.0;
	vec3 col = vec3(0.0);
	float alpha = 0.0;

	if (path >= 0.012) {
		// Two rare deep signals only.
		signals = max(signals, synth_deep_thought(uv, t, 10.0, tint_acc, weight_acc));
		signals = max(signals, synth_deep_thought(uv, t, 11.0, tint_acc, weight_acc));

		signals *= path;
		col = weight_acc > 0.001 ? (tint_acc / weight_acc) : synth_palette(0.3);
		alpha = clamp(signals * pulse_strength, 0.0, 0.42);
	}

	COLOR = vec4(col * alpha * 1.25, alpha);
}
