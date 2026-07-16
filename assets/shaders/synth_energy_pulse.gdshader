// DEPRECATED — Synth V1. Replaced by synth_fiber_deep.gdshader + SynthTopology.
shader_type canvas_item;
render_mode blend_add, unshaded;

#include "synth_circuit_field.gdshaderinc"

// Layer 4 — rare deep journeys on alternate designed routes.

uniform float pulse_strength : hint_range(0.0, 1.5) = 0.55;
uniform float time_scale : hint_range(0.0, 1.0) = 0.26;
uniform float packet_speed : hint_range(0.1, 2.0) = 0.48;
uniform float packet_size : hint_range(0.03, 0.25) = 0.095;
uniform float body_length : hint_range(0.10, 0.80) = 0.48;
uniform float trail_length : hint_range(0.10, 1.0) = 0.65;
uniform float synapse_strength : hint_range(0.0, 2.0) = 0.95;
uniform float rainbow_strength : hint_range(0.0, 1.0) = 0.82;
uniform float bloom_strength : hint_range(0.0, 1.5) = 0.55;

float synth_traffic_burst(float real_t) {
	float cycle = fract(real_t * 0.055 + 0.31);
	float burst = smoothstep(0.0, 0.05, cycle) * (1.0 - smoothstep(0.14, 0.26, cycle));
	float ripple = smoothstep(0.58, 0.64, cycle) * (1.0 - smoothstep(0.72, 0.84, cycle)) * 0.4;
	return max(burst, ripple) * 0.7;
}

float synth_stream_owns_route(float seed, float road, float burst) {
	float primary = floor(fract(seed * 0.271 + 0.41) * SYNTH_ROUTE_COUNT);
	float secondary = floor(fract(seed * 0.519 + 0.08) * SYNTH_ROUTE_COUNT);
	float own = max(step(abs(road - primary), 0.1), step(abs(road - secondary), 0.1));
	float neighbor = floor(mod(primary + 2.0, SYNTH_ROUTE_COUNT));
	own = max(own, step(abs(road - neighbor), 0.1) * burst);
	return own;
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
	float road = synth_road_id(uv);
	float route_gate = synth_stream_owns_route(seed, road, burst);
	if (route_gate < 0.5) {
		return 0.0;
	}

	float phase = synth_hash(vec2(seed * 4.7, road + 14.2));
	float base_speed = 0.35 + synth_hash(vec2(seed * 6.1, road + 2.2)) * 0.4;
	float accel = 0.34 * sin(real_t * (0.3 + seed * 0.04) + phase * 6.2831);
	float warped_t = t + accel / max(0.3 + seed * 0.04, 0.15);

	float travel = synth_travel_coord(uv);
	float head = fract(warped_t * packet_speed * base_speed * 0.32 + phase);
	float behind = fract(head - travel);

	float len_mul = 1.2 + synth_hash(vec2(seed * 7.7, road + 10.0)) * 0.2;
	float bright_mul = 0.95 + synth_hash(vec2(seed * 9.4, road + 18.0)) * 0.2;

	float signal = synth_signal_profile(
		behind,
		packet_size,
		body_length * len_mul,
		trail_length * len_mul
	);

	float span = body_length * len_mul + trail_length * len_mul * 0.5;
	float corner = synth_corner_bridge(uv, behind, span) * synapse_strength;
	float near_head = exp(-behind / max(packet_size * 2.4, 0.001));
	float synapse = synth_junction_mask(uv) * near_head * synapse_strength;
	float afterglow = synth_junction_mask(uv) * exp(-behind / max(span, 0.001)) * 0.35;

	float life_period = 14.0 + synth_hash(vec2(seed * 12.0, road + 21.0)) * 12.0;
	float life_phase = synth_hash(vec2(seed * 1.9, road + 29.0));
	float life = fract(t / life_period + life_phase);
	float fade_start = mix(0.48, 0.62, burst);
	float fade_end = mix(0.74, 0.88, burst);
	float envelope = smoothstep(0.0, 0.1, life) * (1.0 - smoothstep(fade_start, fade_end, life));

	float energy = (signal * bright_mul + corner + synapse + afterglow) * envelope * route_gate;

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
		float s1 = synth_deep_thought(uv, t, real_t, 11.0, burst, tint_acc, weight_acc);
		signals = max(signals, s1 * mix(0.25, 1.0, burst));

		float energy = max(signals * path, signals * bloom * bloom_strength * 0.45);
		vec3 col = weight_acc > 0.001 ? (tint_acc / weight_acc) : vec3(0.35, 0.85, 1.0);
		float alpha = clamp(energy * pulse_strength, 0.0, 0.55);
		COLOR = vec4(col * alpha * 1.55, alpha);
	} else {
		COLOR = vec4(0.0);
	}
}
