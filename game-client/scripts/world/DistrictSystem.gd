## DistrictSystem.gd
## Spatial zoning system for Nova City. Wraps NovaCityManager district data with
## gameplay-relevant queries: speed limits, ambient sounds, build rules, and
## runtime DistrictZone Area3D registration.
## Stage 3.7 (City Districts & Zoning)
extends Node

const DEFAULT_SPEED_LIMIT := 50.0
const DEFAULT_AMBIENT := "city_ambient_default"

## Per zone_type configuration: speed limit (km/h), ambient sound id, build height min.
const ZONE_TYPE_PROFILES := {
	"commercial_high": {"speed_limit": 40.0, "ambient": "city_traffic_heavy", "height_min": 15.0},
	"commercial_low": {"speed_limit": 40.0, "ambient": "city_traffic_moderate", "height_min": 10.0},
	"residential_low": {"speed_limit": 30.0, "ambient": "residential_ambient", "height_min": 6.0},
	"residential_high": {"speed_limit": 35.0, "ambient": "residential_ambient", "height_min": 10.0},
	"industrial": {"speed_limit": 50.0, "ambient": "industrial_ambient", "height_min": 10.0},
	"civic": {"speed_limit": 30.0, "ambient": "civic_ambient", "height_min": 15.0},
	"park": {"speed_limit": 20.0, "ambient": "park_ambient", "height_min": 4.0},
	"leisure": {"speed_limit": 20.0, "ambient": "coastal_ambient", "height_min": 4.0},
	"highway": {"speed_limit": 90.0, "ambient": "highway_ambient", "height_min": 6.0}
}

## Runtime Area3D zones registered by scenes (optional, supplements JSON data).
var _runtime_zones: Array = []

signal zone_registered(zone: Node)
signal zone_unregistered(zone: Node)

## Returns the district data dictionary at a world position, or empty dict if none.
func get_district_at(point: Vector3) -> Dictionary:
	var nova := _get_nova_city_manager()
	if nova != null and nova.has_method("get_district_at_position"):
		return nova.get_district_at_position(point)
	return {}

## Returns the DistrictZone Area3D at a point, or null. Runtime zones take priority.
func get_runtime_zone_at(point: Vector3) -> Node:
	for zone in _runtime_zones:
		if zone == null or not is_instance_valid(zone):
			continue
		if zone.has_method("contains_point") and zone.contains_point(point):
			return zone
	return null

## Returns the speed limit (km/h) at a position.
func get_speed_limit_at(point: Vector3) -> float:
	var zone := get_runtime_zone_at(point)
	if zone != null and "speed_limit" in zone:
		return float(zone.speed_limit)
	var district := get_district_at(point)
	if district.is_empty():
		return DEFAULT_SPEED_LIMIT
	return _profile_value(district, "speed_limit", DEFAULT_SPEED_LIMIT)

## Returns the ambient sound id at a position.
func get_ambient_sound_at(point: Vector3) -> String:
	var zone := get_runtime_zone_at(point)
	if zone != null and "ambient_sound" in zone:
		return String(zone.ambient_sound)
	var district := get_district_at(point)
	if district.is_empty():
		return DEFAULT_AMBIENT
	return _profile_value(district, "ambient", DEFAULT_AMBIENT)

## Returns build height range [min, max] for a position.
func get_build_height_range(point: Vector3) -> Vector2:
	var district := get_district_at(point)
	if district.is_empty():
		return Vector2(6.0, 40.0)
	var zone_type := String(district.get("zone_type", ""))
	var profile: Dictionary = ZONE_TYPE_PROFILES.get(zone_type, {})
	var h_min := float(profile.get("height_min", 6.0))
	var h_max := float(district.get("max_height", 40.0))
	return Vector2(h_min, h_max)

## Returns the building density (0.0–1.0) at a position.
func get_building_density_at(point: Vector3) -> float:
	var district := get_district_at(point)
	if district.is_empty():
		return 0.5
	return float(district.get("building_density", 0.5))

## Returns the population density (0.0–1.0) at a position.
func get_population_density_at(point: Vector3) -> float:
	var district := get_district_at(point)
	if district.is_empty():
		return 0.5
	return float(district.get("population_density", 0.5))

## Registers a runtime DistrictZone Area3D node.
func register_zone(zone: Node) -> void:
	if zone == null or _runtime_zones.has(zone):
		return
	_runtime_zones.append(zone)
	zone_registered.emit(zone)
	DebugManager.log_debug("DistrictSystem", "Registered runtime zone: %s" % (zone.district_name if "district_name" in zone else str(zone)))

## Unregisters a runtime zone.
func unregister_zone(zone: Node) -> void:
	var idx := _runtime_zones.find(zone)
	if idx >= 0:
		_runtime_zones.remove_at(idx)
		zone_unregistered.emit(zone)

## Returns all runtime zones.
func get_runtime_zones() -> Array:
	return _runtime_zones

## Returns the count of districts from NovaCityManager.
func get_district_count() -> int:
	var nova := _get_nova_city_manager()
	if nova != null and nova.has_method("get_district_count"):
		return nova.get_district_count()
	return 0

func _get_nova_city_manager() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.get_root().get_node_or_null("NovaCityManager")

func _profile_value(district: Dictionary, key: String, fallback) -> Variant:
	var zone_type := String(district.get("zone_type", ""))
	var profile: Dictionary = ZONE_TYPE_PROFILES.get(zone_type, {})
	return profile.get(key, fallback)
