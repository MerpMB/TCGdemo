class_name DiamondMaterials
extends RefCounted
## Diamond baseline: one Photoshop-authored overlay texture.


static func get_blueprints() -> Array:
	return [
		{
			"id": "diamond_overlay",
			"type": "texture",
			"slot": "overlay",
			"animation": "static",
			"blend_mode": "add",
			"z_order": 40,
			"depth": 0.0,
			"material_response": 0.0,
			"opacity": 0.42,
		},
	]
