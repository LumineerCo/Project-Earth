# Stage 5.10 — Mod Support & Workshop

A robust modding system extends the game's lifespan by empowering the community to create new content — cities, vehicles, missions, items, NPCs, and gameplay systems. Steam Workshop integration provides a central hub for discovering, downloading, and managing mods.

---

## Goal
Build a comprehensive modding framework with a Lua/GDScript modding API, asset loading pipeline, Steam Workshop integration, mod management UI, and sandboxed execution to protect game stability and player security.

---

## Step 1 — Mod Architecture Overview

```text
┌─────────────────────────────────────────────────────────────────┐
│                      Mod System Architecture                     │
│                                                                  │
│   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐        │
│   │  Mod Loader  │───►│  Mod API    │───►│  Game Hooks  │        │
│   │  (discovers, │    │  (Lua VM +  │    │  (events,    │        │
│   │   loads,     │    │   GDScript  │    │   overrides) │        │
│   │   unloads)    │    │   bindings) │    │              │        │
│   └──────┬───────┘    └─────────────┘    └─────────────┘        │
│          │                                                       │
│          ▼                                                       │
│   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐        │
│   │  Mod Manager │    │  Workshop   │    │  Mod Sandbox │        │
│   │  (UI, enable/│    │  (upload,   │    │  (resource  │        │
│   │   disable,   │    │   download, │    │   limits,   │        │
│   │   configure) │    │   subscribe)│    │   security)  │        │
│   └─────────────┘    └─────────────┘    └─────────────┘        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Mod Types

| Mod Type | Description | Examples | Risk Level |
| :--- | :--- | :--- | :--- |
| **Asset Mod** | Adds new models, textures, sounds | New cars, building skins | Low |
| **Content Mod** | Adds new gameplay content | New cities, missions, items | Medium |
| **Script Mod** | Adds new GDScript/Lua logic | New game mechanics, AI behaviors | High |
| **Total Conversion** | Replaces core systems | Different setting, new gameplay | Very High |
| **Utility Mod** | Quality of life, tools | Map editor, debug tools | Low |
| **Library Mod** | Provides API for other mods | Framework, shared utilities | Medium |

---

## Step 2 — Mod File Structure

### Mod Package Format

```text
my_awesome_mod/
├── mod.toml              # Mod metadata (required)
├── preview.png           # Workshop preview image (512x512)
├── changelog.txt         # Version history
├── scripts/              # GDScript or Lua scripts
│   ├── init.gd           # Entry point (called on load)
│   └── systems/
│       └── custom_npc.gd
├── assets/               # Custom assets
│   ├── models/
│   │   └── custom_car.glb
│   ├── textures/
│   │   └── custom_car.png
│   └── sounds/
│       └── engine_v8.wav
├── data/                 # Data files (JSON/TOML)
│   ├── items.json        # New items
│   ├── vehicles.json     # New vehicles
│   └── missions.json     # New missions
├── locales/              # Translations
│   ├── en.po
│   └── hi.po
└── config/               # Mod-specific config
    └── settings.toml
```

### `mod.toml` Metadata Format

```toml
[mod]
id = "my_awesome_mod"
name = "My Awesome Mod"
version = "1.2.0"
author = "ModderName"
description = "Adds 5 new sports cars and a racing mission chain."
game_version = ">=1.0.0"
type = "content"
load_order = 100

[dependencies]
# This mod requires these mods to be loaded first
required = ["earth_core_lib@>=1.0.0"]
optional = ["enhanced_graphics@>=2.0.0"]

[conflicts]
# This mod conflicts with these mods
incompatible = ["old_car_replacer"]

[permissions]
# Declared permissions for sandbox
file_access = ["user://my_awesome_mod/"]
network_access = false
custom_shaders = true
```

---

## Step 3 — Mod Loader

### `ModLoader.gd`

```gdscript
extends Node
class_name ModLoader

const MODS_DIR = "user://mods/"
const WORKSHOP_DIR = "user://workshop/"

var loaded_mods: Dictionary = {}  # mod_id -> ModInstance
var mod_load_order: Array[String] = []
var mod_api: ModAPI

signal mod_loaded(mod_id: String)
signal mod_unloaded(mod_id: String)
signal mod_load_failed(mod_id: String, reason: String)

func _ready() -> void:
    mod_api = ModAPI.new()
    mod_api.mod_loader = self
    _discover_mods()

func _discover_mods() -> void:
    var dirs = [MODS_DIR, WORKSHOP_DIR]
    for base_dir in dirs:
        var dir = DirAccess.open(base_dir)
        if not dir:
            continue
        dir.list_dir_begin()
        var folder = dir.get_next()
        while folder != "":
            if dir.current_is_dir() and not folder.begins_with("."):
                var mod_path = base_dir + folder + "/"
                if FileAccess.file_exists(mod_path + "mod.toml"):
                    _register_mod(mod_path, folder)
            folder = dir.get_next()
        dir.list_dir_end()
    
    _resolve_load_order()
    _load_all_mods()

func _register_mod(mod_path: String, folder_name: String) -> void:
    var config = _parse_mod_toml(mod_path + "mod.toml")
    if config.is_empty():
        push_warning("Failed to parse mod.toml for %s" % folder_name)
        return
    
    var mod_id = config.get("id", folder_name)
    
    # Check game version compatibility
    if not _check_version_compatibility(config.get("game_version", "*")):
        push_warning("Mod %s incompatible with game version" % mod_id)
        return
    
    loaded_mods[mod_id] = ModInstance.new({
        "id": mod_id,
        "name": config.get("name", mod_id),
        "version": config.get("version", "0.0.0"),
        "author": config.get("author", "Unknown"),
        "description": config.get("description", ""),
        "path": mod_path,
        "config": config,
        "enabled": true,
        "loaded": false,
    })

