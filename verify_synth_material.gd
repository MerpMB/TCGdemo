extends SceneTree
## Headless validation — Synth V2 material across artwork, modes, and scales.

const CARD_SCENE := preload("res://scenes/Card.tscn")
const _SynthTopology := preload("res://scripts/ui/synth_topology.gd")

const ARTWORK_FIXTURES := [
	{"id": "common_001", "label": "busy_art"},
	{"id": "legendary_001", "label": "bright_art"},
	{"id": "common_006", "label": "minimal_art"},
]

const MODES := [
	CardScene.DisplayMode.PACK,
	CardScene.DisplayMode.GALLERY,
	CardScene.DisplayMode.PREVIEW,
]

const SCALES := [0.55, 1.0]

const EXPECTED_DEPTHS := {
	"micro_circuit_texture": 0.02,
	"pcb_board": 0.06,
	"fiber_traffic": 0.12,
	"fiber_deep": 0.18,
	"junction_pads": 0.22,
}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not _validate_topology_bake():
		quit(1)
		return

	if not _validate_layer_blueprint():
		quit(1)
		return

	if not _validate_packet_materials():
		quit(1)
		return

	for fixture in ARTWORK_FIXTURES:
		for mode in MODES:
			for card_scale in SCALES:
				var ok := await _validate_spawn(fixture["id"], fixture["label"], mode, card_scale)
				if not ok:
					quit(1)
					return

	print(
		"verify_synth_material: OK — Synth V2, %d fixtures × %d modes × %d scales"
		% [ARTWORK_FIXTURES.size(), MODES.size(), SCALES.size()]
	)
	quit(0)


func _validate_topology_bake() -> bool:
	var board: Texture2D = _SynthTopology.get_board_texture()
	var flow: Texture2D = _SynthTopology.get_flow_texture()
	var pads: Texture2D = _SynthTopology.get_pad_texture()
	var journeys: int = _SynthTopology.get_journey_count()
	if board == null or flow == null or pads == null:
		push_error("SynthTopology bake failed (missing textures).")
		return false
	if journeys < 20:
		push_error("SynthTopology expected >= 20 edge→center journeys, got %d." % journeys)
		return false
	print("synth_topology: journeys=%d board=%s flow=%s" % [journeys, board, flow])
	return true


func _validate_layer_blueprint() -> bool:
	var layers: Array = CardVisualLibrary.get_variant_layers(CardData.Variant.SYNTH)
	var ids: PackedStringArray = PackedStringArray()
	var depths: Dictionary = {}
	var responses: Dictionary = {}
	for layer in layers:
		ids.append(layer.layer_id)
		depths[layer.layer_id] = layer.depth
		responses[layer.layer_id] = layer.material_response

	print("synth_layers: count=%d ids=%s" % [layers.size(), ", ".join(ids)])

	if layers.size() < 5:
		push_error("Expected at least 5 synth layers, got %d." % layers.size())
		return false

	for layer_id in EXPECTED_DEPTHS.keys():
		if not depths.has(layer_id):
			push_error("Missing synth layer '%s'." % layer_id)
			return false
		if not is_equal_approx(float(depths[layer_id]), float(EXPECTED_DEPTHS[layer_id])):
			push_error(
				"Synth layer '%s' depth %.3f != expected %.3f."
				% [layer_id, depths[layer_id], EXPECTED_DEPTHS[layer_id]]
			)
			return false

	if float(depths["micro_circuit_texture"]) >= float(depths["pcb_board"]):
		push_error("Micro circuit depth must be below pcb board.")
		return false
	if float(depths["pcb_board"]) >= float(depths["fiber_traffic"]):
		push_error("PCB board depth must be below fiber traffic.")
		return false
	if float(depths["fiber_traffic"]) >= float(depths["fiber_deep"]):
		push_error("Fiber traffic depth must be below fiber deep.")
		return false
	if float(depths["fiber_deep"]) >= float(depths["junction_pads"]):
		push_error("Fiber deep depth must be below junction pads.")
		return false

	var idle_offset := Vector2(-CardVisualLibrary.PARALLAX_DISTANCE, 0.0)
	var micro_px := absf(
		idle_offset.x
		* float(depths["micro_circuit_texture"])
		* float(responses["micro_circuit_texture"])
	)
	var board_px := absf(
		idle_offset.x * float(depths["pcb_board"]) * float(responses["pcb_board"])
	)
	var traffic_px := absf(
		idle_offset.x * float(depths["fiber_traffic"]) * float(responses["fiber_traffic"])
	)
	var deep_px := absf(
		idle_offset.x * float(depths["fiber_deep"]) * float(responses["fiber_deep"])
	)
	var pad_px := absf(
		idle_offset.x * float(depths["junction_pads"]) * float(responses["junction_pads"])
	)
	print(
		"synth_parallax_effective: micro=%.3f board=%.3f traffic=%.3f deep=%.3f pads=%.3f"
		% [micro_px, board_px, traffic_px, deep_px, pad_px]
	)

	if traffic_px <= board_px or board_px <= micro_px:
		push_error("Synth depth separation failed (micro < board < traffic).")
		return false
	if pad_px > deep_px * 1.1:
		push_error("Junction pads should not float above the fiber deep layer.")
		return false

	var foil_layers: Array = CardVisualLibrary.get_variant_layers(CardData.Variant.FOIL)
	var foil_max := 0.0
	for foil_layer in foil_layers:
		foil_max = maxf(
			foil_max,
			float(foil_layer.depth) * float(foil_layer.material_response)
		)
	var synth_max := 0.0
	for layer_id in EXPECTED_DEPTHS.keys():
		synth_max = maxf(synth_max, float(depths[layer_id]) * float(responses[layer_id]))
	print("synth_vs_foil_motion: synth=%.3f foil=%.3f" % [synth_max, foil_max])

	return true


