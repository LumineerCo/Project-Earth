## NavGraph.gd
## Pedestrian navigation via NavigationRegion3D + A* road graph for vehicles.
## Stage 3.8 (NavMesh & Pathfinding)
extends Node3D

## ──────────────────────────────────────────────
##  Configuration
## ──────────────────────────────────────────────

const AGENT_RADIUS := 0.4
const AGENT_HEIGHT := 1.8
const MAX_SLOPE := 35.0
const STEP_HEIGHT := 0.3

## ──────────────────────────────────────────────
##  State
## ──────────────────────────────────────────────

var _nav_region: NavigationRegion3D = null
var _road_network: RoadNetwork = null

## ──────────────────────────────────────────────
##  Lifecycle
## ──────────────────────────────────────────────

func _ready() -> void:
	_setup_nav_region()
	_road_network = RoadNetwork.new()
	add_child(_road_network)

## ──────────────────────────────────────────────
##  Setup
## ──────────────────────────────────────────────

func _setup_nav_region() -> void:
	_nav_region = NavigationRegion3D.new()
	_nav_region.navigation_mesh = NavigationMesh.new()
	_nav_region.navigation_mesh.agent_radius = AGENT_RADIUS
	_nav_region.navigation_mesh.agent_height = AGENT_HEIGHT
	_nav_region.navigation_mesh.agent_max_slope = MAX_SLOPE
	_nav_region.navigation_mesh.agent_max_climb = STEP_HEIGHT
	add_child(_nav_region)

## Bake the NavMesh from current scene geometry.
func bake_navmesh() -> void:
	NavigationServer3D.region_bake_navigation_mesh(_nav_region.navigation_mesh, _nav_region)
	DebugManager.log_info("NavGraph", "NavMesh baked")

## ──────────────────────────────────────────────
##  Pathfinding API
## ──────────────────────────────────────────────

## Get a pedestrian path from start to end via NavMesh.
## Returns PackedVector3Array of waypoints.
func get_pedestrian_path(start: Vector3, end: Vector3) -> PackedVector3Array:
	var map := _nav_region.get_navigation_map()
	return NavigationServer3D.map_get_path(map, start, end, true)

## Get a vehicle path via A* road graph.
## Returns array of intersection ids.
func get_vehicle_path(start_id: String, goal_id: String) -> Array[String]:
	return _road_network.find_path(start_id, goal_id)

## Get the road network for manual graph manipulation.
func get_road_network() -> RoadNetwork:
	return _road_network
