## NovaCity.gd
## Main scene script for the Nova City world. Builds the city from data loaded
## by NovaCityManager: ground, roads, district markers, and spawn points.
## Stage 3.1 (First City - Nova City Setup)
extends Node3D

const ROAD_SEGMENT_SCRIPT := "res://scripts/world/RoadSegment.gd"
const DISTRICT_MARKER_SIZE := 4.0

@onready var _city_manager: Node = get_node_or_null("/root/NovaCityManager")

var _road_container: Node3D
var _district_container: Node3D
var _marker_container: Node3D

func _ready() -> void:
	if _city_manager == null:
		DebugManager.log_error("NovaCity", "NovaCityManager autoload not found")
		return
	if _city_manager.city_id.is_empty():
		_city_manager.load_city()
	_build_ground()
	_build_roads()
	_build_district_markers()
	_build_spawn_markers()
	DebugManager.log_info("NovaCity", "Nova City scene built successfully")

func _build_ground() -> void:
	var ground := StaticBody3D.new()
	ground.name = "Ground"
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(1000, 1000)
	mesh.material = _create_ground_material()
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	ground.add_child(mi)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1000, 0.1, 1000)
	col.shape = shape
	ground.add_child(col)
	add_child(ground)

func _create_ground_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.28, 0.22)
	mat.roughness = 0.9
	mat.metallic = 0.0
	return mat

func _build_roads() -> void:
	_road_container = Node3D.new()
	_road_container.name = "Roads"
	add_child(_road_container)
	var avenues: Array = _city_manager.get_main_avenues()
	for road_data in avenues:
		_create_road_segment(road_data)
	var collectors: Array = _city_manager.get_collectors()
	for road_data in collectors:
		_create_road_segment(road_data)
	DebugManager.log_info("NovaCity", "Built %d road segments" % (avenues.size() + collectors.size()))

func _create_road_segment(road_data: Dictionary) -> void:
	var road_script := load(ROAD_SEGMENT_SCRIPT)
	var road := road_script.new()
	road.road_type = _parse_road_type(road_data.get("type", "collector"))
	var points_arr: Array = road_data.get("points", [])
	var points: Array[Vector3] = []
	for pt in points_arr:
		if pt is Array and pt.size() >= 3:
			points.append(Vector3(float(pt[0]), float(pt[1]), float(pt[2])))
	road.points = points
	_road_container.add_child(road)
	road.build()

func _parse_road_type(type_str: String) -> int:
	match type_str:
		"highway":
			return 0
		"main_avenue":
			return 1
		"collector":
			return 2
		"alley":
			return 3
		_:
			return 2

func _build_district_markers() -> void:
	_district_container = Node3D.new()
	_district_container.name = "Districts"
	add_child(_district_container)
	var districts: Array = _city_manager.get_districts()
	for district in districts:
		_create_district_marker(district)
	DebugManager.log_info("NovaCity", "Built %d district markers" % districts.size())

func _create_district_marker(district: Dictionary) -> void:
	var b: Dictionary = district.get("bounds", {})
	if b.is_empty():
		return
	var min_x := float(b.get("min_x", 0.0))
	var max_x := float(b.get("max_x", 0.0))
	var min_z := float(b.get("min_z", 0.0))
	var max_z := float(b.get("max_z", 0.0))
	var center := Vector3((min_x + max_x) * 0.5, 0.1, (min_z + max_z) * 0.5)
	var marker := Node3D.new()
	marker.name = "District_" + district.get("district_id", "unknown")
	marker.position = center
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(DISTRICT_MARKER_SIZE, 0.2, DISTRICT_MARKER_SIZE)
	mi.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _district_color(district.get("zone_type", ""))
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.5
	mi.material_override = mat
	marker.add_child(mi)
	_district_container.add_child(marker)

func _district_color(zone_type: String) -> Color:
	match zone_type:
		"commercial_high":
			return Color(0.9, 0.2, 0.2)
		"industrial":
			return Color(0.6, 0.5, 0.3)
		"residential_low":
			return Color(0.8, 0.7, 0.5)
		"civic":
			return Color(0.2, 0.4, 0.9)
		"park":
			return Color(0.2, 0.8, 0.3)
		_:
			return Color(0.5, 0.5, 0.5)

func _build_spawn_markers() -> void:
	_marker_container = Node3D.new()
	_marker_container.name = "SpawnMarkers"
	add_child(_marker_container)
	var player_spawn := _city_manager.get_player_spawn()
	_create_spawn_marker("PlayerSpawn", player_spawn, Color(0.2, 0.9, 0.2))
	var npc_spawns: Array[Vector3] = _city_manager.get_npc_spawn_points()
	for i in range(npc_spawns.size()):
		_create_spawn_marker("NPCSpawn_%d" % i, npc_spawns[i], Color(0.9, 0.6, 0.2))

func _create_spawn_marker(name: String, pos: Vector3, color: Color) -> void:
	var marker := MeshInstance3D.new()
	marker.name = name
	marker.position = pos + Vector3(0, 0.5, 0)
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	marker.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.5
	marker.material_override = mat
	_marker_container.add_child(marker)