func _parse_mod_toml(file_path: String) -> Dictionary:
    var file = FileAccess.open(file_path, FileAccess.READ)
    if not file:
        return {}
    var content = file.get_as_text()
    file.close()
    # Parse TOML (using a TOML parser library)
    return TomlParser.parse(content)

func _check_version_compatibility(required: String) -> bool:
    if required == "*":
        return true
    var game_version = ProjectSettings.get_setting("application/config/version", "1.0.0")
    return VersionChecker.check(game_version, required)

func _resolve_load_order() -> void:
    # Topological sort based on dependencies
    var graph = {}
    for mod_id in loaded_mods:
        var deps = loaded_mods[mod_id].config.get("dependencies", {}).get("required", [])
        graph[mod_id] = deps
    
    mod_load_order = TopologicalSort.sort(graph)
    
    # Check for circular dependencies
    if mod_load_order.is_empty() and loaded_mods.size() > 0:
        push_error("Circular dependency detected in mods!")

func _load_all_mods() -> void:
    for mod_id in mod_load_order:
        var mod = loaded_mods[mod_id]
        if not mod.enabled:
            continue
        
        # Check dependencies are loaded
        var deps = mod.config.get("dependencies", {}).get("required", [])
        var deps_met = true
        for dep in deps:
            var dep_id = dep.split("@")[0]
            if not loaded_mods.has(dep_id) or not loaded_mods[dep_id].loaded:
                deps_met = false
                break
        
        if not deps_met:
            mod_load_failed.emit(mod_id, "Missing dependencies")
            continue
        
        _load_mod(mod)

func _load_mod(mod: ModInstance) -> void:
    print("Loading mod: %s v%s" % [mod.name, mod.version])
    
    # 1. Register assets
    _register_mod_assets(mod)
    
    # 2. Load data files
    _load_mod_data(mod)
    
    # 3. Execute init script
    var init_script = mod.path + "scripts/init.gd"
    if FileAccess.file_exists(init_script):
        var script = load(init_script)
        if script:
            var instance = script.new()
            instance.mod_api = mod_api
            instance.mod_id = mod.id
            instance._init_mod()
            mod.script_instance = instance
    
    mod.loaded = true
    mod_loaded.emit(mod.id)

func _register_mod_assets(mod: ModInstance) -> void:
    # Register custom models, textures, sounds with the resource system
    var assets_dir = mod.path + "assets/"
    if not DirAccess.dir_exists_absolute(assets_dir):
        return
    
    _scan_and_register(assets_dir, "models", ".glb", _register_model)
    _scan_and_register(assets_dir, "textures", ".png", _register_texture)
    _scan_and_register(assets_dir, "sounds", ".wav", _register_sound)

func _scan_and_register(base: String, subdir: String, ext: String, callback: Callable) -> void:
    var dir_path = base + subdir + "/"
    var dir = DirAccess.open(dir_path)
    if not dir:
        return
    dir.list_dir_begin()
    var file = dir.get_next()
    while file != "":
        if file.ends_with(ext):
            callback.call(dir_path + file, file.get_basename())
        file = dir.get_next()
    dir.list_dir_end()

func _register_model(path: String, name: String) -> void:
    var res = ResourceLoader.load(path)
    if res:
        AssetDatabase.register("model:" + name, res)

func _register_texture(path: String, name: String) -> void:
    var res = ResourceLoader.load(path)
    if res:
        AssetDatabase.register("texture:" + name, res)

func _register_sound(path: String, name: String) -> void:
    var res = ResourceLoader.load(path)
    if res:
        AssetDatabase.register("sound:" + name, res)

func _load_mod_data(mod: ModInstance) -> void:
    var data_dir = mod.path + "data/"
    var dir = DirAccess.open(data_dir)
    if not dir:
        return
    dir.list_dir_begin()
    var file = dir.get_next()
    while file != "":
        if file.ends_with(".json"):
            _load_json_data(data_dir + file, mod.id)
        file = dir.get_next()
    dir.list_dir_end()

func _load_json_data(path: String, mod_id: String) -> void:
    var file = FileAccess.open(path, FileAccess.READ)
    if not file:
        return
    var json = JSON.new()
    json.parse(file.get_as_text())
    file.close()
    var data = json.data
    
    var category = path.get_file().get_basename()
    match category:
        "items":
            for item_id in data:
                ItemDatabase.register_mod_item(mod_id, item_id, data[item_id])
        "vehicles":
            for vehicle_id in data:
                VehicleDatabase.register_mod_vehicle(mod_id, vehicle_id, data[vehicle_id])
        "missions":
            for mission_id in data:
                MissionSystem.register_mod_mission(mod_id, mission_id, data[mission_id])
        "npcs":
            for npc_id in data:
                NPCDatabase.register_mod_npc(mod_id, npc_id, data[npc_id])

func unload_mod(mod_id: String) -> void:
    if not loaded_mods.has(mod_id):
        return
    var mod = loaded_mods[mod_id]
    
    # Call mod's cleanup function
    if mod.script_instance and mod.script_instance.has_method("_cleanup"):
        mod.script_instance._cleanup()
    
    # Unregister assets
    AssetDatabase.unregister_mod_assets(mod_id)
    ItemDatabase.unregister_mod_items(mod_id)
    VehicleDatabase.unregister_mod_vehicles(mod_id)
    MissionSystem.unregister_mod_missions(mod_id)
    
    mod.loaded = false
    mod_unloaded.emit(mod_id)
    print("Unloaded mod: %s" % mod.name)

