# Stage 4.12 — Save System & Polish

The save system preserves player progress, and polish ensures the game feels complete and professional.

---

## Goal
Implement a robust save/load system, settings menu, and final polish including bug fixes, audio balancing, and performance optimization.

---

## Step 1 — Save System Architecture

### Save Data Structure

```
save_slot_01.json
├── meta (timestamp, playtime, version)
├── player (stats, position, rotation)
├── money (cash, bank)
├── inventory (items, equipment)
├── vehicles (owned, current, positions)
├── properties (owned, furniture, rent status)
├── world (time, day, weather)
├── missions (active, completed, failed)
├── story (flags, choices, chapter)
├── relationships (all NPC relationships)
├── reputation (all factions)
└── wanted (level, crimes)
```

### `SaveSystem.gd` (Autoload)

```gdscript
extends Node

signal save_started()
signal save_completed()
signal load_completed()

const SAVE_DIR = "user://saves/"
const MAX_SLOTS = 10
const SAVE_VERSION = 1

func _ready() -> void:
    DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func save_game(slot: int) -> bool:
    save_started.emit()
    var save_data = _gather_save_data()
    var path = SAVE_DIR + "save_slot_%02d.json" % slot
    var file = FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        push_error("Failed to open save file: " + path)
        return false
    
    save_data["meta"] = {
        "version": SAVE_VERSION,
        "timestamp": Time.get_unix_time_from_system(),
        "playtime": GlobalWorldState.playtime,
        "day": TimeSystem.get_day(),
        "hour": TimeSystem.get_hour(),
    }
    
    file.store_string(JSON.stringify(save_data, "\t"))
    file.close()
    save_completed.emit()
    return true

func load_game(slot: int) -> bool:
    var path = SAVE_DIR + "save_slot_%02d.json" % slot
    if not FileAccess.file_exists(path):
        return false
    
    var file = FileAccess.open(path, FileAccess.READ)
    if file == null: return false
    var text = file.get_as_text()
    file.close()
    
    var data = JSON.parse_string(text)
    if data == null: return false
    
    # Version check
    if data.get("meta", {}).get("version", 0) != SAVE_VERSION:
        push_warning("Save version mismatch")
        data = _migrate_save(data)
    
    _apply_save_data(data)
    load_completed.emit()
    return true

func _gather_save_data() -> Dictionary:
    var data = {}
    data["player"] = _save_player()
    data["money"] = _save_money()
    data["inventory"] = _save_inventory()
    data["vehicles"] = _save_vehicles()
    data["properties"] = _save_properties()
    data["world"] = _save_world()
    data["missions"] = _save_missions()
    data["story"] = _save_story()
    data["relationships"] = _save_relationships()
    data["reputation"] = _save_reputation()
    data["wanted"] = _save_wanted()
    return data

func _save_player() -> Dictionary:
    var player = get_tree().get_first_node_in_group("player")
    return {
        "stats": PlayerStats.stats,
        "skills": PlayerStats.skills,
        "level": PlayerStats.level,
        "xp": PlayerStats.current_xp,
        "position": {
            "x": player.global_position.x,
            "y": player.global_position.y,
            "z": player.global_position.z,
        },
        "rotation_y": player.rotation.y,
    }

func _save_money() -> Dictionary:
    return {
        "cash": MoneySystem.cash,
        "bank": MoneySystem.bank_balance,
    }

func _save_inventory() -> Dictionary:
    var items = []
    for item in InventorySystem.get_all_items():
        items.append({
            "item_id": item.item_id,
            "quantity": item.quantity,
        })
    return {
        "items": items,
        "max_slots": InventorySystem.max_slots,
        "max_weight": InventorySystem.max_weight,
    }

func _save_vehicles() -> Dictionary:
    var vehicles = []
    for vehicle in VehicleManager.owned_vehicles:
        vehicles.append({
            "vehicle_id": vehicle.vehicle_id,
            "current_health": vehicle.current_health,
            "fuel": vehicle.current_fuel,
            "customizations": vehicle.customizations,
            "state": vehicle.state,
        })
    return {
        "owned": vehicles,
        "current_vehicle": VehicleManager.current_vehicle_id,
    }

func _save_properties() -> Dictionary:
    var properties = []
    for prop in PropertyManager.owned_properties:
        var furniture = []
        for furn in prop.placed_furniture:
            furniture.append({
                "furniture_id": furn.furniture_id,
                "position": {
                    "x": furn.grid_position.x,
                    "y": furn.grid_position.y,
                    "z": furn.grid_position.z,
                },
                "rotation": furn.rotation,
            })
        properties.append({
            "property_id": prop.property_id,
            "is_rental": prop.is_rental,
            "rent_due_day": prop.rent_due_day,
            "furniture": furniture,
        })
    return {"owned": properties}

func _save_world() -> Dictionary:
    return {
        "day": TimeSystem.get_day(),
        "hour": TimeSystem.get_hour(),
        "weather": GlobalWorldState.current_weather,
    }

func _save_missions() -> Dictionary:
    return {
        "active": MissionManager.active_missions,
        "completed": MissionManager.completed_missions,
        "failed": MissionManager.failed_missions,
    }

func _save_story() -> Dictionary:
    return {
        "flags": StoryManager.story_flags,
        "choices": StoryManager.story_choices,
        "current_chapter": StoryManager.current_chapter,
    }

func _save_relationships() -> Dictionary:
    return RelationshipSystem.relationships

func _save_reputation() -> Dictionary:
    return ReputationSystem.faction_reputation

func _save_wanted() -> Dictionary:
    return {
        "level": WantedSystem.wanted_level,
        "crimes": WantedSystem.crimes_committed,
    }

func _apply_save_data(data: Dictionary) -> void:
    _load_player(data.get("player", {}))
    _load_money(data.get("money", {}))
    _load_inventory(data.get("inventory", {}))
    _load_vehicles(data.get("vehicles", {}))
    _load_properties(data.get("properties", {}))
    _load_world(data.get("world", {}))
    _load_missions(data.get("missions", {}))
    _load_story(data.get("story", {}))
    RelationshipSystem.relationships = data.get("relationships", {})
    ReputationSystem.faction_reputation = data.get("reputation", {})
    _load_wanted(data.get("wanted", {}))

func _load_player(pdata: Dictionary) -> void:
    PlayerStats.stats = pdata.get("stats", PlayerStats.stats)
    PlayerStats.skills = pdata.get("skills", PlayerStats.skills)
    PlayerStats.level = pdata.get("level", 1)
    PlayerStats.current_xp = pdata.get("xp", 0)
    var player = get_tree().get_first_node_in_group("player")
    var pos = pdata.get("position", {})
    player.global_position = Vector3(
        pos.get("x", 0), pos.get("y", 0), pos.get("z", 0))
    player.rotation.y = pdata.get("rotation_y", 0)

func _load_money(mdata: Dictionary) -> void:
    MoneySystem.cash = mdata.get("cash", 0)
    MoneySystem.bank_balance = mdata.get("bank", 0)

func _load_inventory(idata: Dictionary) -> void:
    InventorySystem.clear_inventory()
    for item_entry in idata.get("items", []):
        var item = ItemDatabase.get_item(item_entry["item_id"])
        if item:
            item.quantity = item_entry.get("quantity", 1)
            InventorySystem.add_item(item)

func _load_vehicles(vdata: Dictionary) -> void:
    VehicleManager.owned_vehicles.clear()
    for ventry in vdata.get("owned", []):
        var vehicle = VehicleManager.create_vehicle(ventry["vehicle_id"])
        vehicle.current_health = ventry.get("current_health", 100)
        vehicle.current_fuel = ventry.get("fuel", 0)
        vehicle.customizations = ventry.get("customizations", {})
        vehicle.state = ventry.get("state", "stored")
        VehicleManager.owned_vehicles.append(vehicle)
    VehicleManager.current_vehicle_id = vdata.get("current_vehicle", "")

func _load_properties(pdata: Dictionary) -> void:
    PropertyManager.owned_properties.clear()
    for pentry in pdata.get("owned", []):
        var prop = PropertyManager.get_property(pentry["property_id"])
        prop.is_rental = pentry.get("is_rental", false)
        prop.rent_due_day = pentry.get("rent_due_day", 0)
        # Load furniture
        prop.placed_furniture.clear()
        for fentry in pentry.get("furniture", []):
            var furn = FurnitureManager.create_furniture(fentry["furniture_id"])
            furn.grid_position = Vector3(
                fentry["position"].x, fentry["position"].y, fentry["position"].z)
            furn.rotation = fentry.get("rotation", 0)
            prop.placed_furniture.append(furn)
        PropertyManager.owned_properties.append(prop)

func _load_world(wdata: Dictionary) -> void:
    TimeSystem.set_time(wdata.get("hour", 8.0))
    TimeSystem.set_day(wdata.get("day", 1))
    GlobalWorldState.current_weather = wdata.get("weather", "clear")

func _load_missions(mdata: Dictionary) -> void:
    MissionManager.active_missions = mdata.get("active", [])
    MissionManager.completed_missions = mdata.get("completed", [])
    MissionManager.failed_missions = mdata.get("failed", [])

func _load_story(sdata: Dictionary) -> void:
    StoryManager.story_flags = sdata.get("flags", {})
    StoryManager.story_choices = sdata.get("choices", {})
    StoryManager.current_chapter = sdata.get("current_chapter", 1)

func _load_wanted(wdata: Dictionary) -> void:
    WantedSystem.wanted_level = wdata.get("level", 0)
    WantedSystem.crimes_committed = wdata.get("crimes", [])

func _migrate_save(data: Dictionary) -> Dictionary:
    # Handle save file version migrations
    return data

func get_save_info(slot: int) -> Dictionary:
    var path = SAVE_DIR + "save_slot_%02d.json" % slot
    if not FileAccess.file_exists(path):
        return {}
    var file = FileAccess.open(path, FileAccess.READ)
    if file == null: return {}
    var data = JSON.parse_string(file.get_as_text())
    file.close()
    return data.get("meta", {})

func delete_save(slot: int) -> void:
    var path = SAVE_DIR + "save_slot_%02d.json" % slot
    DirAccess.remove_absolute(path)

func has_save(slot: int) -> bool:
    var path = SAVE_DIR + "save_slot_%02d.json" % slot
    return FileAccess.file_exists(path)
```

