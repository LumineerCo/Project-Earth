# Stage 3.3 — Buildings & Modular Assets

Creating an open-world city of believable scale requires an optimized, modular approach to modeling and placing structures. Creating unique, custom models for every single building would lead to bloated file sizes and high memory usage.

---

## Goal
Establish a robust modular system for erecting buildings, planning interiors, and optimizing performance through sharing textures and meshes.

---

## Step 1 — Modular Architecture (Building Blocks)

Instead of modeling whole buildings, we model individual, reusable building pieces in Blender. These pieces snap together in Godot.

### Grid Snap Settings (Metric)
* **Wall Units:** 4.0m width x 3.5m height x 0.5m depth.
* **Door Units:** 4.0m width x 3.5m height (fits double-doors or single door + storefront window).
* **Corner Units:** 1.0m x 1.0m x 3.5m.
* **Roof Units:** Flat 4.0m x 4.0m panels.

```text
Modular Building Wall Pieces:
  ┌───────┐   ┌───┬───┐   ┌───────┐
  │       │   │   │   │   │  [O]  │
  │ Wall  │   │ D │ W │   │Window │
  │ (Solid)   │ o │ i │   │ (Shop)│
  └───────┘   └───┴───┘   └───────┘
```

---

## Step 2 — Building Types & Classification

For Nova City, we categorize buildings by their interaction level:

1. **Category A (Full Interiors):**
   * **Examples:** Player houses, shops, police stations, banks, mechanics.
   * **Technical approach:** Separate interior sub-scenes, dynamically loaded when the player steps inside.
2. **Category B (Partial Interiors / Shop Fronts):**
   * **Examples:** Corner stores, small cafés.
   * **Technical approach:** Interior is modeled directly into the main world mesh with lower-resolution details. Transparent windows let players see in.
3. **Category C (Impenetrable / Shells):**
   * **Examples:** Large skyscrapers, industrial storage warehouses.
   * **Technical approach:** Emissive windows, painted-on textures, completely sealed. Zero collision inside.

---

## Step 3 — Interior/Exterior Scene Splitting (Occlusion Culling)

To maintain 60 FPS, we must avoid rendering the interiors of houses when the player is walking on the street.

### Portal/Area Culling Setup

1. **Exterior Shell Node:** Houses are placed in the master world.
2. **Door Sensor (Area3D):** Detects player proximity.
3. **Interior Sub-scene:** Loaded dynamically or unhidden when the door is opened.

```text
               [Exterior World Scene]
           ┌────────────────────────────┐
           │           House Shell           │
           │          ┌──────────┐         │
           │          │   Door     │         │
           │          │   [Area3D] │         │
           │          └────┬─────┘         │
           └─────────────┼──────────────┘
                         ▼
           Loads `Interior_LivingRoom.tscn` 
           using Addon/Runtime Streamer
```

---

## Step 4 — Godot Modular Building Loader (`BuildingBase.gd`)

We can create a helper script in Godot that manages dynamic interior streaming based on player location.

```gdscript
extends StaticBody3D
class_name BuildingBase

@export_file("*.tscn") var interior_scene_path: String
@export var building_id: String = ""

@onready var portal_sensor: Area3D = $PortalSensor

var loaded_interior: Node = null

func _ready() -> void:
    if portal_sensor:
        portal_sensor.body_entered.connect(_on_player_approached)
        portal_sensor.body_exited.connect(_on_player_departed)

func _on_player_approached(body: Node3D) -> void:
    if body.is_in_group("Player") and interior_scene_path != "":
        _load_interior_async()

func _on_player_departed(body: Node3D) -> void:
    if body.is_in_group("Player") and loaded_interior != null:
        _unload_interior()

func _load_interior_async() -> void:
    if loaded_interior: return
    print_verbose("[Building] Loading interior for: " + building_id)
    
    # Instance interior and add under local hierarchy
    var scene = load(interior_scene_path)
    loaded_interior = scene.instantiate()
    add_child(loaded_interior)
    
    # Hide outer shell surfaces that occlude the interior view
    $Shell/Walls_InteriorBack.hide()

func _unload_interior() -> void:
    if not loaded_interior: return
    print_verbose("[Building] Unloading interior: " + building_id)
    loaded_interior.queue_free()
    loaded_interior = null
    $Shell/Walls_InteriorBack.show()
```

This prevents the graphics card from processing thousands of furniture triangles inside closed apartments until they are actually needed.