func reload_mod(mod_id: String) -> void:
    unload_mod(mod_id)
    _load_mod(loaded_mods[mod_id])

func get_mod(mod_id: String) -> ModInstance:
    return loaded_mods.get(mod_id)

func get_all_mods() -> Array:
    return loaded_mods.values()
```

### `ModInstance.gd`

```gdscript
class_name ModInstance

var id: String
var name: String
var version: String
var author: String
var description: String
var path: String
var config: Dictionary
var enabled: bool = true
var loaded: bool = false
var script_instance: Object

func _init(data: Dictionary) -> void:
    id = data.get("id", "")
    name = data.get("name", id)
    version = data.get("version", "0.0.0")
    author = data.get("author", "Unknown")
    description = data.get("description", "")
    path = data.get("path", "")
    config = data.get("config", {})
    enabled = data.get("enabled", true)
```

---

## Step 4 — Mod API

The Mod API provides a safe, documented interface for modders to interact with the game.

### `ModAPI.gd`

```gdscript
class_name ModAPI

var mod_loader: ModLoader

# === Game State Access ===

func get_player() -> Node:
    return get_tree().get_first_node_in_group("player")

func get_player_position() -> Vector3:
    var player = get_player()
    return player.global_position if player else Vector3.ZERO

func get_world_time() -> float:
    return TimeSystem.get_game_time()

func get_current_season() -> String:
    return SeasonSystem.get_current_season()

func get_current_weather() -> String:
    return WeatherManager.WeatherType.keys()[WeatherManager.current_weather]

# === Entity Registration ===

func register_item(item_id: String, item_data: Dictionary) -> void:
    ItemDatabase.register_item(item_id, item_data)

func register_vehicle(vehicle_id: String, vehicle_data: Dictionary) -> void:
    VehicleDatabase.register_vehicle(vehicle_id, vehicle_data)

func register_npc(npc_id: String, npc_data: Dictionary) -> void:
    NPCDatabase.register_npc(npc_id, npc_data)

func register_mission(mission_id: String, mission_data: Dictionary) -> void:
    MissionSystem.register_mission(mission_id, mission_data)

# === Event Hooks ===

var event_hooks: Dictionary = {}  # event_name -> [callbacks]

func register_event_hook(event_name: String, callback: Callable) -> void:
    if not event_hooks.has(event_name):
        event_hooks[event_name] = []
    event_hooks[event_name].append(callback)

func trigger_event(event_name: String, args: Array = []) -> void:
    if event_hooks.has(event_name):
        for callback in event_hooks[event_name]:
            callback.callv(args)

# === World Manipulation ===

func spawn_entity(scene_path: String, position: Vector3) -> Node:
    var scene = load(scene_path)
    if not scene:
        push_error("ModAPI: Failed to load scene: %s" % scene_path)
        return null
    var entity = scene.instantiate()
    get_tree().current_scene.add_child(entity)
    entity.global_position = position
    return entity

func create_timer(wait_time: float, callback: Callable, one_shot: bool = true) -> Timer:
    var timer = Timer.new()
    timer.wait_time = wait_time
    timer.one_shot = one_shot
    timer.timeout.connect(callback)
    get_tree().current_scene.add_child(timer)
    timer.start()
    return timer

# === UI ===

func show_notification(message: String, duration: float = 3.0) -> void:
    UI.show_notification(message, duration)

func show_dialog(title: String, body: String, buttons: Array = ["OK"]) -> void:
    UI.show_dialog(title, body, buttons)

func add_ui_panel(panel_scene: PackedScene, anchor: int = 0) -> Control:
    var panel = panel_scene.instantiate()
    UI.add_custom_panel(panel, anchor)
    return panel

# === Persistence ===

func save_mod_data(mod_id: String, data: Dictionary) -> void:
    var path = "user://mod_data/%s.save" % mod_id
    var dir = DirAccess.open("user://")
    if not dir.dir_exists("user://mod_data"):
        dir.make_dir("mod_data")
    var file = FileAccess.open(path, FileAccess.WRITE)
    file.store_var(data)
    file.close()

func load_mod_data(mod_id: String) -> Dictionary:
    var path = "user://mod_data/%s.save" % mod_id
    if not FileAccess.file_exists(path):
        return {}
    var file = FileAccess.open(path, FileAccess.READ)
    var data = file.get_var()
    file.close()
    return data

# === Logging ===

func log_info(mod_id: String, message: String) -> void:
    print("[Mod:%s] %s" % [mod_id, message])

func log_warning(mod_id: String, message: String) -> void:
    push_warning("[Mod:%s] %s" % [mod_id, message])

func log_error(mod_id: String, message: String) -> void:
    push_error("[Mod:%s] %s" % [mod_id, message])
