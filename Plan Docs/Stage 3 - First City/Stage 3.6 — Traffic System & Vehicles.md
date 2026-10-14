# Stage 3.6 — Traffic System & Vehicles

Traffic is the circulatory system of any city. A believable open-world game needs cars that follow lanes, stop at intersections, yield to pedestrians, and react to the player's driving. This stage defines the traffic simulation for Nova City.

---

## Goal
Build a lightweight traffic simulation where AI vehicles follow road paths, obey traffic rules, and interact with the player's vehicle and pedestrians.

---

## Step 1 — Traffic Vehicle Types

| Vehicle Type | Max Speed | Spawn Weight | Lanes Used |
| :--- | :--- | :--- | :--- |
| **Sedan** | 60 km/h | 40% | All lanes |
| **SUV** | 55 km/h | 20% | All lanes |
| **Taxi** | 65 km/h | 15% | All lanes |
| **Bus** | 40 km/h | 10% | Right lane only |
| **Delivery Truck** | 45 km/h | 10% | Right lane only |
| **Police Car** | 80 km/h | 5% | All lanes (can overtake) |

---

## Step 2 — Traffic Manager (`TrafficManager.gd`)

The Traffic Manager spawns vehicles on road segments near the player and despawns them when they drive too far away.

```gdscript
extends Node

const MAX_VEHICLES: int = 40
const SPAWN_RADIUS: float = 150.0
const DESPAWN_RADIUS: float = 250.0

var active_vehicles: Array[Node3D] = []
var player: Node3D

func _ready() -> void:
    player = get_tree().get_first_node_in_group("Player")

func _process(_delta: float) -> void:
    _manage_traffic()

func _manage_traffic() -> void:
    if not player: return
    
    # Despawn distant vehicles
    for vehicle in active_vehicles:
        if is_instance_valid(vehicle):
            if vehicle.global_position.distance_to(player.global_position) > DESPAWN_RADIUS:
                _despawn_vehicle(vehicle)
        else:
            active_vehicles.erase(vehicle)
    
    # Spawn new vehicles
    while active_vehicles.size() < MAX_VEHICLES:
        var road = TrafficSystem.get_random_road_near(player.global_position, SPAWN_RADIUS)
        if road == null: break
        _spawn_vehicle(road)

func _spawn_vehicle(road: RoadSegment) -> void:
    var vehicle_type = _pick_random_vehicle_type()
    var vehicle_scene = load("res://scenes/vehicles/" + vehicle_type + ".tscn")
    var vehicle = vehicle_scene.instantiate()
    
    # Place at start of road path
    var lane = road.lane_right if randf() > 0.5 else road.lane_left
    vehicle.global_position = lane.curve.get_point_position(0)
    
    get_tree().current_scene.add_child(vehicle)
    vehicle.assign_road(road, lane)
    active_vehicles.append(vehicle)

func _despawn_vehicle(vehicle: Node3D) -> void:
    active_vehicles.erase(vehicle)
    vehicle.queue_free()

func _pick_random_vehicle_type() -> String:
    var types = {"sedan": 40, "suv": 20, "taxi": 15, "bus": 10, "truck": 10, "police": 5}
    var total = 0
    for w in types.values(): total += w
    var roll = randi() % total
    for key in types.keys():
        roll -= types[key]
        if roll < 0: return key
    return "sedan"
```

---

## Step 3 — AI Vehicle Controller (`AIVehicle.gd`)

Each AI vehicle follows a `Path3D` lane using a `PathFollow3D` node and a state machine for intersection behavior.

### Vehicle States
```
DRIVING  →  APPROACHING_INTERSECTION  →  STOPPED  →  DRIVING
    │
    └──→  YIELDING  →  DRIVING
```

