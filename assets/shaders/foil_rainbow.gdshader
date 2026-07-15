shader_type canvas_item;
render_mode blend_add, unshaded;

// Holofoil laminate — sparse diagonal beams (~40° BL→TR) + film-grain texture.

uniform float rainbow_strength : hint_range(0.0, 1.0) = 0.50;
uniform float foil_strength : hint_range(0.0, 1.0) = 0.48;
uniform float edge_fresnel : hint_range(0.0, 1.0) = 0.13;
uniform float time_scale : hint_range(0.0, 0.5) = 0.04;
uniform float noise_scale : hint_range(1.0, 80.0) = 28.0;
uniform float beam_count : hint_range(2.0, 28.0) = 3.2;
uniform float etch_density : hint_range(20.0, 220.0) = 48.0;
uniform float radial_strength : hint_range(0.0, 1.0) = 0.18;
uniform vec2 beam_angle = vec2(0.78, -0.62);

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

float film_grain(vec2 uv, float t) {
	float g = soft_noise(uv * noise_scale + t * 0.15);
	g += soft_noise(uv * noise_scale * 2.3 - t * 0.08) * 0.5;
	g += soft_noise(uv * noise_scale * 4.7 + t * 0.05) * 0.25;
	return g / 1.75;
}

vec3 holofoil_spectrum(float t) {
	float x = fract(t);
	vec3 c0 = vec3(0.05, 0.92, 1.00);
	vec3 c1 = vec3(1.00, 0.08, 0.88);
	vec3 c2 = vec3(0.28, 1.00, 0.08);
	vec3 c3 = vec3(1.00, 0.62, 0.05);
	vec3 c4 = vec3(0.18, 0.32, 1.00);
	float s = x * 4.0;
	if (s < 1.0) return mix(c0, c1, s);
	if (s < 2.0) return mix(c1, c2, s - 1.0);
	if (s < 3.0) return mix(c2, c3, s - 2.0);
	return mix(c3, c4, s - 3.0);
}

void fragment() {
	vec2 uv = UV;
	float t = TIME * time_scale;

	vec2 ang = normalize(beam_angle);
	vec2 along_dir = vec2(-ang.y, ang.x);
	float across = dot(uv, ang);
	float along = dot(uv, along_dir);

	float wave = sin(along * 5.5 + t * 0.6) * 0.035;
	wave += pow(abs(sin(along * 2.8 + t * 0.3)), 1.6) * 0.028;

	float grain = film_grain(uv, t);
	float jitter = (grain - 0.5) * 0.03;

	float phase = across * 0.7 + along * 0.15 + t * 0.85 + jitter;
	float beams = sin((across + wave + t * 0.4 + jitter) * beam_count * 3.14159);
	beams = pow(abs(beams), 2.5);
	float beam_mask = mix(0.12, 1.0, beams);

	vec2 center = uv - vec2(0.48, 0.42);
	float rad = length(center);
	float radial = mix(1.0, 0.9 + (1.0 - smoothstep(0.0, 0.75, rad)) * 0.18, radial_strength);

	float grain_mod = mix(0.88, 1.12, grain);

	vec3 rainbow = holofoil_spectrum(phase);
	rainbow = mix(rainbow, holofoil_spectrum(phase * 1.2 + 0.18), 0.16 * beams);

	float edge = max(max(1.0 - uv.x, uv.x), max(1.0 - uv.y, uv.y));
	edge = smoothstep(0.68, 1.0, edge);
	float edge_lift = edge * edge_fresnel;

	float intensity = foil_strength * mix(0.55, 1.0, rainbow_strength);
	float body = intensity * beam_mask * radial * grain_mod;
	float alpha = clamp(body + edge_lift * 0.55, 0.0, 0.58);

	vec3 color = rainbow * (1.05 + beams * 0.45);
	float hot = pow(beams, 2.4) * (0.28 + grain * 0.12);
	color += vec3(1.0, 0.97, 0.92) * hot;
	color += rainbow * pow(beams * radial, 1.8) * 0.22;

	COLOR = vec4(color * alpha * 1.15, alpha);
}