```

### Available Event Hooks

| Event Name | Triggered When | Args |
| :--- | :--- | :--- |
| `on_game_start` | New game or save loaded | `[]` |
| `on_game_save` | Player saves the game | `[save_data: Dictionary]` |
| `on_game_load` | Save file loaded | `[save_data: Dictionary]` |
| `on_player_move` | Player position changes | `[position: Vector3]` |
| `on_player_enter_vehicle` | Player enters a vehicle | `[vehicle: Node]` |
| `on_player_exit_vehicle` | Player exits a vehicle | `[vehicle: Node]` |
| `on_item_purchased` | Player buys an item | `[item_id: String, price: float]` |
| `on_item_sold` | Player sells an item | `[item_id: String, price: float]` |
| `on_mission_started` | Mission begins | `[mission_id: String]` |
| `on_mission_completed` | Mission ends | `[mission_id: String, success: bool]` |
| `on_npc_spawned` | NPC enters the world | `[npc: Node]` |
| `on_npc_died` | NPC dies | `[npc: Node, cause: String]` |
| `on_day_changed` | New in-game day | `[day: int]` |
| `on_season_changed` | Season transitions | `[season: String]` |
| `on_weather_changed` | Weather changes | `[weather: String]` |
| `on_player_damage` | Player takes damage | `[amount: float, source: String]` |
| `on_player_death` | Player dies | `[cause: String]` |
| `on_custom_event` | Mod-triggered custom event | `[event_name: String, data: Dictionary]` |

---

## Step 5 — Example Mod: Custom Vehicle

### `init.gd`

```gdscript
extends Node
class_name MyModInit

var mod_api: ModAPI
var mod_id: String = "custom_vehicles_pack"

func _init_mod() -> void:
    mod_api.log_info(mod_id, "Loading Custom Vehicles Pack v1.0")
    
    # Register vehicles from data file
    var vehicle_data = _load_vehicle_data()
    for vehicle_id in vehicle_data:
        mod_api.register_vehicle(vehicle_id, vehicle_data[vehicle_id])
    
    # Register event hooks
    mod_api.register_event_hook("on_player_enter_vehicle", _on_enter_vehicle)
    mod_api.register_event_hook("on_game_save", _on_save)
    mod_api.register_event_hook("on_game_load", _on_load)
    
    mod_api.log_info(mod_id, "Custom Vehicles Pack loaded successfully!")

func _load_vehicle_data() -> Dictionary:
    var file = FileAccess.open("user://mods/custom_vehicles_pack/data/vehicles.json", FileAccess.READ)
    if not file:
        mod_api.log_error(mod_id, "Failed to load vehicle data!")
        return {}
    var json = JSON.new()
    json.parse(file.get_as_text())
    file.close()
    return json.data

func _on_enter_vehicle(vehicle: Node) -> void:
    if vehicle.vehicle_id == "super_sports_car":
        mod_api.show_notification("Vroom! Super Sports Car activated!")
        # Add boost ability
        vehicle.set("max_speed", 350.0)
        vehicle.set("acceleration", 25.0)

func _on_save(save_data: Dictionary) -> void:
    # Save mod-specific data into the save file
    save_data[mod_id] = {
        "cars_unlocked": ["super_sports_car", "muscle_car_v8"],
    }

func _on_load(save_data: Dictionary) -> void:
    var my_data = save_data.get(mod_id, {})
    if my_data:
        mod_api.log_info(mod_id, "Loaded %d unlocked cars" % my_data.get("cars_unlocked", []).size())

func _cleanup() -> void:
    mod_api.log_info(mod_id, "Cleaning up Custom Vehicles Pack")
    # Unregister everything
    mod_api.trigger_event("custom_vehicles_unloaded")
```

### `vehicles.json`

```json
{
    "super_sports_car": {
        "name": "Super Sports Car",
        "model": "model:super_sports_car",
        "max_speed": 300.0,
        "acceleration": 15.0,
        "price": 150000,
        "fuel_type": "premium",
        "seats": 2,
        "category": "sports",
        "description": "A high-performance sports car for speed enthusiasts."
    },
    "muscle_car_v8": {
        "name": "Muscle Car V8",
        "model": "model:muscle_car_v8",
        "max_speed": 220.0,
        "acceleration": 12.0,
        "price": 65000,
        "fuel_type": "regular",
        "seats": 4,
        "category": "muscle",
        "description": "Classic American muscle with a roaring V8 engine."
    },
    "electric_suv": {
        "name": "Electric SUV",
        "model": "model:electric_suv",
        "max_speed": 180.0,
        "acceleration": 10.0,
        "price": 80000,
        "fuel_type": "electric",
        "seats": 5,
        "category": "suv",
        "description": "Eco-friendly electric SUV with great range."
    }
}
```

---

## Step 6 — Steam Workshop Integration

### `WorkshopManager.gd`

```gdscript
extends Node
class_name WorkshopManager

const APP_ID = 0  # Replace with actual Steam App ID
const WORKSHOP_ITEM_TYPE = Steam.WORKSHOP_TYPE_COMMUNITY

var subscribed_items: Array = []
var uploaded_items: Dictionary = {}  # item_id -> upload data

signal workshop_query_completed(items: Array)
signal upload_progress(item_id: int, progress: float)
signal upload_complete(item_id: int, result: int)

func _ready() -> void:
    Steam.steamInit(false, APP_ID)
    Steam.workshop_subscribe_item.connect(_on_item_subscribed)
    Steam.workshop_unsubscribe_item.connect(_on_item_unsubscribed)
    Steam.workshop_item_installed.connect(_on_item_installed)
    _load_subscribed_items()

func _load_subscribed_items() -> void:
    subscribed_items = Steam.getSubscribedItems()
    for item_id in subscribed_items:
        _install_workshop_item(item_id)

func _install_workshop_item(item_id: int) -> void:
    var install_info = Steam.getItemInstallInfo(item_id)
    if install_info.is_empty():
        Steam.downloadItem(item_id, false)
        return
    
    var item_path = install_info["folder"]
    # Copy/symlink to mods directory
    var mod_dir = "user://mods/workshop_%d/" % item_id
    _copy_mod_files(item_path, mod_dir)
    
    print("Installed workshop item %d to %s" % [item_id, mod_dir])

