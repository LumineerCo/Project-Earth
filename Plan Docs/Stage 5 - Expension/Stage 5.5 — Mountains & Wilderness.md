# Stage 5.5 — Mountains & Wilderness

Mountain regions add verticality, danger, and adventure to the world. They offer hiking, camping, mining, skiing, and survival challenges that are completely different from city gameplay.

---

## Goal
Build a mountain biome with elevation-based weather, hiking trails, camping mechanics, mining opportunities, and winter sports.

---

## Step 1 — Mountain Region Overview

| Region | Size | Elevation Range | Biome | Key Features |
| :--- | :--- | :--- | :--- | :--- |
| **Summit Peak Range** | 4.0 km² | 500m–3,800m | Alpine | Skiing, mining, hiking |
| **Pine Valley** | 2.0 km² | 800m–1,500m | Forested slopes | Camping, hunting, foraging |
| **Glacier Pass** | 1.5 km² | 2,000m–3,800m | Snow/ice | Ice climbing, extreme survival |

---

## Step 2 — Elevation System

Mountain gameplay changes dramatically based on altitude.

### Elevation Zones

```text
3,800m ─── Summit Zone (extreme cold, low oxygen, blizzards)
  │
3,000m ─── Alpine Zone (snow, ice, skiing)
  │
2,000m ─── Subalpine Zone (pine forest, cold, camping)
  │
1,000m ─── Montane Zone (mixed forest, mild, hiking)
  │
  500m ─── Foothills (meadows, streams, foraging)
```

### `ElevationSystem.gd`

```gdscript
extends Node
class_name ElevationSystem

var player: Node3D

func _process(_delta: float) -> void:
    if not player: return
    var elevation = player.global_position.y
    _apply_elevation_effects(elevation)

func _apply_elevation_effects(elevation: float) -> void:
    # Temperature decreases with altitude (roughly -6.5°C per 1000m)
    var base_temp = WeatherSystem.get_base_temperature()
    var altitude_factor = elevation / 1000.0
    var adjusted_temp = base_temp - (altitude_factor * 6.5)
    WeatherSystem.set_local_temperature(adjusted_temp)
    
    # Oxygen levels affect stamina
    if elevation > 3000.0:
        var oxygen_factor = 1.0 - ((elevation - 3000.0) / 1000.0) * 0.5
        PlayerStats.set_stamina_drain_multiplier(2.0 / oxygen_factor)
        if elevation > 3500.0:
            UI.showOverlay("altitude_sickness")
    else:
        PlayerStats.set_stamina_drain_multiplier(1.0)
        UI.hideOverlay("altitude_sickness")
    
    # Visibility decreases at high altitude in storms
    if elevation > 2500.0 and WeatherSystem.is_storm_active():
        EnvironmentSystem.set_fog_density(0.08)
    else:
        EnvironmentSystem.set_fog_density(0.01)
```

---

## Step 3 — Hiking & Trail System

### Trail Network

```text
Summit Peak Trail Network
├── Beginner Trail (Foothills Loop) — 2km, easy, 30 min
├── Intermediate Trail (Pine Ridge) — 5km, moderate, 1.5 hr
├── Advanced Trail (Summit Climb) — 8km, hard, 4 hr
├── Expert Trail (Glacier Pass) — 12km, extreme, 8 hr
└── Hidden Trail (Secret Waterfall) — 3km, moderate, 1 hr (discovery)
```

### Trail Markers
Trails are marked with colored flags placed along the path. Players can follow them or use a trail map purchased at the visitor center.

### `HikingTrail.gd`

```gdscript
extends Path3D

@export var trail_difficulty: String = "beginner"  # beginner, intermediate, advanced, expert
@export var trail_length_km: float = 2.0
@export var estimated_time_hours: float = 0.5
@export var trail_name: String = "Foothills Loop"

var checkpoints: Array[Node3D] = []
var player_progress: float = 0.0  # 0.0 to 1.0

func _ready() -> void:
    _generate_checkpoints()

func _generate_checkpoints() -> void:
    var point_count = int(trail_length_km * 2)  # checkpoint every 500m
    for i in range(point_count):
        var offset = curve.get_baked_length() * (float(i) / point_count)
        var pos = curve.sample_baked(offset)
        var checkpoint = preload("res://scenes/world/mountains/trail_marker.tscn").instantiate()
        checkpoint.position = pos
        checkpoint.trail_name = trail_name
        checkpoint.checkpoint_index = i
        add_child(checkpoint)
        checkpoints.append(checkpoint)

func update_progress(player_pos: Vector3) -> float:
    var local_pos = to_local(player_pos)
    var closest_offset = curve.get_closest_offset(local_pos)
    player_progress = closest_offset / curve.get_baked_length()
    return player_progress

func get_completion_reward() -> int:
    var base_reward = {
        "beginner": 200,
        "intermediate": 500,
        "advanced": 1000,
        "expert": 2500,
    }
    return base_reward.get(trail_difficulty, 200)
```

---

## Step 4 — Camping System

Players can set up camp anywhere in the wilderness for rest, cooking, and survival.

### Camping Mechanics

| Action | Requirement | Effect |
| :--- | :--- | :--- |
| **Pitch Tent** | Tent item in inventory | Creates rest point |
| **Light Campfire** | Matches + Firewood | Warmth, cooking, light |
| **Cook Food** | Campfire + Raw food item | Restores hunger |
| **Sleep in Tent** | Tent pitched | Restores health, skips time |
| **Forage Berries** | None (wild bushes) | Small hunger restore |
| **Collect Firewood** | Axe (optional) | Fuel for campfire |

