## BuildingGenerator.gd
## Procedurally generates and places buildings within Nova City districts.
## Creates BuildingBase nodes with BoxMesh shells, applies district zoning rules,
## and populates the city with Category A/B/C buildings.
## Stage 3.3 (Buildings & Modular Assets)
extends Node
class_name BuildingGenerator

## ──────────────────────────────────────────────
##  Configuration
## ──────────────────────────────────────────────

const GRID_CELL_SIZE := 16.0  ## meters — building footprint grid
const ROAD_OFFSET := 8.0      ## meters — keep buildings off roads
const MIN_BUILDING_HEIGHT := 8.0
const MAX_BUILDING_HEIGHT := 80.0

## ──────────────────────────────────────────────
##  State
## ──────────────────────────────────────────────

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _buildings: Array[BuildingBase] = []
var _building_data: Array[BuildingData] = []

## ──────────────────────────────────────────────
##  Signals
## ──────────────────────────────────────────────

signal building_placed(building: BuildingBase)
signal generation_complete(building_count: int)

## ──────────────────────────────────────────────
##  Lifecycle
## ──────────────────────────────────────────────

func _ready() -> void:
	_rng.seed = GameManager.world_seed if GameManager else randi()

## ──────────────────────────────────────────────
##  Public API — Generate from City Data
## ──────────────────────────────────────────────

func generate_for_city(city_manager: Node, parent: Node3D) -> int:
	"""Generate buildings for all districts in a city. Returns count placed."""
	if city_manager == null:
		_log_error("City manager is null")
		return 0
	var count := 0
	var districts: Array = city_manager.get_districts()
	for district in districts:
		count += _generate_district(district, parent)
	_log_info("Generated %d buildings across %d districts" % [count, districts.size()])
	generation_complete.emit(count)
	return count

func generate_for_district(district: Dictionary, parent: Node3D) -> int:
	"""Generate buildings for a single district. Returns count placed."""
	return _generate_district(district, parent)

## ──────────────────────────────────────────────
##  Public API — From BuildingData
## ──────────────────────────────────────────────

func place_building(data: BuildingData, parent: Node3D) -> BuildingBase:
	"""Place a single building from BuildingData at its defined position."""
	var building := _create_building_from_data(data)
	building.global_position = data.position
	building.global_rotation.y = data.rotation_y
	parent.add_child(building)
	_buildings.append(building)
	building_placed.emit(building)
	return building

func load_from_json(path: String, parent: Node3D) -> int:
	"""Load building definitions from a JSON file and place them. Returns count."""
	if not FileAccess.file_exists(path):
		_log_error("Building data file not found: %s" % path)
		return 0
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_log_error("Cannot open building data: %s" % path)
		return 0
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		_log_error("JSON parse error in %s: %s (line %d)" % [path, json.get_error_message(), json.get_error_line()])
		return 0
	var data = json.get_data()
	if not data is Dictionary:
		_log_error("Invalid building data format in %s" % path)
		return 0
	var buildings: Array = data.get("buildings", [])
	var count := 0
	for bdef in buildings:
		var bd := BuildingData.from_dict(bdef)
		_building_data.append(bd)
		place_building(bd, parent)
		count += 1
	_log_info("Loaded %d buildings from %s" % [count, path])
	return count

## ──────────────────────────────────────────────
##  District Generation
## ──────────────────────────────────────────────

