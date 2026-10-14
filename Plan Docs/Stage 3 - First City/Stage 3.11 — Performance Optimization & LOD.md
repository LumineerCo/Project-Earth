# Stage 3.11 — Performance Optimization & LOD

An open-world city with hundreds of buildings, dozens of NPCs, and moving vehicles can overwhelm even capable hardware. This stage defines the performance optimization strategy to keep Nova City running smoothly.

---

## Goal
Maintain a stable 60 FPS target on mid-range hardware through LOD systems, occlusion culling, draw call batching, and smart resource management.

---

## Step 1 — Performance Budget

| Component | Budget (ms/frame) | Notes |
| :--- | :--- | :--- |
| **Rendering** | 12 ms | Buildings, roads, props |
| **NPC AI** | 4 ms | Up to 80 active NPCs |
| **Vehicle AI** | 3 ms | Up to 40 active vehicles |
| **Physics** | 3 ms | Vehicle bodies, raycasts |
| **Audio** | 1 ms | Stream mixing |
| **Gameplay Logic** | 2 ms | Economy, time, missions |
| **Total** | 25 ms | Leaves 11 ms headroom for 60 FPS |

---

## Step 2 — Level of Detail (LOD) System

Each building and prop uses multiple LOD meshes that swap based on distance from the camera.

### LOD Distance Thresholds

| LOD Level | Distance Range | Triangle Budget | Features |
| :--- | :--- | :--- | :--- |
| **LOD0** | 0–30m | Full detail | All windows, props, interiors visible |
| **LOD1** | 30–80m | 50% reduction | Simplified geometry, baked windows |
| **LOD2** | 80–150m | 25% reduction | Flat facades, no window detail |
| **LOD3** | 150–300m | 10% reduction | Simple box shape with texture |
| **LOD4 (Billboard)** | 300m+ | 2 triangles | Flat sprite |

### `LODController.gd`

```gdscript
extends Node
class_name LODController

@export var lod_meshes: Array[MeshInstance3D] = []  # [LOD0, LOD1, LOD2, LOD3]
@export var billboard: SpriteBase3D
@export var lod_distances: Array[float] = [30.0, 80.0, 150.0, 300.0]

var camera: Camera3D

func _ready() -> void:
    camera = get_viewport().get_camera_3d()
    _set_lod(0)

func _process(_delta: float) -> void:
    if not camera: return
    var distance = global_position.distance_to(camera.global_position)
    _update_lod(distance)

func _update_lod(distance: float) -> void:
    for i in range(lod_distances.size()):
        if distance < lod_distances[i]:
            _set_lod(i)
            return
    _set_billboard()

func _set_lod(level: int) -> void:
    billboard.visible = false
    for i in range(lod_meshes.size()):
        lod_meshes[i].visible = (i == level)

func _set_billboard() -> void:
    for mesh in lod_meshes:
        mesh.visible = false
    billboard.visible = true
```

---

## Step 3 — Occlusion Culling

Buildings that are behind other buildings should not be rendered. Godot's built-in occlusion culling handles this.

### Setup

1. Enable occlusion culling in Project Settings → Rendering → Occlusion Culling → Use Occlusion Culling
2. Add `OccluderInstance3D` nodes to large buildings
3. Bake occluder meshes in the scene

```gdscript
# In BuildingBase.gd
func _ready() -> void:
    var occluder = OccluderInstance3D.new()
    var box = BoxOccluder3D.new()
    box.size = Vector3(building_width, building_height, building_depth)
    occluder.occluder = box
    occluder.bake_global_transform = global_transform
    add_child(occluder)
```

---

## Step 4 — Multi-Mesh Instancing for Props

Street props (lampposts, benches, trash cans, fire hydrants) are rendered as a single `MultiMeshInstance3D` per district to reduce draw calls.

### `PropCluster.gd`

