## TrafficManager.gd
## Spawns and despawns AI vehicles around the player based on proximity to roads.
## Stage 3.6 — Traffic System & Vehicles
extends Node

## ──────────────────────────────────────────────
##  Signals
## ──────────────────────────────────────────────

signal vehicle_spawned(road_id: String, vehicle_type: String)
signal vehicle_despawned(road_id: String)

## ──────────────────────────────────────────────
##  Configuration
## ──────────────────────────────────────────────

const MAX_VEHICLES: int = 40
const SPAWN_RADIUS: float = 150.0
const DESPAWN_RADIUS: float = 250.0
const SPAWN_INTERVAL: float = 0.5  # seconds between spawn checks
const AI_VEHICLE_SCRIPT := "res://scripts/vehicle/AIVehicle.gd"

## Vehicle type spawn weights (must sum to 100)
const VEHICLE_TYPES := {
	"sedan": 40,
	"suv": 20,
	"taxi": 15,
	"bus": 10,
	"truck": 10,
	"police": 5,
}

## Max speed per vehicle type in m/s
const VEHICLE_MAX_SPEED := {
	"sedan": 16.67,   # ~60 km/h
	"suv": 15.28,     # ~55 km/h
	"taxi": 18.06,    # ~65 km/h
	"bus": 11.11,     # ~40 km/h
	"truck": 12.50,   # ~45 km/h
	"police": 22.22,  # ~80 km/h
}

## ──────────────────────────────────────────────
##  State
## ──────────────────────────────────────────────

var active_vehicles: Array[Node3D] = []
var player: Node3D = null
var _spawn_timer: float = 0.0
var _is_initialized: bool = false

## ──────────────────────────────────────────────
##  Lifecycle
## ──────────────────────────────────────────────

func _ready() -> void:
	_find_player()
	_is_initialized = true
	if DebugManager:
		DebugManager.log_info("TrafficManager", "Traffic manager initialized (max=%d)" % MAX_VEHICLES)

func _process(delta: float) -> void:
	if not _is_initialized:
		return
	if player == null or not is_instance_valid(player):
		_find_player()
		return
	_spawn_timer += delta
	if _spawn_timer >= SPAWN_INTERVAL:
		_spawn_timer = 0.0
		_manage_traffic()

## ──────────────────────────────────────────────
##  Traffic Management
## ──────────────────────────────────────────────

func _manage_traffic() -> void:
	# Despawn distant vehicles
	var to_despawn: Array[Node3D] = []
	for vehicle in active_vehicles:
		if not is_instance_valid(vehicle):
			to_despawn.append(vehicle)
			continue
		if vehicle.global_position.distance_to(player.global_position) > DESPAWN_RADIUS:
			to_despawn.append(vehicle)
	for vehicle in to_despawn:
		_despawn_vehicle(vehicle)

	# Spawn new vehicles up to the cap
	while active_vehicles.size() < MAX_VEHICLES:
		var road := _get_random_road_near(player.global_position, SPAWN_RADIUS)
		if road == null:
			break
		_spawn_vehicle(road)

func _spawn_vehicle(road: Node) -> void:
	if not ResourceLoader.exists(AI_VEHICLE_SCRIPT):
		if DebugManager:
			DebugManager.log_warn("TrafficManager", "AIVehicle script not found")
		return
	var vehicle_type := _pick_random_vehicle_type()
	var script := load(AI_VEHICLE_SCRIPT)
	var vehicle := script.new()
	vehicle.name = "AIVehicle_%s_%d" % [vehicle_type, active_vehicles.size()]
	vehicle.vehicle_type = vehicle_type
	vehicle.target_speed = VEHICLE_MAX_SPEED.get(vehicle_type, 16.0)

	# Place at start of road path
	var curve: Curve3D = road.get_curve()
	if curve == null or curve.get_point_count() < 2:
		vehicle.queue_free()
		return
	var start_pos: Vector3 = curve.get_point_position(0)
	vehicle.global_position = road.to_global(start_pos)

	# Add to scene and assign road
	get_tree().current_scene.add_child(vehicle)
	vehicle.assign_road(road)
	active_vehicles.append(vehicle)
	vehicle_spawned.emit(road.name, vehicle_type)
	if DebugManager:
		DebugManager.log_trace("TrafficManager", "Spawned %s on %s (total=%d)" % [vehicle_type, road.name, active_vehicles.size()])

func _despawn_vehicle(vehicle: Node3D) -> void:
	var road_id := ""
	if vehicle.has_method("get_road_id"):
		road_id = vehicle.get_road_id()
	active_vehicles.erase(vehicle)
	if is_instance_valid(vehicle):
		vehicle.queue_free()
	vehicle_despawned.emit(road_id)
	if DebugManager:
		DebugManager.log_trace("TrafficManager", "Despawned vehicle (total=%d)" % active_vehicles.size())

## ──────────────────────────────────────────────
##  Road Queries
## ──────────────────────────────────────────────

func _get_random_road_near(pos: Vector3, radius: float) -> Node:
	if not TrafficSystem:
		return null
	var roads: Dictionary = TrafficSystem.get_all_roads()
	if roads.is_empty():
		return null
	var candidates: Array = []
	for road_id in roads:
		var road: Node = roads[road_id]
		if road == null or not road.has_method("get_curve"):
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

## ──────────────────────────────────────────────
##  Vehicle Type Selection
## ──────────────────────────────────────────────

func _pick_random_vehicle_type() -> String:
	var total := 0
	for w in VEHICLE_TYPES.values():
		total += w
	var roll := randi() % total
	for key in VEHICLE_TYPES.keys():
		roll -= VEHICLE_TYPES[key]
		if roll < 0:
			return key
	return "sedan"

## ──────────────────────────────────────────────
##  Player
## ──────────────────────────────────────────────

func _find_player() -> void:
	player = get_tree().get_first_node_in_group("Player")
	if player == null:
		# Fallback: search by name
		var root := get_tree().current_scene
		if root:
			for child in root.get_children():
				if child is Node3D and child.name.to_lower().find("player") >= 0:
					player = child
					break

func set_player(p: Node3D) -> void:
	player = p

## ──────────────────────────────────────────────
##  Cleanup
## ──────────────────────────────────────────────

func despawn_all() -> void:
	for vehicle in active_vehicles:
		if is_instance_valid(vehicle):
			vehicle.queue_free()
	active_vehicles.clear()
	if DebugManager:
		DebugManager.log_info("TrafficManager", "Despawned all vehicles")

func get_active_count() -> int:
	return active_vehicles.size()

## ──────────────────────────────────────────────
##  Persistence
## ──────────────────────────────────────────────

func serialize() -> Dictionary:
	return {
		"active_count": active_vehicles.size(),
		"max_vehicles": MAX_VEHICLES,
	}

func deserialize(data: Dictionary) -> void:
	# Vehicles are transient — just clear and let the manager respawn
	despawn_all()
	if DebugManager:
		DebugManager.log_info("TrafficManager", "Deserialized (vehicles will respawn)")
