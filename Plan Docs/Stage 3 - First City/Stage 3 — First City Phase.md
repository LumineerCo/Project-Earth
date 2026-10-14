Excellent. We are moving from the high-level prototype stage to building the game's actual world. Our first major milestone is creating a living, breathing, playable **First City**.

Rather than designing a massive city that would crush performance and take years of solo labor, we will design a highly organized, modular **First City** (Codename: *Nova City*) that serves as the proof-of-concept for all subsequent cities.

---

# Stage 3 — First City Phase

In this phase, we move from a blank prototype workspace to a structured urban environment. This stage establishes the modular standards for all future world-building, traffic simulation, and urban AI.

```
Stage 3
│
├── 3.1 First City Setup & Concept
├── 3.2 Road Network & Layout
├── 3.3 Buildings & Modular Assets
├── 3.4 NPC Spawning & Wandering AI
├── 3.5 Shops & Economy Integration
├── 3.6 Traffic System & Vehicles
├── 3.7 City Districts & Zoning
├── 3.8 Navigation Mesh & Pathfinding
├── 3.9 Soundscape & City Ambience
├── 3.10 Day-Night Cycle & Lighting
├── 3.11 Performance Optimization & LOD
└── 3.12 First City Playable
```

This stage will produce a **fully playable, detailed urban playground** that acts as the core of the game's initial build.

---

# Stage 3.1 — First City Setup & Concept

## Goal
Establish the aesthetic, map layout, and technical scale of the First City (*Nova City*), organizing the scene hierarchy in Godot to support modular loading.

---

# Step 1 — Nova City Profile

Nova City represents a modern, coastal metropolis with a balance of commercial, residential, and industrial areas. It acts as the player's starting area.

| Characteristic | Detail |
| :--- | :--- |
| **Theme** | Coastal, Pacific Northwest-inspired, clean, semi-stylized modern look |
| **Grid Size** | 2000m x 2000m (4 km² total area) |
| **Target Population** | 50–100 active simulated NPCs at any given time (optimized via proximity) |
| **Target Traffic** | 20–40 active simulated vehicles |
| **Key Landmarks** | Central Plaza, Coastal Marina, Industrial Port, Suburban Hills, Financial District |

---

# Step 2 — Godot Scene Hierarchy

To prevent scene corruption and allow collaborative editing (if you work with others later) or clean organization, we split Nova City into sub-scenes loaded under a main world controller.

```text
res://scenes/world/nova_city/
├── nova_city_main.tscn       # Master scene containing environment and coordinates
├── subscenes/
│   ├── terrain.tscn          # Ground mesh, coast, beaches, hills
│   ├── road_network.tscn     # Asphalt, intersections, traffic paths
│   ├── district_residential.tscn
│   ├── district_commercial.tscn
│   ├── district_industrial.tscn
│   └── city_lighting.tscn    # Streetlights, emissives, neighborhood glows
```

### `nova_city_main.gd` Setup Script Skeleton

```gdscript
extends Node3D

@onready var terrain = $Subscenes/Terrain
@onready var road_network = $Subscenes/RoadNetwork
@onready var npc_manager = $Managers/NPCManager
@onready var traffic_manager = $Managers/TrafficManager

func _ready() -> void:
    print_verbose("[Nova City] Initializing master city systems...")
    _initialize_districts()
    _bootstrap_simulation()

func _initialize_districts() -> void:
    # Set up district coordinate bounds for zoning checks
    GlobalWorldState.register_city("Nova City", self)

func _bootstrap_simulation() -> void:
    # Trigger spawning systems
    npc_manager.start_city_simulation()
    traffic_manager.start_traffic_simulation()
```

---

# Step 3 — Coordinate Standards

To ensure perfect alignment of roads and buildings, we adopt a strict **metric grid scale**:
* **1 Godot Unit** = 1 Meter.
* **Standard Lane Width** = 4.0 Meters.
* **Standard Sidewalk Width** = 2.5 Meters.
* **Modular Building Grid** = 5.0m x 5.0m or 10.0m x 10.0m increments.
* **Origin (0,0,0)** = Central Plaza Fountain.

By establishing these rules, all assets imported from Blender will align perfectly without requiring scaling or manual offset adjustments in the Godot Inspector.
