class_name SynthTopology
extends RefCounted
## Synth V2 — intentional PCB graph + baked render maps.
## Topology is authored once (static architecture). Packets only read flow data.
## Composition: many hair-thin Manhattan runs from the card edge toward empty center.

const BAKE_WIDTH := 512
const BAKE_HEIGHT := 720
## Hair-thin fiber cores (reference: narrow neon traces).
const TRACE_HALF_UV := 0.0019
const GLOW_HALF_UV := 0.0055
const BLOOM_HALF_UV := 0.014
const JUNC_HALF_UV := 0.0055
const FLOW_RADIUS_UV := 0.022

## Shared bake cache (one layout for all Synth cards).
static var _cache: Dictionary = {}


static func get_board_texture() -> Texture2D:
	return _ensure_bake()["board"] as Texture2D


static func get_flow_texture() -> Texture2D:
	return _ensure_bake()["flow"] as Texture2D


static func get_pad_texture() -> Texture2D:
	return _ensure_bake()["pads"] as Texture2D


static func get_journey_count() -> int:
	return int(_ensure_bake().get("journey_count", 0))


static func clear_cache() -> void:
	_cache.clear()


static func _ensure_bake() -> Dictionary:
	if not _cache.is_empty():
		return _cache
	_cache = _bake()
	return _cache


static func _bake() -> Dictionary:
	var graph := _build_authored_graph()
	var journeys: Array = graph["journeys"]
	var junctions: Array = graph["junctions"]
	var pads: Array = graph["pads"]

	var board := Image.create(BAKE_WIDTH, BAKE_HEIGHT, false, Image.FORMAT_RGBA8)
	var flow := Image.create(BAKE_WIDTH, BAKE_HEIGHT, false, Image.FORMAT_RGBA8)
	var pad_img := Image.create(BAKE_WIDTH, BAKE_HEIGHT, false, Image.FORMAT_RGBA8)
	board.fill(Color(0, 0, 0, 0))
	flow.fill(Color(0, 0, 0, 0))
	pad_img.fill(Color(0, 0, 0, 0))

	var inv_w := 1.0 / float(BAKE_WIDTH)
	var inv_h := 1.0 / float(BAKE_HEIGHT)

	for y in BAKE_HEIGHT:
		var uv_y := (float(y) + 0.5) * inv_h
		for x in BAKE_WIDTH:
			var uv := Vector2((float(x) + 0.5) * inv_w, uv_y)
			var sample := _sample_topology(uv, journeys, junctions)
			var dist: float = sample["dist"]
			if dist > FLOW_RADIUS_UV * 1.35:
				continue

			var travel: float = sample["travel"]
			var road: float = sample["road"]
			var junc: float = sample["junc"]

			var core := _soft_mask(dist, TRACE_HALF_UV)
			var glow := _soft_mask(dist, GLOW_HALF_UV) * 0.42
			var bloom := pow(_soft_mask(dist, BLOOM_HALF_UV), 1.35)
			var jmask := _soft_mask(junc, JUNC_HALF_UV) * _soft_mask(dist, 0.010)
			var traces := maxf(core, glow)
			traces = maxf(traces, jmask * 0.55)

			board.set_pixel(
				x,
				y,
				Color(
					clampf(traces, 0.0, 1.0),
					clampf(jmask, 0.0, 1.0),
					clampf(bloom, 0.0, 1.0),
					clampf(core * 0.95 + jmask * 0.35, 0.0, 1.0)
				)
			)

			var coverage := 1.0 - clampf(dist / FLOW_RADIUS_UV, 0.0, 1.0)
			var jprox := 1.0 - clampf(junc / 0.028, 0.0, 1.0)
			flow.set_pixel(
				x,
				y,
				Color(
					clampf(travel, 0.0, 1.0),
					clampf(road / 255.0, 0.0, 1.0),
					clampf(jprox, 0.0, 1.0),
					clampf(coverage, 0.0, 1.0)
				)
			)

	for pad in pads:
		_stamp_pad(pad_img, pad["uv"], float(pad.get("radius", 0.0045)), float(pad.get("brightness", 0.50)))

	board.generate_mipmaps()
	flow.generate_mipmaps()
	pad_img.generate_mipmaps()

	return {
		"board": ImageTexture.create_from_image(board),
		"flow": ImageTexture.create_from_image(flow),
		"pads": ImageTexture.create_from_image(pad_img),
		"journey_count": journeys.size(),
	}


