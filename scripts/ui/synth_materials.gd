class_name SynthMaterials
extends RefCounted
## Synth variant — PCB architecture + fiber traffic (tuning, blueprints, factories).


const _VariantShaderCache := preload("res://scripts/ui/variant_shader_cache.gd")
const _SynthTopology := preload("res://scripts/ui/synth_topology.gd")


# ---------------------------------------------------------------------------
# Tuning (production) — micro etch → pcb board → fiber traffic → deep → pads
# ---------------------------------------------------------------------------

const MASTER_TIME_SCALE := 1.0

const MICRO_CIRCUIT_STRENGTH := 0.024
const MICRO_CIRCUIT_FREQUENCY := 2.4

const TRACE_STRENGTH := 0.11
const TRACE_EDGE_GLOW := 0.008
const JUNCTION_BOOST := 0.95
const FIBER_HALO := 0.70

const STREAM_STRENGTH := 1.05
const STREAM_TIME_SCALE := 0.52
const PACKET_SPEED := 0.92
const PACKET_SIZE := 0.055
const BODY_LENGTH := 0.55
const TRAIL_LENGTH := 0.72
const SYNAPSE_STRENGTH := 0.95
const RAINBOW_STRENGTH := 0.88
const BLOOM_STRENGTH := 0.58

const TRAIL_STRENGTH := 0.48
const TRAIL_TIME_SCALE := 0.28
const TRAIL_PACKET_SPEED := 0.55
const TRAIL_PACKET_SIZE := 0.06
const TRAIL_BODY_LENGTH := 0.60
const TRAIL_LENGTH_SECONDARY := 0.78
const TRAIL_SYNAPSE_STRENGTH := 0.75
const TRAIL_RAINBOW_STRENGTH := 0.82
const TRAIL_BLOOM_STRENGTH := 0.45

const NODE_OPACITY := 0.055
const NODE_PULSE_SPEED := 0.05
const NODE_SIZE := 1.0


static func get_blueprints() -> Array:
	return [
		{
			"id": "micro_circuit_texture",
			"type": "texture",
			"procedural": "synth_micro_circuit",
			"animation": "static",
			"z_order": 0,
			"depth": 0.02,
			"material_response": 0.35,
			"opacity": 1.0,
			"blend_mode": "mul",
		},
		{
			"id": "pcb_board",
			"type": "shader",
			"shader_key": "synth_pcb_board",
			"animation": "static",
			"z_order": 10,
			"depth": 0.06,
			"material_response": 0.65,
			"opacity": 1.0,
		},
		{
			"id": "fiber_traffic",
			"type": "shader",
			"shader_key": "synth_fiber_traffic",
			"animation": "static",
			"z_order": 20,
			"depth": 0.12,
			"material_response": 0.85,
			"opacity": 1.0,
		},
		{
			"id": "fiber_deep",
			"type": "shader",
			"shader_key": "synth_fiber_deep",
			"animation": "static",
			"z_order": 30,
			"depth": 0.18,
			"material_response": 1.0,
			"opacity": 1.0,
		},
		{
			"id": "junction_pads",
			"type": "texture",
			"procedural": "synth_junction_pads",
			"animation": "pulse",
			"z_order": 40,
			"depth": 0.22,
			"material_response": 0.4,
			"opacity": NODE_OPACITY,
			"blend_mode": "add",
			"pulse_speed": NODE_PULSE_SPEED,
			"uv_scale": Vector2(NODE_SIZE, NODE_SIZE),
		},
	]


static func create_pcb_board_material() -> ShaderMaterial:
	var material := _VariantShaderCache.create("synth_pcb_board")
	if material:
		material.set_shader_parameter("board_map", _SynthTopology.get_board_texture())
		material.set_shader_parameter("trace_strength", TRACE_STRENGTH)
		material.set_shader_parameter("edge_glow", TRACE_EDGE_GLOW)
		material.set_shader_parameter("junction_boost", JUNCTION_BOOST)
		material.set_shader_parameter("fiber_halo", FIBER_HALO)
	return material