func _copy_mod_files(src: String, dst: String) -> void:
    var dir = DirAccess.open(src)
    if not dir:
        return
    DirAccess.make_dir_recursive_absolute(dst)
    dir.list_dir_begin()
    var file = dir.get_next()
    while file != "":
        if dir.current_is_dir():
            if not file.begins_with("."):
                _copy_mod_files(src + "/" + file, dst + "/" + file)
        else:
            DirAccess.copy_absolute(src + "/" + file, dst + "/" + file)
        file = dir.get_next()
    dir.list_dir_end()

func browse_workshop(tags: Array = [], page: int = 1) -> void:
    # Query Steam Workshop for items
    var query = Steam.createQueryAllUGCQuery(
        Steam.UGC_QUERY_RANKED_BY_TOTAL_SUBSCRIPTIONS,
        WORKSHOP_ITEM_TYPE,
        APP_ID,
        APP_ID,
        page
    )
    
    for tag in tags:
        Steam.addRequiredTagToQuery(query, tag)
    
    Steam.sendUGCQuery(query)
    Steam.ugc_query_completed.connect(_on_query_completed)

func _on_query_completed(handle: int, result: int, num_results: int) -> void:
    var items = []
    for i in num_results:
        var item = Steam.getQueryUGCResult(handle, i)
        items.append({
            "id": item["published_file_id"],
            "title": item["title"],
            "description": item["description"],
            "tags": item["tags"],
            "subscriptions": Steam.getItemSubscribeCount(item["published_file_id"]),
            "preview_url": item["preview_url"],
            "creator": item["creator"],
        })
    workshop_query_completed.emit(items)

func subscribe_item(item_id: int) -> void:
    Steam.subscribeItem(item_id)
    print("Subscribed to workshop item %d" % item_id)

func unsubscribe_item(item_id: int) -> void:
    Steam.unsubscribeItem(item_id)
    # Remove from mods directory
    var mod_dir = "user://mods/workshop_%d/" % item_id
    DirAccess.remove_absolute(mod_dir)
    print("Unsubscribed from workshop item %d" % item_id)

func upload_mod(mod_path: String, metadata: Dictionary) -> void:
    var item_id = metadata.get("workshop_id", 0)
    var is_new = item_id == 0
    
    if is_new:
        item_id = Steam.createItem(APP_ID, false)
        if item_id == 0:
            push_error("Failed to create workshop item")
            return
    
    var update_handle = Steam.startItemUpdate(APP_ID, item_id)
    
    Steam.setItemTitle(update_handle, metadata["name"])
    Steam.setItemDescription(update_handle, metadata["description"])
    Steam.setItemVisibility(update_handle, Steam.WORKSHOP_VISIBILITY_PUBLIC)
    
    # Set preview image
    if metadata.has("preview_image"):
        Steam.setItemPreview(update_handle, metadata["preview_image"])
    
    # Set content folder
    Steam.setItemContent(update_handle, mod_path)
    
    # Set tags
    if metadata.has("tags"):
        Steam.setItemTags(update_handle, metadata["tags"])
    
    var result = Steam.submitItemUpdate(update_handle, metadata.get("change_note", ""))
    
    uploaded_items[item_id] = {
        "handle": update_handle,
        "path": mod_path,
        "metadata": metadata,
    }
    
    # Poll for upload progress
    set_process(true)

func _process(_delta: float) -> void:
    if uploaded_items.is_empty():
        set_process(false)
        return
    
    for item_id in uploaded_items:
        var status = Steam.getItemUpdateProgress(item_id)
        if status["status"] == Steam.ITEM_UPDATE_STATUS_UPLOADING:
            upload_progress.emit(item_id, status["progress"])
        elif status["status"] == Steam.ITEM_UPDATE_STATUS_COMMITTED:
            upload_complete.emit(item_id, Steam.RESULT_OK)
            uploaded_items.erase(item_id)
        elif status["status"] == Steam.ITEM_UPDATE_STATUS_FAILED:
            upload_complete.emit(item_id, status["result"])
            uploaded_items.erase(item_id)

func _on_item_subscribed(item_id: int) -> void:
    print("Subscribed to workshop item: %d" % item_id)
    _install_workshop_item(item_id)

func _on_item_unsubscribed(item_id: int) -> void:
    print("Unsubscribed from workshop item: %d" % item_id)
    var mod_dir = "user://mods/workshop_%d/" % item_id
    DirAccess.remove_absolute(mod_dir)

func _on_item_installed(item_id: int) -> void:
    print("Workshop item installed: %d" % item_id)
    _install_workshop_item(item_id)
```

---

## Step 7 — Mod Manager UI

### `ModManagerUI.gd`

```gdscript
extends Control
class_name ModManagerUI

@onready var mod_list: ItemList = $VBox/ModList
@onready var mod_details: RichTextLabel = $VBox/ModDetails
@onready var mod_preview: TextureRect = $VBox/ModPreview
@onready var enable_button: Button = $VBox/Buttons/EnableButton
@onready var workshop_button: Button = $VBox/Buttons/WorkshopButton
@onready var upload_button: Button = $VBox/Buttons/UploadButton

var selected_mod_id: String = ""

func _ready() -> void:
    _refresh_mod_list()
    ModLoader.mod_loaded.connect(_on_mod_loaded)
    ModLoader.mod_unloaded.connect(_on_mod_unloaded)

