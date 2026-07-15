class_name VariantRenderer
extends RefCounted
## Generic material-layer renderer. Consumes VariantLayer definitions from CardVisualLibrary only.

const _VariantLayer := preload("res://scripts/ui/variant_layer.gd")


class LayerInstance:
	var layer
	var root: Control
	var visual: CanvasItem
	var anim_time := 0.0
	var scroll_offset := Vector2.ZERO
	var base_modulate := Color.WHITE
	var root_rest_position := Vector2.ZERO


var _container: Control
var _host_size := Vector2.ZERO
var _instances: Array[LayerInstance] = []
var _unimplemented_warned: Dictionary = {}
var _idle_phase := 0.0


func bind(p_container: Control, p_host_size: Vector2) -> void:
	_container = p_container
	_host_size = p_host_size


func apply(card_data: CardData) -> void:
	reset()
	if card_data == null or _container == null:
		return

	var layers: Array = CardVisualLibrary.get_variant_layers(card_data.variant)
	layers.sort_custom(_sort_by_z_order)
	for layer in layers:
		if layer != null:
			_spawn_layer(layer)


func reset() -> void:
	_idle_phase = 0.0
	_clear_instances()
	if _container:
		for child in _container.get_children():
			child.queue_free()


func process_idle(delta: float) -> void:
	if _instances.is_empty() or delta <= 0.0:
		return

	_idle_phase += delta * CardVisualLibrary.IDLE_SPEED
	var idle_offset: Vector2 = _compute_idle_offset()

	for inst in _instances:
		if inst.layer == null or inst.visual == null:
			continue
		inst.anim_time += delta
		match inst.layer.animation_type:
			_VariantLayer.AnimationType.STATIC:
				pass
			_VariantLayer.AnimationType.SCROLL:
				_update_scroll(inst, delta)
			_VariantLayer.AnimationType.ROTATE:
				_update_rotate(inst, delta)
			_VariantLayer.AnimationType.PULSE:
				_update_pulse(inst)
			_VariantLayer.AnimationType.SHIMMER:
				_update_shimmer(inst)
		_apply_depth_parallax(inst, idle_offset)


func _compute_idle_offset() -> Vector2:
	## One shared driver: center → left → right → center. Magnitude capped by PARALLAX_DISTANCE.
	var phase := fmod(_idle_phase, 1.0)
	var segment := 1.0 / 3.0
	var driver_x := 0.0

	if phase < segment:
		driver_x = -_apply_idle_curve(phase / segment)
	elif phase < segment * 2.0:
		driver_x = lerpf(-1.0, 1.0, _apply_idle_curve((phase - segment) / segment))
	else:
		driver_x = lerpf(1.0, 0.0, _apply_idle_curve((phase - segment * 2.0) / segment))

	return Vector2(driver_x * CardVisualLibrary.PARALLAX_DISTANCE, 0.0)


func _apply_idle_curve(t: float) -> float:
	var eased := clampf(t, 0.0, 1.0)
	var curve: float = CardVisualLibrary.IDLE_CURVE
	if curve <= 1.0:
		return eased
	return pow(eased, curve)


func _apply_depth_parallax(inst: LayerInstance, idle_offset: Vector2) -> void:
	if inst.root == null:
		return
	var depth: float = inst.layer.depth
	var response: float = inst.layer.material_response
	inst.root.position = inst.root_rest_position + idle_offset * depth * response


func _sort_by_z_order(a, b) -> bool:
	return a.z_order < b.z_order


func _spawn_layer(layer) -> void:
	match layer.type:
		_VariantLayer.LayerType.TEXTURE:
			if layer.texture == null:
				return
			_spawn_texture_layer(layer)
		_VariantLayer.LayerType.SHADER:
			_spawn_shader_layer(layer)
		_VariantLayer.LayerType.COLOR:
			_warn_unimplemented_layer("color", layer.layer_id)
		_VariantLayer.LayerType.PARTICLES:
			_warn_unimplemented_layer("particles", layer.layer_id)


func _spawn_texture_layer(layer) -> void:
	var needs_clip: bool = layer.animation_type == _VariantLayer.AnimationType.SCROLL
	var root := _make_layer_root(layer, needs_clip)

	var texture_rect := TextureRect.new()
	texture_rect.name = "Texture"
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_rect.texture = layer.texture
	## Project default is nearest; foil grain/speckle need linear or they pixelate.
	texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	texture_rect.material = _resolve_layer_material(layer)

	if needs_clip:
		_configure_scroll_rect(texture_rect, layer)
		root.add_child(texture_rect)
	else:
		texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		texture_rect.scale = layer.uv_scale
		root.add_child(texture_rect)

	_container.add_child(root)
	_apply_layer_visuals(texture_rect, layer)
	_register_instance(layer, root, texture_rect)


func _spawn_shader_layer(layer) -> void:
	var mat: Material = layer.material
	if mat == null and layer.shader != null:
		var shader_mat := ShaderMaterial.new()
		shader_mat.shader = layer.shader
		mat = shader_mat
	if mat == null:
		_warn_unimplemented_layer("shader", layer.layer_id)
		return

	var root := _make_layer_root(layer, false)
	var rect := ColorRect.new()
	rect.name = "Shader"
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.color = Color(1.0, 1.0, 1.0, 1.0)
	rect.material = mat
	root.add_child(rect)
	_container.add_child(root)
	_apply_layer_visuals(rect, layer)
	_register_instance(layer, root, rect)


