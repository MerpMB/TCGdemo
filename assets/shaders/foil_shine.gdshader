shader_type canvas_item;
render_mode blend_add;

uniform float time_scale : hint_range(0.05, 1.0) = 0.18;
uniform float phase : hint_range(0.0, 1.0) = 0.0;
uniform float intensity : hint_range(0.0, 1.0) = 0.22;

void fragment() {
	vec2 uv = UV;
	float diag = uv.x * 0.7 + uv.y * 0.92;
	float sweep = fract(TIME * time_scale + phase) * 1.55 - 0.28;
	float band = smoothstep(sweep - 0.06, sweep - 0.01, diag);
	band *= 1.0 - smoothstep(sweep + 0.04, sweep + 0.11, diag);
	vec3 cool_a = vec3(0.72, 0.84, 1.0);
	vec3 cool_b = vec3(0.86, 0.92, 1.0);
	vec3 shine = mix(cool_a, cool_b, sin(diag * 10.0 + sweep * 4.0) * 0.5 + 0.5);
	float brighten = 1.0 + band * 0.12;
	float alpha = band * intensity;
	COLOR = vec4(shine * brighten * alpha, alpha * 0.48);
}
