extends Node

const SAVE_SCHEMA_VERSION := 1
const SAVE_DIR := "user://saves"
const SAVE_PATH := SAVE_DIR + "/slot_1.json"
const TEMP_SAVE_PATH := SAVE_DIR + "/slot_1.tmp"
const BACKUP_SAVE_PATH := SAVE_DIR + "/slot_1.bak"

func get_schema_version() -> int:
	return SAVE_SCHEMA_VERSION

func build_save(player: Node, world_state: Dictionary) -> Dictionary:
	var payload := {
		"schema_version": SAVE_SCHEMA_VERSION,
		"saved_at_unix": Time.get_unix_time_from_system(),
		"player": player.get_save_state() if player.has_method("get_save_state") else {},
		"world": world_state,
	}
	return {
		"checksum": _checksum(payload),
		"payload": payload,
	}

func save_game(player: Node, world_state: Dictionary) -> Dictionary:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))
	var save_data := build_save(player, world_state)
	var validation_error := validate_save_data(save_data)
	if validation_error != "":
		return {"ok": false, "message": validation_error}

	var temp_file := FileAccess.open(TEMP_SAVE_PATH, FileAccess.WRITE)
	if temp_file == null:
		return {"ok": false, "message": "Unable to open temp save for writing."}
	temp_file.store_string(JSON.stringify(save_data, "\t"))
	temp_file.close()

	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(SAVE_PATH), ProjectSettings.globalize_path(BACKUP_SAVE_PATH))
	var rename_error := DirAccess.rename_absolute(ProjectSettings.globalize_path(TEMP_SAVE_PATH), ProjectSettings.globalize_path(SAVE_PATH))
	if rename_error != OK:
		return {"ok": false, "message": "Unable to replace save file."}
	return {"ok": true, "message": "Game saved."}

func load_game(player: Node) -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {"ok": false, "message": "No save file found."}
	var save_file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if save_file == null:
		return {"ok": false, "message": "Unable to open save file."}
	var parsed = JSON.parse_string(save_file.get_as_text())
	save_file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"ok": false, "message": "Save file is not valid JSON."}
	var validation_error := validate_save_data(parsed)
	if validation_error != "":
		return {"ok": false, "message": validation_error}
	var payload: Dictionary = parsed["payload"]
	if player.has_method("apply_save_state"):
		player.apply_save_state(payload.get("player", {}))
	return {"ok": true, "message": "Game loaded.", "world": payload.get("world", {})}

func validate_save_data(save_data: Variant) -> String:
	if typeof(save_data) != TYPE_DICTIONARY:
		return "Save root must be a dictionary."
	if not save_data.has("payload") or not save_data.has("checksum"):
		return "Save requires payload and checksum."
	var payload: Variant = save_data["payload"]
	if typeof(payload) != TYPE_DICTIONARY:
		return "Save payload must be a dictionary."
	if int(payload.get("schema_version", -1)) != SAVE_SCHEMA_VERSION:
		return "Unsupported save schema version."
	if str(save_data["checksum"]) != _checksum(payload):
		return "Save checksum mismatch; refusing to load corrupted data."
	if typeof(payload.get("player", {})) != TYPE_DICTIONARY:
		return "Save player state must be a dictionary."
	if typeof(payload.get("world", {})) != TYPE_DICTIONARY:
		return "Save world state must be a dictionary."
	return ""

func _checksum(payload: Dictionary) -> String:
	return JSON.stringify(payload).sha256_text()
