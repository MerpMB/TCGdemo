shader_type canvas_item;
render_mode blend_mix, unshaded;

// Remap artwork to monochrome engraved gold — dark recesses vs polished highlights.
// Matches gold secret-rare cards (Gardevoir / Lucario style) via luminance contrast.

uniform float contrast : hint_range(0.5, 3.0) = 1.85;
uniform float black_point : hint_range(0.0, 0.4) = 0.08;
uniform float white_point : hint_range(0.6, 1.0) = 0.92;
uniform float edge_darken : hint_range(0.0, 1.0) = 0.45;
uniform float polish : hint_range(0.0, 1.0) = 0.35;

float luma(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float lum = luma(tex.rgb);

	// Soft edge cue — darken high-contrast neighbors so linework reads engraved.
	vec2 px = 1.0 / vec2(textureSize(TEXTURE, 0));
	float l1 = luma(texture(TEXTURE, UV + vec2(px.x, 0.0)).rgb);
	float l2 = luma(texture(TEXTURE, UV - vec2(px.x, 0.0)).rgb);
	float l3 = luma(texture(TEXTURE, UV + vec2(0.0, px.y)).rgb);
	float l4 = luma(texture(TEXTURE, UV - vec2(0.0, px.y)).rgb);
	float edge = abs(l1 - l2) + abs(l3 - l4);
	edge = smoothstep(0.05, 0.35, edge);
	lum = mix(lum, lum * (1.0 - edge * 0.55), edge_darken);

	// Levels + contrast — crush mids so etched lines pop.
	lum = (lum - black_point) / max(white_point - black_point, 0.001);
	lum = clamp(lum, 0.0, 1.0);
	lum = clamp((lum - 0.5) * contrast + 0.5, 0.0, 1.0);
	// Slight S-curve for metal engraving punch.
	lum = smoothstep(0.0, 1.0, lum);
	lum = mix(lum, lum * lum * (3.0 - 2.0 * lum), 0.35);

	// Engraved gold palette: deep umber → amber → pale white-gold.
	vec3 recess = vec3(0.14, 0.08, 0.03);
	vec3 bronze = vec3(0.42, 0.26, 0.08);
	vec3 gold = vec3(0.92, 0.72, 0.28);
	vec3 polish_c = vec3(1.0, 0.95, 0.78);

	vec3 engraved = mix(recess, bronze, smoothstep(0.0, 0.28, lum));
	engraved = mix(engraved, gold, smoothstep(0.28, 0.62, lum));
	engraved = mix(engraved, polish_c, smoothstep(0.62, 1.0, lum) * (0.55 + polish * 0.45));

	// Keep a hint of original hue in midtones so busy art doesn't flatten completely.
	vec3 tinted = mix(engraved, engraved * normalize(tex.rgb + 0.001) * 1.35, 0.08 * (1.0 - edge));

	COLOR = vec4(tinted, tex.a);
}
