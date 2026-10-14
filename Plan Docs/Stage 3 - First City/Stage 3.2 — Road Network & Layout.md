# Stage 3.2 — Road Network & Layout

A believable open-world city requires a solid, cohesive road network. This acts as the skeletal structure of the city, defining where buildings are placed, how pedestrians navigate, and where traffic flows.

---

## Goal
Design and construct a modular road system for Nova City using spline paths, path-following systems, and standardized intersections.

---

## Step 1 — Road Hierarchy & Specifications

We define four types of roads to structure the city layout logically.

| Road Type | Lanes | Width (Total) | Sidewalks | Target Speed |
| :--- | :--- | :--- | :--- | :--- |
| **Highway / Arterial** | 4–6 Lanes | 24m–32m | None | 80–110 km/h |
| **Main Avenue** | 4 Lanes (with median) | 20m | 3.0m on each side | 50–60 km/h |
| **Collector / Local Road** | 2 Lanes | 10m | 2.5m on each side | 30–40 km/h |
| **Alleys / Service Lanes** | 1 Lane (Shared) | 4.5m | 1.0m (unmarked) | 15–20 km/h |

---

## Step 2 — Intersection Design Standards

Intersections are the most complex part of any road network. We design them using modular connectors:

* **T-Intersection:** Used to connect local residential streets to major avenues.
* **4-Way Crossroads:** Used in the commercial downtown area.
* **Roundabout:** Used at key collectors to prevent traffic jams.

### Aligning Intersections
Each intersection must be centered precisely on a metric grid coordinate (e.g., multiples of 10 meters) to allow seamless snaps of building blocks adjacent to them.

```text
       [Road Lane Up ↑]
              │
       ┌──────┼──────┐
───────┼──────┼──────┼───────  [Cross Street]
       │  Intersection  │
───────┼──────┼──────┼───────
       └──────┼──────┘
              │
       [Road Lane Down ↓]
```

---

## Step 3 — Godot Spline Implementation (Path3D)

In Godot, we represent lanes using `Path3D` nodes and `Curve3D` splines. These paths will guide the traffic and NPC systems.

### Spline Layout
* **Vehicle Path:** Drawn down the center of each lane.
* **Pedestrian Path:** Drawn down the center of the sidewalk.
* **Connection Points:** Intersections contain internal spline connections that bind incoming lanes to outgoing lanes.

### Scene Hierarchy for a Road Segment

```text
RoadSegment_A/ (Node3D)
├── MeshInstance3D (Visual Road Mesh)
├── StaticBody3D (Collision for physics)
├── Lanes/
│   ├── Lane_Right (Path3D)
│   └── Lane_Left (Path3D)
└── Sidewalks/
    ├── Sidewalk_Right (Path3D)
    └── Sidewalk_Left (Path3D)
```

---

## Step 4 — Node Linker System

To build a pathfinding graph for AI vehicles, each road segment registers its input and output connectors with a global navigation database.

### Linker Script Configuration (`RoadSegment.gd`)

```gdscript
extends Node3D
class_name RoadSegment

@export var speed_limit: float = 50.0
@export var adjacent_segments: Array[RoadSegment] = []

@onready var lane_right: Path3D = $Lanes/Lane_Right
@onready var lane_left: Path3D = $Lanes/Lane_Left

func _ready() -> void:
    _register_with_traffic_system()

func _register_with_traffic_system() -> void:
    if Engine.is_editor_hint(): return
    TrafficSystem.register_road(self)

# Returns a point along the lane closest to a target position
func get_closest_point(lane_index: int, target_pos: Vector3) -> Vector3:
    var path = lane_right if lane_index == 0 else lane_left
    var local_pos = path.to_local(target_pos)
    var offset = path.curve.get_closest_offset(local_pos)
    return path.to_global(path.curve.sample_baked(offset))
```

This system ensures that when an NPC needs to drive somewhere, they can calculate a path using A* from node to node through interconnected road paths.
