## AIVehicle.gd
## An AI-controlled vehicle that follows road paths using a PathFollow3D node.
## Implements a simple state machine for intersection behavior.
## Stage 3.6 — Traffic System & Vehicles
extends VehicleBody3D
class_name AIVehicle

## ──────────────────────────────────────────────
##  Vehicle States
## ──────────────────────────────────────────────

enum VehicleState { DRIVING, APPROACHING_INTERSECTION, STOPPED, YIELDING }

## ──────────────────────────────────────────────
##  Exports / Public State
## ──────────────────────────────────────────────

var vehicle_type: String = "sedan"
var target_speed: float = 16.0  # m/s (~60 km/h)
var current_road: Node = null   # RoadSegment
var current_lane: Path3D = null
var speed: float = 0.0
var state: VehicleState = VehicleState.DRIVING

## ──────────────────────────────────────────────
##  Internal State
## ──────────────────────────────────────────────

var _path_follow: PathFollow3D = null
var _obstacle_check_timer: float = 0.0
const OBSTACLE_CHECK_INTERVAL := 0.3
const OBSTACLE_LOOKAHEAD := 8.0  # meters ahead
const ACCEL_RATE := 3.0  # m/s²
const BRAKE_RATE := 6.0  # m/s²

## ──────────────────────────────────────────────
##  Lifecycle
## ──────────────────────────────────────────────

func _ready() -> void:
	add_to_group("Vehicle")
	# Build a simple visual body if none exists
	_build_body()
	# Create path follow child
	_path_follow = PathFollow3D.new()
	_path_follow.rotation_mode = PathFollow3D.ROTATION_Y
	_path_follow.loop = false

func _build_body() -> void:
	# Simple box mesh as placeholder vehicle body
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(2.0, 1.2, 4.5)
	mesh_instance.mesh = box
	mesh_instance.position = Vector3(0, 0.6, 0)
	add_child(mesh_instance)
	# Collision shape matching the body
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.0, 1.2, 4.5)
	col.shape = shape
	col.position = Vector3(0, 0.6, 0)
	add_child(col)

func _physics_process(delta: float) -> void:
	match state:
		VehicleState.DRIVING:
			_state_driving(delta)
		VehicleState.APPROACHING_INTERSECTION:
			_state_approaching(delta)
		VehicleState.STOPPED:
			_state_stopped(delta)
		VehicleState.YIELDING:
			_state_yielding(delta)

	# Periodic obstacle check
	_obstacle_check_timer += delta
	if _obstacle_check_timer >= OBSTACLE_CHECK_INTERVAL:
		_obstacle_check_timer = 0.0
		_check_obstacle_ahead()

## ──────────────────────────────────────────────
##  Road Assignment
## ──────────────────────────────────────────────

## Assign this vehicle to a road segment. Creates a Path3D lane from the road curve.
func assign_road(road: Node) -> void:
	current_road = road
	# Build a lane Path3D from the road's curve
	var curve: Curve3D = road.get_curve()
	if curve == null:
		return
	current_lane = Path3D.new()
	current_lane.curve = curve
	current_lane.name = "Lane_%s" % road.name
	# Add the lane to the road's parent so positions are in world space
	road.get_parent().add_child(current_lane)
	# Attach path follow to the lane
	current_lane.add_child(_path_follow)
	_path_follow.unit_offset = 0.0
	state = VehicleState.DRIVING

func get_road_id() -> String:
	if current_road:
		return current_road.name
	return ""

## ──────────────────────────────────────────────
##  State: DRIVING
## ──────────────────────────────────────────────

func _state_driving(delta: float) -> void:
	if current_lane == null or _path_follow == null:
		return
	var baked_length: float = current_lane.curve.get_baked_length()
	if baked_length <= 0.0:
		return
	# Accelerate toward target speed
	speed = move_toward(speed, target_speed, ACCEL_RATE * delta)
	# Advance along path
	var advance := speed * delta / baked_length
	_path_follow.unit_offset += advance
	# Sync vehicle transform to path follow
	global_transform = _path_follow.global_transform
	# Check for end of road
	if _path_follow.unit_offset >= 0.95:
		_handle_end_of_road()

## ──────────────────────────────────────────────
##  State: APPROACHING_INTERSECTION
## ──────────────────────────────────────────────

