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
	return smoothstep(0.67, 0.86, region);
}

float synth_line_mask(float dist, float half_width) {
	return 1.0 - smoothstep(0.0, half_width, dist);
}

vec2 synth_grid_uv(vec2 uv) {
	return uv * vec2(8.0, 11.0);
}

float synth_h_gate(vec2 cell) {
	return step(0.54, synth_hash(cell));
}

float synth_v_gate(vec2 cell) {
	return step(0.57, synth_hash(cell + vec2(19.0, 7.0)));
}

float synth_trace_field(vec2 uv) {
	vec2 grid_uv = synth_grid_uv(uv);
	vec2 cell = floor(grid_uv);
	vec2 f = fract(grid_uv);

	float h_gate = synth_h_gate(cell);
	float v_gate = synth_v_gate(cell);

	float road_w = 0.026;
	float h_line = h_gate * synth_line_mask(abs(f.y - 0.5), road_w);
	float v_line = v_gate * synth_line_mask(abs(f.x - 0.5), road_w);

	float glow_w = 0.055;
	float h_glow = h_gate * synth_line_mask(abs(f.y - 0.5), glow_w) * 0.18;
	float v_glow = v_gate * synth_line_mask(abs(f.x - 0.5), glow_w) * 0.18;

	float junction = h_gate * v_gate * synth_line_mask(length(f - 0.5), 0.06);
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

	float road_w = 0.032;
	float h_line = h_gate * synth_line_mask(abs(f.y - 0.5), road_w);
	float v_line = v_gate * synth_line_mask(abs(f.x - 0.5), road_w);
	return max(h_line, v_line) * synth_region_mask(uv);
}

float synth_junction_mask(vec2 uv) {
	vec2 grid_uv = synth_grid_uv(uv);
	vec2 cell = floor(grid_uv);
	vec2 f = fract(grid_uv);
	float both = synth_h_gate(cell) * synth_v_gate(cell);
	return both * synth_line_mask(length(f - 0.5), 0.10) * synth_region_mask(uv);
}

// Continuous Manhattan travel with soft L-turn blending at junctions.
float synth_travel_coord(vec2 uv) {
	vec2 g = synth_grid_uv(uv);
	vec2 cell = floor(g);
	vec2 f = fract(g);
	float h = synth_h_gate(cell);
	float v = synth_v_gate(cell);

	float h_travel = g.x;
	float v_travel = g.y + (cell.x - cell.y);

	if (h > 0.5 && v > 0.5) {
		// Wide soft blend through the corner so the wave bridges the turn.
		float on_h = 1.0 - smoothstep(0.0, 0.28, abs(f.y - 0.5));
		float on_v = 1.0 - smoothstep(0.0, 0.28, abs(f.x - 0.5));
		float w = on_h + on_v;
		float blended = mix(v_travel, h_travel, on_h / max(w, 0.001));
		// Pull toward junction center path length for smoother corner occupancy.
		float corner = (h_travel + v_travel) * 0.5;
		float corner_w = 1.0 - smoothstep(0.0, 0.22, length(f - 0.5));
		return mix(blended, corner, corner_w * 0.45);
	}
	if (h >= v) {
		return h_travel;
	}
	return v_travel;
}

float synth_cross_travel_coord(vec2 uv) {
	vec2 g = synth_grid_uv(uv);
	vec2 cell = floor(g);
	float h = synth_h_gate(cell);
	float v = synth_v_gate(cell);
	if (h >= v) {
		return g.y + (cell.x - cell.y);
	}
	return g.x;
}

float synth_road_id(vec2 uv) {
	vec2 cell = floor(synth_grid_uv(uv));
	return synth_hash(cell + vec2(3.7, 11.3));
}

// Signal silhouette: one continuous flowing wave (no capsule tip).
// behind=0 at leading edge; smooth falloff into a long soft wake.
float synth_signal_profile(float behind, float head_w, float body_w, float trail_w) {
	float extent = body_w + trail_w * 2.6;
	if (behind > extent) {
		return 0.0;
	}

	// Soft leading edge (not a hard white bead).
	float lead = exp(-behind / max(head_w * 1.8, 0.001));
	// Long contiguous body that can cover multiple segments.
	float body = exp(-behind / max(body_w * 0.85, 0.001));
	// Extended wake — fades gradually into idle.
	float wake = exp(-behind / max(trail_w * 1.15, 0.001)) * 0.55;

	float wave = max(lead * 0.9, max(body, wake));
	// Gentle taper so the front still reads as the focus without a capsule.
	float focus = 1.0 - smoothstep(0.0, body_w * 1.4, behind) * 0.22;
	return wave * focus;
}

// Soft corner bridge — keeps glow continuous through 90° turns.
float synth_corner_bridge(vec2 uv, float behind, float span) {
	float junction = synth_junction_mask(uv);
	float near = 1.0 - smoothstep(0.0, max(span, 0.001), behind);
	return junction * near * near;
}

// Idle board: cool cyan/teal only (no rainbow).
vec3 synth_palette(float t) {
	vec3 teal = vec3(0.12, 0.72, 0.82);
	vec3 cyan = vec3(0.18, 0.88, 1.0);
	vec3 blue = vec3(0.14, 0.48, 0.95);
	vec3 c = mix(teal, cyan, smoothstep(0.0, 0.55, t));
	return mix(c, blue, smoothstep(0.55, 1.0, t) * 0.35);
}

// Packet-only iridescence: cyan → blue → violet → magenta → white.
vec3 synth_iridescent(float t) {
	float x = fract(t);
	vec3 c0 = vec3(0.25, 0.95, 1.00); // cyan
	vec3 c1 = vec3(0.28, 0.55, 1.00); // electric blue
	vec3 c2 = vec3(0.58, 0.32, 1.00); // violet
	vec3 c3 = vec3(0.95, 0.38, 0.88); // magenta
	vec3 c4 = vec3(0.96, 0.98, 1.00); // white highlight
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

// Thick soft path for readable packet body.
float synth_trace_soft(vec2 uv) {
	vec2 grid_uv = synth_grid_uv(uv);
	vec2 cell = floor(grid_uv);
	vec2 f = fract(grid_uv);
	float h_gate = synth_h_gate(cell);
	float v_gate = synth_v_gate(cell);
	float soft_w = 0.095;
	float h_line = h_gate * synth_line_mask(abs(f.y - 0.5), soft_w);
	float v_line = v_gate * synth_line_mask(abs(f.x - 0.5), soft_w);
	float junction = h_gate * v_gate * synth_line_mask(length(f - 0.5), 0.16);
	return max(max(h_line, v_line), junction) * synth_region_mask(uv);
}

// Wide bloom halo — emits light outside the trace line (packet only).
float synth_trace_bloom(vec2 uv) {
	vec2 grid_uv = synth_grid_uv(uv);
	vec2 cell = floor(grid_uv);
	vec2 f = fract(grid_uv);
	float h_gate = synth_h_gate(cell);
	float v_gate = synth_v_gate(cell);
	float bloom_w = 0.18;
	float h_line = h_gate * synth_line_mask(abs(f.y - 0.5), bloom_w);
	float v_line = v_gate * synth_line_mask(abs(f.x - 0.5), bloom_w);
	float junction = h_gate * v_gate * synth_line_mask(length(f - 0.5), 0.22);
	float bloom = max(max(h_line, v_line), junction);
	return pow(bloom, 1.35) * synth_region_mask(uv);
}
