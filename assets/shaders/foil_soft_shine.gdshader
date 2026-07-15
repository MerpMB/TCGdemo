shader_type canvas_item;
render_mode blend_add, unshaded;

// Soft prismatic sweep along the same ~40° diagonal as the foil beams.

uniform float shine_opacity : hint_range(0.0, 1.0) = 0.34;
uniform float time_scale : hint_range(0.0, 0.3) = 0.02;
uniform float band_width : hint_range(0.05, 0.5) = 0.24;
uniform float softness : hint_range(0.02, 0.3) = 0.14;
uniform vec2 angle_weights = vec2(0.78, -0.62);
uniform float etch_density : hint_range(20.0, 220.0) = 36.0;
uniform float prism_strength : hint_range(0.0, 1.0) = 0.95;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float soft_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float film_grain(vec2 uv) {
	float g = soft_noise(uv * 32.0);
	g += soft_noise(uv * 64.0) * 0.45;
	return g / 1.45;
}

vec3 prism_tint(float t) {
	float x = fract(t);
	vec3 c0 = vec3(0.15, 0.95, 1.00);
	vec3 c1 = vec3(1.00, 0.15, 0.92);
	vec3 c2 = vec3(0.40, 1.00, 0.18);
	vec3 c3 = vec3(1.00, 0.72, 0.12);
	float s = x * 3.0;
	if (s < 1.0) return mix(c0, c1, s);
	if (s < 2.0) return mix(c1, c2, s - 1.0);
	return mix(c2, c3, s - 2.0);
}

void fragment() {
	vec2 uv = UV;
	vec2 ang = normalize(angle_weights);
	float diag = dot(uv, ang);
	float along = dot(uv, vec2(-ang.y, ang.x));
	float wave = sin(along * 5.5) * 0.02;
	float sweep = fract(TIME * time_scale) * 1.2 - 0.1;

	float half_w = band_width * 0.5;
	float d = abs(diag + wave - sweep);

	float core = 1.0 - smoothstep(half_w * 0.32, half_w * 0.32 + softness * 0.55, d);
	float band = 1.0 - smoothstep(half_w, half_w + softness, d);
	float halo = 1.0 - smoothstep(half_w * 1.55, half_w * 1.55 + softness * 2.0, d);
	float shine = max(core * 1.2, max(band * 0.78, halo * 0.28));

	float grain = film_grain(uv + sweep);
	shine *= mix(0.9, 1.14, grain);

	float fringe = (diag - sweep) / max(half_w + softness, 0.001);
	vec3 tint = mix(vec3(0.94, 0.96, 1.0), prism_tint(sweep * 1.2 + fringe * 0.45 + uv.x * 0.4), prism_strength);
	tint = mix(tint, vec3(1.0, 0.99, 0.96), core * 0.55);

	float alpha = clamp(shine * shine_opacity, 0.0, 0.58);
	COLOR = vec4(tint * alpha * 1.35, alpha * 0.65);
}
