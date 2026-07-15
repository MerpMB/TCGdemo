extends SceneTree
## Headless validation — production Synth material across artwork, modes, and scales.

const CARD_SCENE := preload("res://scenes/Card.tscn")

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
	"circuit_trace_network": 0.06,
	"flowing_data_stream": 0.12,
	"energy_pulse": 0.18,
	"tiny_data_nodes": 0.22,
}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not _validate_layer_blueprint():
		quit(1)
		return

	if not _validate_shared_pulse_timing():
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
		"verify_synth_material: OK — %d fixtures × %d modes × %d scales"
		% [ARTWORK_FIXTURES.size(), MODES.size(), SCALES.size()]
	)
	quit(0)


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

	if float(depths["micro_circuit_texture"]) >= float(depths["circuit_trace_network"]):
		push_error("Micro circuit depth must be below trace network.")
		return false
	if float(depths["circuit_trace_network"]) >= float(depths["flowing_data_stream"]):
		push_error("Trace network depth must be below data stream.")
		return false
	if float(depths["flowing_data_stream"]) >= float(depths["energy_pulse"]):
		push_error("Data stream depth must be below energy pulse.")
		return false
	if float(depths["energy_pulse"]) >= float(depths["tiny_data_nodes"]):
		push_error("Energy pulse depth must be below data nodes.")
		return false

	var idle_offset := Vector2(-CardVisualLibrary.PARALLAX_DISTANCE, 0.0)
	var micro_px := absf(
		idle_offset.x
		* float(depths["micro_circuit_texture"])
		* float(responses["micro_circuit_texture"])
	)
	var trace_px := absf(
		idle_offset.x
		* float(depths["circuit_trace_network"])
		* float(responses["circuit_trace_network"])
	)
	var stream_px := absf(
		idle_offset.x
		* float(depths["flowing_data_stream"])
		* float(responses["flowing_data_stream"])
	)
	var pulse_px := absf(
		idle_offset.x * float(depths["energy_pulse"]) * float(responses["energy_pulse"])
	)
	var node_px := absf(
		idle_offset.x * float(depths["tiny_data_nodes"]) * float(responses["tiny_data_nodes"])
	)
	print(
		"synth_parallax_effective: micro=%.3f trace=%.3f stream=%.3f pulse=%.3f nodes=%.3f"
		% [micro_px, trace_px, stream_px, pulse_px, node_px]
	)

	if stream_px <= trace_px or trace_px <= micro_px:
		push_error("Synth depth separation failed (micro < trace < stream).")
		return false
	if node_px > pulse_px * 1.1:
		push_error("Data nodes should not float above the energy pulse layer.")
		return false

	# Synth is emissive tech — motion profile differs from reflective foil.
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


func _validate_shared_pulse_timing() -> bool:
	var stream_mat := CardVisualLibrary.create_synth_data_stream_material()
	var pulse_mat := CardVisualLibrary.create_synth_energy_pulse_material()
	if stream_mat == null or pulse_mat == null:
		push_error("Synth shader materials failed to build.")
		return false

	var stream_interval: Variant = stream_mat.get_shader_parameter("pulse_interval")
	var pulse_interval: Variant = pulse_mat.get_shader_parameter("pulse_interval")
	if stream_interval != pulse_interval:
		push_error(
			"Data stream and energy pulse must share pulse_interval (got %s vs %s)."
			% [str(stream_interval), str(pulse_interval)]
		)
		return false

	if not is_equal_approx(float(stream_interval), CardVisualLibrary.SYNTH_PULSE_INTERVAL):
		push_error("Synth pulse_interval does not match library constant.")
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

	# Synth must not remap art — artwork stays readable via generic renderer only.
	var art := scene.get_node_or_null("%ArtTexture") as TextureRect
	if art != null and art.material != null:
		push_error("[%s mode=%d scale=%.2f] Synth must not apply art material overlay." % [label, mode, card_scale])
		scene.queue_free()
		return false

	scene.queue_free()
	return true
