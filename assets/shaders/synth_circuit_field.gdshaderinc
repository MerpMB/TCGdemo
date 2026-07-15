// Shared Synth topology — static neural PCB + helpers for living signal traffic.
// Geometry never animates. Motion is authored only in packet/synapse shaders.

float synth_hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float synth_soft_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = synth_hash(i);
	float b = synth_hash(i + vec2(1.0, 0.0));
	float c = synth_hash(i + vec2(0.0, 1.0));
	float d = synth_hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float synth_region_mask(vec2 uv) {
	float coarse = synth_soft_noise(uv * vec2(2.4, 3.0) + vec2(0.17, 0.31));
	float cells = synth_soft_noise(uv * vec2(5.5, 6.8) + vec2(4.2, 1.8));
	float region = mix(coarse, cells, 0.38);
	return smoothstep(0.55, 0.78, region);
}

float synth_line_mask(float dist, float half_width) {
	return 1.0 - smoothstep(0.0, half_width, dist);
}

vec2 synth_grid_uv(vec2 uv) {
	return uv * vec2(10.0, 14.0);
}

float synth_h_gate(vec2 cell) {
	return step(0.42, synth_hash(cell));
}

float synth_v_gate(vec2 cell) {
	return step(0.45, synth_hash(cell + vec2(19.0, 7.0)));
}

float synth_trace_field(vec2 uv) {
	vec2 grid_uv = synth_grid_uv(uv);
	vec2 cell = floor(grid_uv);
	vec2 f = fract(grid_uv);

	float h_gate = synth_h_gate(cell);
	float v_gate = synth_v_gate(cell);

	float road_w = 0.028;
	float h_line = h_gate * synth_line_mask(abs(f.y - 0.5), road_w);
	float v_line = v_gate * synth_line_mask(abs(f.x - 0.5), road_w);

	float glow_w = 0.075;
	float h_glow = h_gate * synth_line_mask(abs(f.y - 0.5), glow_w) * 0.28;
	float v_glow = v_gate * synth_line_mask(abs(f.x - 0.5), glow_w) * 0.28;

	float junction = h_gate * v_gate * synth_line_mask(length(f - 0.5), 0.07);
	float traces = max(max(h_line, v_line), junction);
	traces = max(traces, max(h_glow, v_glow));
	return traces * synth_region_mask(uv);
}

float synth_trace_core(vec2 uv) {
	vec2 grid_uv = synth_grid_uv(uv);
	vec2 cell = floor(grid_uv);
	vec2 f = fract(grid_uv);

	float h_gate = synth_h_gate(cell);
	float v_gate = synth_v_gate(cell);

	float road_w = 0.022;
	float h_line = h_gate * synth_line_mask(abs(f.y - 0.5), road_w);
	float v_line = v_gate * synth_line_mask(abs(f.x - 0.5), road_w);
	return max(h_line, v_line) * synth_region_mask(uv);
}

// Synapse / junction mask — neural routing nodes at H∩V crossings.
float synth_junction_mask(vec2 uv) {
	vec2 grid_uv = synth_grid_uv(uv);
	vec2 cell = floor(grid_uv);
	vec2 f = fract(grid_uv);
	float both = synth_h_gate(cell) * synth_v_gate(cell);
	return both * synth_line_mask(length(f - 0.5), 0.09) * synth_region_mask(uv);
}

// Continuous travel along the dominant road axis.
float synth_travel_coord(vec2 uv) {
	vec2 grid_uv = synth_grid_uv(uv);
	vec2 cell = floor(grid_uv);
	if (synth_h_gate(cell) >= synth_v_gate(cell)) {
		return grid_uv.x;
	}
	return grid_uv.y;
}

// Perpendicular travel — used for brief branch / split glow at synapses.
float synth_cross_travel_coord(vec2 uv) {
	vec2 grid_uv = synth_grid_uv(uv);
	vec2 cell = floor(grid_uv);
	if (synth_h_gate(cell) >= synth_v_gate(cell)) {
		return grid_uv.y;
	}
	return grid_uv.x;
}

float synth_road_id(vec2 uv) {
	vec2 cell = floor(synth_grid_uv(uv));
	return synth_hash(cell + vec2(3.7, 11.3));
}

// Signal silhouette: bright leading edge → glowing body → soft fading tail.
// Visual: █████▓▒░   (behind=0 at head, increases into the wake)
float synth_signal_profile(float behind, float head_w, float body_w, float trail_w) {
	float extent = body_w + trail_w * 2.2;
	float window = 1.0 - step(extent, behind);

	float tip = exp(-(behind * behind) / max(head_w * head_w * 0.22, 0.00005));
	float body = pow(1.0 - smoothstep(0.0, body_w, behind), 0.55);
	float tail = exp(-max(behind - body_w * 0.35, 0.0) / max(trail_w, 0.001)) * 0.5;

	return max(tip * 1.55, max(body * 0.95, tail)) * window;
}

vec3 synth_palette(float t) {
	vec3 cyan = vec3(0.15, 0.95, 1.0);
	vec3 blue = vec3(0.10, 0.55, 1.0);
	vec3 violet = vec3(0.48, 0.30, 1.0);
	vec3 white = vec3(0.95, 0.99, 1.0);
	vec3 c = mix(cyan, blue, smoothstep(0.0, 0.55, t));
	c = mix(c, violet, smoothstep(0.55, 0.88, t) * 0.22);
	return mix(c, white, smoothstep(0.85, 1.0, t) * 0.45);
}

// Soft iridescent spectrum for moving signals only (not the idle board).
// Controlled saturation — elegant data sheen, not RGB gamer lighting.
vec3 synth_iridescent(float t) {
	float x = fract(t);
	vec3 c0 = vec3(0.42, 0.88, 1.00); // soft cyan
	vec3 c1 = vec3(0.58, 0.52, 1.00); // periwinkle
	vec3 c2 = vec3(0.92, 0.48, 0.78); // muted rose
	vec3 c3 = vec3(0.88, 0.78, 0.52); // pale gold
	vec3 c4 = vec3(0.45, 0.92, 0.85); // aqua pearl
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
	// Pull toward cool pearl so saturation stays restrained.
	vec3 pearl = vec3(0.72, 0.88, 1.0);
	return mix(pearl, c, 0.62);
}

// Wider soft path for substantial signal glow (still road-bound).
float synth_trace_soft(vec2 uv) {
	vec2 grid_uv = synth_grid_uv(uv);
	vec2 cell = floor(grid_uv);
	vec2 f = fract(grid_uv);
	float h_gate = synth_h_gate(cell);
	float v_gate = synth_v_gate(cell);
	float soft_w = 0.065;
	float h_line = h_gate * synth_line_mask(abs(f.y - 0.5), soft_w);
	float v_line = v_gate * synth_line_mask(abs(f.x - 0.5), soft_w);
	float junction = h_gate * v_gate * synth_line_mask(length(f - 0.5), 0.12);
	return max(max(h_line, v_line), junction) * synth_region_mask(uv);
}