func _generate_district(district: Dictionary, parent: Node3D) -> int:
	var district_id: String = district.get("id", "")
	var zone_type: String = district.get("zone_type", "residential_low")
	var bounds: Dictionary = district.get("bounds", {})
	var density: float = float(district.get("building_density", 0.5))
	var max_height: float = float(district.get("max_height", 30.0))

	if bounds.is_empty():
		_log_warn("District %s has no bounds — skipping" % district_id)
		return 0

	var min_x := float(bounds.get("min_x", -100.0))
	var max_x := float(bounds.get("max_x", 100.0))
	var min_z := float(bounds.get("min_z", -100.0))
	var max_z := float(bounds.get("max_z", 100.0))

	var count := 0
	var cells_x := int((max_x - min_x) / GRID_CELL_SIZE)
	var cells_z := int((max_z - min_z) / GRID_CELL_SIZE)

	for cx in range(cells_x):
		for cz in range(cells_z):
			# Density check — skip some cells for parks/empty lots
			if _rng.randf() > density:
				continue
			var pos := Vector3(
				min_x + (cx + 0.5) * GRID_CELL_SIZE,
				0.0,
				min_z + (cz + 0.5) * GRID_CELL_SIZE
			)
			var bd := _generate_building_data(district_id, zone_type, pos, max_height)
			var building := _create_building_from_data(bd)
			building.global_position = pos
			building.global_rotation.y = _rng.randf() * 0.1  # Slight variation
			parent.add_child(building)
			_buildings.append(building)
			building_placed.emit(building)
			count += 1
	_log_info("District %s: placed %d buildings" % [district_id, count])
	return count

## ──────────────────────────────────────────────
##  Building Data Generation
## ──────────────────────────────────────────────

func _generate_building_data(district_id: String, zone_type: String, pos: Vector3, max_height: float) -> BuildingData:
	var bd := BuildingData.new()
	bd.building_id = "%s_b_%04d" % [district_id, _rng.randi() % 10000]
	bd.district_id = district_id
	bd.zone_type = zone_type
	bd.position = pos

	# Determine category based on zone
	match zone_type:
		"commercial_high":
			bd.category = "shell"
			bd.height = _rng.randf_range(30.0, min(max_height, MAX_BUILDING_HEIGHT))
			bd.floors = int(bd.height / 3.5)
			bd.color_primary = _random_color(0.3, 0.6)
		"commercial_low":
			bd.category = "partial_interior"
			bd.height = _rng.randf_range(8.0, 15.0)
			bd.floors = 2
			bd.is_enterable = true
			bd.color_primary = _random_color(0.5, 0.8)
		"residential_high":
			bd.category = "shell"
			bd.height = _rng.randf_range(20.0, min(max_height, 50.0))
			bd.floors = int(bd.height / 3.5)
			bd.color_primary = _random_color(0.6, 0.85)
		"residential_low":
			bd.category = "full_interior"
			bd.height = _rng.randf_range(6.0, 12.0)
			bd.floors = 2
			bd.is_enterable = true
			bd.color_primary = _random_color(0.65, 0.9)
		"industrial":
			bd.category = "shell"
			bd.height = _rng.randf_range(8.0, 20.0)
			bd.floors = 1
			bd.color_primary = Color(0.5, 0.5, 0.45)
		"civic":
			bd.category = "full_interior"
			bd.height = _rng.randf_range(12.0, 25.0)
			bd.floors = int(bd.height / 4.0)
			bd.is_enterable = true
			bd.color_primary = Color(0.8, 0.78, 0.72)
		"park":
			bd.category = "shell"
			bd.height = 0.0
			bd.floors = 0
		_:
			bd.category = "shell"
			bd.height = _rng.randf_range(MIN_BUILDING_HEIGHT, 20.0)
			bd.floors = int(bd.height / 3.5)

	bd.width = GRID_CELL_SIZE - ROAD_OFFSET + _rng.randf_range(-2.0, 2.0)
	bd.depth = GRID_CELL_SIZE - ROAD_OFFSET + _rng.randf_range(-2.0, 2.0)
	bd.building_name = _generate_name(zone_type)
	bd.window_density = _rng.randf_range(0.4, 0.8)
	return bd

## ──────────────────────────────────────────────
##  Building Node Creation
## ──────────────────────────────────────────────

func _create_building_from_data(data: BuildingData) -> BuildingBase:
	var building := BuildingBase.new()
	building.building_id = data.building_id
	building.building_name = data.building_name
	building.district_id = data.district_id
	building.zone_type = data.zone_type
	building.width = data.width
	building.depth = data.depth
	building.height = data.height
	building.floors = data.floors
	building.is_enterable = data.is_enterable
	building.interior_scene_path = data.interior_scene_path

	# Set category enum
	match data.category:
		"full_interior": building.category = BuildingBase.Category.FULL_INTERIOR
		"partial_interior": building.category = BuildingBase.Category.PARTIAL_INTERIOR
		_: building.category = BuildingBase.Category.SHELL

	# Create visual shell (mesh + collision)
	if data.height > 0.5:
		_create_shell_mesh(building, data)
		_create_portal_sensor(building, data)

	return building

