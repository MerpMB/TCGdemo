shader_type canvas_item;
render_mode blend_mix, unshaded;

#include "diamond_common.gdshaderinc"

// DEPRECATED for Diamond look — glass is an overlay, not an art warp.
// Kept only so create_diamond_refraction_material still loads if called.
// Prefer leaving ArtTexture material-free (Synth-style).

uniform float warp_strength : hint_range(0.0, 0.05) = 0.0;
uniform float clarity : hint_range(0.9, 1.15) = 1.0;
uniform float cool_lift : hint_range(0.0, 0.2) = 0.0;
uniform float edge_sharpen : hint_range(0.0, 0.35) = 0.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	COLOR = vec4(tex.rgb * clarity, tex.a);
}
