shader_type canvas_item;
render_mode blend_add;

uniform float time_scale : hint_range(0.1, 3.0) = 1.1;
uniform float intensity : hint_range(0.0, 1.0) = 0.18;

void fragment() {
	vec2 uv = UV;
	float t = TIME * time_scale;
	float facet_x = abs(sin((uv.x * 18.0 + uv.y * 6.0) + t * 0.55));
	float facet_y = abs(cos((uv.y * 16.0 - uv.x * 5.0) - t * 0.42));
	float crystal = pow(facet_x * facet_y, 2.2);
	vec3 ice = vec3(0.78, 0.9, 1.0);
	vec3 white = vec3(0.95, 0.98, 1.0);
	vec3 col = mix(ice, white, crystal) * crystal * intensity;
	COLOR = vec4(col, crystal * intensity * 0.5);
}