## Many thin edge→center Manhattan runs. Points ordered: edge first, tip last
## so baked travel=0 at rim and travel=1 toward center (packets run inward).
static func _build_authored_graph() -> Dictionary:
	var journeys: Array = []
	var junctions: Array = []
	var pads: Array = []
	var next_id := 0

	# ============================================================
	# TOP edge → down into card (parallel bundles + L/T)
	# ============================================================
	next_id = _add_run(journeys, junctions, pads, next_id,
		[Vector2(0.08, 0.02), Vector2(0.08, 0.14), Vector2(0.18, 0.14)],
		[Vector2(0.08, 0.14)],
		[Vector2(0.08, 0.02), Vector2(0.18, 0.14)])
	next_id = _add_run(journeys, junctions, pads, next_id,
		[Vector2(0.11, 0.02), Vector2(0.11, 0.11), Vector2(0.20, 0.11)],
		[Vector2(0.11, 0.11)], [])
	next_id = _add_run(journeys, junctions, pads, next_id,
		[Vector2(0.22, 0.02), Vector2(0.22, 0.18), Vector2(0.22, 0.28)],
		[],
		[Vector2(0.22, 0.02), Vector2(0.22, 0.28)])
	next_id = _add_run(journeys, junctions, pads, next_id,
		[Vector2(0.25, 0.02), Vector2(0.25, 0.16)],
		[],
		[Vector2(0.25, 0.16)])
	next_id = _add_run(journeys, junctions, pads, next_id,
		[Vector2(0.38, 0.02), Vector2(0.38, 0.12), Vector2(0.48, 0.12), Vector2(0.48, 0.22)],
		[Vector2(0.38, 0.12), Vector2(0.48, 0.12)],
		[Vector2(0.38, 0.02), Vector2(0.48, 0.22)])
	next_id = _add_run(journeys, junctions, pads, next_id,
		[Vector2(0.41, 0.02), Vector2(0.41, 0.09), Vector2(0.50, 0.09)],
		[Vector2(0.41, 0.09)], [])
	next_id = _add_run(journeys, junctions, pads, next_id,
		[Vector2(0.56, 0.02), Vector2(0.56, 0.20), Vector2(0.66, 0.20)],
		[Vector2(0.56, 0.20)],
		[Vector2(0.56, 0.02), Vector2(0.66, 0.20)])
	next_id = _add_run(journeys, junctions, pads, next_id,
		[Vector2(0.72, 0.02), Vector2(0.72, 0.10), Vector2(0.84, 0.10), Vector2(0.84, 0.20)],
		[Vector2(0.72, 0.10), Vector2(0.84, 0.10)],
		[Vector2(0.72, 0.02)])
	next_id = _add_run(journeys, junctions, pads, next_id,
		[Vector2(0.75, 0.02), Vector2(0.75, 0.08), Vector2(0.86, 0.08)],
		[Vector2(0.75, 0.08)], [])
	next_id = _add_run(journeys, junctions, pads, next_id,
		[Vector2(0.92, 0.02), Vector2(0.92, 0.16), Vector2(0.80, 0.16), Vector2(0.80, 0.26)],
		[Vector2(0.92, 0.16), Vector2(0.80, 0.16)],
		[Vector2(0.92, 0.02), Vector2(0.80, 0.26)])

	# ============================================================
	# BOTTOM edge → up into card
	# ============================================================
	next_id = _add_run(journeys, junctions, pads, next_id,
		[Vector2(0.08, 0.98), Vector2(0.08, 0.86), Vector2(0.20, 0.86)],
		[Vector2(0.08, 0.86)],
		[Vector2(0.08, 0.98), Vector2(0.20, 0.86)])
	next_id = _add_run(journeys, junctions, pads, next_id,
		[Vector2(0.11, 0.98), Vector2(0.11, 0.90), Vector2(0.22, 0.90)],
		[Vector2(0.11, 0.90)], [])
	next_id = _add_run(journeys, junctions, pads, next_id,
		[Vector2(0.28, 0.98), Vector2(0.28, 0.82), Vector2(0.28, 0.72)],
		[],
		[Vector2(0.28, 0.98), Vector2(0.28, 0.72)])
	next_id = _add_run(journeys, junctions, pads, next_id,
		[Vector2(0.31, 0.98), Vector2(0.31, 0.84)],
		[],
		[Vector2(0.31, 0.84)])
	next_id = _add_run(journeys, junctions, pads, next_id,
		[Vector2(0.44, 0.98), Vector2(0.44, 0.88), Vector2(0.56, 0.88), Vector2(0.56, 0.76)],
		[Vector2(0.44, 0.88), Vector2(0.56, 0.88)],
		[Vector2(0.44, 0.98), Vector2(0.56, 0.76)])
	next_id = _add_run(journeys, junctions, pads, next_id,
		[Vector2(0.47, 0.98), Vector2(0.47, 0.91), Vector2(0.58, 0.91)],
		[Vector2(0.47, 0.91)], [])
	next_id = _add_run(journeys, junctions, pads, next_id,
		[Vector2(0.68, 0.98), Vector2(0.68, 0.86), Vector2(0.80, 0.86), Vector2(0.80, 0.74)],
		[Vector2(0.68, 0.86), Vector2(0.80, 0.86)],
		[Vector2(0.68, 0.98), Vector2(0.80, 0.74)])
	next_id = _add_run(journeys, junctions, pads, next_id,
		[Vector2(0.88, 0.98), Vector2(0.88, 0.84), Vector2(0.76, 0.84)],
		[Vector2(0.88, 0.84)],
		[Vector2(0.88, 0.98), Vector2(0.76, 0.84)])
	next_id = _add_run(journeys, junctions, pads, next_id,
		[Vector2(0.91, 0.98), Vector2(0.91, 0.88), Vector2(0.78, 0.88)],
		[Vector2(0.91, 0.88)], [])

	# ============================================================
	# LEFT edge → right toward center
	# ============================================================
	next_id = _add_run(journeys, junctions, pads, next_id,
		[Vector2(0.02, 0.18), Vector2(0.14, 0.18), Vector2(0.14, 0.28)],
		[Vector2(0.14, 0.18)],
		[Vector2(0.02, 0.18), Vector2(0.14, 0.28)])
	next_id = _add_run(journeys, junctions, pads, next_id,
		[Vector2(0.02, 0.21), Vector2(0.12, 0.21)],
		[],
		[Vector2(0.12, 0.21)])
	next_id = _add_run(journeys, junctions, pads, next_id,
		[Vector2(0.02, 0.36), Vector2(0.16, 0.36), Vector2(0.26, 0.36), Vector2(0.26, 0.46)],
		[Vector2(0.16, 0.36), Vector2(0.26, 0.36)],
		[Vector2(0.02, 0.36), Vector2(0.26, 0.46)])
	next_id = _add_run(journeys, junctions, pads, next_id,
		[Vector2(0.02, 0.48), Vector2(0.14, 0.48), Vector2(0.28, 0.48)],
		[Vector2(0.14, 0.48)],
		[Vector2(0.02, 0.48), Vector2(0.28, 0.48)])
	next_id = _add_run(journeys, junctions, pads, next_id,
		[Vector2(0.14, 0.48), Vector2(0.14, 0.58)],
		[Vector2(0.14, 0.48)],
		[Vector2(0.14, 0.58)])
	next_id = _add_run(journeys, junctions, pads, next_id,
		[Vector2(0.02, 0.51), Vector2(0.18, 0.51)],
		[],
		[Vector2(0.18, 0.51)])
	next_id = _add_run(journeys, junctions, pads, next_id,
		[Vector2(0.02, 0.64), Vector2(0.18, 0.64), Vector2(0.18, 0.74), Vector2(0.28, 0.74)],
		[Vector2(0.18, 0.64), Vector2(0.18, 0.74)],
		[Vector2(0.02, 0.64), Vector2(0.28, 0.74)])
	next_id = _add_run(journeys, junctions, pads, next_id,
		[Vector2(0.02, 0.78), Vector2(0.16, 0.78), Vector2(0.16, 0.68)],
		[Vector2(0.16, 0.78)],
		[Vector2(0.02, 0.78), Vector2(0.16, 0.68)])
	next_id = _add_run(journeys, junctions, pads, next_id,
		[Vector2(0.02, 0.81), Vector2(0.14, 0.81)],
		[],
		[Vector2(0.14, 0.81)])

	# ============================================================
	# RIGHT edge → left toward center (dense parallel stack)
	# ============================================================
	next_id = _add_run(journeys, junctions, pads, next_id,
		[Vector2(0.98, 0.14), Vector2(0.84, 0.14), Vector2(0.84, 0.24)],
		[Vector2(0.84, 0.14)],
		[Vector2(0.98, 0.14), Vector2(0.84, 0.24)])
	next_id = _add_run(journeys, junctions, pads, next_id,
		[Vector2(0.98, 0.17), Vector2(0.86, 0.17)],
		[],
		[Vector2(0.86, 0.17)])
	next_id = _add_run(journeys, junctions, pads, next_id,
		[Vector2(0.98, 0.30), Vector2(0.82, 0.30), Vector2(0.72, 0.30)],
		[Vector2(0.82, 0.30)],
		[Vector2(0.98, 0.30), Vector2(0.72, 0.30)])
	next_id = _add_run(journeys, junctions, pads, next_id,
		[Vector2(0.98, 0.33), Vector2(0.84, 0.33), Vector2(0.84, 0.42)],
		[Vector2(0.84, 0.33)],
		[Vector2(0.84, 0.42)])
	next_id = _add_run(journeys, junctions, pads, next_id,
		[Vector2(0.98, 0.46), Vector2(0.80, 0.46), Vector2(0.70, 0.46)],
		[Vector2(0.80, 0.46)],
		[Vector2(0.98, 0.46), Vector2(0.70, 0.46)])
	next_id = _add_run(journeys, junctions, pads, next_id,
		[Vector2(0.98, 0.49), Vector2(0.82, 0.49)],
		[],
		[Vector2(0.82, 0.49)])
	next_id = _add_run(journeys, junctions, pads, next_id,
		[Vector2(0.98, 0.58), Vector2(0.86, 0.58), Vector2(0.86, 0.68), Vector2(0.74, 0.68)],
		[Vector2(0.86, 0.58), Vector2(0.86, 0.68)],
		[Vector2(0.98, 0.58), Vector2(0.74, 0.68)])
	next_id = _add_run(journeys, junctions, pads, next_id,
		[Vector2(0.98, 0.61), Vector2(0.88, 0.61), Vector2(0.76, 0.61)],
		[Vector2(0.88, 0.61)],
		[Vector2(0.76, 0.61)])
	next_id = _add_run(journeys, junctions, pads, next_id,
		[Vector2(0.98, 0.74), Vector2(0.84, 0.74), Vector2(0.84, 0.64)],
		[Vector2(0.84, 0.74)],
		[Vector2(0.98, 0.74), Vector2(0.84, 0.64)])
	next_id = _add_run(journeys, junctions, pads, next_id,
		[Vector2(0.98, 0.86), Vector2(0.86, 0.86), Vector2(0.86, 0.76), Vector2(0.74, 0.76)],
		[Vector2(0.86, 0.86), Vector2(0.86, 0.76)],
		[Vector2(0.98, 0.86), Vector2(0.74, 0.76)])
	next_id = _add_run(journeys, junctions, pads, next_id,
		[Vector2(0.98, 0.89), Vector2(0.88, 0.89)],
		[],
		[Vector2(0.88, 0.89)])

	# ============================================================
	# Corner stairs (memorable edge→center zig modules)
	# ============================================================
	next_id = _add_run(journeys, junctions, pads, next_id,
		[
			Vector2(0.98, 0.06), Vector2(0.88, 0.06), Vector2(0.88, 0.12),
			Vector2(0.78, 0.12), Vector2(0.78, 0.20), Vector2(0.68, 0.20),
		],
		[Vector2(0.88, 0.06), Vector2(0.88, 0.12), Vector2(0.78, 0.12), Vector2(0.78, 0.20)],
		[Vector2(0.98, 0.06), Vector2(0.68, 0.20)])
	next_id = _add_run(journeys, junctions, pads, next_id,
		[
			Vector2(0.02, 0.94), Vector2(0.12, 0.94), Vector2(0.12, 0.86),
			Vector2(0.22, 0.86), Vector2(0.22, 0.78),
		],
		[Vector2(0.12, 0.94), Vector2(0.12, 0.86), Vector2(0.22, 0.86)],
		[Vector2(0.02, 0.94), Vector2(0.22, 0.78)])

	return {"journeys": journeys, "junctions": junctions, "pads": pads}


