// DEPRECATED — Synth V1. Replaced by synth_fiber_traffic.gdshader + SynthTopology.
shader_type canvas_item;
render_mode blend_add, unshaded;

#include "synth_circuit_field.gdshaderinc"

// Layer 3 — packets travel designed PCB routes (architecture ≠ animation).

uniform float stream_strength : hint_range(0.0, 1.5) = 1.15;
uniform float time_scale : hint_range(0.0, 1.5) = 0.48;
uniform float packet_speed : hint_range(0.2, 3.0) = 0.78;
uniform float packet_size : hint_range(0.03, 0.25) = 0.09;
uniform float body_length : hint_range(0.08, 0.70) = 0.42;
uniform float trail_length : hint_range(0.08, 1.0) = 0.58;
uniform float synapse_strength : hint_range(0.0, 2.0) = 1.20;
uniform float rainbow_strength : hint_range(0.0, 1.0) = 0.88;
uniform float bloom_strength : hint_range(0.0, 1.5) = 0.72;

float synth_traffic_burst(float real_t) {
	float cycle = fract(real_t * 0.055);
	float burst = smoothstep(0.0, 0.05, cycle) * (1.0 - smoothstep(0.14, 0.26, cycle));
	float ripple = smoothstep(0.58, 0.64, cycle) * (1.0 - smoothstep(0.72, 0.84, cycle)) * 0.4;
	return max(burst, ripple) * 0.7;
}

// Each stream owns 1–2 designed routes so journeys stay long and coherent.
float synth_stream_owns_route(float seed, float road, float burst) {
	float primary = floor(fract(seed * 0.618 + 0.13) * SYNTH_ROUTE_COUNT);
	float secondary = floor(fract(seed * 0.382 + 0.71) * SYNTH_ROUTE_COUNT);
	float own = max(step(abs(road - primary), 0.1), step(abs(road - secondary), 0.1));
	// During bursts, allow one extra neighboring route.
	float neighbor = floor(mod(primary + 1.0, SYNTH_ROUTE_COUNT));
	own = max(own, step(abs(road - neighbor), 0.1) * burst);
	return own;
}

float synth_thought_stream(
	vec2 uv,
	float t,
	float real_t,
	float seed,
	float head_w,
	float body_w,
	float trail_w,
	float burst,
	inout vec3 tint_acc,
	inout float weight_acc
) {
	float road = synth_road_id(uv);
	float route_gate = synth_stream_owns_route(seed, road, burst);
	if (route_gate < 0.5) {
		return 0.0;
	}

	float phase = synth_hash(vec2(seed * 7.3, road + 4.1));
	float base_speed = 0.48 + synth_hash(vec2(seed * 2.9, road + 9.7)) * 0.45;
	float accel = 0.28 * sin(real_t * (0.38 + seed * 0.06) + phase * 6.2831);
	float warped_t = t + accel / max(0.38 + seed * 0.06, 0.2);

	// Travel is normalized arc-length along the designed route [0,1].
	float travel = synth_travel_coord(uv);
	float head = fract(warped_t * packet_speed * base_speed * 0.35 + phase);
	float behind = fract(head - travel);

	float len_mul = 1.15 + synth_hash(vec2(seed * 6.4, road + 12.0)) * 0.25;
	float bright_mul = 1.0 + synth_hash(vec2(seed * 8.2, road + 15.0)) * 0.2;

	float signal = synth_signal_profile(
		behind,
		head_w,
		body_w * len_mul,
		trail_w * len_mul
	);

	float span = body_w * len_mul + trail_w * len_mul * 0.5;
	float corner = synth_corner_bridge(uv, behind, span) * synapse_strength;

	// Junction flare: brief bright node when the wave head arrives.
	float near_head = exp(-behind / max(head_w * 2.2, 0.001));
	float synapse = synth_junction_mask(uv) * near_head * synapse_strength * 1.1;

	float life_period = 12.0 + synth_hash(vec2(seed * 11.0, road + 17.0)) * 10.0;
	float life_phase = synth_hash(vec2(seed * 3.1, road + 23.0));
	float life = fract(t / life_period + life_phase);
	float fade_start = mix(0.52, 0.66, burst);
	float fade_end = mix(0.78, 0.90, burst);
	float envelope = smoothstep(0.0, 0.08, life) * (1.0 - smoothstep(fade_start, fade_end, life));

	float energy = (signal * bright_mul + corner + synapse) * envelope * route_gate;

	float hue = fract(head * 0.55 - behind * 0.75 + seed * 0.11 + road * 0.17);
	vec3 tint = mix(vec3(0.35, 0.90, 1.0), synth_iridescent(hue), rainbow_strength);
	float lead_soft = exp(-behind / max(head_w * 2.4, 0.001));
	tint = mix(tint, vec3(0.92, 0.97, 1.0), lead_soft * 0.28);

	tint_acc += tint * energy;
	weight_acc += energy;
	return energy;
}

void fragment() {
	vec2 uv = UV;
	float real_t = TIME;
	float t = real_t * time_scale;
	float burst = synth_traffic_burst(real_t);

	float core = synth_trace_core(uv);
	float soft = synth_trace_soft(uv);
	float bloom = synth_trace_bloom(uv);
	float path = max(core, soft * 0.88);
	path = max(path, synth_junction_mask(uv) * 0.95);

	float signals = 0.0;
	vec3 tint_acc = vec3(0.0);
	float weight_acc = 0.0;

	if (path >= 0.008 || bloom >= 0.02) {
		// Few streams — each owns specific designed routes for long journeys.
		signals = max(signals, synth_thought_stream(uv, t, real_t, 0.0, packet_size, body_length, trail_length, burst, tint_acc, weight_acc));
		signals = max(signals, synth_thought_stream(uv, t, real_t, 1.0, packet_size * 1.05, body_length * 1.08, trail_length * 1.05, burst, tint_acc, weight_acc));
		float s2 = synth_thought_stream(uv, t, real_t, 2.0, packet_size * 0.95, body_length * 1.12, trail_length * 1.1, burst, tint_acc, weight_acc);
		signals = max(signals, s2 * mix(0.35, 1.0, burst));

		float energy = max(signals * path, signals * bloom * bloom_strength * 0.55);
		vec3 col = weight_acc > 0.001 ? (tint_acc / weight_acc) : vec3(0.4, 0.9, 1.0);
		float alpha = clamp(energy * stream_strength, 0.0, 0.92);
		COLOR = vec4(col * alpha * 1.85, alpha);
	} else {
		COLOR = vec4(0.0);
	}
}
