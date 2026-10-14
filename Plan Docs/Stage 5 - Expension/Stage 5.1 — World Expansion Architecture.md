# Stage 5.1 — World Expansion Architecture

The technical foundation that enables a planet-scale world with multiple cities, biomes, and seamless streaming.

---

## Goal
Build a world streaming architecture that supports multiple regions, cities, and biomes with dynamic loading and unloading.

---

## Step 1 — Region System

The planet is divided into regions, each containing a city or biome.

### Region Map

```
+----------------+----------------+----------------+
|                |                |                |
|   Summit Peak  |   Nova City    |   Harbor Bay   |
|   (Mountain)   |   (Urban)      |   (Coastal)    |
|                |                |                |
+----------------+----------------+----------------+
|                |                |                |
|   Greenfield   |   Central Hub |   Wasteland    |
|   (Rural)      |   (Airport)   |   (Desert)      |
|                |                |                |
+----------------+----------------+----------------+
```

### `RegionData.gd`

```gdscript
extends Resource
class_name RegionData

@export var region_id: String = ""
@export var display_name: String = ""
@export var biome_type: String = "urban"  # urban, coastal, mountain, rural, desert
@export var scene_path: String = ""
@export var world_position: Vector2 = Vector2.ZERO  # Grid position on planet map
@export var size: Vector2 = Vector2(2000, 2000)  # Region dimensions in meters
@export var connections: Array[String] = []  # Connected region IDs
@export var default_weather: String = "clear"
@export var min_level: int = 1  # Recommended player level
@export var fast_travel_cost: int = 0  # Cost to fast travel here
```

---

## Step 2 — World Streaming Manager

### `WorldStreamingManager.gd` (Autoload)

```gdscript
extends Node

signal region_loaded(region_id: String)
signal region_unloaded(region_id: String)

var regions: Dictionary = {}  # region_id -> RegionData
var loaded_regions: Dictionary = {}  # region_id -> Node
var current_region_id: String = ""
var load_radius: float = 1500.0  # Load regions within this distance

const REGIONS_DIR = "res://scenes/world/regions/"

func _ready() -> void:
    _register_regions()

func _register_regions() -> void:
    var dir = DirAccess.open(REGIONS_DIR)
    if dir == null: return
    dir.list_dir_begin()
    var file = dir.get_next()
    while file != "":
        if file.ends_with(".tres"):
            var region = load(REGIONS_DIR + file) as RegionData
            if region:
                regions[region.region_id] = region
        file = dir.get_next()

func set_current_region(region_id: String) -> void:
    current_region_id = region_id
    _update_streaming()

func _process(delta: float) -> void:
    if current_region_id == "": return
    _update_streaming()

func _update_streaming() -> void:
    var player = get_tree().get_first_node_in_group("player")
    if player == null: return
    
    var current_region = regions[current_region_id]
    var player_grid = current_region.world_position
    
    # Load nearby regions
    for region_id in regions:
        var region = regions[region_id]
        var distance = player_grid.distance_to(region.world_position) * 2000.0
        
        if distance < load_radius:
            if not loaded_regions.has(region_id):
                _load_region(region_id)
        else:
            if loaded_regions.has(region_id):
                _unload_region(region_id)

func _load_region(region_id: String) -> void:
    var region = regions[region_id]
    var scene = load(region.scene_path)
    if scene == null:
        push_error("Failed to load region scene: " + region.scene_path)
        return
    
    var instance = scene.instantiate()
    get_tree().current_scene.add_child(instance)
    
    # Position region in world space
    var world_pos = Vector3(
        region.world_position.x * region.size.x, 0,
        region.world_position.y * region.size.y)
    instance.global_position = world_pos
    
    loaded_regions[region_id] = instance
    region_loaded.emit(region_id)

func _unload_region(region_id: String) -> void:
    if not loaded_regions.has(region_id): return
    var instance = loaded_regions[region_id]
    
    # Save region state before unloading
    _save_region_state(region_id, instance)
    
    instance.queue_free()
    loaded_regions.erase(region_id)
    region_unloaded.emit(region_id)

func _save_region_state(region_id: String, region_node: Node) -> void:
    # Save dynamic objects, NPC positions, vehicle positions
    var state = {
        "npcs": [],
        "vehicles": [],
        "dynamic_objects": [],
    }
    for npc in region_node.get_tree().get_nodes_in_group("npc"):
        if npc.get_parent() == region_node or region_node.is_ancestor_of(npc):
            state["npcs"].append({
                "npc_id": npc.npc_id,
                "position": npc.global_position,
            })
    # Store in memory or save to disk
    GlobalWorldState.region_states[region_id] = state

func get_region_at_position(world_pos: Vector3) -> String:
    for region_id in regions:
        var region = regions[region_id]
        var region_origin = Vector3(
            region.world_position.x * region.size.x, 0,
            region.world_position.y * region.size.y)
        var local_pos = world_pos - region_origin
        if local_pos.x >= 0 and local_pos.x < region.size.x and \
           local_pos.z >= 0 and local_pos.z < region.size.y:
            return region_id
    return ""

func travel_to_region(region_id: String) -> void:
    if not regions.has(region_id): return
    set_current_region(region_id)
    var region = regions[region_id]
    var spawn_pos = Vector3(
        region.world_position.x * region.size.x + region.size.x / 2, 0,
        region.world_position.y * region.size.y + region.size.y / 2)
    var player = get_tree().get_first_node_in_group("player")
    player.global_position = spawn_pos
```