static func _add_run(
	journeys: Array,
	junctions: Array,
	pads: Array,
	next_id: int,
	points: Array,
	juncs: Array,
	pad_uvs: Array
) -> int:
	if points.size() < 2:
		return next_id
	journeys.append({"id": next_id, "points": points.duplicate()})
	for j in juncs:
		junctions.append(j)
	for p in pad_uvs:
		pads.append({"uv": p, "radius": 0.0042, "brightness": 0.48})
	return next_id + 1



static func _sample_topology(uv: Vector2, journeys: Array, junctions: Array) -> Dictionary:
	var best_d := 1e6
	var best_travel := 0.0
	var best_road := 0.0
	var best_junc := 1e6

	for journey in journeys:
		var points: Array = journey["points"]
		var road_id := float(journey["id"])
		var total := 0.0
		for i in range(points.size() - 1):
			total += (points[i] as Vector2).distance_to(points[i + 1] as Vector2)
		if total < 1e-5:
			continue

		var arc_base := 0.0
		for i in range(points.size() - 1):
			var a: Vector2 = points[i]
			var b: Vector2 = points[i + 1]
			var seg_len: float = a.distance_to(b)
			var d := _seg_dist(uv, a, b)
			if d < best_d:
				best_d = d
				var t_local := _seg_param(uv, a, b)
				best_travel = (arc_base + t_local * seg_len) / total
				best_road = road_id
			arc_base += seg_len

	for j in junctions:
		best_junc = minf(best_junc, uv.distance_to(j as Vector2))

	return {"dist": best_d, "travel": best_travel, "road": best_road, "junc": best_junc}


