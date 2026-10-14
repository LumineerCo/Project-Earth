## TrafficSystem.gd
## Central hub for road segment registration, traffic management, and vehicle routing.
## Acts as the global navigation database that RoadSegments register with.
## Stage 3.2 (Road Network & Layout) + Stage 3.6 (Traffic System & Vehicles)
extends Node

const ROAD_NETWORK_SCRIPT := "res://scripts/world/RoadNetwork.gd"

var _road_network: Node
var _registered_roads: Dictionary = {}  # road_id → RoadSegment node
var _road_by_position: Array = []  # sorted by x for spatial queries
var _vehicle_count: int = 0
var _max_vehicles: int = 40

signal road_registered(road_id: String, road: Node)
signal road_unregistered(road_id: String)
signal vehicle_count_changed(count: int)

func _ready() -> void:
	_road_network = load(ROAD_NETWORK_SCRIPT).new()
	_road_network.name = "RoadNetwork"
	add_child(_road_network)
	DebugManager.log_info("TrafficSystem", "Traffic system initialized")

func register_road(road: Node) -> String:
	var road_id: String = road.get_name()
	if road_id.is_empty():
		road_id = "road_%d" % _registered_roads.size()
		road.name = road_id
	_registered_roads[road_id] = road
	_road_by_position.append(road)
	_register_intersections(road)
	road_registered.emit(road_id, road)
	DebugManager.log_trace("TrafficSystem", "Registered road: %s" % road_id)
	return road_id

func unregister_road(road_id: String) -> void:
	if not _registered_roads.has(road_id):
		return
	_registered_roads.erase(road_id)
	road_unregistered.emit(road_id)
	DebugManager.log_trace("TrafficSystem", "Unregistered road: %s" % road_id)

func _register_intersections(road: Node) -> void:
	if not road.has_method("get_curve"):
		return
	var curve: Curve3D = road.get_curve()
	if curve == null or curve.get_point_count() < 2:
		return
	var start_pos := road.to_global(curve.get_point_position(0))
	var end_pos := road.to_global(curve.get_point_position(curve.get_point_count() - 1))
	var start_id := _road_network.find_or_add_intersection(start_pos)
	var end_id := _road_network.find_or_add_intersection(end_pos)
	_road_network.connect(start_id, end_id)
	_road_network.add_road(road.name, start_id, end_id)

func get_road(road_id: String) -> Node:
	return _registered_roads.get(road_id)

func get_all_roads() -> Dictionary:
	return _registered_roads

func get_road_count() -> int:
	return _registered_roads.size()

func get_road_network() -> Node:
	return _road_network

func find_path(start_pos: Vector3, goal_pos: Vector3) -> Array[String]:
	var start_id := _find_nearest_intersection(start_pos)
	var goal_id := _find_nearest_intersection(goal_pos)
	if start_id.is_empty() or goal_id.is_empty():
		return []
	if start_id == goal_id:
		return [start_id]
	return _road_network.find_path(start_id, goal_id)

