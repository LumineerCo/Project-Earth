# Stage 3.8 — Navigation Mesh & Pathfinding

For NPCs and vehicles to move intelligently through the city, they need a wayfinding system. This stage defines the navigation mesh setup, A* pathfinding graph, and how AI agents calculate routes from point A to point B.

---

## Goal
Create a robust navigation system that supports both pedestrian NavMesh pathfinding and vehicle road-graph pathfinding.

---

## Step 1 — Dual Navigation Systems

Nova City uses two separate navigation systems because pedestrians and vehicles have fundamentally different movement rules.

| System | Technology | Used By | Purpose |
| :--- | :--- | :--- | :--- |
| **Pedestrian NavMesh** | Godot `NavigationRegion3D` | NPCs, Player (on foot) | Walk on sidewalks, avoid obstacles |
| **Vehicle Road Graph** | Custom A* graph | AI Vehicles, Player (driving) | Follow lanes, obey one-way rules |

---

## Step 2 — Pedestrian NavMesh Setup

### Baking the NavMesh

In Godot, we use `NavigationRegion3D` nodes to define walkable areas. Each district has its own NavMesh region.

```text
NovaCity/
├── Navigation/
│   ├── NavMesh_CentralPlaza (NavigationRegion3D)
│   ├── NavMesh_Financial (NavigationRegion3D)
│   ├── NavMesh_Suburban (NavigationRegion3D)
│   ├── NavMesh_Industrial (NavigationRegion3D)
│   └── NavMesh_Coastal (NavigationRegion3D)
```

### NavMesh Baking Rules

| Parameter | Value | Reason |
| :--- | :--- | :--- |
| **Agent Radius** | 0.4m | Human shoulder width |
| **Agent Height** | 1.8m | Average human height |
| **Max Slope** | 35° | Stairs and ramps |
| **Max Step Height** | 0.3m | Curbs and steps |
| **Region Min Size** | 2.0m | Avoid tiny walkable slivers |

### Baking at Runtime

```gdscript
extends NavigationRegion3D

func _ready() -> void:
    # Bake NavMesh at runtime for dynamic obstacle support
    NavigationServer3D.map_set_active(get_world_3d().navigation_map, true)
    bake_navigation_mesh(false)  # false = async, non-blocking
```

---

## Step 3 — NPC Pathfinding (`NPCNavigation.gd`)

NPCs request paths from the navigation server and follow them.

```gdscript
extends Node

var navigation_agent: NavigationAgent3D

func _ready() -> void:
    navigation_agent = NavigationAgent3D.new()
    add_child(navigation_agent)
    navigation_agent.path_desired_distance = 1.0
    navigation_agent.target_desired_distance = 1.5

func set_destination(target: Vector3) -> void:
    navigation_agent.target_position = target

func _physics_process(delta: float) -> void:
    if navigation_agent.is_navigation_finished():
        return
    
    var next_pos = navigation_agent.get_next_path_position()
    var direction = (next_pos - owner.global_position)
    direction.y = 0
    direction = direction.normalized()
    
    var character = owner as CharacterBody3D
    character.velocity = direction * character.walk_speed
    character.move_and_slide()
    
    # Face movement direction
    if direction.length() > 0.1:
        var look_pos = character.global_position + direction
        character.look_at(Vector3(look_pos.x, character.global_position.y, look_pos.z), Vector3.UP)
```

---

## Step 4 — Vehicle Road Graph (A* Pathfinding)

Vehicles do not use NavMesh. Instead, they use a custom graph of road nodes connected by lane paths.

### Graph Structure

```text
RoadNode_A ──[Lane]── RoadNode_B ──[Lane]── RoadNode_C
     │                                    │
  [Lane]                               [Lane]
     │                                    │
RoadNode_D ──[Lane]── RoadNode_E ──[Lane]── RoadNode_F
```

### `RoadGraph.gd`

