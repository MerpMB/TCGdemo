shader_type canvas_item;
render_mode blend_add, unshaded;

// Clean gold-bar specular sweep — polished metal only, no bump / etch.

uniform float shine_opacity : hint_range(0.0, 1.0) = 0.62;
uniform float time_scale : hint_range(0.0, 0.15) = 0.008;
uniform float band_width : hint_range(0.1, 0.7) = 0.42;
uniform float softness : hint_range(0.05, 0.4) = 0.22;
uniform vec2 angle_weights = vec2(0.5, 0.86);

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

void fragment() {
	vec2 uv = UV;
	vec2 ang = normalize(angle_weights);
	float diag = dot(uv, ang);
	float sweep = fract(TIME * time_scale) * 1.15 - 0.08;

	float half_w = band_width * 0.5;
	float d = abs(diag - sweep);

	float core = 1.0 - smoothstep(half_w * 0.22, half_w * 0.22 + softness * 0.35, d);
	float band = 1.0 - smoothstep(half_w, half_w + softness, d);
	float halo = 1.0 - smoothstep(half_w * 1.5, half_w * 1.5 + softness * 2.0, d);
	float shine = max(core * 1.3, max(band * 0.82, halo * 0.3));

	float grit = soft_noise(uv * 22.0 + sweep);
	shine *= 0.94 + grit * 0.12;

	// Extra hot flecks inside the specular band.
	float spark = soft_noise(uv * 90.0 + sweep * 4.0);
	spark = pow(smoothstep(0.72, 0.98, spark), 2.4) * core;
	shine += spark * 0.55;

	vec3 highlight = vec3(1.0, 0.99, 0.92);
	vec3 champagne = vec3(1.0, 0.93, 0.68);
	vec3 amber = vec3(1.0, 0.82, 0.38);
	vec3 tint = mix(amber, champagne, band);
	tint = mix(tint, highlight, core * 0.8 + spark * 0.5);

	float alpha = clamp(shine * shine_opacity, 0.0, 0.72);
	COLOR = vec4(tint * alpha * 1.35, alpha * 0.7);
}