func _state_approaching(delta: float) -> void:
	# Slow down while approaching
	speed = move_toward(speed, target_speed * 0.3, BRAKE_RATE * delta)
	if current_lane and _path_follow:
		var baked_length: float = current_lane.curve.get_baked_length()
		if baked_length > 0.0:
			var advance := speed * delta / baked_length
			_path_follow.unit_offset += advance
			global_transform = _path_follow.global_transform
	# Check if we should stop or proceed
	if _path_follow and _path_follow.unit_offset >= 0.95:
		_handle_end_of_road()

## ──────────────────────────────────────────────
##  State: STOPPED
## ──────────────────────────────────────────────

func _state_stopped(delta: float) -> void:
	speed = move_toward(speed, 0.0, BRAKE_RATE * delta)
	# Check if light turned green
	if current_road and current_road.has_method("is_light_green") and current_road.is_light_green():
		state = VehicleState.DRIVING

## ──────────────────────────────────────────────
##  State: YIELDING
## ──────────────────────────────────────────────

func _state_yielding(delta: float) -> void:
	speed = move_toward(speed, 0.0, BRAKE_RATE * delta)
	# Yield for a brief moment then resume
	if speed < 1.0:
		state = VehicleState.DRIVING

## ──────────────────────────────────────────────
##  End-of-Road Handling
## ──────────────────────────────────────────────

func _handle_end_of_road() -> void:
	if TrafficSystem == null:
		_despawn_self()
		return
	# Find next connected road
	var next_road: Node = null
	if TrafficSystem.has_method("get_next_road"):
		next_road = TrafficSystem.get_next_road(current_road, current_lane)
	if next_road == null:
		# Dead end — despawn
		_despawn_self()
		return
	# Check for traffic light
	if next_road.has_method("has_traffic_light") and next_road.has_traffic_light():
		if next_road.has_method("is_light_green") and not next_road.is_light_green():
			state = VehicleState.STOPPED
			return
	_transition_to_road(next_road)

func _transition_to_road(new_road: Node) -> void:
	# Detach path follow from old lane
	if current_lane and _path_follow and _path_follow.get_parent() == current_lane:
		current_lane.remove_child(_path_follow)
	# Clean up old lane
	if current_lane and is_instance_valid(current_lane):
		current_lane.queue_free()
	current_road = new_road
	# Build new lane
	var curve: Curve3D = new_road.get_curve()
	if curve == null:
		_despawn_self()
		return
	current_lane = Path3D.new()
	current_lane.curve = curve
	current_lane.name = "Lane_%s" % new_road.name
	new_road.get_parent().add_child(current_lane)
	current_lane.add_child(_path_follow)
	_path_follow.unit_offset = 0.0
	state = VehicleState.DRIVING

func _despawn_self() -> void:
	if TrafficManager and TrafficManager.has_method("_despawn_vehicle"):
		TrafficManager._despawn_vehicle(self)
	else:
		queue_free()

## ──────────────────────────────────────────────
##  Obstacle Avoidance
## ──────────────────────────────────────────────

func _check_obstacle_ahead() -> void:
	if state == VehicleState.STOPPED:
		return
	# Cast a ray ahead to detect vehicles or obstacles
	var ray := RayCast3D.new()
	ray.target_position = Vector3(0, 0.6, -OBSTACLE_LOOKAHEAD)
	ray.collision_mask = 1  # default
	add_child(ray)
	ray.force_raycast_update()
	var collider := ray.get_collider()
	ray.queue_free()
	if collider and (collider.is_in_group("Vehicle") or collider.is_in_group("player")):
		# Slow down
		target_speed = min(target_speed, 5.0)
		if speed > 5.0:
			state = VehicleState.APPROACHING_INTERSECTION
	else:
		# Resume normal speed based on vehicle type
		if TrafficManager and TrafficManager.VEHICLE_MAX_SPEED.has(vehicle_type):
			target_speed = TrafficManager.VEHICLE_MAX_SPEED[vehicle_type]

## ──────────────────────────────────────────────
##  Horn Response
## ──────────────────────────────────────────────

## Called when the player honks nearby — briefly accelerate.
func on_player_honk() -> void:
	target_speed = min(target_speed * 1.2, 25.0)
	state = VehicleState.DRIVING

## ──────────────────────────────────────────────
##  Cleanup
## ──────────────────────────────────────────────

func _exit_tree() -> void:
	if current_lane and is_instance_valid(current_lane):
		current_lane.queue_free()
