shader_type canvas_item;
render_mode blend_add, unshaded;

#include "synth_circuit_field.gdshaderinc"

// Layer 3 — racing light packets traveling along roads (Tron light-cycle feel).

uniform float stream_strength : hint_range(0.0, 1.0) = 0.55;
uniform float time_scale : hint_range(0.0, 0.5) = 0.16;
uniform float packet_speed : hint_range(0.2, 3.0) = 1.35;
uniform float packet_size : hint_range(0.02, 0.2) = 0.045;
uniform float pulse_interval : hint_range(2.0, 12.0) = 5.5;
uniform float pulse_width : hint_range(0.05, 0.4) = 0.16;

void fragment() {
	vec2 uv = UV;
	float t = TIME * time_scale;
	float core = synth_trace_core(uv);
	float packets = 0.0;
	vec3 col = vec3(0.0);
	float alpha = 0.0;

	if (core >= 0.02) {
		// Shared heartbeat with energy pulse — brightens racing lights as it passes.
		float cycle = fract(t / max(pulse_interval, 0.001));
		float wave_pos = cycle * 1.35 - 0.1;
		float path_base = uv.x * 0.75 + uv.y * 0.35 + synth_path_coord(uv) * 0.15;
		float pd = abs(path_base - wave_pos);
		float pulse_boost = 1.0 - smoothstep(pulse_width, pulse_width * 0.35, pd);
		pulse_boost = pow(pulse_boost, 1.6);

		float path = synth_path_coord(uv);

		// Staggered bright dashes racing along the road (■■■□□□, not waves).
		for (int i = 0; i < 4; i++) {
			float fi = float(i);
			float speed = packet_speed * (0.9 + fi * 0.16);
			float lane = fract(t * speed + fi * 0.31 + synth_hash(floor(uv * vec2(10.0, 14.0)) + fi) * 0.4);
			float d = abs(fract(path * 0.95) - lane);
			d = min(d, 1.0 - d);
			// Elongated dash along the path, tight across the road.
			float pkt = 1.0 - smoothstep(packet_size, packet_size * 0.2, d);
			pkt = pow(pkt, 1.4);
			// Brief pause / merge at some junctions.
			float pause_gate = step(0.22, synth_hash(floor(uv * vec2(10.0, 14.0)) + fi * 3.0));
			pkt *= mix(0.25, 1.0, pause_gate);
			packets = max(packets, pkt);
		}

		packets *= core;
		packets *= 1.0 + pulse_boost * 0.9;

		col = synth_palette(0.55 + packets * 0.45);
		alpha = clamp(packets * stream_strength, 0.0, 0.62);
	}

	COLOR = vec4(col * alpha * 1.45, alpha);
}
