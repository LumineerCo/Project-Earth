# Stage 4.7 — Health & Survival

Health and survival mechanics add stakes to exploration. The player must eat, drink, sleep, and seek medical help when injured.

---

## Goal
Create a survival system that integrates with the stats from Stage 4.1, adding injury states, medical facilities, and death/respawn.

---

## Step 1 — Survival Needs

| Need | Decay Rate | Effect When Low | Refill Method |
| :--- | :--- | :--- | :--- |
| **Hunger** | -1 per 30s | Stamina regen halved, then health damage | Eat food |
| **Thirst** | -1 per 20s | Stamina regen halved, then health damage | Drink liquids |
| **Energy** | -1 per 60s | Movement speed -20%, screen blur | Sleep in bed |
| **Hygiene** | -1 per 120s | NPC reactions worsen, charisma checks harder | Shower at home |
| **Social** | -1 per 300s | Mood decreases, slight XP gain reduction | Talk to NPCs |

---

## Step 2 — Injury System

Injuries are separate from the base health stat and require specific treatment.

| Injury | Cause | Effect | Treatment |
| :--- | :--- | :--- | :--- |
| **Sprained Ankle** | Falling from height | Movement speed -30% | Rest or hospital |
| **Broken Arm** | Vehicle crash, combat | Cannot use two-handed items | Hospital visit |
| **Concussion** | Head trauma | Screen blur, random stumbling | Hospital visit |
| **Laceration** | Combat (bladed) | Slow health bleed | Bandage or hospital |
| **Burn** | Fire, explosions | Health damage over time | Burn kit or hospital |
| **Food Poisoning** | Spoiled food | Random vomiting, stamina drain | Medicine or hospital |

### `InjurySystem.gd`

```gdscript
extends Node

signal injury_added(injury_type: String)
signal injury_healed(injury_type: String)

var active_injuries: Dictionary = {}  # injury_type -> {severity, time_inflicted}

const INJURY_EFFECTS = {
    "sprained_ankle": {"speed_mult": 0.7, "stamina_drain": 1.5},
    "broken_arm": {"two_handed_block": true},
    "concussion": {"blur": true, "stumble_chance": 0.1},
    "laceration": {"health_bleed": 0.5},
    "burn": {"health_drain": 0.3},
    "food_poisoning": {"stamina_drain": 2.0, "vomit_chance": 0.05},
}

func add_injury(injury_type: String, severity: float = 1.0) -> void:
    active_injuries[injury_type] = {
        "severity": severity,
        "time_inflicted": Time.get_ticks_msec() / 1000.0,
    }
    injury_added.emit(injury_type)
    PhoneSystem.add_notification("Health", "Injury", 
        "You have: %s" % injury_type.replace("_", " ").capitalize())

func heal_injury(injury_type: String) -> void:
    if active_injuries.has(injury_type):
        active_injuries.erase(injury_type)
        injury_healed.emit(injury_type)

func has_injury(injury_type: String) -> bool:
    return active_injuries.has(injury_type)

func get_speed_multiplier() -> float:
    var mult = 1.0
    for injury in active_injuries:
        var effects = INJURY_EFFECTS.get(injury, {})
        if effects.has("speed_mult"):
            mult *= effects["speed_mult"]
    return mult

func get_stamina_drain_multiplier() -> float:
    var mult = 1.0
    for injury in active_injuries:
        var effects = INJURY_EFFECTS.get(injury, {})
        if effects.has("stamina_drain"):
            mult *= effects["stamina_drain"]
    return mult

func has_two_handed_block() -> bool:
    for injury in active_injuries:
        var effects = INJURY_EFFECTS.get(injury, {})
        if effects.get("two_handed_block", false):
            return true
    return false

func _process(delta: float) -> void:
    # Apply ongoing injury effects
    for injury in active_injuries:
        var effects = INJURY_EFFECTS.get(injury, {})
        if effects.has("health_bleed"):
            PlayerStats._modify_stat("health", -effects["health_bleed"] * delta)
        if effects.has("health_drain"):
            PlayerStats._modify_stat("health", -effects["health_drain"] * delta)
        if effects.has("stamina_drain"):
            PlayerStats._modify_stat("stamina", -effects["stamina_drain"] * delta)
```

---

## Step 3 — Food & Drink System

### Food Items

| Item | Hunger | Thirst | Energy | Health | Price |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Coffee** | 0 | +10 | +15 | 0 | 5 Cr |
| **Water Bottle** | 0 | +30 | 0 | 0 | 3 Cr |
| **Sandwich** | +25 | 0 | +5 | 0 | 10 Cr |
| **Burger** | +35 | -5 | +10 | 0 | 15 Cr |
| **Salad** | +20 | +5 | +5 | +5 | 12 Cr |
| **Energy Drink** | 0 | +15 | +30 | -5 | 8 Cr |
| **Cooked Meal** | +50 | +10 | +20 | +10 | 25 Cr |
| **Medkit** | 0 | 0 | 0 | +50 | 50 Cr |

