// DEPRECATED — Synth V1 GPU topology. Synth V2 bakes architecture in SynthTopology.gd.
// Shared Synth topology — intentional PCB architecture (not probabilistic grid).
// Geometry is designed modules: buses, L/T junctions, loops, branching corridors.
// Packets travel through this architecture; they do not invent the layout.

float synth_hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float synth_line_mask(float dist, float half_width) {
	return 1.0 - smoothstep(0.0, half_width, dist);
}

// Distance from point to segment AB, plus arc-length parameter along AB.
float synth_seg_dist(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / max(dot(ba, ba), 1e-6), 0.0, 1.0);
	return length(pa - ba * h);
}

float synth_seg_param(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	return clamp(dot(pa, ba) / max(dot(ba, ba), 1e-6), 0.0, 1.0);
}

// ---- Designed PCB modules (UV space, card is taller than wide) ----
// Sparse edge composition with a large empty center — reference style.

const float SYNTH_ROUTE_COUNT = 5.0;

// Accumulate closest segment on a route: updates best_d / best_t / best_road.
void synth_accum_seg(
	vec2 uv,
	vec2 a,
	vec2 b,
	float road,
	float arc_base,
	float route_len,
	inout float best_d,
	inout float best_t,
	inout float best_road
) {
	float d = synth_seg_dist(uv, a, b);
	if (d < best_d) {
		best_d = d;
		float local = synth_seg_param(uv, a, b);
		float seg_len = length(b - a);
		best_t = (arc_base + local * seg_len) / max(route_len, 1e-4);
		best_road = road;
	}
}

void synth_accum_node(vec2 uv, vec2 n, inout float best_j) {
	best_j = min(best_j, length(uv - n));
}

// Sample designed topology: distance field, normalized travel [0,1], route id, junction dist.
void synth_sample_topo(vec2 uv, out float dist, out float travel, out float road, out float junc) {
	float best_d = 1e3;
	float best_t = 0.0;
	float best_road = 0.0;
	float best_j = 1e3;

	// ============================================================
	// Route 0 — bottom-left L into long bottom bus (continuous journey)
	// ============================================================
	{
		float road_id = 0.0;
		vec2 p0 = vec2(0.08, 0.22);
		vec2 p1 = vec2(0.08, 0.09);
		vec2 p2 = vec2(0.48, 0.09);
		vec2 p3 = vec2(0.48, 0.16);
		vec2 p4 = vec2(0.62, 0.16);
		float L = length(p1 - p0) + length(p2 - p1) + length(p3 - p2) + length(p4 - p3);
		float a0 = 0.0;
		float a1 = length(p1 - p0);
		float a2 = a1 + length(p2 - p1);
		float a3 = a2 + length(p3 - p2);
		synth_accum_seg(uv, p0, p1, road_id, a0, L, best_d, best_t, best_road);
		synth_accum_seg(uv, p1, p2, road_id, a1, L, best_d, best_t, best_road);
		synth_accum_seg(uv, p2, p3, road_id, a2, L, best_d, best_t, best_road);
		synth_accum_seg(uv, p3, p4, road_id, a3, L, best_d, best_t, best_road);
		synth_accum_node(uv, p1, best_j); // L corner
		synth_accum_node(uv, p2, best_j); // step
		synth_accum_node(uv, p3, best_j); // T-ish bend
	}

	// ============================================================
	// Route 1 — left mid T-junction (stem + arms)
	// ============================================================
	{
		float road_id = 1.0;
		vec2 c = vec2(0.12, 0.48);
		vec2 left = vec2(0.05, 0.48);
		vec2 right = vec2(0.26, 0.48);
		vec2 down = vec2(0.12, 0.36);
		float L = length(c - left) + length(right - c) + length(c - down);
		synth_accum_seg(uv, left, c, road_id, 0.0, L, best_d, best_t, best_road);
		synth_accum_seg(uv, c, right, road_id, length(c - left), L, best_d, best_t, best_road);
		synth_accum_seg(uv, c, down, road_id, length(c - left) + length(right - c), L, best_d, best_t, best_road);
		synth_accum_node(uv, c, best_j);
	}

	// ============================================================
	// Route 2 — right vertical bus with two branch T stubs (long corridor)
	// ============================================================
	{
		float road_id = 2.0;
		vec2 top = vec2(0.90, 0.74);
		vec2 mid = vec2(0.90, 0.48);
		vec2 bot = vec2(0.90, 0.22);
		vec2 stub_a = vec2(0.76, 0.58);
		vec2 stub_b = vec2(0.78, 0.34);
		vec2 j_a = vec2(0.90, 0.58);
		vec2 j_b = vec2(0.90, 0.34);
		float L = length(mid - top) + length(bot - mid) + length(j_a - stub_a) + length(j_b - stub_b);
		float a0 = 0.0;
		float a1 = length(mid - top);
		float a2 = a1 + length(bot - mid);
		float a3 = a2 + length(j_a - stub_a);
		synth_accum_seg(uv, top, mid, road_id, a0, L, best_d, best_t, best_road);
		synth_accum_seg(uv, mid, bot, road_id, a1, L, best_d, best_t, best_road);
		synth_accum_seg(uv, stub_a, j_a, road_id, a2, L, best_d, best_t, best_road);
		synth_accum_seg(uv, stub_b, j_b, road_id, a3, L, best_d, best_t, best_road);
		synth_accum_node(uv, j_a, best_j);
		synth_accum_node(uv, j_b, best_j);
		synth_accum_node(uv, mid, best_j);
	}

	// ============================================================
	// Route 3 — top-right T + stair / zig module
	// ============================================================
	{
		float road_id = 3.0;
		vec2 t0 = vec2(0.68, 0.90);
		vec2 t1 = vec2(0.94, 0.90);
		vec2 stem = vec2(0.84, 0.82);
		vec2 j = vec2(0.84, 0.90);
		vec2 z0 = vec2(0.76, 0.76);
		vec2 z1 = vec2(0.92, 0.76);
		vec2 z2 = vec2(0.92, 0.68);
		vec2 z3 = vec2(0.80, 0.68);
		float L = length(t1 - t0) + length(j - stem)
			+ length(z1 - z0) + length(z2 - z1) + length(z3 - z2);
		float a0 = 0.0;
		float a1 = length(t1 - t0);
		float a2 = a1 + length(j - stem);
		float a3 = a2 + length(z1 - z0);
		float a4 = a3 + length(z2 - z1);
		synth_accum_seg(uv, t0, t1, road_id, a0, L, best_d, best_t, best_road);
		synth_accum_seg(uv, j, stem, road_id, a1, L, best_d, best_t, best_road);
		synth_accum_seg(uv, z0, z1, road_id, a2, L, best_d, best_t, best_road);
		synth_accum_seg(uv, z1, z2, road_id, a3, L, best_d, best_t, best_road);
		synth_accum_seg(uv, z2, z3, road_id, a4, L, best_d, best_t, best_road);
		synth_accum_node(uv, j, best_j);
		synth_accum_node(uv, z1, best_j);
		synth_accum_node(uv, z2, best_j);
	}

	// ============================================================
	// Route 4 — bottom-right L / stub cluster
	// ============================================================
	{
		float road_id = 4.0;
		vec2 a = vec2(0.70, 0.11);
		vec2 b = vec2(0.92, 0.11);
		vec2 c = vec2(0.92, 0.30);
		vec2 stub = vec2(0.80, 0.20);
		vec2 j = vec2(0.92, 0.20);
		float L = length(b - a) + length(c - b) + length(j - stub);
		float a0 = 0.0;
		float a1 = length(b - a);
		synth_accum_seg(uv, a, b, road_id, a0, L, best_d, best_t, best_road);
		synth_accum_seg(uv, b, c, road_id, a1, L, best_d, best_t, best_road);
		synth_accum_seg(uv, stub, j, road_id, a1 + length(c - b), L, best_d, best_t, best_road);
		synth_accum_node(uv, b, best_j);
		synth_accum_node(uv, j, best_j);
	}

	dist = best_d;
	travel = best_t;
	road = best_road;
	junc = best_j;
}