static func create_fiber_traffic_material() -> ShaderMaterial:
	var material := _VariantShaderCache.create("synth_fiber_traffic")
	if material:
		material.set_shader_parameter("board_map", _SynthTopology.get_board_texture())
		material.set_shader_parameter("flow_map", _SynthTopology.get_flow_texture())
		material.set_shader_parameter("stream_strength", STREAM_STRENGTH)
		material.set_shader_parameter(
			"time_scale", STREAM_TIME_SCALE * MASTER_TIME_SCALE
		)
		material.set_shader_parameter("packet_speed", PACKET_SPEED)
		material.set_shader_parameter("packet_size", PACKET_SIZE)
		material.set_shader_parameter("body_length", BODY_LENGTH)
		material.set_shader_parameter("trail_length", TRAIL_LENGTH)
		material.set_shader_parameter("synapse_strength", SYNAPSE_STRENGTH)
		material.set_shader_parameter("rainbow_strength", RAINBOW_STRENGTH)
		material.set_shader_parameter("bloom_strength", BLOOM_STRENGTH)
		material.set_shader_parameter("journey_count", float(_SynthTopology.get_journey_count()))
	return material


static func create_fiber_deep_material() -> ShaderMaterial:
	var material := _VariantShaderCache.create("synth_fiber_deep")
	if material:
		material.set_shader_parameter("board_map", _SynthTopology.get_board_texture())
		material.set_shader_parameter("flow_map", _SynthTopology.get_flow_texture())
		material.set_shader_parameter("pulse_strength", TRAIL_STRENGTH)
		material.set_shader_parameter(
			"time_scale", TRAIL_TIME_SCALE * MASTER_TIME_SCALE
		)
		material.set_shader_parameter("packet_speed", TRAIL_PACKET_SPEED)
		material.set_shader_parameter("packet_size", TRAIL_PACKET_SIZE)
		material.set_shader_parameter("body_length", TRAIL_BODY_LENGTH)
		material.set_shader_parameter("trail_length", TRAIL_LENGTH_SECONDARY)
		material.set_shader_parameter("synapse_strength", TRAIL_SYNAPSE_STRENGTH)
		material.set_shader_parameter("rainbow_strength", TRAIL_RAINBOW_STRENGTH)
		material.set_shader_parameter("bloom_strength", TRAIL_BLOOM_STRENGTH)
		material.set_shader_parameter("journey_count", float(_SynthTopology.get_journey_count()))
	return material


static func create_named_shader_material(shader_key: String) -> ShaderMaterial:
	match shader_key:
		"synth_pcb_board", "synth_circuit_traces":
			return create_pcb_board_material()
		"synth_fiber_traffic", "synth_data_stream":
			return create_fiber_traffic_material()
		"synth_fiber_deep", "synth_energy_pulse":
			return create_fiber_deep_material()
		_:
			return null


static func build_procedural_texture(procedural_key: String) -> Texture2D:
	match procedural_key:
		"synth_micro_circuit":
			return _build_micro_circuit_texture()
		"synth_junction_pads", "synth_data_nodes":
			return _SynthTopology.get_pad_texture()
		_:
			return null


static func warmup_topology() -> void:
	_SynthTopology.get_board_texture()
	_SynthTopology.get_flow_texture()
	_SynthTopology.get_pad_texture()
	_SynthTopology.get_journey_count()


static func _build_micro_circuit_texture() -> Texture2D:
	var size := 1024
	var fine := FastNoiseLite.new()
	fine.seed = 67
	fine.noise_type = FastNoiseLite.TYPE_VALUE
	fine.frequency = MICRO_CIRCUIT_FREQUENCY * 1.8
	fine.fractal_type = FastNoiseLite.FRACTAL_NONE

	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var strength := clampf(MICRO_CIRCUIT_STRENGTH * 2.2, 0.015, 0.08)
	for y in size:
		for x in size:
			var fx := float(x) / float(size)
			var fy := float(y) / float(size)
			var grid := _vec2_like_grid(fx, fy, 48.0)
			var h_line: float = 1.0 - smoothstep(0.0, 0.012, absf(grid.y - 0.5))
			var v_line: float = 1.0 - smoothstep(0.0, 0.012, absf(grid.x - 0.5))
			var etch: float = maxf(h_line, v_line) * 0.55
			var n := (fine.get_noise_2d(float(x), float(y)) + 1.0) * 0.5
			etch = clampf(etch + (n - 0.5) * 0.08, 0.0, 1.0)
			var g: float = 1.0 - etch * strength
			g = clampf(g, 0.94, 1.0)
			img.set_pixel(x, y, Color(g, g, g, 1.0))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


static func _vec2_like_grid(fx: float, fy: float, cells: float) -> Vector2:
	return Vector2(fmod(fx * cells, 1.0), fmod(fy * cells, 1.0))
