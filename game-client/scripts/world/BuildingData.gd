## BuildingData.gd
## Data model representing a building definition loaded from JSON.
## Stage 3.3 (Buildings & Modular Assets)
extends RefCounted
class_name BuildingData

## ──────────────────────────────────────────────
##  Fields
## ──────────────────────────────────────────────

var building_id: String = ""
var building_name: String = ""
var category: String = "shell"  ## full_interior | partial_interior | shell
var district_id: String = ""
var zone_type: String = ""

# Dimensions (meters)
var width: float = 12.0
var depth: float = 12.0
var height: float = 15.0
var floors: int = 4

# Visual
var color_primary: Color = Color(0.7, 0.7, 0.7)
var color_secondary: Color = Color(0.5, 0.5, 0.5)
var roof_type: String = "flat"  ## flat | pitched | domed
var window_density: float = 0.6  ## 0.0 to 1.0

# Interior
var interior_scene_path: String = ""
var is_enterable: bool = false

# Economy
var shop_id: String = ""  ## Linked shop if this is a commercial building
var job_ids: Array[String] = []

# Position (for procedural placement)
var position: Vector3 = Vector3.ZERO
var rotation_y: float = 0.0

## ──────────────────────────────────────────────
##  Factory
## ──────────────────────────────────────────────

static func from_dict(data: Dictionary) -> BuildingData:
	var bd := BuildingData.new()
	bd.building_id = data.get("building_id", "")
	bd.building_name = data.get("building_name", "")
	bd.category = data.get("category", "shell")
	bd.district_id = data.get("district_id", "")
	bd.zone_type = data.get("zone_type", "")
	bd.width = float(data.get("width", 12.0))
	bd.depth = float(data.get("depth", 12.0))
	bd.height = float(data.get("height", 15.0))
	bd.floors = int(data.get("floors", 4))
	bd.color_primary = _parse_color(data.get("color_primary", [0.7, 0.7, 0.7]))
	bd.color_secondary = _parse_color(data.get("color_secondary", [0.5, 0.5, 0.5]))
	bd.roof_type = data.get("roof_type", "flat")
	bd.window_density = float(data.get("window_density", 0.6))
	bd.interior_scene_path = data.get("interior_scene_path", "")
	bd.is_enterable = bool(data.get("is_enterable", false))
	bd.shop_id = data.get("shop_id", "")
	var jobs: Array = data.get("job_ids", [])
	for j in jobs:
		bd.job_ids.append(str(j))
	var pos: Array = data.get("position", [0.0, 0.0, 0.0])
	if pos.size() >= 3:
		bd.position = Vector3(float(pos[0]), float(pos[1]), float(pos[2]))
	bd.rotation_y = float(data.get("rotation_y", 0.0))
	return bd

## ──────────────────────────────────────────────
##  Public API
## ──────────────────────────────────────────────

func get_footprint_area() -> float:
	return width * depth

func get_volume() -> float:
	return width * depth * height

func get_floor_height() -> float:
	if floors <= 0:
		return height
	return height / float(floors)

func is_commercial() -> bool:
	return zone_type.begins_with("commercial") or shop_id != ""

func is_residential() -> bool:
	return zone_type.begins_with("residential")

func is_industrial() -> bool:
	return zone_type.begins_with("industrial")

func is_civic() -> bool:
	return zone_type == "civic"

func is_park() -> bool:
	return zone_type == "park"

func serialize() -> Dictionary:
	return {
		"building_id": building_id,
		"building_name": building_name,
		"category": category,
		"district_id": district_id,
		"zone_type": zone_type,
		"width": width,
		"depth": depth,
		"height": height,
		"floors": floors,
		"color_primary": [color_primary.r, color_primary.g, color_primary.b],
		"color_secondary": [color_secondary.r, color_secondary.g, color_secondary.b],
		"roof_type": roof_type,
		"window_density": window_density,
		"interior_scene_path": interior_scene_path,
		"is_enterable": is_enterable,
		"shop_id": shop_id,
		"job_ids": job_ids.duplicate(),
		"position": [position.x, position.y, position.z],
		"rotation_y": rotation_y,
	}

## ──────────────────────────────────────────────
##  Helpers
## ──────────────────────────────────────────────

static func _parse_color(arr) -> Color:
	if arr is Array and arr.size() >= 3:
		return Color(float(arr[0]), float(arr[1]), float(arr[2]))
	return Color(0.7, 0.7, 0.7)