static func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var pa := p - a
	var ba := b - a
	var denom := ba.length_squared()
	var h := 0.0 if denom < 1e-12 else clampf(pa.dot(ba) / denom, 0.0, 1.0)
	return (pa - ba * h).length()


static func _seg_param(p: Vector2, a: Vector2, b: Vector2) -> float:
	var pa := p - a
	var ba := b - a
	var denom := ba.length_squared()
	if denom < 1e-12:
		return 0.0
	return clampf(pa.dot(ba) / denom, 0.0, 1.0)


static func _soft_mask(dist: float, half_width: float) -> float:
	return 1.0 - smoothstep(0.0, maxf(half_width, 1e-5), dist)


static func _stamp_pad(img: Image, uv: Vector2, radius_uv: float, brightness: float) -> void:
	var cx := int(uv.x * float(BAKE_WIDTH))
	var cy := int(uv.y * float(BAKE_HEIGHT))
	var rx := int(ceil(radius_uv * float(BAKE_WIDTH) * 2.4))
	var ry := int(ceil(radius_uv * float(BAKE_HEIGHT) * 2.4))
	for dy in range(-ry, ry + 1):
		for dx in range(-rx, rx + 1):
			var x := cx + dx
			var y := cy + dy
			if x < 0 or y < 0 or x >= BAKE_WIDTH or y >= BAKE_HEIGHT:
				continue
			var puv := Vector2((float(x) + 0.5) / float(BAKE_WIDTH), (float(y) + 0.5) / float(BAKE_HEIGHT))
			var d := puv.distance_to(uv)
			var core := 1.0 - smoothstep(0.0, radius_uv, d)
			var ring := (1.0 - smoothstep(radius_uv * 0.55, radius_uv * 1.55, d)) * 0.35
			var a := clampf(maxf(core, ring) * brightness, 0.0, 1.0)
			if a < 0.04:
				continue
			var prev := img.get_pixel(x, y)
			var col := Color(0.35, 0.95, 1.0, maxf(prev.a, a))
			img.set_pixel(x, y, col)
