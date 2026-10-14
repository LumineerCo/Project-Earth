## BuildingManager.gd
## Global manager for building data, generation, and queries.
## Loads building definitions from JSON and coordinates BuildingGenerator.
## Stage 3.3 (Buildings & Modular Assets)
extends Node

## ──────────────────────────────────────────────
##  Configuration
## ──────────────────────────────────────────────

const BUILDINGS_DATA_PATH := "res://data/buildings/nova_city_buildings.json"
const BUILDING_GENERATOR_SCRIPT := "res://scripts/world/BuildingGenerator.gd"

## ──────────────────────────────────────────────
##  State
## ──────────────────────────────────────────────

var _generator: BuildingGenerator = null
var _building_defs: Array[BuildingData] = []
var _is_loaded: bool = false

## ──────────────────────────────────────────────
##  Signals
## ──────────────────────────────────────────────

signal buildings_loaded(count: int)
signal buildings_generated(count: int)

## ──────────────────────────────────────────────
##  Lifecycle
## ──────────────────────────────────────────────

func _ready() -> void:
	_generator = load(BUILDING_GENERATOR_SCRIPT).new()
	_generator.name = "BuildingGenerator"
	add_child(_generator)
	_generator.building_placed.connect(_on_building_placed)
	_generator.generation_complete.connect(_on_generation_complete)

## ──────────────────────────────────────────────
##  Public API — Loading
## ──────────────────────────────────────────────

func load_building_data() -> int:
	"""Load building definitions from JSON. Returns count loaded."""
	_building_defs.clear()
	if not FileAccess.file_exists(BUILDINGS_DATA_PATH):
		_log_warn("Buildings data file not found: %s" % BUILDINGS_DATA_PATH)
		_is_loaded = false
		return 0
	var file := FileAccess.open(BUILDINGS_DATA_PATH, FileAccess.READ)
	if file == null:
		_log_error("Cannot open buildings data: %s" % BUILDINGS_DATA_PATH)
		_is_loaded = false
		return 0
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		_log_error("JSON parse error: %s (line %d)" % [json.get_error_message(), json.get_error_line()])
		_is_loaded = false
		return 0
	var data = json.get_data()
	if not data is Dictionary:
		_log_error("Invalid buildings data format")
		_is_loaded = false
		return 0
	var buildings: Array = data.get("buildings", [])
	for bdef in buildings:
		_building_defs.append(BuildingData.from_dict(bdef))
	_is_loaded = true
	_log_info("Loaded %d building definitions" % _building_defs.size())
	buildings_loaded.emit(_building_defs.size())
	return _building_defs.size()

## ──────────────────────────────────────────────
##  Public API — Generation
## ──────────────────────────────────────────────

func generate_buildings(city_manager: Node, parent: Node3D) -> int:
	"""Generate buildings for a city. Returns count placed."""
	if _generator == null:
		_log_error("BuildingGenerator not initialized")
		return 0
	# First load explicit building definitions from JSON
	var json_count := _generator.load_from_json(BUILDINGS_DATA_PATH, parent)
	# Then procedurally fill remaining district space
	var proc_count := _generator.generate_for_city(city_manager, parent)
	var total := json_count + proc_count
	_log_info("Generated %d buildings (JSON: %d, procedural: %d)" % [total, json_count, proc_count])
	buildings_generated.emit(total)
	return total

func generate_district_buildings(district: Dictionary, parent: Node3D) -> int:
	"""Generate buildings for a single district. Returns count placed."""
	if _generator == null:
		return 0
	return _generator.generate_for_district(district, parent)

## ──────────────────────────────────────────────
##  Public API — Queries
## ──────────────────────────────────────────────

func get_generator() -> BuildingGenerator:
	return _generator

func get_building_count() -> int:
	if _generator:
		return _generator.get_building_count()
	return 0

func get_buildings() -> Array[BuildingBase]:
	if _generator:
		return _generator.get_buildings()
	return []

func get_buildings_in_district(district_id: String) -> Array[BuildingBase]:
	if _generator:
		return _generator.get_buildings_in_district(district_id)
	return []

func get_building_at(pos: Vector3, radius: float = 5.0) -> BuildingBase:
	if _generator:
		return _generator.get_building_at(pos, radius)
	return null

func get_building_definitions() -> Array[BuildingData]:
	return _building_defs

func get_building_definition(building_id: String) -> BuildingData:
	for bd in _building_defs:
		if bd.building_id == building_id:
			return bd
	return null

func is_loaded() -> bool:
	return _is_loaded

func clear_all() -> void:
	if _generator:
		_generator.clear_buildings()
	_building_defs.clear()
	_is_loaded = false

## ──────────────────────────────────────────────
##  Serialization
## ──────────────────────────────────────────────

func serialize() -> Dictionary:
	var buildings: Array = []
	if _generator:
		buildings = _generator.serialize()
	return {
		"is_loaded": _is_loaded,
		"definition_count": _building_defs.size(),
		"buildings": buildings,
	}

## ──────────────────────────────────────────────
##  Signal Handlers
## ──────────────────────────────────────────────

func _on_building_placed(_building: BuildingBase) -> void:
	pass  # Can be used for stats tracking

func _on_generation_complete(count: int) -> void:
	_log_debug("Generation complete: %d buildings" % count)

## ──────────────────────────────────────────────
##  Helpers
## ──────────────────────────────────────────────

func _log_debug(msg: String) -> void:
	if has_node("/root/DebugManager"):
		DebugManager.log_debug("BuildingMgr", msg)

func _log_info(msg: String) -> void:
	if has_node("/root/DebugManager"):
		DebugManager.log_info("BuildingMgr", msg)

func _log_warn(msg: String) -> void:
	if has_node("/root/DebugManager"):
		DebugManager.log_warn("BuildingMgr", msg)

func _log_error(msg: String) -> void:
	if has_node("/root/DebugManager"):
		DebugManager.log_error("BuildingMgr", msg)