---

## Step 2 — Autosave System

### `AutosaveManager.gd`

```gdscript
extends Node

var autosave_timer: float = 0.0
const AUTOSAVE_INTERVAL = 300.0  # 5 minutes

func _process(delta: float) -> void:
    autosave_timer += delta
    if autosave_timer >= AUTOSAVE_INTERVAL:
        autosave_timer = 0.0
        SaveSystem.save_game(0)  # Slot 0 = autosave
        PhoneSystem.add_notification("System", "Autosave", "Game saved.")

func save_on_event(event: String) -> void:
    match event:
        "mission_complete":
            SaveSystem.save_game(0)
        "enter_property":
            SaveSystem.save_game(0)
        "sleep":
            SaveSystem.save_game(0)
        "exit_vehicle":
            SaveSystem.save_game(0)
```

---

## Step 3 — Settings Menu

### `SettingsManager.gd` (Autoload)

```gdscript
extends Node

signal settings_changed(key: String, value)

var settings: Dictionary = {
    "master_volume": 1.0,
    "music_volume": 0.8,
    "sfx_volume": 1.0,
    "voice_volume": 1.0,
    "ambient_volume": 0.6,
    "graphics_quality": "high",  # low, medium, high, ultra
    "shadow_quality": "high",
    "anti_aliasing": "fxaa",
    "vsync": true,
    "fov": 75,
    "sensitivity": 1.0,
    "invert_y": false,
    "subtitles": true,
    "language": "en",
    "difficulty": "normal",
    "auto_save": true,
}

const SETTINGS_PATH = "user://settings.cfg"

func _ready() -> void:
    load_settings()

func load_settings() -> void:
    var config = ConfigFile.new()
    var err = config.load(SETTINGS_PATH)
    if err == OK:
        for key in config.get_section_keys("settings"):
            settings[key] = config.get_value("settings", key)
    _apply_settings()

func save_settings() -> void:
    var config = ConfigFile.new()
    for key in settings:
        config.set_value("settings", key, settings[key])
    config.save(SETTINGS_PATH)

func set_setting(key: String, value) -> void:
    settings[key] = value
    _apply_setting(key, value)
    save_settings()
    settings_changed.emit(key, value)

func _apply_settings() -> void:
    for key in settings:
        _apply_setting(key, settings[key])

func _apply_setting(key: String, value) -> void:
    match key:
        "master_volume":
            AudioServer.set_bus_volume_db(0, linear_to_db(value))
        "music_volume":
            AudioServer.set_bus_volume_db(1, linear_to_db(value))
        "sfx_volume":
            AudioServer.set_bus_volume_db(2, linear_to_db(value))
        "voice_volume":
            AudioServer.set_bus_volume_db(3, linear_to_db(value))
        "ambient_volume":
            AudioServer.set_bus_volume_db(4, linear_to_db(value))
        "vsync":
            DisplayServer.window_set_vsync_mode(
                DisplayServer.VSYNC_ENABLED if value else DisplayServer.VSYNC_DISABLED)
        "fov":
            var camera = get_tree().get_first_node_in_group("player_camera")
            if camera: camera.fov = value
        "shadow_quality":
            _set_shadow_quality(value)
        "graphics_quality":
            _set_graphics_quality(value)

func _set_shadow_quality(quality: String) -> void:
    var world_env = get_tree().get_first_node_in_group("world_environment")
    if world_env == null: return
    var env = world_env.environment
    match quality:
        "off":
            env.shadow_attributes = null
        "low":
            env.shadow_attributes.shadow_size = 1024
        "medium":
            env.shadow_attributes.shadow_size = 2048
        "high":
            env.shadow_attributes.shadow_size = 4096
        "ultra":
            env.shadow_attributes.shadow_size = 8192

func _set_graphics_quality(quality: String) -> void:
    match quality:
        "low":
            get_viewport().msaa_3d = Viewport.MSAA_DISABLED
            get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
        "medium":
            get_viewport().msaa_3d = Viewport.MSAA_2X
            get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
        "high":
            get_viewport().msaa_3d = Viewport.MSAA_4X
            get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_ENABLED
        "ultra":
            get_viewport().msaa_3d = Viewport.MSAA_8X
            get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_ENABLED
```

