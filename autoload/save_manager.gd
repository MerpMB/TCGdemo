extends Node
## Versioned persistence boundary. It serializes and hydrates state but never
## coordinates gameplay transactions.


const SAVE_VERSION := 1
const SAVE_PATH := "user://tcg_save.json"
const TEMP_SAVE_PATH := "user://tcg_save.tmp"

var _player_statistics: Dictionary = {}
var _settings: Dictionary = {}
var _active_save_path := SAVE_PATH
var _active_temp_save_path := TEMP_SAVE_PATH


func _ready() -> void:
	call_deferred("load_game")


func save_game() -> bool:
	return save_runtime_state(PackInventoryManager.get_owned_counts())


func save_runtime_state(inventory_counts: Dictionary) -> bool:
	var dto := {
		"save_version": SAVE_VERSION,
		"collection": CollectionManager.export_save_data(),
		"inventory": inventory_counts.duplicate(),
		"player_statistics": _player_statistics.duplicate(),
		"settings": _settings.duplicate(),
		"selected_pack_id": GameManager.selected_pack_id,
	}
	return _write_dto(dto)


func load_game() -> bool:
	if not FileAccess.file_exists(_active_save_path):
		return true
	var file := FileAccess.open(_active_save_path, FileAccess.READ)
	if file == null:
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return false
	var dto := _migrate_to_current(parsed)
	if dto.is_empty() or not _is_valid_dto(dto):
		return false
	if not CollectionManager.hydrate_from_save_data(dto["collection"], CardDatabase):
		return false
	PackInventoryManager.apply_owned_counts(dto["inventory"])
	_player_statistics = dto["player_statistics"].duplicate()
	_settings = dto["settings"].duplicate()
	GameManager.set_selected_pack(String(dto["selected_pack_id"]))
	return true


func delete_save() -> bool:
	if not FileAccess.file_exists(_active_save_path):
		return true
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(_active_save_path)) == OK


func set_storage_paths_for_testing(save_path: String, temp_save_path: String) -> void:
	_active_save_path = save_path
	_active_temp_save_path = temp_save_path


func reset_storage_paths() -> void:
	_active_save_path = SAVE_PATH
	_active_temp_save_path = TEMP_SAVE_PATH

func get_player_statistics() -> Dictionary:
	return _player_statistics.duplicate()


func apply_player_statistics(statistics: Dictionary) -> void:
	_player_statistics = statistics.duplicate()


func get_settings() -> Dictionary:
	return _settings.duplicate()


func apply_settings(settings: Dictionary) -> void:
	_settings = settings.duplicate()


func _write_dto(dto: Dictionary) -> bool:
	var file := FileAccess.open(_active_temp_save_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(dto))
	file.flush()
	file.close()
	return DirAccess.rename_absolute(
		ProjectSettings.globalize_path(_active_temp_save_path),
		ProjectSettings.globalize_path(_active_save_path)
	) == OK


func _migrate_to_current(raw_dto: Dictionary) -> Dictionary:
	var version := int(raw_dto.get("save_version", 0))
	if version != SAVE_VERSION:
		return {}
	return raw_dto.duplicate(true)


func _is_valid_dto(dto: Dictionary) -> bool:
	return dto.has("collection") and dto["collection"] is Dictionary \
		and dto.has("inventory") and dto["inventory"] is Dictionary \
		and dto.has("player_statistics") and dto["player_statistics"] is Dictionary \
		and dto.has("settings") and dto["settings"] is Dictionary \
		and dto.has("selected_pack_id")
