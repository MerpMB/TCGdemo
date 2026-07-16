shader_type canvas_item;
render_mode blend_add, unshaded;

#include "synth_circuit_field.gdshaderinc"

// Layer 4 — rare deep waves; joins primary bursts for occasional traffic peaks.

uniform float pulse_strength : hint_range(0.0, 1.5) = 0.55;
uniform float time_scale : hint_range(0.0, 1.0) = 0.26;
uniform float packet_speed : hint_range(0.1, 2.0) = 0.48;
uniform float packet_size : hint_range(0.03, 0.25) = 0.095;
uniform float body_length : hint_range(0.10, 0.80) = 0.42;
uniform float trail_length : hint_range(0.10, 1.0) = 0.62;
uniform float synapse_strength : hint_range(0.0, 2.0) = 0.70;
uniform float rainbow_strength : hint_range(0.0, 1.0) = 0.82;
uniform float bloom_strength : hint_range(0.0, 1.5) = 0.55;

float synth_traffic_burst(float real_t) {
	float cycle = fract(real_t * 0.062 + 0.31);
	float burst = smoothstep(0.0, 0.06, cycle) * (1.0 - smoothstep(0.18, 0.32, cycle));
	float ripple = smoothstep(0.55, 0.62, cycle) * (1.0 - smoothstep(0.70, 0.82, cycle)) * 0.45;
	return max(burst, ripple) * 0.75;
}

float synth_deep_thought(
	vec2 uv,
	float t,
	float real_t,
	float seed,
	float burst,
	inout vec3 tint_acc,
	inout float weight_acc
) {
	vec2 cell = floor(synth_grid_uv(uv));
	float road = synth_road_id(uv);
	vec2 corridor = floor(cell * 0.28);

	float route_thresh = mix(0.84, 0.62, burst);
	float route_gate = step(route_thresh, synth_hash(corridor + vec2(seed * 19.0, 8.3)));
	if (route_gate < 0.5) {
		return 0.0;
	}

	float phase = synth_hash(corridor + vec2(seed * 4.7, 14.2));
	float base_speed = 0.40 + synth_hash(corridor + vec2(seed * 6.1, 2.2)) * 0.65;
	float accel = 0.38 * sin(real_t * (0.33 + seed * 0.05) + phase * 6.2831);
	float warped_t = t + accel / max(0.33 + seed * 0.05, 0.15);
	float spacing = 0.95 + synth_hash(corridor + vec2(seed * 8.8, 6.6)) * 1.0;
	float bright_mul = 0.95 + synth_hash(corridor + vec2(seed * 9.4, 18.0)) * 0.25;
	float life_period = 13.0 + synth_hash(corridor + vec2(seed * 12.0, 21.0)) * 14.0;
	float life_phase = synth_hash(corridor + vec2(seed * 1.9, 29.0));
	float len_mul = 1.1 + synth_hash(corridor + vec2(seed * 7.7, 10.0)) * 0.3;

	float travel = synth_travel_coord(uv) / max(spacing, 0.001);
	float head = fract(warped_t * packet_speed * base_speed + phase + road * 0.27);
	float behind = fract(head - travel);

	float signal = synth_signal_profile(
		behind,
		packet_size,
		body_length * len_mul,
		trail_length * len_mul
	);

	float span = body_length * len_mul + trail_length * len_mul * 0.5;
	float corner = synth_corner_bridge(uv, behind, span) * synapse_strength * 1.05;
	float afterglow = synth_junction_mask(uv) * exp(-behind / max(span, 0.001)) * 0.3;

	float life = fract(t / life_period + life_phase + seed * 0.23);
	float fade_start = mix(0.44, 0.58, burst);
	float fade_end = mix(0.66, 0.82, burst);
	float envelope = smoothstep(0.0, 0.12, life) * (1.0 - smoothstep(fade_start, fade_end, life));
	envelope = mix(envelope, max(envelope, burst * 0.8), burst * 0.6);

	float energy = (signal * bright_mul + corner + afterglow) * envelope * route_gate;

	float hue = fract(head * 0.48 - behind * 0.7 + seed * 0.19 + road * 0.13);
	vec3 tint = mix(vec3(0.30, 0.85, 1.0), synth_iridescent(hue), rainbow_strength);
	float lead_soft = exp(-behind / max(packet_size * 2.6, 0.001));
	tint = mix(tint, vec3(0.90, 0.96, 1.0), lead_soft * 0.22);

	tint_acc += tint * energy;
	weight_acc += energy;

	return energy;
}

void fragment() {
	vec2 uv = UV;
	float real_t = TIME;
	float t = real_t * time_scale;
	float burst = synth_traffic_burst(real_t);

	float path = max(synth_trace_core(uv), synth_trace_soft(uv) * 0.85);
	path = max(path, synth_junction_mask(uv) * 0.9);
	float bloom = synth_trace_bloom(uv);

	float signals = 0.0;
	vec3 tint_acc = vec3(0.0);
	float weight_acc = 0.0;

	if (path >= 0.008 || bloom >= 0.02) {
		signals = max(signals, synth_deep_thought(uv, t, real_t, 10.0, burst, tint_acc, weight_acc));
		signals = max(signals, synth_deep_thought(uv, t, real_t, 11.0, burst, tint_acc, weight_acc));
		float s2 = synth_deep_thought(uv, t, real_t, 12.0, burst, tint_acc, weight_acc);
		signals = max(signals, s2 * mix(0.0, 0.8, burst));

		float energy = max(signals * path, signals * bloom * bloom_strength * 0.45);
		vec3 col = weight_acc > 0.001 ? (tint_acc / weight_acc) : vec3(0.35, 0.85, 1.0);
		float alpha = clamp(energy * pulse_strength, 0.0, 0.55);
		COLOR = vec4(col * alpha * 1.55, alpha);
	} else {
		COLOR = vec4(0.0);
	}
}
