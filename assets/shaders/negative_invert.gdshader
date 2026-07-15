shader_type canvas_item;

uniform float time_scale : hint_range(0.05, 1.0) = 0.28;
uniform float brightness : hint_range(0.9, 1.2) = 1.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec3 inv = vec3(1.0) - tex.rgb;
	float pulse = sin(TIME * time_scale) * 0.5 + 0.5;
	float lift = brightness + pulse * 0.025;
	vec2 uv = UV;
	float dist = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
	float vignette = smoothstep(0.0, 0.35, dist);
	inv *= mix(0.88, 1.0, vignette);
	COLOR = vec4(inv * lift, tex.a);
}