func _make_layer_root(layer, clip_contents: bool) -> Control:
	var root := Control.new()
	root.name = "Layer_%s" % layer.layer_id
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.clip_contents = clip_contents
	root.z_index = layer.z_order
	return root


func _register_instance(layer, root: Control, visual: CanvasItem) -> void:
	var inst := LayerInstance.new()
	inst.layer = layer
	inst.root = root
	inst.visual = visual
	inst.base_modulate = visual.modulate
	inst.root_rest_position = root.position
	if visual is Control:
		inst.scroll_offset = (visual as Control).position
	_instances.append(inst)


func _resolve_layer_material(layer) -> Material:
	if layer.material != null:
		return layer.material
	return _create_blend_material(layer.blend_mode)


func _configure_scroll_rect(texture_rect: TextureRect, layer) -> void:
	var texture: Texture2D = layer.texture
	var host_h := _host_size.y if _host_size.y > 0.0 else 200.0
	var host_w := _host_size.x if _host_size.x > 0.0 else 140.0
	var aspect := float(texture.get_width()) / maxf(float(texture.get_height()), 1.0)
	var size := Vector2(
		maxf(host_w, host_h * aspect) * layer.uv_scale.x,
		host_h * layer.uv_scale.y
	)
	texture_rect.custom_minimum_size = size
	texture_rect.size = size
	var direction: Vector2 = layer.scroll_direction
	if direction.length_squared() <= 0.0001:
		direction = Vector2(1.0, 0.0)
	else:
		direction = direction.normalized()
	texture_rect.position = -direction * size * 0.35


func _apply_layer_visuals(visual: CanvasItem, layer) -> void:
	var tint: Color = layer.tint
	tint.a *= layer.opacity
	visual.modulate = tint


func _update_scroll(inst: LayerInstance, delta: float) -> void:
	var layer = inst.layer
	var texture_rect := inst.visual as TextureRect
	if texture_rect == null:
		return

	var direction: Vector2 = layer.scroll_direction
	if direction.length_squared() <= 0.0001:
		direction = Vector2(1.0, 0.0)
	else:
		direction = direction.normalized()

	inst.scroll_offset += direction * layer.scroll_speed * delta
	texture_rect.position = inst.scroll_offset

	var host := _host_size
	var tex_size := texture_rect.size
	if host.x <= 0.0 or host.y <= 0.0:
		return

	if direction.x > 0.0 and inst.scroll_offset.x > host.x:
		inst.scroll_offset.x = -tex_size.x * 0.5
	elif direction.x < 0.0 and inst.scroll_offset.x < -tex_size.x:
		inst.scroll_offset.x = host.x
	if direction.y > 0.0 and inst.scroll_offset.y > host.y:
		inst.scroll_offset.y = -tex_size.y * 0.5
	elif direction.y < 0.0 and inst.scroll_offset.y < -tex_size.y:
		inst.scroll_offset.y = host.y

	texture_rect.position = inst.scroll_offset


func _update_rotate(inst: LayerInstance, delta: float) -> void:
	if inst.visual:
		inst.visual.rotation += deg_to_rad(inst.layer.rotation_speed * delta)


func _update_pulse(inst: LayerInstance) -> void:
	var layer = inst.layer
	if inst.visual == null:
		return
	var speed: float = layer.pulse_speed if layer.pulse_speed > 0.0 else 3.0
	var pulse: float = 0.5 + 0.5 * sin(inst.anim_time * speed)
	var modulate: Color = inst.base_modulate
	modulate.a = layer.opacity * lerp(0.72, 1.0, pulse)
	inst.visual.modulate = modulate


func _update_shimmer(inst: LayerInstance) -> void:
	var layer = inst.layer
	if inst.visual == null:
		return
	var shimmer: float = 0.5 + 0.5 * sin(inst.anim_time * 2.2)
	var modulate: Color = inst.base_modulate
	modulate.a = layer.opacity * lerp(0.75, 1.0, shimmer)
	inst.visual.modulate = modulate


func _create_blend_material(blend_mode: int) -> CanvasItemMaterial:
	var material := CanvasItemMaterial.new()
	match blend_mode:
		_VariantLayer.BlendMode.ADD:
			material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		_VariantLayer.BlendMode.SUB:
			material.blend_mode = CanvasItemMaterial.BLEND_MODE_SUB
		_VariantLayer.BlendMode.MUL:
			material.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
		_:
			material.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
	return material


func _warn_unimplemented_layer(layer_type: String, layer_id: String) -> void:
	var key := "%s:%s" % [layer_type, layer_id]
	if _unimplemented_warned.has(key):
		return
	_unimplemented_warned[key] = true
	push_warning(
		"VariantRenderer: %s layers are not implemented yet (layer '%s')."
		% [layer_type, layer_id]
	)


func _clear_instances() -> void:
	_instances.clear()