func _refresh_mod_list() -> void:
    mod_list.clear()
    var mods = ModLoader.get_all_mods()
    mods.sort_custom(func(a, b): return a.name < b.name)
    
    for mod in mods:
        var status_icon = "✓" if mod.loaded else "✗"
        var text = "%s %s v%s by %s" % [status_icon, mod.name, mod.version, mod.author]
        mod_list.add_item(text)
        mod_list.set_item_metadata(mod_list.item_count - 1, mod.id)

func _on_mod_list_item_selected(index: int) -> void:
    selected_mod_id = mod_list.get_item_metadata(index)
    _show_mod_details(selected_mod_id)

func _show_mod_details(mod_id: String) -> void:
    var mod = ModLoader.get_mod(mod_id)
    if not mod:
        return
    
    var details_text = "[b]%s[/b] v%s\n" % [mod.name, mod.version]
    details_text += "by %s\n\n" % mod.author
    details_text += mod.description + "\n\n"
    details_text += "Type: %s\n" % mod.config.get("type", "unknown")
    details_text += "Status: %s\n" % ("Loaded" if mod.loaded else "Not Loaded")
    
    var deps = mod.config.get("dependencies", {}).get("required", [])
    if not deps.is_empty():
        details_text += "\nDependencies:\n"
        for dep in deps:
            details_text += "  • %s\n" % dep
    
    mod_details.text = details_text
    
    # Load preview image
    var preview_path = mod.path + "preview.png"
    if FileAccess.file_exists(preview_path):
        var tex = load(preview_path)
        if tex:
            mod_preview.texture = tex
    
    # Update button states
    enable_button.text = "Disable" if mod.loaded else "Enable"
    enable_button.disabled = false

func _on_enable_button_pressed() -> void:
    if selected_mod_id.is_empty():
        return
    var mod = ModLoader.get_mod(selected_mod_id)
    if mod.loaded:
        ModLoader.unload_mod(selected_mod_id)
    else:
        ModLoader._load_mod(mod)
    _refresh_mod_list()

func _on_workshop_button_pressed() -> void:
    WorkshopBrowserUI.show_browser()

func _on_upload_button_pressed() -> void:
    if selected_mod_id.is_empty():
        return
    var mod = ModLoader.get_mod(selected_mod_id)
    WorkshopUploadUI.show_upload_dialog(mod)

func _on_mod_loaded(mod_id: String) -> void:
    _refresh_mod_list()

func _on_mod_unloaded(mod_id: String) -> void:
    _refresh_mod_list()
```

### Mod Manager UI Layout

```text
┌─────────────────────────────────────────────────────────────────┐
│  Mod Manager                                          [Close]   │
├──────────────────────────┬──────────────────────────────────────┤
│  Installed Mods          │  Mod Details                         │
│  ┌─────────────────────┐ │  ┌──────────┐                       │
│  │ ✓ Custom Cars 1.2  │ │  │ Preview  │  Custom Cars v1.2     │
│  │ ✓ City Expansion   │ │  │  Image   │  by ModderName        │
│  │ ✗ Old Mod 0.5      │ │  │          │                       │
│  │ ✓ HD Textures 2.0  │ │  └──────────┘  Adds 5 new sports   │
│  │ ✓ New Missions 1.0 │ │                cars and a racing    │
│  │ ✗ Debug Tools 0.3  │ │                mission chain.       │
│  └─────────────────────┘ │                                       │
│                          │  Type: Content                        │
│                          │  Status: Loaded                       │
│                          │  Dependencies: earth_core_lib         │
│                          │                                       │
│  [Enable] [Workshop] [Upload Mod] [Settings]                    │
└──────────────────────────┴──────────────────────────────────────┘
```

---

## Step 8 — Mod Sandbox & Security

### `ModSandbox.gd`

```gdscript
extends Node
class_name ModSandbox

# Resource limits per mod
const MAX_MEMORY_MB = 256
const MAX_CPU_TIME_MS = 16  # per frame
const MAX_FILE_SIZE_MB = 500
const MAX_ENTITIES_SPAWNED = 500

var mod_resource_usage: Dictionary = {}  # mod_id -> {memory, cpu, entities}

func check_resource_limits(mod_id: String) -> bool:
    if not mod_resource_usage.has(mod_id):
        mod_resource_usage[mod_id] = {"memory": 0, "cpu": 0, "entities": 0}
    
    var usage = mod_resource_usage[mod_id]
    
    if usage["memory"] > MAX_MEMORY_MB * 1024 * 1024:
        _report_violation(mod_id, "Memory limit exceeded (%d MB)" % (usage["memory"] / 1048576))
        return false
    
    if usage["entities"] > MAX_ENTITIES_SPAWNED:
        _report_violation(mod_id, "Entity limit exceeded (%d)" % usage["entities"])
        return false
    
    return true

func validate_file_access(mod_id: String, path: String) -> bool:
    var mod = ModLoader.get_mod(mod_id)
    if not mod:
        return false
    
    var allowed_paths = mod.config.get("permissions", {}).get("file_access", [])
    
    # Mods can always access their own directory
    if path.begins_with(mod.path):
        return true
    
    # Check declared permissions
    for allowed in allowed_paths:
        if path.begins_with(allowed):
            return true
    
    # Check user data directory (mod-specific)
    if path.begins_with("user://mod_data/%s/" % mod_id):
        return true
    
    _report_violation(mod_id, "Unauthorized file access: %s" % path)
    return false

func validate_network_access(mod_id: String) -> bool:
    var mod = ModLoader.get_mod(mod_id)
    if not mod:
        return false
    return mod.config.get("permissions", {}).get("network_access", false)

