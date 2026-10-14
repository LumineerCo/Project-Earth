# Stage 4.1 — Player Character & Stats

The player character is the avatar through which the player experiences the world. This stage defines the player's core attributes, skills, and progression system.

---

## Goal
Create a player stats system with health, stamina, hunger, skills, and a leveling mechanism that provides meaningful progression.

---

## Step 1 — Core Stats

| Stat | Range | Regen Rate | Effect When Depleted |
| :--- | :--- | :--- | :--- |
| **Health** | 0–100 | 1/sec (out of combat) | Death at 0, respawn at hospital |
| **Stamina** | 0–100 | 5/sec (when not sprinting) | Cannot sprint or fight |
| **Hunger** | 0–100 | -1/30sec | Reduces stamina regen, then health |
| **Thirst** | 0–100 | -1/20sec | Reduces stamina regen, then health |
| **Energy** | 0–100 | -1/60sec | Reduced movement speed, blurry vision |

---

## Step 2 — Skill System

Skills improve through use and unlock new abilities.

| Skill | Max Level | Improves By | Unlocks |
| :--- | :--- | :--- | :--- |
| **Driving** | 100 | Driving distance, races | Better vehicle handling |
| **Fitness** | 100 | Sprinting, swimming | Higher stamina cap |
| **Strength** | 100 | Combat, carrying | More inventory weight |
| **Charisma** | 100 | NPC interactions | Better prices, more dialogue |
| **Intelligence** | 100 | Reading, studying | Higher job pay |
| **Cooking** | 100 | Cooking food | Better food quality |
| **Crafting** | 100 | Crafting items | New recipes |

---

## Step 3 — `PlayerStats.gd` (Autoload)

```gdscript
extends Node

signal stat_changed(stat_name: String, value: float)
signal skill_leveled_up(skill_name: String, new_level: int)
signal player_died

var stats: Dictionary = {
    "health": 100.0,
    "stamina": 100.0,
    "hunger": 100.0,
    "thirst": 100.0,
    "energy": 100.0,
}

var max_stats: Dictionary = {
    "health": 100.0,
    "stamina": 100.0,
    "hunger": 100.0,
    "thirst": 100.0,
    "energy": 100.0,
}

var skills: Dictionary = {
    "driving": 1,
    "fitness": 1,
    "strength": 1,
    "charisma": 1,
    "intelligence": 1,
    "cooking": 1,
    "crafting": 1,
}

var skill_xp: Dictionary = {
    "driving": 0,
    "fitness": 0,
    "strength": 0,
    "charisma": 0,
    "intelligence": 0,
    "cooking": 0,
    "crafting": 0,
}

var money: int = 500  # Starting cash
var level: int = 1
var total_xp: int = 0

const HUNGER_RATE = 1.0 / 30.0  # per second
const THIRST_RATE = 1.0 / 20.0
const ENERGY_RATE = 1.0 / 60.0

func _process(delta: float) -> void:
    _decay_stats(delta)
    _regen_stats(delta)
    _check_death()

func _decay_stats(delta: float) -> void:
    _modify_stat("hunger", -HUNGER_RATE * delta)
    _modify_stat("thirst", -THIRST_RATE * delta)
    _modify_stat("energy", -ENERGY_RATE * delta)

func _regen_stats(delta: float) -> void:
    # Health regenerates slowly when not in combat and hunger/thirst are OK
    if stats["hunger"] > 20 and stats["thirst"] > 20:
        _modify_stat("health", 1.0 * delta)
    
    # Stamina regenerates when not sprinting
    if not Input.is_action_pressed("sprint"):
        _modify_stat("stamina", 5.0 * delta)
    
    # Low hunger/thirst reduces stamina regen
    if stats["hunger"] < 20 or stats["thirst"] < 20:
        _modify_stat("stamina", -2.0 * delta)
        _modify_stat("health", -0.5 * delta)

func _modify_stat(stat_name: String, amount: float) -> void:
    var old_val = stats[stat_name]
    stats[stat_name] = clamp(stats[stat_name] + amount, 0.0, max_stats[stat_name])
    if abs(stats[stat_name] - old_val) > 0.01:
        stat_changed.emit(stat_name, stats[stat_name])

func _check_death() -> void:
    if stats["health"] <= 0.0:
        player_died.emit()

func add_skill_xp(skill_name: String, amount: int) -> void:
    skill_xp[skill_name] += amount
    var xp_needed = _xp_for_next_level(skills[skill_name])
    while skill_xp[skill_name] >= xp_needed:
        skill_xp[skill_name] -= xp_needed
        skills[skill_name] += 1
        skill_leveled_up.emit(skill_name, skills[skill_name])
        xp_needed = _xp_for_next_level(skills[skill_name])

func _xp_for_next_level(current_level: int) -> int:
    return current_level * 100

func add_xp(amount: int) -> void:
    total_xp += amount
    var xp_needed = level * 500
    while total_xp >= xp_needed:
        total_xp -= xp_needed
        level += 1
        _on_level_up()

func _on_level_up() -> void:
    # Increase max stats slightly
    max_stats["health"] += 5
    max_stats["stamina"] += 5
    stats["health"] = max_stats["health"]
    stats["stamina"] = max_stats["stamina"]
```

---

## Step 4 — Stat Effects on Gameplay

| Condition | Gameplay Effect |
| :--- | :--- |
| **Hunger < 20** | Stamina regen halved, health slowly drops |
| **Thirst < 20** | Stamina regen halved, health slowly drops |
| **Energy < 20** | Movement speed -20%, screen blur |
| **Stamina = 0** | Cannot sprint, attack speed halved |
| **Health < 25** | Screen red vignette, movement speed -10% |
| **Strength ≥ 50** | Inventory weight cap +50% |
| **Fitness ≥ 50** | Stamina cap +50% |
| **Driving ≥ 50** | Vehicle handling improved, less skidding |

---

## Step 5 — HUD Integration

The HUD displays stats as circular gauges or bars.

### `StatBar.gd`

```gdscript
extends TextureProgressBar

@export var stat_name: String = "health"
@export var color: Color = Color.RED

func _ready() -> void:
    PlayerStats.stat_changed.connect(_on_stat_changed)
    _update_display(PlayerStats.stats[stat_name], PlayerStats.max_stats[stat_name])

func _on_stat_changed(changed_stat: String, value: float) -> void:
    if changed_stat == stat_name:
        _update_display(value, PlayerStats.max_stats[stat_name])

func _update_display(current: float, maximum: float) -> void:
    max_value = maximum
    value = current
    modulate = color
```

This system gives the player a constant sense of their character's physical state and rewards skill use with tangible progression.
