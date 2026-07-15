class_name PackLayout
extends RefCounted
## Pure layout math for the pack-opening card grid. No scene ownership.


const BASE_CARD_SIZE := Vector2(140, 200)
const GRID_COLUMNS := 4
const GRID_SPACING := 12.0
const INNER_PADDING := 8.0
const HEADER_GAP := 20.0
const FOOTER_GAP := 16.0


static func usable_card_area(fly_layer_rect: Rect2) -> Rect2:
	var rect := fly_layer_rect
	rect.position.x += INNER_PADDING
	rect.position.y += HEADER_GAP
	rect.size.x -= INNER_PADDING * 2.0
	rect.size.y -= HEADER_GAP + FOOTER_GAP
	rect.size.x = maxf(rect.size.x, 0.0)
	rect.size.y = maxf(rect.size.y, 0.0)
	return rect


static func scaled_card_size(card_scale: float) -> Vector2:
	return BASE_CARD_SIZE * card_scale


static func scaled_card_half_size(card_scale: float) -> Vector2:
	return scaled_card_size(card_scale) * 0.5


static func measure_grid_size(columns: int, rows: int, card_size: Vector2) -> Vector2:
	return Vector2(
		columns * card_size.x + (columns - 1) * GRID_SPACING,
		rows * card_size.y + (rows - 1) * GRID_SPACING,
	)


static func resolve_card_scale(columns: int, rows: int, available: Rect2) -> float:
	var full_grid_size := measure_grid_size(columns, rows, BASE_CARD_SIZE)
	if full_grid_size.x <= available.size.x and full_grid_size.y <= available.size.y:
		return 1.0
	var scale_x := available.size.x / full_grid_size.x if full_grid_size.x > 0.0 else 1.0
	var scale_y := available.size.y / full_grid_size.y if full_grid_size.y > 0.0 else 1.0
	return minf(minf(scale_x, scale_y), 1.0)


static func resolve_grid_columns(count: int, available_width: float) -> int:
	var preferred := GRID_COLUMNS if count > GRID_COLUMNS else count
	var max_fit := int((available_width + GRID_SPACING) / (BASE_CARD_SIZE.x + GRID_SPACING))
	return clampi(mini(preferred, max_fit), 1, count)


## Returns { "card_scale": float, "centers": Array[Vector2] }.
static func compute_card_layout(count: int, available: Rect2) -> Dictionary:
	var columns := resolve_grid_columns(count, available.size.x)
	var rows := int(ceil(float(count) / float(columns)))
	var card_scale := resolve_card_scale(columns, rows, available)
	var card_size := scaled_card_size(card_scale)
	var grid_size := measure_grid_size(columns, rows, card_size)

	var origin := available.position + (available.size - grid_size) * 0.5
	origin.x = clampf(
		origin.x,
		available.position.x,
		maxf(available.position.x, available.position.x + available.size.x - grid_size.x)
	)
	origin.y = maxf(origin.y, available.position.y)

	var centers: Array[Vector2] = []
	for index in count:
		var row := int(index / columns)
		var col := index % columns
		var cards_in_row := mini(columns, count - row * columns)
		var row_width := cards_in_row * card_size.x + (cards_in_row - 1) * GRID_SPACING
		var row_offset_x := (grid_size.x - row_width) * 0.5
		centers.append(origin + Vector2(
			row_offset_x + col * (card_size.x + GRID_SPACING) + card_size.x * 0.5,
			row * (card_size.y + GRID_SPACING) + card_size.y * 0.5,
		))

	return {"card_scale": card_scale, "centers": centers}


static func prepare_card_for_layout(card_scene: CardScene, card_scale: float) -> void:
	card_scene.custom_minimum_size = BASE_CARD_SIZE
	card_scene.size = BASE_CARD_SIZE
	card_scene.prepare_layout_scale(card_scale)


static func apply_card_slot_position(
	card_scene: CardScene,
	center_local: Vector2,
	card_scale: float
) -> void:
	prepare_card_for_layout(card_scene, card_scale)
	card_scene.position = center_local - scaled_card_half_size(card_scale)
	card_scene.scale = Vector2.ONE * card_scale