```gdscript
class_name RoadGraph

var nodes: Dictionary = {}  # {node_id: RoadGraphNode}
var edges: Dictionary = {}  # {node_id: [connected_node_ids]}

func add_node(node_id: String, position: Vector3) -> void:
    nodes[node_id] = {"id": node_id, "position": position}

func add_edge(from_id: String, to_id: String, lane: Path3D, distance: float) -> void:
    if not edges.has(from_id):
        edges[from_id] = []
    edges[from_id].append({"to": to_id, "lane": lane, "distance": distance})

func find_path(start_id: String, goal_id: String) -> Array:
    # A* pathfinding
    var open_set = [start_id]
    var came_from = {}
    var g_score = {start_id: 0.0}
    var f_score = {start_id: _heuristic(start_id, goal_id)}
    
    while open_set.size() > 0:
        # Get node with lowest f_score
        var current = _get_lowest_f(open_set, f_score)
        
        if current == goal_id:
            return _reconstruct_path(came_from, current)
        
        open_set.erase(current)
        
        for edge in edges.get(current, []):
            var neighbor = edge["to"]
            var tentative_g = g_score[current] + edge["distance"]
            
            if not g_score.has(neighbor) or tentative_g < g_score[neighbor]:
                came_from[neighbor] = current
                g_score[neighbor] = tentative_g
                f_score[neighbor] = tentative_g + _heuristic(neighbor, goal_id)
                if not open_set.has(neighbor):
                    open_set.append(neighbor)
    
    return []  # no path found

func _heuristic(from_id: String, to_id: String) -> float:
    return nodes[from_id]["position"].distance_to(nodes[to_id]["position"])

func _get_lowest_f(open_set: Array, f_score: Dictionary) -> String:
    var lowest = open_set[0]
    for node_id in open_set:
        if f_score.get(node_id, INF) < f_score.get(lowest, INF):
            lowest = node_id
    return lowest

func _reconstruct_path(came_from: Dictionary, current: String) -> Array:
    var path = [current]
    while came_from.has(current):
        current = came_from[current]
        path.insert(0, current)
    return path
```

---

## Step 5 — Dynamic Obstacle Avoidance

Both pedestrians and vehicles need to avoid dynamic obstacles (other NPCs, parked cars, the player).

### Pedestrian Avoidance (RVO2)

Godot includes built-in RVO (Reciprocal Velocity Obstacle) avoidance for `NavigationAgent3D`.

```gdscript
func _ready() -> void:
    navigation_agent.avoidance_enabled = true
    navigation_agent.radius = 0.4
    navigation_agent.avoidance_priority = 1.0
    navigation_agent.velocity_computed.connect(_on_velocity_computed)

func _physics_process(_delta: float) -> void:
    if navigation_agent.is_navigation_finished():
        return
    var next_pos = navigation_agent.get_next_path_position()
    var direction = (next_pos - owner.global_position).normalized()
    var desired_velocity = direction * owner.walk_speed
    navigation_agent.set_velocity(desired_velocity)

func _on_velocity_computed(safe_velocity: Vector3) -> void:
    var character = owner as CharacterBody3D
    character.velocity = safe_velocity
    character.move_and_slide()
```

### Vehicle Avoidance

Vehicles use a simpler raycast-based forward check (defined in Stage 3.6) since they are constrained to lanes and cannot sidestep like pedestrians.

---

## Step 6 — Navigation Debug Visualization

During development, it is critical to visualize NavMesh and road paths.

```gdscript
# Debug toggle in DebugMenu
func _input(event: InputEvent) -> void:
    if event.is_action_pressed("debug_toggle_navmesh"):
        var regions = get_tree().get_nodes_in_group("NavigationRegion")
        for region in regions:
            region.enabled = not region.enabled  # toggle visibility
        DebugManager.toggle_navmesh_debug()
```

This allows the developer to instantly see if NPCs have valid walkable surfaces and if road graph connections are properly linked.