---

## Step 3 — Planet Map System

### `PlanetMap.gd`

```gdscript
extends Control
class_name PlanetMap

@onready var map_texture = $MapTexture
@onready var region_markers = $RegionMarkers

var region_icons: Dictionary = {}

func _ready() -> void:
    _create_region_markers()

func _create_region_markers() -> void:
    for region_id in WorldStreamingManager.regions:
        var region = WorldStreamingManager.regions[region_id]
        var marker = Button.new()
        marker.text = region.display_name
        marker.position = _world_to_map_position(region.world_position)
        marker.size = Vector2(120, 40)
        marker.pressed.connect(_on_region_selected.bind(region_id))
        region_markers.add_child(marker)
        region_icons[region_id] = marker

func _world_to_map_position(grid_pos: Vector2) -> Vector2:
    # Convert grid position to map UI position
    var map_size = map_texture.size
    var scale = map_size / Vector2(6000, 6000)  # Total planet size
    return grid_pos * 2000.0 * scale

func _on_region_selected(region_id: String) -> void:
    var region = WorldStreamingManager.regions[region_id]
    if region.fast_travel_cost > 0:
        if MoneySystem.cash < region.fast_travel_cost:
            PhoneSystem.add_notification("Travel", "Insufficient Funds",
                "You need %d Cr to travel to %s." % [region.fast_travel_cost, region.display_name])
            return
        MoneySystem.spend_cash(region.fast_travel_cost)
    
    # Show loading screen
    LoadingScreen.show("Traveling to " + region.display_name)
    await LoadingScreen.shown
    
    WorldStreamingManager.travel_to_region(region_id)
    LoadingScreen.hide()
```

---

## Step 4 — Loading Screen

### `LoadingScreen.gd`

```gdscript
extends CanvasLayer

signal shown

@onready var progress_bar = $Panel/ProgressBar
@onready var tip_label = $Panel/TipLabel
@onready var title_label = $Panel/TitleLabel

var tips: Array[String] = [
    "Tip: Press F to interact with objects and people.",
    "Tip: Visit an ATM to deposit cash safely.",
    "Tip: Sleeping restores energy and saves your game.",
    "Tip: Higher wanted levels mean more police response.",
    "Tip: Gifts improve relationships with NPCs.",
    "Tip: Keep your vehicle fueled — running out strands you.",
    "Tip: Jobs pay better as you level up your skills.",
    "Tip: Property generates passive income through rent.",
    "Tip: The countryside has unique jobs and activities.",
    "Tip: Wildlife can be hunted for food and materials.",
]

func _ready() -> void:
    visible = false

func show(title: String = "Loading...") -> void:
    title_label.text = title
    tip_label.text = tips.pick_random()
    progress_bar.value = 0
    visible = true
    shown.emit()

func hide() -> void:
    visible = false

func set_progress(value: float) -> void:
    progress_bar.value = value * 100.0
```

---

## Step 5 — Cross-Region Systems

Systems that operate across all regions need to be region-aware.

### `GlobalWorldState.gd` (Updated)

```gdscript
extends Node

var player_global_position: Vector3 = Vector3.ZERO
var current_weather: String = "clear"
var current_season: String = "spring"
var playtime: float = 0.0
var region_states: Dictionary = {}  # region_id -> saved state

func find_nearest_location(from: Vector3, type: String) -> Vector3:
    var current_region = WorldStreamingManager.get_region_at_position(from)
    if current_region == "": return Vector3.ZERO
    
    var region = WorldStreamingManager.regions[current_region]
    var region_origin = Vector3(
        region.world_position.x * region.size.x, 0,
        region.world_position.y * region.size.y)
    
    # Search within current region
    var nearest = Vector3.ZERO
    var nearest_dist = INF
    var locations = _get_locations_in_region(current_region, type)
    for loc in locations:
        var dist = from.distance_to(loc)
        if dist < nearest_dist:
            nearest_dist = dist
            nearest = loc
    return nearest

func _get_locations_in_region(region_id: String, type: String) -> Array:
    # Query location database for this region and type
    return []
```

The world expansion architecture provides the technical backbone for a planet-scale game, enabling seamless travel between diverse regions.