```gdscript
extends VehicleBody3D
class_name AIVehicle

var current_road: RoadSegment
var current_lane: Path3D
var path_follow: PathFollow3D
var speed: float = 0.0
var target_speed: float = 16.0  # ~60 km/h in m/s
var state: String = "driving"

func assign_road(road: RoadSegment, lane: Path3D) -> void:
    current_road = road
    current_lane = lane
    path_follow = PathFollow3D.new()
    path_follow.rotation_mode = PathFollow3D.ROTATION_Y
    current_lane.add_child(path_follow)
    path_follow.unit_offset = 0.0
    reparent_to_lane()

func _physics_process(delta: float) -> void:
    match state:
        "driving":               _state_driving(delta)
        "approaching_intersection": _state_approaching(delta)
        "stopped":               _state_stopped(delta)
        "yielding":               _state_yielding(delta)

func _state_driving(delta: float) -> void:
    # Advance along path
    var advance = speed * delta / current_lane.curve.get_baked_length()
    path_follow.unit_offset += advance
    
    # Sync vehicle position to path follow
    global_transform = path_follow.global_transform
    
    # Accelerate toward target speed
    speed = move_toward(speed, target_speed, 2.0 * delta)
    
    # Check for upcoming intersection
    if path_follow.unit_offset > 0.9:
        _handle_end_of_road()

func _handle_end_of_road() -> void:
    # Find next connected road segment
    var next_road = TrafficSystem.get_next_road(current_road, current_lane)
    if next_road == null:
        # Dead end — despawn
        TrafficManager._despawn_vehicle(self)
        return
    
    # Check for traffic light or stop sign
    if next_road.has_traffic_light() and not next_road.is_light_green():
        state = "stopped"
    else:
        _transition_to_road(next_road)

func _transition_to_road(new_road: RoadSegment) -> void:
    current_lane.remove_child(path_follow)
    current_road = new_road
    current_lane = new_road.lane_right
    current_lane.add_child(path_follow)
    path_follow.unit_offset = 0.0
    state = "driving"

func _state_stopped(delta: float) -> void:
    speed = move_toward(speed, 0.0, 5.0 * delta)
    # Check if light turned green
    if current_road.is_light_green():
        state = "driving"
```

---

## Step 4 — Traffic Lights & Intersections

Intersections use a timed traffic light controller.

```gdscript
extends Node3D
class_name TrafficLightController

@export var green_duration: float = 15.0
@export var yellow_duration: float = 3.0
@export var red_duration: float = 15.0

var current_phase: String = "green"  # green, yellow, red
var phase_timer: float = 0.0

func _process(delta: float) -> void:
    phase_timer -= delta
    if phase_timer <= 0.0:
        _advance_phase()

func _advance_phase() -> void:
    match current_phase:
        "green":
            current_phase = "yellow"
            phase_timer = yellow_duration
        "yellow":
            current_phase = "red"
            phase_timer = red_duration
        "red":
            current_phase = "green"
            phase_timer = green_duration
    _update_light_meshes()

func is_green() -> bool:
    return current_phase == "green"

func _update_light_meshes() -> void:
    $GreenLight.visible = current_phase == "green"
    $YellowLight.visible = current_phase == "yellow"
    $RedLight.visible = current_phase == "red"
```

---

## Step 5 — Player Vehicle Interaction

When the player drives a vehicle, AI vehicles must react:

* **Collision avoidance:** AI vehicles slow down if the player is directly ahead in the same lane.
* **Overtaking:** If the player is stopped, AI vehicles on multi-lane roads switch lanes to pass.
* **Horn response:** If the player honks, nearby AI vehicles may briefly accelerate or change lanes.

```gdscript
func _check_obstacle_ahead() -> void:
    var front = global_transform.basis.z * -5.0  # 5m ahead
    var ray = RayCast3D.new()
    ray.target_position = front
    ray.force_raycast_update()
    if ray.get_collider() and ray.get_collider().is_in_group("Vehicle"):
        target_speed = min(target_speed, 5.0)  # slow down
    else:
        target_speed = 16.0  # resume normal speed
```

This creates a traffic system that feels alive without requiring heavy physics computation for every car on the map.
