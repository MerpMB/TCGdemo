shader_type canvas_item;
render_mode blend_add, unshaded;

// Simple polished gold sheet — warm metal body, no emboss / bump / etch patterns.

uniform float metal_strength : hint_range(0.0, 1.0) = 0.38;
uniform float edge_fresnel : hint_range(0.0, 1.0) = 0.20;
uniform float brush_strength : hint_range(0.0, 1.0) = 0.25;
uniform float time_scale : hint_range(0.0, 0.1) = 0.01;
uniform vec2 brush_direction = vec2(1.0, 0.1);

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
	float t = TIME * time_scale;

	vec2 brush = normalize(brush_direction);
	float along = dot(uv, brush);
	float across = dot(uv, vec2(-brush.y, brush.x));

	// Soft brushed metal only — no rings or sunburst etch.
	float brush_line = sin(across * 90.0 + soft_noise(uv * 14.0) * 1.2) * 0.5 + 0.5;
	brush_line = smoothstep(0.35, 0.65, brush_line);
	float grit = soft_noise(uv * 36.0 + along);
	float metal_body = mix(0.7, 1.0, brush_line * brush_strength + grit * 0.12);

	// Soft center lift — like a gold bar catching light.
	vec2 center = uv - vec2(0.5, 0.48);
	float rad = length(center * vec2(1.0, 1.15));
	float bar_glow = 1.0 - smoothstep(0.05, 0.85, rad);
	bar_glow = pow(bar_glow, 1.4);

	vec3 highlight = vec3(1.0, 0.96, 0.78);
	vec3 champagne = vec3(1.0, 0.88, 0.48);
	vec3 amber = vec3(0.96, 0.68, 0.22);
	vec3 bronze = vec3(0.55, 0.34, 0.12);

	float warmth = smoothstep(0.15, 0.88, along + sin(t + uv.y * 1.2) * 0.03);
	vec3 warm = mix(bronze, mix(amber, champagne, warmth), 0.58 + metal_body * 0.28);
	warm = mix(warm, highlight, bar_glow * 0.35);

	float edge = max(max(1.0 - uv.x, uv.x), max(1.0 - uv.y, uv.y));
	edge = smoothstep(0.6, 1.0, edge);
	float fresnel = edge * edge_fresnel;

	float alpha = clamp(metal_strength * metal_body * (0.75 + bar_glow * 0.45) + fresnel * 0.55, 0.0, 0.48);
	COLOR = vec4(warm * alpha * 1.25, alpha);
}
