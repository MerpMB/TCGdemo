shader_type canvas_item;
render_mode blend_add, unshaded;

#include "synth_v2_common.gdshaderinc"

// Synth V2 — deep / secondary traffic (rarer, slower thoughts on alternate journeys).

uniform sampler2D board_map : source_color, filter_linear_mipmap;
uniform sampler2D flow_map : source_color, filter_linear_mipmap;

uniform float pulse_strength : hint_range(0.0, 1.5) = 0.55;
uniform float time_scale : hint_range(0.0, 1.5) = 0.26;
uniform float packet_speed : hint_range(0.2, 3.0) = 0.48;
uniform float packet_size : hint_range(0.03, 0.25) = 0.095;
uniform float body_length : hint_range(0.08, 0.70) = 0.48;
uniform float trail_length : hint_range(0.08, 1.0) = 0.65;
uniform float synapse_strength : hint_range(0.0, 2.0) = 0.95;
uniform float rainbow_strength : hint_range(0.0, 1.0) = 0.82;
uniform float bloom_strength : hint_range(0.0, 1.5) = 0.55;
uniform float journey_count : hint_range(1.0, 16.0) = 7.0;

float synth_rare_event(float real_t) {
	// Sparse memorable flashes — not a heartbeat.
	float a = fract(real_t * 0.027);
	float b = fract(real_t * 0.019 + 0.41);
	float flash_a = smoothstep(0.0, 0.03, a) * (1.0 - smoothstep(0.08, 0.16, a));
	float flash_b = smoothstep(0.0, 0.025, b) * (1.0 - smoothstep(0.06, 0.14, b)) * 0.55;
	return max(flash_a, flash_b);
}

float synth_deep_owns(float seed, float road, float rare, float count) {
	// Deep layer prefers every other lane so primary stays readable.
	float own = step(0.5, mod(road + seed * 2.0, 2.0));
	float pick = floor(fract(seed * 0.271 + 0.44) * count);
	own = max(own * 0.85, step(abs(road - pick), 0.1));
	own = max(own, step(0.5, 1.0 - mod(road + seed * 5.0, 5.0)) * (0.4 + rare));
	return own;
}

float synth_deep_packet(
	vec4 flow,
	vec4 board,
	float t,
	float real_t,
	float seed,
	float head_w,
	float body_w,
	float trail_w,
	float rare,
	inout vec3 tint_acc,
	inout float weight_acc
) {
	float coverage = synth_flow_coverage(flow);
	if (coverage < 0.025) {
		return 0.0;
	}

	float road = synth_flow_road(flow);
	float route_gate = synth_deep_owns(seed, road, rare, journey_count);
	if (route_gate < 0.5) {
		return 0.0;
	}

	float phase = synth_hash(vec2(seed * 5.1, road + 8.3));
	float base_speed = 0.38 + synth_hash(vec2(seed * 3.7, road + 2.2)) * 0.35;
	float travel = synth_flow_travel(flow);
	float head = fract(t * packet_speed * base_speed * 0.32 + phase);
	float behind = fract(head - travel);

	float signal = synth_signal_profile(behind, head_w, body_w, trail_w);
	float near_head = exp(-behind / max(head_w * 2.4, 0.001));
	float junc = max(synth_flow_junction(flow), board.g);
	float synapse = junc * near_head * synapse_strength;

	float life_period = 16.0 + synth_hash(vec2(seed * 9.0, road + 5.0)) * 14.0;
	float life = fract(t / life_period + synth_hash(vec2(seed, road + 1.7)));
	float envelope = smoothstep(0.0, 0.10, life) * (1.0 - smoothstep(0.55, 0.82, life));
	envelope = max(envelope, rare * 0.55);

	float path = max(board.r * 0.9, board.g);
	float energy = (signal + synapse) * envelope * route_gate * path * coverage;

	float hue = fract(head * 0.4 + seed * 0.23 + road * 0.11);
	vec3 tint = mix(vec3(0.45, 0.55, 1.0), synth_iridescent(hue), rainbow_strength * 0.9);
	tint = mix(tint, vec3(0.85, 0.55, 1.0), rare * 0.25);

	tint_acc += tint * energy;
	weight_acc += energy;
	return energy;
}

void fragment() {
	vec2 uv = UV;
	vec4 board = texture(board_map, uv);
	vec4 flow = texture(flow_map, uv);
	float active = step(0.02, synth_flow_coverage(flow)) + step(0.02, board.b);

	float real_t = TIME;
	float t = real_t * time_scale;
	float rare = synth_rare_event(real_t);

	float signals = 0.0;
	vec3 tint_acc = vec3(0.0);
	float weight_acc = 0.0;

	if (active > 0.5) {
		signals = max(signals, synth_deep_packet(flow, board, t, real_t, 0.0, packet_size, body_length, trail_length, rare, tint_acc, weight_acc));
		signals = max(signals, synth_deep_packet(flow, board, t, real_t, 1.0, packet_size * 1.08, body_length * 1.12, trail_length * 1.1, rare, tint_acc, weight_acc) * 0.7);
	}

	vec3 tint = weight_acc > 1e-4 ? tint_acc / weight_acc : vec3(0.5, 0.7, 1.0);
	float bloom = board.b * signals * bloom_strength * 0.45;
	float alpha = clamp(signals * pulse_strength + bloom * 0.3, 0.0, 0.85) * step(0.5, active);
	COLOR = vec4(tint * (signals * pulse_strength + bloom), alpha);
}
