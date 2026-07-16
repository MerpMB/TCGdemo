// Synth V2 shared lighting / packet helpers (topology is baked — not recomputed here).

float synth_hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float synth_signal_profile(float behind, float head_w, float body_w, float trail_w) {
	float extent = body_w + trail_w * 2.6;
	if (behind > extent) {
		return 0.0;
	}
	float lead = exp(-behind / max(head_w * 1.8, 0.001));
	float body = exp(-behind / max(body_w * 0.85, 0.001));
	float wake = exp(-behind / max(trail_w * 1.15, 0.001)) * 0.55;
	float wave = max(lead * 0.9, max(body, wake));
	float focus = 1.0 - smoothstep(0.0, body_w * 1.4, behind) * 0.22;
	return wave * focus;
}

vec3 synth_palette(float t) {
	vec3 teal = vec3(0.12, 0.72, 0.82);
	vec3 cyan = vec3(0.18, 0.88, 1.0);
	vec3 blue = vec3(0.14, 0.48, 0.95);
	vec3 c = mix(teal, cyan, smoothstep(0.0, 0.55, t));
	return mix(c, blue, smoothstep(0.55, 1.0, t) * 0.35);
}

vec3 synth_iridescent(float t) {
	float x = fract(t);
	vec3 c0 = vec3(0.25, 0.95, 1.00);
	vec3 c1 = vec3(0.28, 0.55, 1.00);
	vec3 c2 = vec3(0.58, 0.32, 1.00);
	vec3 c3 = vec3(0.95, 0.38, 0.88);
	vec3 c4 = vec3(0.96, 0.98, 1.00);
	float s = x * 4.0;
	vec3 c;
	if (s < 1.0) {
		c = mix(c0, c1, s);
	} else if (s < 2.0) {
		c = mix(c1, c2, s - 1.0);
	} else if (s < 3.0) {
		c = mix(c2, c3, s - 2.0);
	} else {
		c = mix(c3, c4, s - 3.0);
	}
	vec3 cool = vec3(0.55, 0.82, 1.0);
	return mix(cool, c, 0.78);
}

// Decode baked flow map.
float synth_flow_travel(vec4 flow) {
	return flow.r;
}

float synth_flow_road(vec4 flow) {
	return floor(flow.g * 255.0 + 0.5);
}

float synth_flow_junction(vec4 flow) {
	return flow.b;
}

float synth_flow_coverage(vec4 flow) {
	return flow.a;
}