### `ConsumableItem.gd`

```gdscript
extends ItemData
class_name ConsumableItem

@export var hunger_restore: float = 0.0
@export var thirst_restore: float = 0.0
@export var energy_restore: float = 0.0
@export var health_restore: float = 0.0
@export var hygiene_restore: float = 0.0
@export var can_cure: Array[String] = []  # Injury types it cures
@export var spoil_time: float = 0.0  # Hours until spoiled, 0 = never

func use() -> void:
    PlayerStats._modify_stat("hunger", hunger_restore)
    PlayerStats._modify_stat("thirst", thirst_restore)
    PlayerStats._modify_stat("energy", energy_restore)
    PlayerStats._modify_stat("health", health_restore)
    for cure in can_cure:
        InjurySystem.heal_injury(cure)
```

---

## Step 4 — Sleep System

Sleep restores energy and advances time.

### `BedInteractable.gd`

```gdscript
extends Area3D
class_name BedInteractable

@export var sleep_quality: float = 1.0  # 0.5 = poor, 1.0 = normal, 1.5 = luxury

func interact(player: Node3D) -> void:
    _start_sleep()

func _start_sleep() -> void:
    ShopUIManager.open_sleep_ui(sleep_quality)

func do_sleep(hours: float) -> void:
    # Restore energy
    var energy_gain = hours * 10.0 * sleep_quality
    PlayerStats._modify_stat("energy", energy_gain)
    
    # Advance time
    TimeSystem.advance_time(hours)
    
    # Heal minor injuries with good sleep
    if sleep_quality >= 1.0:
        if InjurySystem.has_injury("sprained_ankle"):
            InjurySystem.heal_injury("sprained_ankle")
    
    PhoneSystem.add_notification("Health", "Rested",
        "Slept for %.1f hours. Energy restored." % hours)
```

---

## Step 5 — Hospitals & Medical

Hospitals are placed in the city for treating serious injuries.

### `HospitalInteractable.gd`

```gdscript
extends Area3D
class_name HospitalInteractable

@export var treatment_cost: int = 100

func interact(player: Node3D) -> void:
    ShopUIManager.open_hospital_ui(treatment_cost)

func treat_all_injuries() -> bool:
    if not MoneySystem.spend_cash(treatment_cost):
        PhoneSystem.add_notification("Hospital", "Insufficient Funds",
            "Treatment costs %d Cr" % treatment_cost)
        return false
    
    # Heal all injuries
    for injury in InjurySystem.active_injuries.keys():
        InjurySystem.heal_injury(injury)
    
    # Restore health
    PlayerStats.stats["health"] = PlayerStats.max_stats["health"]
    
    PhoneSystem.add_notification("Hospital", "Treated",
        "All injuries healed. You feel much better.")
    return true
```

### Hospital Locations

| District | Hospital Name | Services |
| :--- | :--- | :--- |
| **Central Plaza** | Nova City General | Full treatment, emergency respawn |
| **Suburban Hills** | Lakeside Medical | Full treatment |
| **Coastal Marina** | Coastline Clinic | Basic treatment, lower cost |

---

## Step 6 — Death & Respawn

When health reaches zero, the player respawns at the nearest hospital with a penalty.

### `DeathSystem.gd`

```gdscript
extends Node

var is_dead: bool = false
var respawn_points: Array[Vector3] = []

func _ready() -> void:
    PlayerStats.player_died.connect(_on_player_death)

func _on_player_death() -> void:
    if is_dead: return
    is_dead = true
    _show_death_screen()

func _show_death_screen() -> void:
    ShopUIManager.open_death_ui()

func respawn() -> void:
    is_dead = false
    
    # Find nearest hospital
    var nearest = _find_nearest_respawn()
    GlobalWorldState.player_global_position = nearest
    
    # Death penalty
    var cash_penalty = int(MoneySystem.cash * 0.1)
    MoneySystem.spend_cash(cash_penalty)
    
    # Restore stats
    PlayerStats.stats["health"] = PlayerStats.max_stats["health"]
    PlayerStats.stats["stamina"] = PlayerStats.max_stats["stamina"]
    PlayerStats.stats["energy"] = PlayerStats.max_stats["energy"] * 0.5
    
    # Clear minor injuries, keep major ones
    InjurySystem.heal_injury("sprained_ankle")
    InjurySystem.heal_injury("food_poisoning")
    
    PhoneSystem.add_notification("Hospital", "Revived",
        "Hospital fee: %d Cr. Take care out there." % cash_penalty)

func _find_nearest_respawn() -> Vector3:
    var player_pos = GlobalWorldState.player_global_position
    var nearest = respawn_points[0] if respawn_points.size() > 0 else Vector3.ZERO
    var nearest_dist = INF
    for point in respawn_points:
        var dist = player_pos.distance_to(point)
        if dist < nearest_dist:
            nearest_dist = dist
            nearest = point
    return nearest
```

The survival system creates meaningful resource management without being overly punishing, keeping the player engaged in the world's economy and facilities.
