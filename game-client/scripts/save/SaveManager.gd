## SaveManager.gd
## Handles save/load to local storage (SQLite for structured data, JSON for simple state).
## In online mode, defers to the server for persistence.
class_name SaveManager

extends Node

## ──────────────────────────────────────────────
##  Signals
## ──────────────────────────────────────────────

signal save_completed(slot: int)
signal load_completed(slot: int)
signal save_failed(slot: int, reason: String)

## ──────────────────────────────────────────────
##  Configuration
## ──────────────────────────────────────────────

const SAVE_DIR := "user://saves/"
const MAX_SLOTS := 10
const SAVE_VERSION := 1

## ──────────────────────────────────────────────
##  State
## ──────────────────────────────────────────────

var _current_slot: int = 0

## ──────────────────────────────────────────────
##  Lifecycle
## ──────────────────────────────────────────────

func _ready() -> void:
	_ensure_save_dir()

## ──────────────────────────────────────────────
##  Save
## ──────────────────────────────────────────────

func save_game(slot: int = 0) -> bool:
	_current_slot = slot
	var save_data := _collect_save_data()
	var path := _slot_path(slot)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		save_failed.emit(slot, "Cannot open file: %s" % path)
		DebugManager.log_error("SaveManager", "Cannot open save file: %s" % path)
		return false
	
	file.store_string(JSON.stringify(save_data))
	file.close()
	save_completed.emit(slot)
	DebugManager.log_info("SaveManager", "Game saved to slot %d (%s)" % [slot, path])
	return true

func _collect_save_data() -> Dictionary:
	var data := {
		"save_version": SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"game_version": GameManager.game_version,
		"player_data": GameManager.player_data,
		"world_seed": GameManager.world_seed,
	}
	
	# Collect subsystem state
	if WorldTime:
		data["world_time"] = WorldTime.serialize()
	if EconomyManager:
		data["economy"] = EconomyManager.serialize()
	if MemoryStore:
		data["memories"] = MemoryStore.serialize()
	if PlayerStats:
		data["player_stats"] = PlayerStats.serialize()
	if MoneySystem:
		data["money_system"] = MoneySystem.serialize()
	if InventorySystem:
		data["inventory_system"] = InventorySystem.serialize()
	if WorldServerBridge:
		data["server_mode"] = WorldServerBridge.current_mode
	
	return data

## ──────────────────────────────────────────────
##  Load
## ──────────────────────────────────────────────

func load_game(slot: int = 0) -> bool:
	_current_slot = slot
	var path := _slot_path(slot)
	if not FileAccess.file_exists(path):
		save_failed.emit(slot, "Save file does not exist")
		DebugManager.log_error("SaveManager", "Save file not found: %s" % path)
		return false
	
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		save_failed.emit(slot, "Cannot read file")
		return false
	
	var text := file.get_as_text()
	file.close()
	
	var parsed = JSON.parse_string(text)
	if not parsed is Dictionary:
		save_failed.emit(slot, "Corrupt save data")
		DebugManager.log_error("SaveManager", "Corrupt save data in slot %d" % slot)
		return false
	
	_apply_save_data(parsed)
	load_completed.emit(slot)
	DebugManager.log_info("SaveManager", "Game loaded from slot %d" % slot)
	return true

func _apply_save_data(data: Dictionary) -> void:
	GameManager.player_data = data.get("player_data", {})
	GameManager.world_seed = data.get("world_seed", 0)
	
	if data.has("world_time") and WorldTime:
		WorldTime.deserialize(data["world_time"])
	if data.has("economy") and EconomyManager:
		EconomyManager.deserialize(data["economy"])
	if data.has("memories") and MemoryStore:
		MemoryStore.deserialize(data["memories"])
	if data.has("player_stats") and PlayerStats:
		PlayerStats.deserialize(data["player_stats"])
	if data.has("money_system") and MoneySystem:
		MoneySystem.deserialize(data["money_system"])
	if data.has("inventory_system") and InventorySystem:
		InventorySystem.deserialize(data["inventory_system"])

## ──────────────────────────────────────────────
##  Slot Management
## ──────────────────────────────────────────────

func get_save_info(slot: int) -> Dictionary:
	var path := _slot_path(slot)
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if not parsed is Dictionary:
		return {}
	return {
		"slot": slot,
		"timestamp": parsed.get("timestamp", 0),
		"game_version": parsed.get("game_version", ""),
		"player_name": parsed.get("player_data", {}).get("name", "Unknown"),
		"save_version": parsed.get("save_version", 0),
	}

func list_saves() -> Array[Dictionary]:
	var saves: Array[Dictionary] = []
	for i in MAX_SLOTS:
		var info := get_save_info(i)
		if not info.is_empty():
			saves.append(info)
	return saves

func delete_save(slot: int) -> bool:
	var path := _slot_path(slot)
	var dir := DirAccess.open(SAVE_DIR)
	if dir and dir.file_exists(path.get_file()):
		dir.remove(path.get_file())
		DebugManager.log_info("SaveManager", "Deleted save slot %d" % slot)
		return true
	return false

func has_save(slot: int) -> bool:
	return FileAccess.file_exists(_slot_path(slot))

## ──────────────────────────────────────────────
##  Internal
## ──────────────────────────────────────────────

func _slot_path(slot: int) -> String:
	return "%sslot_%02d.json" % [SAVE_DIR, slot]

func _ensure_save_dir() -> void:
	var dir := DirAccess.open("user://")
	if dir and not dir.dir_exists("saves"):
		dir.make_dir("saves")
