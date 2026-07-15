shader_type canvas_item;
render_mode blend_add;

uniform float sweep : hint_range(-0.5, 1.5) = 0.0;
uniform float intensity : hint_range(0.0, 1.0) = 0.28;

void fragment() {
	vec2 uv = UV;
	float diag = uv.x * 0.72 + uv.y * 0.88;
	float band = smoothstep(sweep - 0.07, sweep - 0.01, diag);
	band *= 1.0 - smoothstep(sweep + 0.05, sweep + 0.14, diag);
	vec3 cool = vec3(0.78, 0.86, 1.0);
	vec3 warm = vec3(1.0, 0.92, 0.72);
	vec3 shine = mix(cool, warm, sin(diag * 8.0 + sweep * 3.0) * 0.5 + 0.5);
	float alpha = band * intensity;
	COLOR = vec4(shine * alpha, alpha * 0.55);
}
