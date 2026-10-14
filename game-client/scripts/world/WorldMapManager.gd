## WorldMapManager.gd
## Loads and exposes the hierarchical world map data for continents, countries, cities, districts, roads, and landmarks.
## Stage 1.3 (World Map Design)
extends Node

const MAP_PATH := "res://data/world/world_map_design.json"

var world_name: String = ""
var world_scale: Dictionary = {}
var geographic_layers: Array = []
var transport: Dictionary = {}
var landmark_categories: Dictionary = {}
var continents: Array = []
var regions: Array = []

func _ready() -> void:
	load_map()

func load_map() -> void:
	var file := FileAccess.open(MAP_PATH, FileAccess.READ)
	if file == null:
		DebugManager.log_error("WorldMapManager", "Unable to load %s" % MAP_PATH)
		return
	var text := file.get_as_text()
	file.close()
	var parsed := JSON.parse_string(text)
	if parsed is Dictionary:
		var world_data: Dictionary = parsed.get("world", {})
		world_name = world_data.get("name", "Unknown World")
		world_scale = world_data.get("scale", {})
		geographic_layers = world_data.get("geographic_layers", [])
		transport = world_data.get("transport", {})
		landmark_categories = world_data.get("landmark_categories", {})
		continents = parsed.get("continents", [])
		regions = parsed.get("regions", [])
		DebugManager.log_info("WorldMapManager", "Loaded world map: %s" % world_name)
	else:
		DebugManager.log_error("WorldMapManager", "Failed to parse %s" % MAP_PATH)

func get_continent(continent_id: String):
	for continent in continents:
		if continent.get("id", "") == continent_id:
			return continent
	return null

func get_country(continent_id: String, country_id: String):
	var continent = get_continent(continent_id)
	if continent == null:
		return null
	for country in continent.get("countries", []):
		if country.get("id", "") == country_id:
			return country
	return null

func get_city(continent_id: String, country_id: String, state_id: String, city_id: String):
	var country = get_country(continent_id, country_id)
	if country == null:
		return null
	for state in country.get("states", []):
		if state.get("id", "") == state_id:
			for city in state.get("cities", []):
				if city.get("id", "") == city_id:
					return city
	return null

func get_region(region_id: String):
	for region in regions:
		if region.get("id", "") == region_id:
			return region
	return null

func get_continent_names() -> Array[String]:
	var names: Array[String] = []
	for continent in continents:
		names.append(continent.get("name", ""))
	return names