func _create_shell_mesh(building: BuildingBase, data: BuildingData) -> void:
	# BoxMesh for the building shell
	var box := BoxMesh.new()
	box.size = Vector3(data.width, data.height, data.depth)
	var mi := MeshInstance3D.new()
	mi.name = "ShellMesh"
	mi.mesh = box
	# Material
	var mat := StandardMaterial3D.new()
	mat.albedo_color = data.color_primary
	mat.roughness = 0.8
	mat.metalness = 0.1
	if data.category == "shell":
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.95, 0.7) * 0.15
		mat.emission_energy_multiplier = 0.3
	mi.material_override = mat
	# Position mesh so base is at y=0
	mi.position.y = data.height / 2.0
	building.add_child(mi)

	# Collision shape already part of StaticBody3D (BuildingBase extends StaticBody3D)
	var col_shape := BoxShape3D.new()
	col_shape.size = Vector3(data.width, data.height, data.depth)
	var col := CollisionShape3D.new()
	col.name = "CollisionShape"
	col.shape = col_shape
	col.position.y = data.height / 2.0
	building.add_child(col)

func _create_portal_sensor(building: BuildingBase, data: BuildingData) -> void:
	if not data.is_enterable:
		return
	var area := Area3D.new()
	area.name = "PortalSensor"
	# Sensor box at the front door
	var sensor_box := BoxShape3D.new()
	sensor_box.size = Vector3(4.0, 3.5, 2.0)
	var col := CollisionShape3D.new()
	col.shape = sensor_box
	col.position = Vector3(0.0, 1.75, data.depth / 2.0 + 1.0)
	area.add_child(col)
	building.add_child(area)

## ──────────────────────────────────────────────
##  Queries
## ──────────────────────────────────────────────

func get_buildings() -> Array[BuildingBase]:
	return _buildings

func get_building_count() -> int:
	return _buildings.size()

func get_buildings_in_district(district_id: String) -> Array[BuildingBase]:
	var result: Array[BuildingBase] = []
	for b in _buildings:
		if b.district_id == district_id:
			result.append(b)
	return result

func get_building_at(pos: Vector3, radius: float = 5.0) -> BuildingBase:
	var closest: BuildingBase = null
	var closest_dist := radius * radius
	for b in _buildings:
		var d := b.global_position.distance_squared_to(pos)
		if d < closest_dist:
			closest_dist = d
			closest = b
	return closest

func clear_buildings() -> void:
	for b in _buildings:
		if is_instance_valid(b):
			b.queue_free()
	_buildings.clear()
	_building_data.clear()

## ──────────────────────────────────────────────
##  Serialization
## ──────────────────────────────────────────────

func serialize() -> Array:
	var result: Array = []
	for b in _buildings:
		if is_instance_valid(b):
			result.append(b.serialize())
	return result

## ──────────────────────────────────────────────
##  Helpers
## ──────────────────────────────────────────────

func _random_color(min_v: float, max_v: float) -> Color:
	return Color(
		_rng.randf_range(min_v, max_v),
		_rng.randf_range(min_v, max_v),
		_rng.randf_range(min_v, max_v)
	)

func _generate_name(zone_type: String) -> String:
	var prefixes := ["Nova", "Aurora", "Central", "Grand", "Royal", "Metro", "City", "Harbor"]
	var suffixes := ["Tower", "Plaza", "Building", "Heights", "Center", "House", "Block", "Lofts"]
	return "%s %s" % [prefixes[_rng.randi() % prefixes.size()], suffixes[_rng.randi() % suffixes.size()]]

func _log_info(msg: String) -> void:
	if has_node("/root/DebugManager"):
		DebugManager.log_info("BuildingGen", msg)

func _log_warn(msg: String) -> void:
	if has_node("/root/DebugManager"):
		DebugManager.log_warn("BuildingGen", msg)

func _log_error(msg: String) -> void:
	if has_node("/root/DebugManager"):
		DebugManager.log_error("BuildingGen", msg)