---

## Step 4 — Options Menu UI

### `OptionsMenu.gd`

```gdscript
extends Control

@onready var master_slider = $VBox/Audio/MasterSlider
@onready var music_slider = $VBox/Audio/MusicSlider
@onready var sfx_slider = $VBox/Audio/SFXSlider
@onready var fov_slider = $VBox/Video/FOVSlider
@onready var sensitivity_slider = $VBox/Controls/SensitivitySlider
@onready var quality_dropdown = $VBox/Video/QualityDropdown
@onready var shadow_dropdown = $VBox/Video/ShadowDropdown
@onready var vsync_check = $VBox/Video/VSyncCheck
@onready var subtitles_check = $VBox/Gameplay/SubtitlesCheck
@onready var autosave_check = $VBox/Gameplay/AutosaveCheck

func _ready() -> void:
    _load_current_settings()
    visible = false

func _load_current_settings() -> void:
    master_slider.value = SettingsManager.settings["master_volume"]
    music_slider.value = SettingsManager.settings["music_volume"]
    sfx_slider.value = SettingsManager.settings["sfx_volume"]
    fov_slider.value = SettingsManager.settings["fov"]
    sensitivity_slider.value = SettingsManager.settings["sensitivity"]
    quality_dropdown.selected = quality_dropdown.item_index(SettingsManager.settings["graphics_quality"])
    shadow_dropdown.selected = shadow_dropdown.item_index(SettingsManager.settings["shadow_quality"])
    vsync_check.button_pressed = SettingsManager.settings["vsync"]
    subtitles_check.button_pressed = SettingsManager.settings["subtitles"]
    autosave_check.button_pressed = SettingsManager.settings["auto_save"]

func _on_master_slider_changed(value: float) -> void:
    SettingsManager.set_setting("master_volume", value)

func _on_music_slider_changed(value: float) -> void:
    SettingsManager.set_setting("music_volume", value)

func _on_sfx_slider_changed(value: float) -> void:
    SettingsManager.set_setting("sfx_volume", value)

func _on_fov_slider_changed(value: float) -> void:
    SettingsManager.set_setting("fov", int(value))

func _on_sensitivity_slider_changed(value: float) -> void:
    SettingsManager.set_setting("sensitivity", value)

func _on_quality_dropdown_item_selected(index: int) -> void:
    SettingsManager.set_setting("graphics_quality", quality_dropdown.get_item_text(index).to_lower())

func _on_shadow_dropdown_item_selected(index: int) -> void:
    SettingsManager.set_setting("shadow_quality", shadow_dropdown.get_item_text(index).to_lower())

func _on_vsync_check_toggled(pressed: bool) -> void:
    SettingsManager.set_setting("vsync", pressed)

func _on_subtitles_check_toggled(pressed: bool) -> void:
    SettingsManager.set_setting("subtitles", pressed)

func _on_autosave_check_toggled(pressed: bool) -> void:
    SettingsManager.set_setting("auto_save", pressed)

func _on_apply_button_pressed() -> void:
    SettingsManager.save_settings()
    visible = false

func _on_reset_button_pressed() -> void:
    SettingsManager.settings = SettingsManager.DEFAULT_SETTINGS.duplicate()
    SettingsManager.save_settings()
    _load_current_settings()
```