func validate_shader_access(mod_id: String) -> bool:
    var mod = ModLoader.get_mod(mod_id)
    if not mod:
        return false
    return mod.config.get("permissions", {}).get("custom_shaders", false)

func _report_violation(mod_id: String, message: String) -> void:
    push_warning("[ModSandbox] %s: %s" % [mod_id, message])
    # Log violation for review
    var log_path = "user://mod_violations.log"
    var file = FileAccess.open(log_path, FileAccess.READ_WRITE)
    if not file:
        file = FileAccess.open(log_path, FileAccess.WRITE)
    file.seek_end()
    file.store_line("[%s] %s: %s" % [Time.get_datetime_string_from_system(), mod_id, message])
    file.close()
    
    # If too many violations, disable the mod
    var mod = ModLoader.get_mod(mod_id)
    if mod:
        mod.violation_count = mod.get("violation_count", 0) + 1
        if mod.violation_count > 10:
            ModLoader.unload_mod(mod_id)
            UI.show_notification("Mod '%s' disabled due to security violations" % mod.name)
```

---

## Step 9 — Mod Conflict Resolution

### Conflict Types

| Conflict Type | Description | Resolution Strategy |
| :--- | :--- | :--- |
| **Asset Override** | Two mods replace the same asset | Load order determines priority |
| **Script Hook** | Two mods hook the same event | Both run in load order; last can override |
| **Data Override** | Two mods define the same item ID | Last loaded wins; warn user |
| **System Override** | Two mods replace the same system | Only one can be active; user chooses |

### `ModConflictResolver.gd`

```gdscript
extends Node
class_name ModConflictResolver

func detect_conflicts() -> Array:
    var conflicts = []
    var asset_owners = {}  # asset_key -> [mod_ids]
    
    for mod_id in ModLoader.loaded_mods:
        var mod = ModLoader.loaded_mods[mod_id]
        if not mod.loaded:
            continue
        
        # Check asset overrides
        for asset_key in mod.registered_assets:
            if not asset_owners.has(asset_key):
                asset_owners[asset_key] = []
            asset_owners[asset_key].append(mod_id)
    
    for asset_key in asset_owners:
        if asset_owners[asset_key].size() > 1:
            conflicts.append({
                "type": "asset_override",
                "asset": asset_key,
                "mods": asset_owners[asset_key],
                "resolution": "Load order: %s" % " > ".join(asset_owners[asset_key]),
            })
    
    return conflicts

func resolve_conflict(conflict: Dictionary) -> void:
    match conflict["type"]:
        "asset_override":
            # The mod loaded last (highest in load order) wins
            var winner = conflict["mods"][-1]
            print("Conflict resolved: %s wins for %s" % [winner, conflict["asset"]])
        "data_override":
            # Warn the user
            UI.show_notification("Mod conflict: %s — last loaded mod wins" % conflict["asset"])
```

---

## Step 10 — Modding Documentation & Tools

### Modding Documentation Site

```text
┌─────────────────────────────────────────────────────────────┐
│              Modding Documentation Structure                 │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. Getting Started                                          │
│     ├── Installation & Setup                                 │
│     ├── Your First Mod (Hello World)                         │
│     ├── mod.toml Reference                                   │
│     └── Project Structure                                    │
│                                                              │
│  2. Mod API Reference                                        │
│     ├── Game State Access                                    │
│     ├── Entity Registration                                   │
│     ├── Event Hooks                                          │
│     ├── World Manipulation                                   │
│     ├── UI Integration                                        │
│     ├── Persistence (Save/Load)                              │
│     └── Logging                                              │
│                                                              │
│  3. Asset Creation                                           │
│     ├── Models (Blender → GLB)                               │
│     ├── Textures (PNG, normal maps)                          │
│     ├── Sounds (WAV, OGG)                                    │
│     └── Materials                                            │
│                                                              │
│  4. Data Files                                               │
│     ├── items.json Format                                    │
│     ├── vehicles.json Format                                 │
│     ├── missions.json Format                                 │
│     └── npcs.json Format                                     │
│                                                              │
│  5. Advanced Topics                                          │
│     ├── Custom Shaders                                       │
│     ├── Custom UI Panels                                     │
│     ├── Inter-Mod Communication                              │
│     ├── Steam Workshop Upload                                │
│     └── Performance Best Practices                           │
│                                                              │
│  6. Tools                                                    │
│     ├── Mod Template Generator                               │
│     ├── Mod Validator (lint)                                 │
│     ├── Asset Importer                                       │
│     └── Debug Console                                        │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Mod Template Generator

```gdscript
extends EditorScript

func _run() -> void:
    var mod_name = "new_mod"
    var mod_dir = "res://mods/" + mod_name + "/"
    
    DirAccess.make_dir_recursive_absolute(mod_dir + "scripts")
    DirAccess.make_dir_recursive_absolute(mod_dir + "assets/models")
    DirAccess.make_dir_recursive_absolute(mod_dir + "assets/textures")
    DirAccess.make_dir_recursive_absolute(mod_dir + "assets/sounds")
    DirAccess.make_dir_recursive_absolute(mod_dir + "data")
    DirAccess.make_dir_recursive_absolute(mod_dir + "locales")
    DirAccess.make_dir_recursive_absolute(mod_dir + "config")
    
    # Create mod.toml
    var toml_content = """[mod]
id = "%s"
name = "%s"
version = "0.1.0"
author = "Your Name"
description = "A new mod."
game_version = ">=1.0.0"
type = "content"
load_order = 100

[dependencies]
required = []
optional = []

[permissions]
file_access = ["user://%s/"]
network_access = false
custom_shaders = false
""" % [mod_name, mod_name.replace("_", " ").capitalize(), mod_name]
    
    _write_file(mod_dir + "mod.toml", toml_content)
    
    # Create init.gd
    var init_content = """extends Node
class_name %sInit

var mod_api: ModAPI
var mod_id: String = "%s"

func _init_mod() -> void:
    mod_api.log_info(mod_id, "Hello from %s!")
    # Your mod code goes here

func _cleanup() -> void:
    mod_api.log_info(mod_id, "Cleaning up %s")
""" % [mod_name.capitalize(), mod_name, mod_name, mod_name]
    
    _write_file(mod_dir + "scripts/init.gd", init_content)
    
    print("Mod template created at: %s" % mod_dir)

func _write_file(path: String, content: String) -> void:
    var file = FileAccess.open(path, FileAccess.WRITE)
    file.store_string(content)
    file.close()
```