### `CampingSystem.gd`

```gdscript
extends Node
class_name CampingSystem

var camp_active: bool = false
var campfire_lit: bool = false
var campfire_node: Node3D
var tent_node: Node3D

func setup_camp(pos: Vector3) -> bool:
    if not InventorySystem.has_item("tent"):
        UI.showToast("You need a tent to camp here.")
        return false
    
    # Place tent
    tent_node = preload("res://scenes/world/mountains/tent.tscn").instantiate()
    tent_node.global_position = pos
    get_tree().current_scene.add_child(tent_node)
    
    camp_active = true
    InventorySystem.remove_item("tent", 1)
    UI.showToast("Camp set up. You can rest here.")
    return true

func light_campfire(pos: Vector3) -> bool:
    if not InventorySystem.has_item("matches") or not InventorySystem.has_item("firewood"):
        UI.showToast("Need matches and firewood to start a fire.")
        return false
    
    campfire_node = preload("res://scenes/world/mountains/campfire.tscn").instantiate()
    campfire_node.global_position = pos + Vector3(2, 0, 0)
    get_tree().current_scene.add_child(campfire_node)
    campfire_lit = true
    
    InventorySystem.remove_item("matches", 1)
    InventorySystem.remove_item("firewood", 1)
    
    # Warmth effect
    PlayerStats.set_warmth_source(campfire_node, 5.0)  # 5m radius
    UI.showToast("Campfire lit. Stay warm!")
    return true

func sleep_at_camp() -> void:
    if not camp_active:
        UI.showToast("Set up camp first.")
        return
    
    # Fade to black, skip time
    UIFadeScreen.fade_out(1.0)
    await get_tree().create_timer(1.0).timeout
    
    TimeSystem.advance_time(8.0 * 3600)  # Skip 8 hours
    PlayerStats.restore_health(30)
    PlayerStats.restore_stamina(100)
    PlayerStats.reduce_hunger(20)  # Sleeping makes you hungry
    
    UIFadeScreen.fade_in(1.0)
    UI.showToast("You slept well. Health and stamina restored.")

func dismantle_camp() -> void:
    if campfire_node: campfire_node.queue_free()
    if tent_node: tent_node.queue_free()
    camp_active = false
    campfire_lit = false
    InventorySystem.add_item("tent", 1)  # Recover tent
    UI.showToast("Camp packed up.")
```

---

## Step 5 — Mining System

Mountains contain valuable minerals that players can mine for income.

### Ore Distribution by Elevation

| Ore | Min Elevation | Rarity | Value per Unit |
| :--- | :--- | :--- | :--- |
| **Iron** | 500m | Common | ₹50 |
| **Copper** | 800m | Common | ₹70 |
| **Coal** | 600m | Common | ₹40 |
| **Silver** | 1,500m | Uncommon | ₹200 |
| **Gold** | 2,000m | Rare | ₹500 |
| **Diamond** | 3,000m | Very Rare | ₹2,000 |
| **Emerald** | 2,500m | Rare | ₹1,200 |

### `MiningSystem.gd`

```gdscript
extends Node
class_name MiningSystem

const ORE_NODES = {
    "iron": {"min_elevation": 500, "rarity": 0.8, "value": 50, "hardness": 2},
    "copper": {"min_elevation": 800, "rarity": 0.6, "value": 70, "hardness": 3},
    "coal": {"min_elevation": 600, "rarity": 0.7, "value": 40, "hardness": 1},
    "silver": {"min_elevation": 1500, "rarity": 0.3, "value": 200, "hardness": 5},
    "gold": {"min_elevation": 2000, "rarity": 0.15, "value": 500, "hardness": 6},
    "diamond": {"min_elevation": 3000, "rarity": 0.05, "value": 2000, "hardness": 9},
    "emerald": {"min_elevation": 2500, "rarity": 0.08, "value": 1200, "hardness": 7},
}

func mine_ore(ore_type: String, pickaxe_level: int) -> Dictionary:
    var ore_data = ORE_NODES.get(ore_type, {})
    if ore_data.is_empty():
        return {"success": false, "reason": "Unknown ore type"}
    
    if pickaxe_level < ore_data["hardness"]:
        return {"success": false, "reason": "Pickaxe too weak for this ore"}
    
    # Mining minigame: timing-based
    var yield_amount = randi_range(1, 5) + pickaxe_level
    var value = ore_data["value"] * yield_amount
    
    return {
        "success": true,
        "ore_type": ore_type,
        "amount": yield_amount,
        "value": value
    }

func get_available_ores_at_elevation(elevation: float) -> Array:
    var available = []
    for ore_type in ORE_NODES:
        if elevation >= ORE_NODES[ore_type]["min_elevation"]:
            available.append(ore_type)
    return available
```

---

## Step 6 — Winter Sports (Skiing)

Summit Peak offers a ski resort with rental equipment and slopes.

### Ski Slopes

| Slope | Difficulty | Length | Requirements |
| :--- | :--- | :--- | :--- |
| **Bunny Hill** | Beginner | 200m | None |
| **Pine Run** | Intermediate | 800m | Ski rental |
| **Summit Slalom** | Advanced | 1,500m | Ski rental + skill level 3 |
| **Glacier Extreme** | Expert | 2,500m | Pro skis + skill level 5 |

### Skiing Controls
* **W/↑** — Lean forward (accelerate)
* **S/↓** — Brake/snowplow
* **A/←** — Turn left
* **D/→** — Turn right
* **Space** — Jump (over ramps)
* **Shift** — Crouch (speed boost)