func _find_nearest_intersection(pos: Vector3) -> String:
	var intersections: Dictionary = _road_network.get_all_intersections()
	var nearest_id := ""
	var nearest_dist := INF
	for id in intersections.keys():
		var intersection = intersections[id]
		var dist := pos.distance_to(intersection.position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest_id = id
	return nearest_id

func get_closest_road_point(target_pos: Vector3, lane_index: int = 0) -> Vector3:
	var closest_point := target_pos
	var closest_dist := INF
	for road_id in _registered_roads.keys():
		var road: Node = _registered_roads[road_id]
		if not road.has_method("sample_position"):
			continue
		var num_points := 20
		for i in range(num_points + 1):
			var t := float(i) / float(num_points)
			var point: Vector3 = road.sample_position(t)
			var dist := target_pos.distance_to(point)
			if dist < closest_dist:
				closest_dist = dist
				closest_point = point
	return closest_point

func register_vehicle() -> bool:
	if _vehicle_count >= _max_vehicles:
		DebugManager.log_warn("TrafficSystem", "Max vehicles reached (%d)" % _max_vehicles)
		return false
	_vehicle_count += 1
	vehicle_count_changed.emit(_vehicle_count)
	return true

func unregister_vehicle() -> void:
	if _vehicle_count > 0:
		_vehicle_count -= 1
		vehicle_count_changed.emit(_vehicle_count)

func get_vehicle_count() -> int:
	return _vehicle_count

func get_max_vehicles() -> int:
	return _max_vehicles

func set_max_vehicles(max_val: int) -> void:
	_max_vehicles = max(0, max_val)

func build_network_from_city_data(city_manager: Node) -> void:
	if city_manager == null:
		DebugManager.log_error("TrafficSystem", "City manager is null")
		return
	var avenues: Array = city_manager.get_main_avenues()
	for road_data in avenues:
		_create_road_from_data(road_data)
	var collectors: Array = city_manager.get_collectors()
	for road_data in collectors:
		_create_road_from_data(road_data)
	DebugManager.log_info("TrafficSystem", "Built network from city data (%d roads)" % _registered_roads.size())

func _create_road_from_data(road_data: Dictionary) -> void:
	var road_script := load("res://scripts/world/RoadSegment.gd")
	var road := road_script.new()
	road.road_type = _parse_road_type(road_data.get("type", "collector"))
	var points_arr: Array = road_data.get("points", [])
	var points: Array[Vector3] = []
	for pt in points_arr:
		if pt is Array and pt.size() >= 3:
			points.append(Vector3(float(pt[0]), float(pt[1]), float(pt[2])))
	road.points = points
	road.name = road_data.get("id", "road_%d" % _registered_roads.size())
	add_child(road)
	road.build()
	register_road(road)

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

## Returns a random road segment whose start point is within `radius` of `pos`.
## Used by TrafficManager to spawn vehicles near the player.
func get_random_road_near(pos: Vector3, radius: float) -> Node:
	var candidates: Array = []
	for road_id in _registered_roads.keys():
		var road: Node = _registered_roads[road_id]
		if road == null or not is_instance_valid(road):
			continue
		if not road.has_method("get_curve"):
			continue
		var curve: Curve3D = road.get_curve()
		if curve == null or curve.get_point_count() < 2:
			continue
		var road_pos: Vector3 = road.to_global(curve.get_point_position(0))
		if road_pos.distance_to(pos) <= radius:
			candidates.append(road)
	if candidates.is_empty():
		return null
	return candidates[randi() % candidates.size()]

## Returns the next connected road after `current_road` for a given lane.
## Uses the road network's adjacency data. Returns null at a dead end.
func get_next_road(current_road: Node, _lane: Node = null) -> Node:
	if current_road == null or _road_network == null:
		return null
	var road_id: String = current_road.get_name()
	# Find intersections connected to this road's end point
	var curve: Curve3D = current_road.get_curve()
	if curve == null or curve.get_point_count() < 2:
		return null
	var end_pos: Vector3 = current_road.to_global(curve.get_point_position(curve.get_point_count() - 1))
	# Query the road network for connected roads near the end point
	if _road_network.has_method("find_nearest_intersection"):
		var intersection_id: String = _road_network.find_nearest_intersection(end_pos)
		if intersection_id.is_empty():
			return null
		# Get roads connected to this intersection, excluding current
		if _road_network.has_method("get_connected_roads"):
			var connected: Array = _road_network.get_connected_roads(intersection_id)
			for rid in connected:
				if rid != road_id and _registered_roads.has(rid):
					return _registered_roads[rid]
	# Fallback: pick any other road near the end point
	for road_id in _registered_roads.keys():
		if road_id == current_road.get_name():
			continue
		var road: Node = _registered_roads[road_id]
		if road == null or not road.has_method("get_curve"):
			continue
		var other_curve: Curve3D = road.get_curve()
		if other_curve == null or other_curve.get_point_count() < 2:
			continue
		var other_start: Vector3 = road.to_global(other_curve.get_point_position(0))
		if other_start.distance_to(end_pos) < 5.0:
			return road
	return null

func serialize() -> Dictionary:
	return {
		"road_count": _registered_roads.size(),
		"vehicle_count": _vehicle_count,
		"max_vehicles": _max_vehicles
	}