---

## Step 11 — Mod Validation (Linting)

### `ModValidator.gd`

```gdscript
extends Node
class_name ModValidator

func validate_mod(mod_path: String) -> Array:
    var errors = []
    var warnings = []
    
    # Check required files
    if not FileAccess.file_exists(mod_path + "mod.toml"):
        errors.append("Missing mod.toml")
        return errors  # Can't continue without metadata
    
    # Parse and validate mod.toml
    var config = _parse_toml(mod_path + "mod.toml")
    if config.is_empty():
        errors.append("Invalid mod.toml format")
        return errors
    
    if not config.has("id") or config["id"].is_empty():
        errors.append("mod.toml: 'id' is required")
    if not config.has("name") or config["name"].is_empty():
        errors.append("mod.toml: 'name' is required")
    if not config.has("version") or not _is_valid_version(config["version"]):
        errors.append("mod.toml: 'version' must be semver (e.g., 1.0.0)")
    
    # Check for preview image (required for Workshop)
    if not FileAccess.file_exists(mod_path + "preview.png"):
        warnings.append("Missing preview.png (required for Steam Workshop upload)")
    
    # Validate scripts
    var scripts_dir = mod_path + "scripts/"
    if DirAccess.dir_exists_absolute(scripts_dir):
        _validate_scripts(scripts_dir, errors, warnings)
    
    # Validate data files
    var data_dir = mod_path + "data/"
    if DirAccess.dir_exists_absolute(data_dir):
        _validate_data_files(data_dir, errors, warnings)
    
    # Check file sizes
    _check_file_sizes(mod_path, errors, warnings)
    
    return errors + warnings

func _is_valid_version(version: String) -> bool:
    var regex = RegEx.new()
    regex.compile("^\\d+\\.\\d+\\.\\d+$")
    return regex.search(version) != null

func _validate_scripts(dir_path: String, errors: Array, warnings: Array) -> void:
    var dir = DirAccess.open(dir_path)
    dir.list_dir_begin()
    var file = dir.get_next()
    while file != "":
        if file.ends_with(".gd"):
            var script = load(dir_path + file)
            if not script:
                errors.append("Failed to load script: %s" % file)
            elif not script.has_method("_init_mod"):
                warnings.append("Script %s has no _init_mod() function" % file)
        file = dir.get_next()
    dir.list_dir_end()

func _validate_data_files(dir_path: String, errors: Array, warnings: Array) -> void:
    var dir = DirAccess.open(dir_path)
    dir.list_dir_begin()
    var file = dir.get_next()
    while file != "":
        if file.ends_with(".json"):
            var json_file = FileAccess.open(dir_path + file, FileAccess.READ)
            var json = JSON.new()
            var err = json.parse(json_file.get_as_text())
            json_file.close()
            if err != OK:
                errors.append("Invalid JSON in %s: %s" % [file, json.get_error_message()])
        file = dir.get_next()
    dir.list_dir_end()

func _check_file_sizes(mod_path: String, errors: Array, warnings: Array) -> void:
    var total_size = _get_dir_size(mod_path)
    if total_size > ModSandbox.MAX_FILE_SIZE_MB * 1024 * 1024:
        warnings.append("Mod size (%.1f MB) exceeds recommended limit (%d MB)" % [
            total_size / 1048576.0, ModSandbox.MAX_FILE_SIZE_MB
        ])

func _get_dir_size(path: String) -> int:
    var size = 0
    var dir = DirAccess.open(path)
    if not dir:
        return 0
    dir.list_dir_begin()
    var file = dir.get_next()
    while file != "":
        if dir.current_is_dir():
            if not file.begins_with("."):
                size += _get_dir_size(path + "/" + file)
        else:
            size += FileAccess.file_exists(path + "/" + file) and FileAccess.get_file_as_bytes(path + "/" + file).size()
        file = dir.get_next()
    dir.list_dir_end()
    return size
```

---

## Step 12 — Implementation Checklist

| Task | Priority | Status |
| :--- | :--- | :--- |
| ModLoader (discover/load/unload) | Critical | Pending |
| ModAPI (game interface) | Critical | Pending |
| mod.toml parser | Critical | Pending |
| Asset registration pipeline | High | Pending |
| Data file loading (JSON) | High | Pending |
| Event hook system | High | Pending |
| WorkshopManager (Steam) | High | Pending |
| ModManagerUI | High | Pending |
| ModSandbox (security) | High | Pending |
| ModConflictResolver | Medium | Pending |
| ModValidator (linting) | Medium | Pending |
| Mod template generator | Low | Pending |
| Modding documentation | Medium | Pending |
| Load order topological sort | Medium | Pending |
