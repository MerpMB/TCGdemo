shader_type canvas_item;
render_mode blend_add, unshaded;

#include "synth_v2_common.gdshaderinc"

// Synth V2 — primary fiber traffic along baked journeys.
// Topology is static; this layer only animates packets on owned routes.

uniform sampler2D board_map : source_color, filter_linear_mipmap;
uniform sampler2D flow_map : source_color, filter_linear_mipmap;

uniform float stream_strength : hint_range(0.0, 1.5) = 1.15;
uniform float time_scale : hint_range(0.0, 1.5) = 0.48;
uniform float packet_speed : hint_range(0.2, 3.0) = 0.78;
uniform float packet_size : hint_range(0.03, 0.25) = 0.09;
uniform float body_length : hint_range(0.08, 0.70) = 0.42;
uniform float trail_length : hint_range(0.08, 1.0) = 0.58;
uniform float synapse_strength : hint_range(0.0, 2.0) = 1.20;
uniform float rainbow_strength : hint_range(0.0, 1.0) = 0.88;
uniform float bloom_strength : hint_range(0.0, 1.5) = 0.72;
uniform float journey_count : hint_range(1.0, 16.0) = 7.0;

float synth_traffic_burst(float real_t) {
	float cycle = fract(real_t * 0.048);
	float burst = smoothstep(0.0, 0.04, cycle) * (1.0 - smoothstep(0.12, 0.22, cycle));
	float ripple = smoothstep(0.62, 0.68, cycle) * (1.0 - smoothstep(0.76, 0.88, cycle)) * 0.35;
	return max(burst, ripple) * 0.75;
}

float synth_owns_journey(float seed, float road, float burst, float count) {
	// Spread traffic across many edge→center runs (not just 1–2 routes).
	float slot = floor(mod(road + seed * 3.0, 4.0));
	float own = step(abs(slot - seed), 0.1);
	// Neighbor lane during burst — parallel bundles light together.
	float neighbor = floor(mod(road + 1.0, count));
	float primary = floor(mod(seed * 7.0 + 1.0, count));
	own = max(own, step(abs(road - primary), 0.1));
	own = max(own, step(abs(road - neighbor), 0.1) * burst * 0.7);
	// Every 3rd journey always has a pulse from this seed family.
	own = max(own, step(0.5, 1.0 - mod(road + seed, 3.0)));
	return own;
}

float synth_fiber_packet(
	vec2 uv,
	vec4 flow,
	vec4 board,
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
	float coverage = synth_flow_coverage(flow);
	if (coverage < 0.02) {
		return 0.0;
	}

	float road = synth_flow_road(flow);
	float route_gate = synth_owns_journey(seed, road, burst, journey_count);
	if (route_gate < 0.5) {
		return 0.0;
	}

	float phase = synth_hash(vec2(seed * 7.3, road + 4.1));
	float base_speed = 0.48 + synth_hash(vec2(seed * 2.9, road + 9.7)) * 0.45;
	float accel = 0.26 * sin(real_t * (0.36 + seed * 0.05) + phase * 6.2831);
	float warped_t = t + accel / max(0.36 + seed * 0.05, 0.2);

	float travel = synth_flow_travel(flow);
	float head = fract(warped_t * packet_speed * base_speed * 0.35 + phase);
	float behind = fract(head - travel);

	float len_mul = 1.12 + synth_hash(vec2(seed * 6.4, road + 12.0)) * 0.28;
	float bright_mul = 1.0 + synth_hash(vec2(seed * 8.2, road + 15.0)) * 0.22;

	float signal = synth_signal_profile(behind, head_w, body_w * len_mul, trail_w * len_mul);

	float near_head = exp(-behind / max(head_w * 2.2, 0.001));
	float junc = max(synth_flow_junction(flow), board.g);
	float synapse = junc * near_head * synapse_strength * 1.15;

	// Rare memorable event: synapse cascade on epic spine during burst.
	float cascade = step(abs(road - 0.0), 0.1) * burst * junc * near_head * 0.85;

	float life_period = 11.0 + synth_hash(vec2(seed * 11.0, road + 17.0)) * 11.0;
	float life_phase = synth_hash(vec2(seed * 3.1, road + 23.0));
	float life = fract(t / life_period + life_phase);
	float fade_start = mix(0.50, 0.64, burst);
	float fade_end = mix(0.78, 0.92, burst);
	float envelope = smoothstep(0.0, 0.08, life) * (1.0 - smoothstep(fade_start, fade_end, life));

	float path = max(board.r, board.a);
	path = max(path, board.g * 0.95);
	float energy = (signal * bright_mul + synapse + cascade) * envelope * route_gate * path * coverage;

	float hue = fract(head * 0.55 - behind * 0.75 + seed * 0.11 + road * 0.17);
	vec3 tint = mix(vec3(0.35, 0.90, 1.0), synth_iridescent(hue), rainbow_strength);
	float lead_soft = exp(-behind / max(head_w * 2.4, 0.001));
	tint = mix(tint, vec3(0.92, 0.97, 1.0), lead_soft * 0.30);

	tint_acc += tint * energy;
	weight_acc += energy;
	return energy;
}

void fragment() {
	vec2 uv = UV;
	vec4 board = texture(board_map, uv);
	vec4 flow = texture(flow_map, uv);
	float coverage = synth_flow_coverage(flow);
	float active = step(0.015, coverage) + step(0.02, board.b);

	float real_t = TIME;
	float t = real_t * time_scale;
	float burst = synth_traffic_burst(real_t);

	float signals = 0.0;
	vec3 tint_acc = vec3(0.0);
	float weight_acc = 0.0;

	if (active > 0.5) {
		signals = max(signals, synth_fiber_packet(uv, flow, board, t, real_t, 0.0, packet_size, body_length, trail_length, burst, tint_acc, weight_acc));
		signals = max(signals, synth_fiber_packet(uv, flow, board, t, real_t, 1.0, packet_size * 1.02, body_length * 1.05, trail_length * 1.04, burst, tint_acc, weight_acc));
		signals = max(signals, synth_fiber_packet(uv, flow, board, t, real_t, 2.0, packet_size * 0.95, body_length * 1.08, trail_length * 1.06, burst, tint_acc, weight_acc));
		float s3 = synth_fiber_packet(uv, flow, board, t, real_t, 3.0, packet_size * 0.9, body_length * 1.12, trail_length * 1.1, burst, tint_acc, weight_acc);
		signals = max(signals, s3 * (0.55 + burst * 0.45));
	}

	vec3 tint = weight_acc > 1e-4 ? tint_acc / weight_acc : vec3(0.4, 0.9, 1.0);
	float bloom = board.b * signals * bloom_strength * 0.55;
	float alpha = clamp(signals * stream_strength + bloom * 0.35, 0.0, 1.0) * step(0.5, active);
	vec3 col = tint * (signals * stream_strength + bloom);
	COLOR = vec4(col, alpha);
}
