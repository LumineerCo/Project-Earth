## ContinentGeographyManager.gd
## Loads and exposes continent-scale geography data: oceans, mountains, rivers, climate zones, resources, and continent profiles.
## Stage 1.4 (Continent Layout & Planet Geography)
extends Node

const GEOGRAPHY_PATH := "res://data/world/continent_geography.json"

var planet_rules: Dictionary = {}
var oceans: Array = []
var mountain_ranges: Array = []
var river_systems: Array = []
var climate_zones: Array = []
var resources: Array = []
var continents: Array = []

func _ready() -> void:
	load_geography()

func load_geography() -> void:
	var file := FileAccess.open(GEOGRAPHY_PATH, FileAccess.READ)
	if file == null:
		DebugManager.log_error("ContinentGeographyManager", "Unable to load %s" % GEOGRAPHY_PATH)
		return
	var text := file.get_as_text()
	file.close()
	var parsed := JSON.parse_string(text)
	if parsed is Dictionary:
		planet_rules = parsed.get("planet_rules", {})
		oceans = parsed.get("oceans", [])
		mountain_ranges = parsed.get("mountain_ranges", [])
		river_systems = parsed.get("river_systems", [])
		climate_zones = parsed.get("climate_zones", [])
		resources = parsed.get("resources", [])
		continents = parsed.get("continents", [])
		DebugManager.log_info("ContinentGeographyManager", "Loaded continent geography")
	else:
		DebugManager.log_error("ContinentGeographyManager", "Failed to parse %s" % GEOGRAPHY_PATH)

func get_continent(continent_id: String):
	for continent in continents:
		if continent.get("id", "") == continent_id:
			return continent
	return null

func get_mountain_range(range_id: String):
	for range_data in mountain_ranges:
		if range_data.get("id", "") == range_id:
			return range_data
	return null

func get_river(river_id: String):
	for river in river_systems:
		if river.get("id", "") == river_id:
			return river
	return null

func get_climate_zone(zone_id: String):
	for zone in climate_zones:
		if zone.get("id", "") == zone_id:
			return zone
	return null

func get_resource(resource_id: String):
	for resource_data in resources:
		if resource_data.get("id", "") == resource_id:
			return resource_data
	return null

func get_continent_names() -> Array[String]:
	var names: Array[String] = []
	for continent in continents:
		names.append(continent.get("name", ""))
	return names
