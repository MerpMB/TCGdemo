extends Node
## Registry of all pack definitions. Loads PackConfig resources from resources/packs/.


const PACKS_ROOT := "res://resources/packs"


var _packs_by_id: Dictionary = {}


func _ready() -> void:
	_load_all_packs()
	_print_load_summary()


func get_pack(pack_id: String) -> PackConfig:
	return _packs_by_id.get(pack_id)


func get_all_packs() -> Array[PackConfig]:
	var all_packs: Array[PackConfig] = []
	for pack in _packs_by_id.values():
		all_packs.append(pack)
	all_packs.sort_custom(func(a: PackConfig, b: PackConfig) -> bool:
		return a.display_name < b.display_name
	)
	return all_packs


## Packs shown in Pack Hub — visible_in_shop only (data-driven, no manual list).
func get_hub_packs() -> Array[PackConfig]:
	var hub_packs: Array[PackConfig] = []
	for pack in get_all_packs():
		if pack.visible_in_shop:
			hub_packs.append(pack)
	return hub_packs


## Player-facing packs — excludes debug_only and hidden shop entries.
func get_shop_packs() -> Array[PackConfig]:
	var shop_packs: Array[PackConfig] = []
	for pack in get_all_packs():
		if pack.debug_only:
			continue
		if not pack.visible_in_shop:
			continue
		shop_packs.append(pack)
	return shop_packs


func register_pack(pack: PackConfig) -> void:
	if pack.pack_id.is_empty():
		push_warning("PackDatabase: attempted to register a pack with an empty id.")
		return

	if _packs_by_id.has(pack.pack_id):
		push_warning("PackDatabase: duplicate pack_id '%s' — skipping." % pack.pack_id)
		return

	_packs_by_id[pack.pack_id] = pack


func _load_all_packs() -> void:
	var dir := DirAccess.open(PACKS_ROOT)
	if dir == null:
		push_warning("PackDatabase: could not open directory '%s'." % PACKS_ROOT)
		return

	for file_name in dir.get_files():
		if not file_name.ends_with(".tres"):
			continue
		var resource_path := PACKS_ROOT + "/" + file_name
		var resource := load(resource_path)
		if resource is PackConfig:
			register_pack(resource)
		else:
			push_warning("PackDatabase: '%s' is not a PackConfig resource." % resource_path)


func _print_load_summary() -> void:
	print("Loaded Packs: %d" % _packs_by_id.size())
	for pack_id in _packs_by_id.keys():
		var pack: PackConfig = _packs_by_id[pack_id]
		print("  - %s (%s)" % [pack_id, pack.display_name])