---

## Step 5 — Performance Optimization

### Optimization Checklist

| Area | Technique | Target |
| :--- | :--- | :--- |
| **Rendering** | LOD (Level of Detail) | 3 LOD levels per building |
| **Rendering** | Occlusion culling | Use Godot's built-in |
| **Rendering** | Instanced rendering | Streetlights, trees, benches |
| **NPCs** | Distance-based activation | Only update NPCs within 100m |
| **NPCs** | Cap active NPCs | Max 50 active at once |
| **Traffic** | Simplified physics for distant cars | Kinematic body for far vehicles |
| **Physics** | Disable collision for distant objects | Beyond 200m |
| **Audio** | 3D attenuation | Sounds fade with distance |
| **Memory** | Scene streaming | Load/unload districts dynamically |
| **Memory** | Texture streaming | Mipmap streaming enabled |

### `PerformanceManager.gd`

```gdscript
extends Node

var active_npc_count: int = 0
const MAX_ACTIVE_NPCS = 50
const NPC_UPDATE_DISTANCE = 100.0
const PHYSICS_DISABLE_DISTANCE = 200.0

func _process(delta: float) -> void:
    _manage_npcs()
    _manage_distant_objects()

func _manage_npcs() -> void:
    var player = get_tree().get_first_node_in_group("player")
    if player == null: return
    var npcs = get_tree().get_nodes_in_group("npc")
    active_npc_count = 0
    
    for npc in npcs:
        var distance = npc.global_position.distance_to(player.global_position)
        if distance < NPC_UPDATE_DISTANCE and active_npc_count < MAX_ACTIVE_NPCS:
            npc.set_process(true)
            npc.set_physics_process(true)
            active_npc_count += 1
        else:
            npc.set_process(false)
            npc.set_physics_process(false)

func _manage_distant_objects() -> void:
    var player = get_tree().get_first_node_in_group("player")
    if player == null: return
    var objects = get_tree().get_nodes_in_group("distant_physics")
    for obj in objects:
        var distance = obj.global_position.distance_to(player.global_position)
        if distance > PHYSICS_DISABLE_DISTANCE:
            obj.set_physics_process(false)
            if obj is RigidBody3D:
                obj.sleeping = true
        else:
            obj.set_physics_process(true)
```

