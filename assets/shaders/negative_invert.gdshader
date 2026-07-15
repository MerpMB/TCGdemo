shader_type canvas_item;

uniform float pulse : hint_range(0.0, 1.0) = 0.0;
uniform float brightness : hint_range(0.9, 1.2) = 1.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec3 inv = vec3(1.0) - tex.rgb;
	float lift = brightness + pulse * 0.03;
	COLOR = vec4(inv * lift, tex.a);
}
