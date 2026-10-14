## PoliticalDesignManager.gd
## Loads and exposes political and societal design data for countries, governments, laws, services, and culture.
## Stage 1.5 (Country & Political Design)
extends Node

const POLITICAL_PATH := "res://data/world/political_design.json"

var world_structure: Dictionary = {}
var countries: Array = []

func _ready() -> void:
	load_political_design()

func load_political_design() -> void:
	var file := FileAccess.open(POLITICAL_PATH, FileAccess.READ)
	if file == null:
		DebugManager.log_error("PoliticalDesignManager", "Unable to load %s" % POLITICAL_PATH)
		return
	var text := file.get_as_text()
	file.close()
	var parsed := JSON.parse_string(text)
	if parsed is Dictionary:
		world_structure = parsed.get("world_structure", {})
		countries = parsed.get("countries", [])
		DebugManager.log_info("PoliticalDesignManager", "Loaded political design (%d countries)" % countries.size())
	else:
		DebugManager.log_error("PoliticalDesignManager", "Failed to parse %s" % POLITICAL_PATH)

func get_country(country_id: String):
	for country in countries:
		if country.get("id", "") == country_id:
			return country
	return null

func get_country_names() -> Array[String]:
	var names: Array[String] = []
	for country in countries:
		names.append(country.get("name", ""))
	return names

func get_country_by_continent(continent_id: String) -> Array:
	var results: Array = []
	for country in countries:
		if country.get("continent", "") == continent_id:
			results.append(country)
	return results
