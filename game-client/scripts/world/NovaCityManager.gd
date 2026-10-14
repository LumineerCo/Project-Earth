## NovaCityManager.gd
## Loads and exposes the Nova City definition for Stage 3 (First City).
## Provides district queries, spawn point access, and road network data.
## Stage 3.1 (First City - Nova City Setup)
extends Node

const CITY_PATH := "res://data/cities/nova_city.json"

var city_id: String = ""
var city_name: String = ""
var country_id: String = ""
var region_id: String = ""
var population: int = 0
var founded_year: int = 0
var coordinates: Dictionary = {}
var world_offset: Vector3 = Vector3.ZERO
var bounds: Dictionary = {}
var districts: Array = []
var road_network: Dictionary = {}
var spawn_points: Dictionary = {}

signal city_loaded(city_data: Dictionary)
signal city_load_failed(reason: String)

func _ready() -> void:
	load_city()

func load_city() -> void:
	var file := FileAccess.open(CITY_PATH, FileAccess.READ)
	if file == null:
		var reason := "Unable to open %s" % CITY_PATH
		DebugManager.log_error("NovaCityManager", reason)
		city_load_failed.emit(reason)
		return
	var text := file.get_as_text()
	file.close()
	var parsed := JSON.parse_string(text)
	if not (parsed is Dictionary):
		var reason := "Failed to parse %s" % CITY_PATH
		DebugManager.log_error("NovaCityManager", reason)
		city_load_failed.emit(reason)
		return
	_apply_city_data(parsed)
	city_loaded.emit(parsed)
	DebugManager.log_info("NovaCityManager", "Loaded city: %s (%d districts)" % [city_name, districts.size()])

func _apply_city_data(data: Dictionary) -> void:
	city_id = data.get("city_id", "")
	city_name = data.get("city_name", "Unknown")
	country_id = data.get("country_id", "")
	region_id = data.get("region_id", "")
	population = int(data.get("population", 0))
	founded_year = int(data.get("founded_year", 0))
	coordinates = data.get("coordinates", {})
	var offset_arr: Array = data.get("world_offset", [0, 0, 0])
	world_offset = _array_to_vector3(offset_arr)
	bounds = data.get("bounds", {})
	districts = data.get("districts", [])
	road_network = data.get("road_network", {})
	spawn_points = data.get("spawn_points", {})

func _array_to_vector3(arr: Array) -> Vector3:
	if arr.size() >= 3:
		return Vector3(float(arr[0]), float(arr[1]), float(arr[2]))
	return Vector3.ZERO

func get_district(district_id: String) -> Dictionary:
	for district in districts:
		if district.get("district_id", "") == district_id:
			return district
	return {}

func get_districts() -> Array:
	return districts

func get_district_count() -> int:
	return districts.size()

func get_district_at_position(pos: Vector3) -> Dictionary:
	for district in districts:
		var b: Dictionary = district.get("bounds", {})
		if b.is_empty():
			continue
		var min_x := float(b.get("min_x", 0.0))
		var max_x := float(b.get("max_x", 0.0))
		var min_z := float(b.get("min_z", 0.0))
		var max_z := float(b.get("max_z", 0.0))
		if pos.x >= min_x and pos.x <= max_x and pos.z >= min_z and pos.z <= max_z:
			return district
	return {}

func get_spawn_point(point_id: String) -> Vector3:
	var arr: Array = spawn_points.get(point_id, [])
	return _array_to_vector3(arr)

func get_player_spawn() -> Vector3:
	return get_spawn_point("player_default")

func get_npc_spawn_points() -> Array[Vector3]:
	var points: Array[Vector3] = []
	for key in spawn_points.keys():
		if key.begins_with("npc_"):
			points.append(get_spawn_point(key))
	return points

func get_random_npc_spawn() -> Vector3:
	var points := get_npc_spawn_points()
	if points.is_empty():
		return get_player_spawn()
	return points.pick_random()

func get_road_network() -> Dictionary:
	return road_network

func get_main_avenues() -> Array:
	return road_network.get("main_avenues", [])

func get_collectors() -> Array:
	return road_network.get("collectors", [])

func get_city_bounds() -> Dictionary:
	return bounds

func is_within_city(pos: Vector3) -> bool:
	if bounds.is_empty():
		return false
	var min_x := float(bounds.get("min_x", 0.0))
	var max_x := float(bounds.get("max_x", 0.0))
	var min_z := float(bounds.get("min_z", 0.0))
	var max_z := float(bounds.get("max_z", 0.0))
	return pos.x >= min_x and pos.x <= max_x and pos.z >= min_z and pos.z <= max_z

func serialize() -> Dictionary:
	return {
		"city_id": city_id,
		"city_name": city_name,
		"country_id": country_id,
		"region_id": region_id,
		"population": population,
		"founded_year": founded_year,
		"world_offset": [world_offset.x, world_offset.y, world_offset.z]
	}
