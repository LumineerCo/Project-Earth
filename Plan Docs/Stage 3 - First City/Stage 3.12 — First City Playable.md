# Stage 3.12 — First City Playable

All the systems from Stages 3.2 through 3.11 come together here. This is the integration milestone where Nova City becomes a walkable, drivable, living city that a player can actually explore.

---

## Goal
Integrate all Stage 3 subsystems into a single playable scene, verify they work together, and establish the baseline experience for future gameplay stages.

---

## Step 1 — Integration Checklist

| System | Stage | Integration Task | Status |
| :--- | :--- | :--- | :--- |
| Road Network | 3.2 | All roads connected, Path3D lanes functional | ☐ |
| Buildings | 3.3 | Modular buildings placed, interiors streamable | ☐ |
| NPCs | 3.4 | NPCs spawn, wander, and despawn correctly | ☐ |
| Shops | 3.5 | Shops interactable, economy running | ☐ |
| Traffic | 3.6 | Vehicles spawn, follow lanes, obey lights | ☐ |
| Districts | 3.7 | All 6 districts placed with zoning | ☐ |
| Navigation | 3.8 | NavMesh baked, road graph connected | ☐ |
| Audio | 3.9 | District ambient zones active | ☐ |
| Day-Night | 3.10 | Sun moves, lights activate at night | ☐ |
| Performance | 3.11 | LOD active, 60 FPS maintained | ☐ |

---

## Step 2 — Main Scene Structure

```text
NovaCity_Main.tscn
├── WorldEnvironment
├── DirectionalLight3D (DayNightCycle)
├── NavigationRegion3D (Pedestrian NavMesh)
├── Districts/
│   ├── CentralPlaza/
│   │   ├── Buildings/
│   │   ├── Roads/
│   │   ├── Props/
│   │   └── DistrictAudioZone
│   ├── FinancialDistrict/
│   ├── SuburbanHills/
│   ├── IndustrialPort/
│   ├── CoastalMarina/
│   └── HighwayCorridor/
├── Player/
│   ├── CharacterBody3D (on-foot mode)
│   └── Camera3D
├── NPCManager
├── TrafficManager
├── AudioManager
└── DebugMenu
```

---

## Step 3 — Player Controller Integration

The player can switch between on-foot and driving modes.

### `PlayerController.gd`

```gdscript
extends CharacterBody3D
class_name PlayerController

@export var walk_speed: float = 5.0
@export var run_speed: float = 8.0
@export var current_mode: String = "on_foot"  # "on_foot" or "driving"

var current_vehicle: VehicleBody3D = null
var camera: Camera3D

func _ready() -> void:
    camera = $Camera3D
    add_to_group("Player")

func _physics_process(delta: float) -> void:
    match current_mode:
        "on_foot": _handle_on_foot(delta)
        "driving": _handle_driving(delta)

func _handle_on_foot(delta: float) -> void:
    var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    
    var speed = run_speed if Input.is_action_pressed("sprint") else walk_speed
    velocity = direction * speed
    velocity.y -= 9.8 * delta  # gravity
    
    move_and_slide()
    
    # Check for vehicle entry
    if Input.is_action_just_pressed("interact"):
        _try_enter_vehicle()

func _try_enter_vehicle() -> void:
    var space_state = get_world_3d().direct_space_state
    var ray = PhysicsRayQueryParameters3D.create(
        global_position, 
        global_position + (-global_transform.basis.z * 3.0)
    )
    var result = space_state.intersect_ray(ray)
    if result and result.collider.is_in_group("Vehicle"):
        _enter_vehicle(result.collider)

func _enter_vehicle(vehicle: VehicleBody3D) -> void:
    current_vehicle = vehicle
    current_mode = "driving"
    vehicle.set_driver(self)
    # Move camera to vehicle
    camera.reparent(vehicle)
    camera.position = Vector3(0, 1.2, -3.0)

func _exit_vehicle() -> void:
    current_vehicle.set_driver(null)
    # Place player beside vehicle
    global_position = current_vehicle.global_position + Vector3(2.0, 0, 0)
    camera.reparent(self)
    camera.position = Vector3(0, 1.7, 0)
    current_vehicle = null
    current_mode = "on_foot"

func _handle_driving(_delta: float) -> void:
    # Vehicle handles its own physics; player provides input
    if Input.is_action_just_pressed("exit_vehicle"):
        _exit_vehicle()
```

---

## Step 4 — Testing Criteria

### Core Functionality Tests

| Test ID | Description | Pass Criteria |
| :--- | :--- | :--- |
| T-001 | Walk through all 6 districts | No falls through floor, no stuck spots |
| T-002 | Enter and exit a vehicle | Smooth transition, camera repositions |
| T-003 | Drive through city following lanes | Vehicle stays on road, obeys lights |
| T-004 | Observe NPC wandering | NPCs walk on sidewalks, avoid obstacles |
| T-005 | Interact with a shop | Shop UI opens, can browse items |
| T-006 | Watch day-night transition | Sun moves, lights activate at dusk |
| T-007 | Listen to district audio | Ambient changes when entering districts |
| T-008 | Check performance | 60 FPS maintained while walking |
| T-009 | Check performance while driving | 60 FPS maintained at speed |
| T-010 | Verify NPC despawn | NPCs despawn when player leaves area |

### Edge Case Tests

| Test ID | Description | Pass Criteria |
| :--- | :--- | :--- |
| T-101 | Drive into building | Vehicle stops, no clipping through |
| T-102 | Block traffic with player vehicle | AI vehicles slow/stop, no pile-up |
| T-103 | Enter building interior | Interior loads, exterior culls |
| T-104 | Fast travel across city | NPCs/vehicles spawn correctly at new location |
| T-105 | Time skip to night | All streetlights activate, windows light up |

---

## Step 5 — Milestone Deliverables

### Deliverable 1: Playable Build
- Exported executable (Windows, Linux, macOS)
- Player can walk and drive through Nova City
- All 6 districts accessible

### Deliverable 2: Debug Tools
- Debug menu with toggles for:
  - NavMesh visualization
  - Road graph visualization
  - NPC spawn/despawn zones
  - Performance overlay
  - Time-of-day override
  - Free camera mode

### Deliverable 3: Documentation
- Updated architecture document
- Scene tree reference
- Control scheme document
- Known issues list

---

## Step 6 — Known Limitations (To Address in Stage 4)

| Limitation | Stage 4 Solution |
| :--- | :--- |
| No money or inventory | Stage 4.2 — Money & Banking |
| No missions or goals | Stage 4.6 — Missions & Story |
| NPCs have no schedules | Stage 4.10 — Advanced NPC AI |
| No combat | Stage 4.11 — Combat System |
| No save/load | Stage 4.12 — Save System |
| Limited vehicle types | Stage 4.8 — Vehicles & Garage |

---

## Step 7 — Next Steps

With Nova City playable, the project transitions to **Stage 4 — Gameplay**, where systems like money, inventory, jobs, missions, and combat will be layered on top of the city foundation built in Stage 3.

The city is the stage; gameplay is the performance.
