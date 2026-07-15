// Shared Synth topology — thin Manhattan "light roads" + sparse tech regions.
// Designed for Tron-style racing energy, NOT filled digital blocks.

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

// Technology regions — ~25–35% coverage; large empty art-safe zones.
float synth_region_mask(vec2 uv) {
	float coarse = synth_soft_noise(uv * vec2(2.4, 3.0) + vec2(0.17, 0.31));
	float cells = synth_soft_noise(uv * vec2(5.5, 6.8) + vec2(4.2, 1.8));
	float region = mix(coarse, cells, 0.38);
	return smoothstep(0.55, 0.78, region);
}

// Thin glowing road lines (Manhattan grid). Returns 1 on the road, 0 off it.
float synth_line_mask(float dist, float half_width) {
	return 1.0 - smoothstep(0.0, half_width, dist);
}

// Motherboard / city-grid light roads.
float synth_trace_field(vec2 uv) {
	vec2 grid_uv = uv * vec2(10.0, 14.0);
	vec2 cell = floor(grid_uv);
	vec2 f = fract(grid_uv);

	float h_gate = step(0.42, synth_hash(cell + vec2(0.0, 0.0)));
	float v_gate = step(0.45, synth_hash(cell + vec2(19.0, 7.0)));

	// Thin center roads — NOT inverted fills.
	float road_w = 0.028;
	float h_line = h_gate * synth_line_mask(abs(f.y - 0.5), road_w);
	float v_line = v_gate * synth_line_mask(abs(f.x - 0.5), road_w);

	// Soft outer glow along the same roads (still thin).
	float glow_w = 0.075;
	float h_glow = h_gate * synth_line_mask(abs(f.y - 0.5), glow_w) * 0.28;
	float v_glow = v_gate * synth_line_mask(abs(f.x - 0.5), glow_w) * 0.28;

	float junction = h_gate * v_gate * synth_line_mask(length(f - 0.5), 0.06);
	float traces = max(max(h_line, v_line), junction);
	traces = max(traces, max(h_glow, v_glow));
	return traces * synth_region_mask(uv);
}

// Strict core of the road (for packets / pulse).
float synth_trace_core(vec2 uv) {
	vec2 grid_uv = uv * vec2(10.0, 14.0);
	vec2 cell = floor(grid_uv);
	vec2 f = fract(grid_uv);

	float h_gate = step(0.42, synth_hash(cell + vec2(0.0, 0.0)));
	float v_gate = step(0.45, synth_hash(cell + vec2(19.0, 7.0)));

	float road_w = 0.022;
	float h_line = h_gate * synth_line_mask(abs(f.y - 0.5), road_w);
	float v_line = v_gate * synth_line_mask(abs(f.x - 0.5), road_w);
	return max(h_line, v_line) * synth_region_mask(uv);
}

// 1D path coordinate along the dominant road axis (for racing lights).
float synth_path_coord(vec2 uv) {
	vec2 grid_uv = uv * vec2(10.0, 14.0);
	vec2 cell = floor(grid_uv);
	vec2 f = fract(grid_uv);
	float h_gate = step(0.42, synth_hash(cell));
	float v_gate = step(0.45, synth_hash(cell + vec2(19.0, 7.0)));
	if (h_gate >= v_gate) {
		return f.x + cell.x * 0.07 + cell.y * 0.11;
	}
	return f.y + cell.y * 0.09 + cell.x * 0.13;
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