// ---- Public field API (used by idle + packet shaders) ----

float synth_region_mask(vec2 uv) {
	// Negative space is authored by module placement, not a noise mask.
	float d;
	float t;
	float r;
	float j;
	synth_sample_topo(uv, d, t, r, j);
	return 1.0 - smoothstep(0.045, 0.12, d);
}

float synth_trace_field(vec2 uv) {
	float d;
	float t;
	float r;
	float j;
	synth_sample_topo(uv, d, t, r, j);
	float core = synth_line_mask(d, 0.0045);
	float glow = synth_line_mask(d, 0.010) * 0.22;
	float node = synth_line_mask(j, 0.008) * 0.55;
	return max(max(core, glow), node);
}

float synth_trace_core(vec2 uv) {
	float d;
	float t;
	float r;
	float j;
	synth_sample_topo(uv, d, t, r, j);
	return synth_line_mask(d, 0.0055);
}

float synth_junction_mask(vec2 uv) {
	float d;
	float t;
	float r;
	float j;
	synth_sample_topo(uv, d, t, r, j);
	// Meaningful routing nodes only — designed junctions, not accidental crossings.
	return synth_line_mask(j, 0.011) * synth_line_mask(d, 0.014);
}

float synth_trace_soft(vec2 uv) {
	float d;
	float t;
	float r;
	float j;
	synth_sample_topo(uv, d, t, r, j);
	return max(synth_line_mask(d, 0.014), synth_line_mask(j, 0.018));
}

float synth_trace_bloom(vec2 uv) {
	float d;
	float t;
	float r;
	float j;
	synth_sample_topo(uv, d, t, r, j);
	float bloom = max(synth_line_mask(d, 0.028), synth_line_mask(j, 0.032));
	return pow(bloom, 1.25);
}

// Normalized arc-length along the closest designed route [0,1].
float synth_travel_coord(vec2 uv) {
	float d;
	float t;
	float r;
	float j;
	synth_sample_topo(uv, d, t, r, j);
	return t;
}

// Secondary axis hint near junctions (for branch glow).
float synth_cross_travel_coord(vec2 uv) {
	float d;
	float t;
	float r;
	float j;
	synth_sample_topo(uv, d, t, r, j);
	return fract(t * 2.7 + r * 0.37);
}

float synth_road_id(vec2 uv) {
	float d;
	float t;
	float r;
	float j;
	synth_sample_topo(uv, d, t, r, j);
	return r;
}

// Legacy name kept for packet shaders that still sample cell space.
vec2 synth_grid_uv(vec2 uv) {
	return uv * vec2(8.0, 11.0);
}

// Signal silhouette: continuous flowing wave.
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

float synth_corner_bridge(vec2 uv, float behind, float span) {
	float junction = synth_junction_mask(uv);
	float near = 1.0 - smoothstep(0.0, max(span, 0.001), behind);
	return junction * near * near;
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
