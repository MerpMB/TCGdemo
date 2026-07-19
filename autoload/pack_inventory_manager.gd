extends Node
## Runtime ownership for unopened packs. Pack definitions remain in PackDatabase.
## SaveManager can later persist via get_owned_counts() / apply_owned_counts().


signal inventory_changed(pack_id: String, owned_count: int)


const INITIAL_COUNTS: Dictionary = {
	"knight_pack": 0,
	"mage_pack": 0,
	"priest_pack": 0,
	"rogue_pack": 0,
}


var _owned_counts: Dictionary = INITIAL_COUNTS.duplicate()


func add_pack(pack_id: String, amount: int = 1) -> void:
	if pack_id.is_empty() or amount <= 0:
		return
	var new_count := get_owned_count(pack_id) + amount
	_owned_counts[pack_id] = new_count
	inventory_changed.emit(pack_id, new_count)


func remove_pack(pack_id: String, amount: int = 1) -> bool:
	if pack_id.is_empty() or amount <= 0:
		return false
	var current_count := get_owned_count(pack_id)
	if current_count < amount:
		return false
	var new_count := current_count - amount
	_owned_counts[pack_id] = new_count
	inventory_changed.emit(pack_id, new_count)
	return true


func consume_pack(pack_id: String, amount: int = 1) -> bool:
	return remove_pack(pack_id, amount)


func get_owned_count(pack_id: String) -> int:
	return maxi(int(_owned_counts.get(pack_id, 0)), 0)


func can_open_pack(pack_id: String) -> bool:
	return get_owned_count(pack_id) > 0


func get_owned_counts() -> Dictionary:
	return _owned_counts.duplicate()


func apply_owned_counts(counts: Dictionary) -> void:
	_owned_counts = counts.duplicate()
	for pack_id in _owned_counts:
		inventory_changed.emit(pack_id, get_owned_count(pack_id))


func reset_runtime_data() -> void:
	_owned_counts = INITIAL_COUNTS.duplicate()
	for pack_id in _owned_counts:
		inventory_changed.emit(pack_id, get_owned_count(pack_id))
