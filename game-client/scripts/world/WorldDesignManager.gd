## WorldDesignManager.gd
## Loads and exposes the planet/world design data for gameplay and world generation.
## Stage 1.2 (Planet & World Design)
extends Node

const DESIGN_PATH := "res://data/world/planet_design.json"

var planet_name: String = ""
var planet_type: String = ""
var gravity: float = 9.81
var day_length_hours: float = 24.0
var year_days: float = 365.0
var seasons: Array = []
var climate_zones: Array = []
var biomes: Array = []
var continents: Array = []

func _ready() -> void:
	load_design()

func load_design() -> void:
	var file := FileAccess.open(DESIGN_PATH, FileAccess.READ)
	if file == null:
		DebugManager.log_error("WorldDesignManager", "Unable to load %s" % DESIGN_PATH)
		return
	var text := file.get_as_text()
	file.close()
	var parsed := JSON.parse_string(text)
	if parsed is Dictionary:
		planet_name = parsed.get("name", "Unknown Planet")
		planet_type = parsed.get("planet_type", "rocky")
		gravity = float(parsed.get("gravity", 9.81))
		day_length_hours = float(parsed.get("day_length_hours", 24.0))
		year_days = float(parsed.get("year_days", 365.0))
		seasons = parsed.get("seasons", [])
		climate_zones = parsed.get("climate_zones", [])
		biomes = parsed.get("biomes", [])
		continents = parsed.get("continents", [])
		DebugManager.log_info("WorldDesignManager", "Loaded world design for %s" % planet_name)
	else:
		DebugManager.log_error("WorldDesignManager", "Failed to parse %s" % DESIGN_PATH)

func get_climate_zone(zone_id: String):
	for zone in climate_zones:
		if zone.get("id", "") == zone_id:
			return zone
	return null

func get_biome(biome_id: String):
	for biome in biomes:
		if biome.get("id", "") == biome_id:
			return biome
	return null

func get_continent(continent_id: String):
	for continent in continents:
		if continent.get("id", "") == continent_id:
			return continent
	return null

func get_continent_names() -> Array[String]:
	var names: Array[String] = []
	for continent in continents:
		names.append(continent.get("name", ""))
	return names