```gdscript
extends MultiMeshInstance3D

func _ready() -> void:
    var multimesh = MultiMesh.new()
    multimesh.transform_format = MultiMesh.TRANSFORM_3D
    multimesh.mesh = load("res://meshes/props/lamppost.mesh")
    multimesh.instance_count = 0  # set dynamically
    
    var positions = _get_prop_positions()
    multimesh.instance_count = positions.size()
    
    for i in range(positions.size()):
        var t = Transform3D()
        t = t.translated(positions[i])
        t = t.rotated(Vector3.UP, randf() * TAU)
        multimesh.set_instance_transform(i, t)
    
    multimesh_ = multimesh

func _get_prop_positions() -> Array[Vector3]:
    # Read from district prop placement data
    return DistrictSystem.get_prop_positions(global_position)
```

---

## Step 5 — Texture Streaming & Compression

| Texture Type | Compression | Max Resolution | Mipmaps |
| :--- | :--- | :--- | :--- |
| **Building facades** | BPTC (desktop) / ASTC (mobile) | 2048x2048 | Yes |
| **Road textures** | BPTC | 1024x1024 | Yes |
| **Prop textures** | BPTC | 512x512 | Yes |
| **UI textures** | Lossless | 2048x2048 | No |
| **Skybox** | Lossless | 4096x2048 | No |

### Texture LOD Bias

```gdscript
# In Project Settings or runtime:
# rendering/textures/default_texture_filter = LINEAR_MIPMAPS
# rendering/limits/streaming/texture_streaming_budget = 512 MB
```

---

## Step 6 — NPC & Vehicle Update Throttling

Not every NPC needs to update every frame. Distant NPCs update less frequently.

### `AIUpdateThrottler.gd`

```gdscript
extends Node

var update_intervals: Dictionary = {}  # {node: interval}
var timers: Dictionary = {}  # {node: accumulated_time}

func register(node: Node, interval: float) -> void:
    update_intervals[node] = interval
    timers[node] = 0.0

func should_update(node: Node, delta: float) -> bool:
    if not update_intervals.has(node): return true
    timers[node] += delta
    if timers[node] >= update_intervals[node]:
        timers[node] = 0.0
        return true
    return false

func unregister(node: Node) -> void:
    update_intervals.erase(node)
    timers.erase(node)
```

### Usage in NPCManager

```gdscript
func _process(delta: float) -> void:
    for npc in active_npcs:
        var distance = npc.global_position.distance_to(player.global_position)
        var interval = 0.0
        
        if distance < 30.0:
            interval = 0.0  # every frame
        elif distance < 80.0:
            interval = 0.05  # 20 Hz
        elif distance < 150.0:
            interval = 0.15  # ~7 Hz
        else:
            interval = 0.5  # 2 Hz
        
        if ai_throttler.should_update(npc, delta):
            npc._update_ai(delta)
```

---

## Step 7 — Performance Monitoring

A built-in performance overlay helps identify bottlenecks during development.

```gdscript
# In DebugMenu
func _input(event: InputEvent) -> void:
    if event.is_action_pressed("debug_toggle_perf"):
        $PerformanceOverlay.visible = not $PerformanceOverlay.visible

# PerformanceOverlay.gd
extends Label

func _process(_delta: float) -> void:
    text = "FPS: %d | Draw Calls: %d | Verts: %d | Mem: %d MB" % [
        Engine.get_frames_per_second(),
        RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS),
        RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
        Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
    ]
```

---

## Step 8 — Optimization Checklist

| Technique | Status | Impact |
| :--- | :--- | :--- |
| LOD meshes on all buildings | Required | -40% render cost |
| Occlusion culling | Required | -30% render cost in dense areas |
| MultiMesh for props | Required | -90% draw calls for props |
| AI update throttling | Required | -50% AI CPU cost |
| Texture streaming | Required | Stable VRAM usage |
| Shadow distance limits | Required | -20% render cost |
| Scene instancing for buildings | Required | Shared resources |
| Physics server simplification | Optional | -10% physics cost |

These optimizations ensure Nova City remains performant even as content density increases in later stages.
