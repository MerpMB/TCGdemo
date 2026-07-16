shader_type canvas_item;
render_mode blend_add, unshaded;

#include "synth_circuit_field.gdshaderinc"

// Layer 3 — continuous flowing energy waves (motion personality pass).
// Brightness locked; focus on organic multi-segment motion.

uniform float stream_strength : hint_range(0.0, 1.5) = 1.15;
uniform float time_scale : hint_range(0.0, 1.5) = 0.48;
uniform float packet_speed : hint_range(0.2, 3.0) = 0.78;
uniform float packet_size : hint_range(0.03, 0.25) = 0.09;
uniform float body_length : hint_range(0.08, 0.70) = 0.38;
uniform float trail_length : hint_range(0.08, 1.0) = 0.55;
uniform float synapse_strength : hint_range(0.0, 2.0) = 0.95;
uniform float rainbow_strength : hint_range(0.0, 1.0) = 0.88;
uniform float bloom_strength : hint_range(0.0, 1.5) = 0.72;

// Occasional network-wide traffic bursts (calm most of the time).
float synth_traffic_burst(float real_t) {
	// ~16s cycle: brief busy window, then long calm.
	float cycle = fract(real_t * 0.062);
	float burst = smoothstep(0.0, 0.06, cycle) * (1.0 - smoothstep(0.18, 0.32, cycle));
	// Secondary quieter ripple so bursts aren't a single metronome.
	float ripple = smoothstep(0.55, 0.62, cycle) * (1.0 - smoothstep(0.70, 0.82, cycle)) * 0.45;
	return max(burst, ripple) * 0.75;
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
	vec2 cell = floor(synth_grid_uv(uv));
	float road = synth_road_id(uv);

	// Larger corridor clusters yield fewer, more elegant long journeys.
	vec2 corridor = floor(cell * 0.28);
	float route_thresh = mix(0.76, 0.54, burst);
	float route_gate = step(route_thresh, synth_hash(corridor + vec2(seed * 13.1, 2.7)));
	if (route_gate < 0.5) {
		return 0.0;
	}

	float phase = synth_hash(corridor + vec2(seed * 7.3, 4.1));
	float base_speed = 0.55 + synth_hash(corridor + vec2(seed * 2.9, 9.7)) * 0.70;
	// Subtle accelerate / decelerate per stream (warped time).
	float accel = 0.32 * sin(real_t * (0.42 + seed * 0.07) + phase * 6.2831);
	float warped_t = t + accel / max(0.42 + seed * 0.07, 0.2);
	float spacing = 0.82 + synth_hash(corridor + vec2(seed * 5.5, 1.3)) * 0.95;
	float bright_mul = 1.0 + synth_hash(corridor + vec2(seed * 8.2, 15.0)) * 0.25;
	float life_period = 10.5 + synth_hash(corridor + vec2(seed * 11.0, 17.0)) * 12.0;
	float life_phase = synth_hash(corridor + vec2(seed * 3.1, 23.0));
	float len_mul = 1.05 + synth_hash(corridor + vec2(seed * 6.4, 12.0)) * 0.35;

	float travel = synth_travel_coord(uv) / max(spacing, 0.001);
	float head = fract(warped_t * packet_speed * base_speed + phase + road * 0.21);
	float behind = fract(head - travel);

	float signal = synth_signal_profile(
		behind,
		head_w,
		body_w * len_mul,
		trail_w * len_mul
	);

	float span = body_w * len_mul + trail_w * len_mul * 0.5;
	float corner = synth_corner_bridge(uv, behind, span) * synapse_strength * 1.15;

	// Soft branch glow only while the wave occupies the junction.
	float split = step(0.74, synth_hash(corridor + vec2(seed * 19.0, 31.0)));
	float cross = synth_cross_travel_coord(uv);
	float cross_near = 1.0 - smoothstep(0.0, 0.22, abs(fract(cross) - 0.5));
	float near_wave = 1.0 - smoothstep(0.0, span * 0.9, behind);
	float branch = split * synth_junction_mask(uv) * near_wave * cross_near * 0.5;

	float life = fract(t / life_period + life_phase + seed * 0.17);
	// During bursts, envelopes stay open longer so several waves coexist.
	float fade_start = mix(0.48, 0.62, burst);
	float fade_end = mix(0.70, 0.86, burst);
	float envelope = smoothstep(0.0, 0.10, life) * (1.0 - smoothstep(fade_start, fade_end, life));
	envelope = mix(envelope, max(envelope, burst * 0.85), burst * 0.65);

	float energy = (signal * bright_mul + corner + branch) * envelope * route_gate;

	float hue = fract(head * 0.55 - behind * 0.75 + seed * 0.11 + road * 0.07);
	vec3 tint = mix(vec3(0.35, 0.90, 1.0), synth_iridescent(hue), rainbow_strength);
	// Soft highlight along the leading third — not a hard white bead.
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
		signals = max(signals, synth_thought_stream(uv, t, real_t, 0.0, packet_size, body_length, trail_length, burst, tint_acc, weight_acc));
		signals = max(signals, synth_thought_stream(uv, t, real_t, 1.0, packet_size * 1.06, body_length * 1.1, trail_length * 1.05, burst, tint_acc, weight_acc));
		signals = max(signals, synth_thought_stream(uv, t, real_t, 2.0, packet_size * 0.95, body_length * 0.98, trail_length * 1.12, burst, tint_acc, weight_acc));
		// Extra stream only appears during occasional burst windows.
		float s3 = synth_thought_stream(uv, t, real_t, 3.0, packet_size * 1.08, body_length * 1.15, trail_length * 1.1, burst, tint_acc, weight_acc);
		signals = max(signals, s3 * mix(0.0, 0.85, burst));

		float core_energy = signals * path;
		float bloom_energy = signals * bloom * bloom_strength * 0.55;
		float energy = max(core_energy, bloom_energy);

		vec3 col = weight_acc > 0.001 ? (tint_acc / weight_acc) : vec3(0.4, 0.9, 1.0);
		float alpha = clamp(energy * stream_strength, 0.0, 0.92);
		COLOR = vec4(col * alpha * 1.85, alpha);
	} else {
		COLOR = vec4(0.0);
	}
}
