## RoadNetwork.gd
## A graph of road intersections and segments for A* vehicle pathfinding.
## Stage 3.2 + Stage 3.8 (NavMesh & Pathfinding)
extends Node

## ──────────────────────────────────────────────
##  Node structure
## ──────────────────────────────────────────────

class Intersection:
	var id: String
	var position: Vector3
	var connections: Array[String] = []  # connected intersection ids
	func _init(i: String = "", p: Vector3 = Vector3.ZERO) -> void:
		id = i
		position = p

## ──────────────────────────────────────────────
##  State
## ──────────────────────────────────────────────

var _intersections: Dictionary = {}  # id → Intersection
var _segments: Array[Node] = []  # RoadSegment nodesvar _road_map: Dictionary = {}  # road_id → [start_intersection_id, end_intersection_id]
var _intersection_roads: Dictionary = {}  # intersection_id → [road_id]
## ──────────────────────────────────────────────
##  Public API
## ──────────────────────────────────────────────

func add_intersection(id: String, pos: Vector3) -> void:
	if _intersections.has(id):
		return
	_intersections[id] = Intersection.new(id, pos)

func connect(a: String, b: String) -> void:
	if not _intersections.has(a) or not _intersections.has(b):
		return
	var ia: Intersection = _intersections[a]
	var ib: Intersection = _intersections[b]
	if a not in ib.connections:
		ib.connections.append(a)
	if b not in ia.connections:
		ia.connections.append(b)

func get_intersection(id: String) -> Intersection:
	return _intersections.get(id)

func get_all_intersections() -> Dictionary:
	return _intersections

func find_or_add_intersection(pos: Vector3, tolerance: float = 1.0) -> String:
	for id in _intersections.keys():
		if _intersections[id].position.distance_to(pos) <= tolerance:
			return id
	var id := "intersection_%d" % _intersections.size()
	add_intersection(id, pos)
	return id

func add_road(road_id: String, start_id: String, end_id: String) -> void:
	_road_map[road_id] = [start_id, end_id]
	if not _intersection_roads.has(start_id):
		_intersection_roads[start_id] = []
	if road_id not in _intersection_roads[start_id]:
		_intersection_roads[start_id].append(road_id)
	if not _intersection_roads.has(end_id):
		_intersection_roads[end_id] = []
	if road_id not in _intersection_roads[end_id]:
		_intersection_roads[end_id].append(road_id)

func get_connected_roads(intersection_id: String) -> Array:
	return _intersection_roads.get(intersection_id, [])

## A* pathfinding between two intersections.
## Returns array of intersection ids (empty if no path).
func find_path(start_id: String, goal_id: String) -> Array[String]:
	if not _intersections.has(start_id) or not _intersections.has(goal_id):
		return []
	if start_id == goal_id:
		return [start_id]
	var open_set: Array[String] = [start_id]
	var came_from: Dictionary = {}
	var g_score: Dictionary = {start_id: 0.0}
	var f_score: Dictionary = {start_id: _heuristic(start_id, goal_id)}
	while open_set.size() > 0:
		# Find lowest f_score in open_set
		var current := open_set[0]
		var lowest_f := f_score.get(current, INF)
		for id in open_set:
			var f := f_score.get(id, INF)
			if f < lowest_f:
				current = id
				lowest_f = f
		if current == goal_id:
			return _reconstruct_path(came_from, current)
		open_set.erase(current)
		var ci: Intersection = _intersections[current]
		for neighbor in ci.connections:
			var tentative_g := g_score.get(current, INF) + _edge_cost(current, neighbor)
			if tentative_g < g_score.get(neighbor, INF):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g
				f_score[neighbor] = tentative_g + _heuristic(neighbor, goal_id)
				if neighbor not in open_set:
					open_set.append(neighbor)
	return []

## ──────────────────────────────────────────────
##  Helpers
## ──────────────────────────────────────────────

func _heuristic(a_id: String, b_id: String) -> float:
	var a: Intersection = _intersections[a_id]
	var b: Intersection = _intersections[b_id]
	return a.position.distance_to(b.position)

func _edge_cost(a_id: String, b_id: String) -> float:
	var a: Intersection = _intersections[a_id]
	var b: Intersection = _intersections[b_id]
	return a.position.distance_to(b.position)

func _reconstruct_path(came_from: Dictionary, current: String) -> Array[String]:
	var path: Array[String] = [current]
	while came_from.has(current):
		current = came_from[current]
		path.push_front(current)
	return path
