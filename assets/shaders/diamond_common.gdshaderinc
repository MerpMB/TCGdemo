// Diamond V1 — 7th Edition confetti / starfoil crystal laminate.
// Dense irregular flakes; boundaries from color+value shifts only (no outlines).
// One continuous film over artwork; iridescence matches MTG foil text-box.

float diamond_hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float diamond_hash2(vec2 p) {
	return fract(sin(dot(p, vec2(269.5, 183.3))) * 43758.5453);
}

vec2 diamond_hash22(vec2 p) {
	return vec2(diamond_hash(p), diamond_hash2(p));
}

// Confetti density — small packed irregular polygons (text-box scale).
vec2 diamond_scale(vec2 uv) {
	vec2 p = uv * vec2(16.0, 22.5);
	p = vec2(p.x + p.y * 0.28, p.y - p.x * 0.12);
	return p;
}

vec2 diamond_cell_normal(vec2 cell) {
	float id = diamond_hash(cell);
	float ang = id * 6.2831853;
	float tilt = 0.55 + diamond_hash2(cell) * 0.75;
	return normalize(vec2(cos(ang), sin(ang)) * tilt);
}

// Hard Voronoi flake (confetti). Color is discontinuous; film is continuous.
void diamond_sample(
	vec2 uv,
	out float crease,
	out float cell_id,
	out vec2 normal_xy,
	out vec2 cell
) {
	vec2 p = diamond_scale(uv);
	vec2 n = floor(p);
	vec2 f = fract(p);

	float md = 8.0;
	float md2 = 8.0;
	vec2 best_cell = n;
	vec2 best_r = vec2(0.0);

	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 g = vec2(float(i), float(j));
			vec2 o = diamond_hash22(n + g);
			o = 0.5 + 0.49 * sin(o * 6.2831853 + o.yx * 3.7);
			vec2 r = g + o - f;
			float d = dot(r, r);
			if (d < md) {
				md2 = md;
				md = d;
				best_r = r;
				best_cell = n + g;
			} else if (d < md2) {
				md2 = d;
			}
		}
	}

	float d1 = sqrt(md);
	float d2 = sqrt(md2);
	float gap = max(d2 - d1, 1e-4);
	// Crease only for micro specular — never drawn as a line.
	crease = pow(1.0 - smoothstep(0.0, 0.06, gap), 2.2);

	cell = best_cell;
	cell_id = diamond_hash(best_cell);
	normal_xy = normalize(diamond_cell_normal(best_cell) + best_r * 0.15);
}

vec2 diamond_light_dir(vec2 base, float t) {
	float a = t * 0.045;
	float c = cos(a);
	float s = sin(a);
	return vec2(base.x * c - base.y * s, base.x * s + base.y * c);
}

float diamond_flake_response(float cell_id, vec2 normal_xy, vec2 light_dir) {
	float z = 0.48 + fract(cell_id * 2.71) * 0.38;
	vec3 N = normalize(vec3(normal_xy, z));
	vec3 L = normalize(vec3(light_dir, 0.48));
	float ndotl = max(dot(N, L), 0.0);
	float gloss = 12.0 + fract(cell_id * 5.33) * 44.0;
	float body = smoothstep(0.0, 0.7, ndotl) * 0.35;
	float spec = pow(ndotl, gloss);
	return body + spec * 0.85;
}

float diamond_specular_peak(float cell_id, vec2 normal_xy, vec2 light_dir) {
	float z = 0.48 + fract(cell_id * 2.71) * 0.38;
	vec3 N = normalize(vec3(normal_xy, z));
	vec3 L = normalize(vec3(light_dir, 0.48));
	float gloss = 26.0 + fract(cell_id * 5.33) * 55.0;
	return pow(max(dot(N, L), 0.0), gloss);
}

float diamond_fresnel_rim(vec2 uv) {
	float border = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
	return pow(1.0 - smoothstep(0.0, 0.22, border), 2.4);
}

// 7th Edition foil spectrum — cyan → magenta → gold → lime → blue.
vec3 diamond_holofoil(float t) {
	float x = fract(t);
	vec3 c0 = vec3(0.15, 0.92, 1.00); // cyan / silver-blue
	vec3 c1 = vec3(0.55, 0.55, 1.00); // lavender
	vec3 c2 = vec3(1.00, 0.28, 0.82); // magenta / pink
	vec3 c3 = vec3(1.00, 0.72, 0.28); // gold / peach
	vec3 c4 = vec3(0.45, 1.00, 0.35); // lime
	float s = x * 4.0;
	if (s < 1.0) {
		return mix(c0, c1, s);
	}
	if (s < 2.0) {
		return mix(c1, c2, s - 1.0);
	}
	if (s < 3.0) {
		return mix(c2, c3, s - 2.0);
	}
	return mix(c3, c4, s - 3.0);
}

// Per-flake confetti color: spatial foil wash + cell identity + light value.
vec3 diamond_confetti_shade(vec2 uv, float cell_id, vec2 normal_xy, vec2 light_dir, float response) {
	// Broad left→right wash like the MTG text box (cool → warm).
	float wash = uv.x * 0.72 + uv.y * 0.12;
	float phase = wash + cell_id * 1.85 + dot(normalize(normal_xy), normalize(light_dir)) * 0.25;
	vec3 flake = diamond_holofoil(phase);
	flake = mix(flake, diamond_holofoil(phase * 1.2 + 0.15), 0.2);

	// Neighbors differ in value — lit flakes lift toward white/silver.
	float lit = smoothstep(0.15, 0.85, response);
	vec3 dim = flake * 0.55;
	vec3 mid = flake;
	vec3 hot = mix(flake, vec3(0.95, 0.97, 1.0), 0.55);
	return mix(mix(dim, mid, lit), hot, lit * lit);
}

vec3 diamond_ice_white(float t) {
	return mix(vec3(0.85, 0.92, 1.0), vec3(1.0), clamp(t, 0.0, 1.0));
}

vec3 diamond_prism(float t) {
	return diamond_holofoil(t);
}