func _validate_packet_materials() -> bool:
	var board_mat := CardVisualLibrary.create_synth_pcb_board_material()
	var traffic_mat := CardVisualLibrary.create_synth_fiber_traffic_material()
	var deep_mat := CardVisualLibrary.create_synth_fiber_deep_material()
	if board_mat == null or traffic_mat == null or deep_mat == null:
		push_error("Synth V2 materials failed to build.")
		return false

	if board_mat.get_shader_parameter("board_map") == null:
		push_error("PCB board missing board_map.")
		return false
	if traffic_mat.get_shader_parameter("flow_map") == null:
		push_error("Fiber traffic missing flow_map.")
		return false
	if traffic_mat.get_shader_parameter("packet_speed") == null:
		push_error("Fiber traffic missing packet_speed.")
		return false
	if deep_mat.get_shader_parameter("packet_speed") == null:
		push_error("Fiber deep missing packet_speed.")
		return false

	var stream_speed := float(traffic_mat.get_shader_parameter("packet_speed"))
	var deep_speed := float(deep_mat.get_shader_parameter("packet_speed"))
	if is_equal_approx(stream_speed, deep_speed):
		push_error("Primary and deep packet speeds must differ (independent traffic).")
		return false

	return true


func _validate_spawn(card_id: String, label: String, mode: CardScene.DisplayMode, card_scale: float) -> bool:
	var path := "res://resources/cards/core/%s.tres" % card_id
	var template := load(path) as CardData
	if template == null:
		push_error("Fixture card missing: %s" % path)
		return false

	var card := template.duplicate_card()
	card.variant = CardData.Variant.SYNTH
	var scene := CARD_SCENE.instantiate() as CardScene
	root.add_child(scene)
	scene.scale = Vector2.ONE * card_scale
	scene.setup(card, mode)

	for _i in 6:
		await process_frame

	var container := scene.get_node_or_null("%RenderLayerContainer") as Control
	if container == null:
		push_error("[%s mode=%d scale=%.2f] RenderLayerContainer missing" % [label, mode, card_scale])
		scene.queue_free()
		return false

	if container.get_child_count() < 5:
		push_error(
			"[%s mode=%d scale=%.2f] Expected 5+ layer nodes, got %d."
			% [label, mode, card_scale, container.get_child_count()]
		)
		scene.queue_free()
		return false

	var art := scene.get_node_or_null("%ArtTexture") as TextureRect
	if art != null and art.material != null:
		push_error("[%s mode=%d scale=%.2f] Synth must not apply art material overlay." % [label, mode, card_scale])
		scene.queue_free()
		return false

	scene.queue_free()
	return true