---

## Step 6 — Bug Fixing & QA

### Bug Tracking Template

| ID | Description | Severity | Status | Assignee |
| :--- | :--- | :--- | :--- | :--- |
| BUG-001 | NPCs clip through walls at corners | Medium | Open | — |
| BUG-002 | Save fails when inventory full | High | Open | — |
| BUG-003 | Vehicle physics jitter at high speed | Low | Open | — |

### QA Checklist

- [ ] All missions completable without soft-locks
- [ ] Save/load works in all scenarios
- [ ] No crashes after 1 hour of play
- [ ] FPS stays above 30 in dense areas
- [ ] All UI elements scale correctly
- [ ] Audio doesn't clip or cut out
- [ ] No z-fighting on building seams
- [ ] NPCs don't spawn inside walls
- [ ] Vehicles don't fall through the ground
- [ ] Phone UI accessible at all times

---

## Step 7 — Final Polish

### Polish Checklist

| Category | Item | Status |
| :--- | :--- | :--- |
| **Audio** | Footstep sounds per surface | ☐ |
| **Audio** | Ambient city sounds | ☐ |
| **Audio** | UI click sounds | ☐ |
| **Visual** | Screen shake on impact | ☐ |
| **Visual** | Damage flash overlay | ☐ |
| **Visual** | Motion blur on vehicles | ☐ |
| **Visual** | Depth of field in menus | ☐ |
| **UX** | Tutorial tooltips | ☐ |
| **UX** | Loading screen tips | ☐ |
| **UX** | Confirmation dialogs | ☐ |
| **UX** | Error messages for player | ☐ |
| **Gameplay** | Difficulty balancing | ☐ |
| **Gameplay** | Economy balancing | ☐ |
| **Gameplay** | NPC spawn rates | ☐ |

### Loading Screen Tips

```
"Tip: Press F to interact with objects and people."
"Tip: Visit an ATM to deposit cash safely."
"Tip: Sleeping restores energy and saves your game."
"Tip: Higher wanted levels mean more police response."
"Tip: Gifts improve relationships with NPCs."
"Tip: Keep your vehicle fueled — running out strands you."
"Tip: Jobs pay better as you level up your skills."
"Tip: Property generates passive income through rent."
```

The save system and polish phase ensure Project Earth is stable, performant, and feels like a complete, professional game ready for expansion.
