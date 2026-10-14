# Stage 3.4 — NPC Spawning & Wandering AI

A city without people is just a ghost town. To make Nova City feel alive, we need pedestrians walking the sidewalks, sitting on benches, entering shops, and reacting to the player. This stage defines the NPC spawning system and the wandering AI that drives pedestrian behavior.

---

## Goal
Build a performant NPC spawning and wandering system that populates the city with believable pedestrians without overwhelming the CPU.

---

## Step 1 — NPC Population Management

We cannot simulate 100,000 NPCs simultaneously. Instead, we use a **proximity-based spawning pool**.

| Parameter | Value |
| :--- | :--- |
| **Max Active NPCs** | 80 (configurable based on hardware) |
| **Spawn Radius** | 120m around the player |
| **Despawn Radius** | 200m from the player |
| **Spawn Interval** | Every 0.5s, check spawn/despawn queue |
| **NPC Types** | Citizen, Worker, Tourist, Police, Homeless |

### Spawn Point Strategy
NPCs spawn at pre-defined **spawn nodes** placed along sidewalks and at building entrances. They despawn when they walk beyond the despawn radius or reach a valid exit node.

```text
[Sidewalk Spawn Nodes]
     ●         ●         ●
  ───┼─────────┼─────────┼───
     │         │         │
  ───┼─────────┼─────────┼───
     ●         ●         ●
```

---

## Step 2 — NPC Data Model

Each NPC instance carries a lightweight data profile.

```gdscript
class_name NPCData

var npc_id: String
var first_name: String
var last_name: String
var npc_type: String  # "citizen", "worker", "tourist", "police"
var home_position: Vector3
var work_position: Vector3
var current_state: String  # "idle", "walking", "fleeing", "talking"
var walk_speed: float = 1.4  # meters per second
var run_speed: float = 4.0
var schedule: Dictionary  # time-based daily routine
```

---

## Step 3 — NPC Manager (`NPCManager.gd`)

The NPC Manager is an autoload singleton that handles spawning, despawning, and updating all active NPCs.

```gdscript
extends Node

const MAX_ACTIVE_NPCS: int = 80
const SPAWN_RADIUS: float = 120.0
const DESPAWN_RADIUS: float = 200.0

var active_npcs: Array[Node3D] = []
var spawn_points: Array[Node3D] = []
var player: Node3D

func _ready() -> void:
    player = get_tree().get_first_node_in_group("Player")

func _process(_delta: float) -> void:
    _manage_population()

func _manage_population() -> void:
    if not player: return
    
    # Despawn NPCs that are too far
    for npc in active_npcs:
        if is_instance_valid(npc):
            var dist = npc.global_position.distance_to(player.global_position)
            if dist > DESPAWN_RADIUS:
                _despawn_npc(npc)
        else:
            active_npcs.erase(npc)
    
    # Spawn new NPCs if below cap
    while active_npcs.size() < MAX_ACTIVE_NPCS:
        var spawn = _find_valid_spawn_point()
        if spawn == null: break
        _spawn_npc(spawn.global_position)

func _find_valid_spawn_point() -> Node3D:
    for point in spawn_points:
        if point.global_position.distance_to(player.global_position) <= SPAWN_RADIUS:
            # Check if this point is not visible to the player (spawn behind buildings)
            if not _is_point_visible_to_player(point.global_position):
                return point
    return null

func _is_point_visible_to_player(point: Vector3) -> bool:
    # Simple distance + FOV check; can be upgraded with raycast occlusion
    var to_point = point - player.global_position
    var cam_dir = -player.get_viewport().get_camera_3d().global_transform.basis.z
    return to_point.normalized().dot(cam_dir) > 0.7 and to_point.length() < 60.0

func _spawn_npc(pos: Vector3) -> void:
    var npc_scene = preload("res://scenes/npc/NPC_Base.tscn")
    var npc = npc_scene.instantiate()
    npc.global_position = pos
    get_tree().current_scene.add_child(npc)
    npc.set_data(NPCGenerator.generate_random())
    active_npcs.append(npc)

func _despawn_npc(npc: Node3D) -> void:
    active_npcs.erase(npc)
    npc.queue_free()
```

---

## Step 4 — Wandering AI State Machine (`NPC_Base.gd`)

Each NPC uses a simple finite state machine (FSM) for believable wandering.

### States
```
IDLE  →  WALKING  →  IDLE  →  WALKING  →  FLEEING (if alarmed)
```

```gdscript
extends CharacterBody3D
class_name NPCBase

var data: NPCData
var state: String = "idle"
var target_position: Vector3
var idle_timer: float = 0.0

func _physics_process(delta: float) -> void:
    match state:
        "idle":    _state_idle(delta)
        "walking": _state_walking(delta)
        "fleeing": _state_fleeing(delta)

func _state_idle(delta: float) -> void:
    idle_timer -= delta
    if idle_timer <= 0.0:
        _pick_new_wander_target()
        state = "walking"

func _state_walking(delta: float) -> void:
    var dir = (target_position - global_position)
    dir.y = 0
    var dist = dir.length()
    
    if dist < 1.0:
        state = "idle"
        idle_timer = randf_range(2.0, 8.0)
        return
    
    dir = dir.normalized()
    velocity = dir * data.walk_speed
    # Face direction of movement
    if velocity.length() > 0.1:
        var look_target = global_position + velocity
        look_at(Vector3(look_target.x, global_position.y, look_target.z), Vector3.UP)
    
    move_and_slide()

func _pick_new_wander_target() -> void:
    # Pick a random point on the sidewalk NavMesh within 15-40m
    var random_offset = Vector3(
        randf_range(-40.0, 40.0),
        0,
        randf_range(-40.0, 40.0)
    )
    target_position = global_position + random_offset

func _state_fleeing(delta: float) -> void:
    # Run away from threat
    var threat_pos = data.current_threat_position
    var flee_dir = (global_position - threat_pos).normalized()
    velocity = flee_dir * data.run_speed
    move_and_slide()
    
    # Return to idle after 5 seconds
    data.flee_timer -= delta
    if data.flee_timer <= 0.0:
        state = "idle"
        idle_timer = 1.0
```

---

## Step 5 — NPC Animation Blending

NPCs use a simple `AnimationTree` with a blend space for idle-to-walk transitions.

```text
AnimationTree
├── BlendSpace1D (movement_speed)
│   ├── 0.0  → Idle.anim
│   ├── 0.5  → Walk.anim
│   └── 1.0  → Run.anim
└── State Machine
    ├── Locomotion (BlendSpace1D)
    └── Talking (Talk.anim)
```

The `blend_position` is updated each frame based on `velocity.length()`:

```gdscript
func _process(_delta: float) -> void:
    $AnimationTree.set("parameters/movement_speed/blend_position", velocity.length() / data.run_speed)
```

This ensures smooth visual transitions between standing, walking, and running without jarring animation pops.
