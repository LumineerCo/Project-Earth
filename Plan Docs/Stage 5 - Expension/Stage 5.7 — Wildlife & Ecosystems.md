# Stage 5.7 — Wildlife & Ecosystems

A living world needs living creatures. Wildlife populates forests, mountains, fields, and waters — creating a dynamic ecosystem that supports hunting, fishing, photography, and environmental storytelling.

---

## Goal
Build a wildlife system with 20+ species across multiple biomes, each with AI behavior, population dynamics, and player interaction mechanics (hunting, fishing, photography).

---

## Step 1 — Species Overview (20+ Species)

### Land Animals

| # | Species | Biome | Behavior | Population | Threat |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | **Deer** | Forest | Grazing, fleeing | Common | Passive |
| 2 | **Rabbit** | Fields/Forest | Hopping, burrowing | Very Common | Passive |
| 3 | **Fox** | Forest/Fields | Hunting small prey | Uncommon | Neutral |
| 4 | **Wolf** | Mountains/Forest | Pack hunting | Uncommon | Aggressive |
| 5 | **Bear** | Mountains/Forest | Foraging, territorial | Rare | Aggressive |
| 6 | **Boar** | Forest | Foraging, charging | Uncommon | Neutral |
| 7 | **Mountain Lion** | Mountains | Stalking, ambush | Rare | Aggressive |
| 8 | **Goat** | Mountains | Climbing, grazing | Common | Passive |
| 9 | **Sheep** | Countryside | Grazing (farmed) | Common | Passive |
| 10 | **Cow** | Countryside | Grazing (farmed) | Common | Passive |
| 11 | **Chicken** | Countryside | Pecking (farmed) | Very Common | Passive |
| 12 | **Squirrel** | Forest | Climbing, foraging | Common | Passive |
| 13 | **Raccoon** | Forest/Urban | Scavenging at night | Common | Neutral |
| 14 | **Snake** | Fields/Mountains | Basking, biting | Uncommon | Neutral |

### Water Animals

| # | Species | Biome | Behavior | Population | Threat |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 15 | **Trout** | Rivers/Lakes | Swimming, schooling | Common | Passive |
| 16 | **Salmon** | Rivers/Ocean | Migrating | Seasonal | Passive |
| 17 | **Bass** | Lakes | Ambush predator | Common | Passive |
| 18 | **Shark** | Ocean | Hunting | Rare | Aggressive |
| 19 | **Dolphin** | Ocean | Pod swimming | Uncommon | Passive |
| 20 | **Turtle** | Beaches/Rivers | Slow swimming | Uncommon | Passive |
| 21 | **Crab** | Beaches | Scuttling, burrowing | Common | Passive |
| 22 | **Whale** | Deep Ocean | Migrating | Very Rare | Passive |

### Birds

| # | Species | Biome | Behavior | Population | Threat |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 23 | **Eagle** | Mountains | Soaring, diving | Uncommon | Passive |
| 24 | **Seagull** | Beaches | Scavenging, flying | Very Common | Passive |
| 25 | **Duck** | Lakes/Rivers | Swimming, quacking | Common | Passive |
| 26 | **Pigeon** | Urban | Scavenging, flocking | Very Common | Passive |

---

## Step 2 — Wildlife AI Behavior

### Behavior State Machine

```text
                    ┌──────────┐
          ┌────────>│  FLEEING  │
          │         └──────────┘
          │              │
          │         (threat gone)
          │              ↓
┌─────────┐         ┌──────────┐
│  IDLE   │<───────│  WANDER  │
└─────────┘         └──────────┘
     │                   │
     │              (hungry)
     ↓                   ↓
┌─────────┐         ┌──────────┐
│ SLEEPING│         │ FORAGING │
└─────────┘         └──────────┘
                         │
                    (predator spots prey)
                         ↓
                   ┌──────────┐
                   │ HUNTING  │
                   └──────────┘
                         │
                   (caught prey)
                         ↓
                   ┌──────────┐
                   │  EATING  │
                   └──────────┘
```

### `WildlifeBase.gd`

```gdscript
extends CharacterBody3D
class_name WildlifeBase

enum State { IDLE, WANDER, FORAGE, SLEEP, FLEE, HUNT, EAT, ATTACK }
enum Temperament { PASSIVE, NEUTRAL, AGGRESSIVE }

@export var species_name: String = "deer"
@export var temperament: Temperament = Temperament.PASSIVE
@export var max_health: float = 50.0
@export var move_speed: float = 5.0
@export var flee_speed: float = 12.0
@export var detect_range: float = 20.0
@export var flee_range: float = 30.0

var current_state: State = State.IDLE
var health: float = max_health
var home_position: Vector3
var wander_target: Vector3
var state_timer: float = 0.0
var threat: Node3D = null

func _ready() -> void:
    home_position = global_position
    _pick_wander_target()

func _physics_process(delta: float) -> void:
    state_timer += delta
    match current_state:
        State.IDLE:    _state_idle(delta)
        State.WANDER:  _state_wander(delta)
        State.FLEE:    _state_flee(delta)
        State.FORAGE:  _state_forage(delta)
        State.SLEEP:   _state_sleep(delta)
        State.HUNT:    _state_hunt(delta)
        State.EAT:     _state_eat(delta)
        State.ATTACK:  _state_attack(delta)
    
    _detect_threats()
    move_and_slide()

func _detect_threats() -> void:
    if temperament == Temperament.PASSIVE or temperament == Temperament.NEUTRAL:
        var player_dist = global_position.distance_to(Player.global_position)
        if player_dist < detect_range:
            threat = Player
            _change_state(State.FLEE)

func _state_idle(delta: float) -> void:
    velocity = velocity.lerp(Vector3.ZERO, 5.0 * delta)
    if state_timer > 3.0:
        _change_state(State.WANDER)

func _state_wander(delta: float) -> void:
    var dir = (wander_target - global_position)
    if dir.length() < 2.0:
        _pick_wander_target()
        _change_state(State.IDLE)
    else:
        velocity = dir.normalized() * move_speed
        look_at(global_position + velocity)

func _state_flee(delta: float) -> void:
    if not threat:
        _change_state(State.WANDER)
        return
    var flee_dir = (global_position - threat.global_position).normalized()
    velocity = flee_dir * flee_speed
    look_at(global_position + velocity)
    
    if global_position.distance_to(threat.global_position) > flee_range:
        threat = null
        _change_state(State.WANDER)

func _pick_wander_target() -> void:
    var rand_offset = Vector3(randf_range(-15, 15), 0, randf_range(-15, 15))
    wander_target = home_position + rand_offset

func _change_state(new_state: State) -> void:
    current_state = new_state
    state_timer = 0.0

func take_damage(amount: float, source: Node3D) -> void:
    health -= amount
    threat = source
    _change_state(State.FLEE)
    if health <= 0:
        _die()

func _die() -> void:
    # Drop loot
    LootSystem.spawn_loot(global_position, species_name)
    # Notify population manager
    WildlifeManager.on_animal_death(species_name)
    queue_free()
```

---

## Step 3 — Population Management

### `WildlifeManager.gd`

```gdscript
extends Node
class_name WildlifeManager

const MAX_ANIMALS_PER_BIOME = {
    "forest": 30,
    "mountain": 20,
    "countryside": 25,
    "beach": 15,
    "ocean": 20,
}

const SPECIES_BIOME_MAP = {
    "deer": "forest", "rabbit": "forest", "fox": "forest",
    "wolf": "mountain", "bear": "mountain", "goat": "mountain",
    "cow": "countryside", "sheep": "countryside", "chicken": "countryside",
    "trout": "water", "bass": "water", "salmon": "water",
    "eagle": "mountain", "seagull": "beach", "duck": "water",
}

var active_animals: Dictionary = {}  # biome -> Array of animals
var population_counts: Dictionary = {}  # species -> count

func _ready() -> void:
    for biome in MAX_ANIMALS_PER_BIOME:
        active_animals[biome] = []

func spawn_animal(species: String, pos: Vector3) -> void:
    var biome = SPECIES_BIOME_MAP.get(species, "forest")
    if active_animals[biome].size() >= MAX_ANIMALS_PER_BIOME[biome]:
        return  # Biome at capacity
    
    var scene_path = "res://scenes/wildlife/%s.tscn" % species
    var scene = load(scene_path)
    var animal = scene.instantiate()
    animal.global_position = pos
    get_tree().current_scene.add_child(animal)
    active_animals[biome].append(animal)
    
    population_counts[species] = population_counts.get(species, 0) + 1

func on_animal_death(species: String) -> void:
    population_counts[species] = max(population_counts.get(species, 0) - 1, 0)
    # Respawn after delay to maintain ecosystem
    await get_tree().create_timer(60.0).timeout
    var biome = SPECIES_BIOME_MAP.get(species, "forest")
    var spawn_pos = _get_random_spawn_pos(biome)
    spawn_animal(species, spawn_pos)

func _get_random_spawn_pos(biome: String) -> Vector3:
    # Get random position within biome bounds
    var bounds = BiomeManager.get_biome_bounds(biome)
    return Vector3(
        randf_range(bounds["x_min"], bounds["x_max"]),
        0,
        randf_range(bounds["z_min"], bounds["z_max"])
    )
```

---

## Step 4 — Hunting System

### Hunting Equipment

| Weapon | Damage | Range | Noise | Cost |
| :--- | :--- | :--- | :--- | :--- |
| **Hunting Rifle** | 80 | 200m | Loud | ₹15,000 |
| **Bow** | 50 | 60m | Silent | ₹8,000 |
| **Crossbow** | 60 | 80m | Quiet | ₹12,000 |
| **Spear** | 40 | 15m (throw) | Silent | ₹2,000 |

### Hunting Rewards

| Species | Meat | Hide | Special | Total Value |
| :--- | :--- | :--- | :--- | :--- |
| **Deer** | 4x Venison (₹200) | 1x Deer Hide (₹300) | — | ₹1,100 |
| **Rabbit** | 2x Rabbit Meat (₹80) | 1x Rabbit Pelt (₹50) | — | ₹210 |
| **Bear** | 6x Bear Meat (₹300) | 1x Bear Hide (₹1,000) | 1x Bear Claw (₹500) | ₹3,300 |
| **Wolf** | 3x Wolf Meat (₹150) | 1x Wolf Pelt (₹600) | — | ₹1,050 |
| **Boar** | 5x Boar Meat (₹180) | 1x Boar Hide (₹250) | — | ₹1,150 |

---

## Step 5 — Fishing System

### Fishing Minigame Flow

```text
Cast Line (hold to aim, release to cast)
    ↓
Wait for Bite (bobber dips when fish bites)
    ↓
Hook Set (press interact at right moment)
    ↓
Reel In (hold interact, manage tension)
    ↓
Catch Fish (or line snaps if tension too high)
```

### `FishingSystem.gd`

```gdscript
extends Node
class_name FishingSystem

enum FishState { IDLE, CASTING, WAITING, BITING, REELING, CAUGHT, ESCAPED }

var current_state: FishState = FishState.IDLE
var cast_power: float = 0.0
var bobber: Node3D
var hooked_fish: String = ""
var line_tension: float = 0.0
var reel_progress: float = 0.0

const FISH_DATA = {
    "trout": {"weight_range": [0.5, 3.0], "value": 150, "difficulty": 0.3},
    "bass": {"weight_range": [1.0, 5.0], "value": 200, "difficulty": 0.4},
    "salmon": {"weight_range": [2.0, 8.0], "value": 350, "difficulty": 0.5},
    "shark": {"weight_range": [50.0, 200.0], "value": 2000, "difficulty": 0.9},
}

func start_fishing() -> void:
    current_state = FishState.CASTING
    cast_power = 0.0
    UI.show_fishing_hud()

func _process(delta: float) -> void:
    match current_state:
        FishState.CASTING: _state_casting(delta)
        FishState.WAITING: _state_waiting(delta)
        FishState.BITING:  _state_biting(delta)
        FishState.REELING: _state_reeling(delta)

func _state_casting(delta: float) -> void:
    if Input.is_action_pressed("interact"):
        cast_power = min(cast_power + 0.5 * delta, 1.0)
        UI.update_cast_bar(cast_power)
    elif Input.is_action_just_released("interact"):
        _cast_line(cast_power)

func _cast_line(power: float) -> void:
    var cast_distance = power * 30.0
    bobber = preload("res://scenes/fishing/bobber.tscn").instantiate()
    var cast_pos = Player.global_position + (-Player.global_transform.basis.z * cast_distance)
    bobber.global_position = cast_pos
    get_tree().current_scene.add_child(bobber)
    current_state = FishState.WAITING
    UI.update_fishing_status("Waiting for a bite...")

func _state_waiting(delta: float) -> void:
    var wait_time = randf_range(5.0, 20.0)
    await get_tree().create_timer(wait_time).timeout
    if current_state == FishState.WAITING:
        _trigger_bite()

func _trigger_bite() -> void:
    current_state = FishState.BITING
    bobber.dip_down()
    UI.update_fishing_status("Fish biting! Press INTERACT to hook!")
    await get_tree().create_timer(2.0).timeout
    if current_state == FishState.BITING:
        # Missed the bite
        current_state = FishState.WAITING
        UI.update_fishing_status("The fish got away...")

func _state_biting(delta: float) -> void:
    if Input.is_action_just_pressed("interact"):
        hooked_fish = _select_fish()
        current_state = FishState.REELING
        reel_progress = 0.0
        line_tension = 0.0
        UI.update_fishing_status("Reeling in %s!" % hooked_fish)

func _state_reeling(delta: float) -> void:
    if Input.is_action_pressed("interact"):
        reel_progress += 0.3 * delta
        line_tension = min(line_tension + 0.5 * delta, 1.0)
    else:
        line_tension = max(line_tension - 1.0 * delta, 0.0)
    
    UI.update_reel_bar(reel_progress)
    UI.update_tension_bar(line_tension)
    
    if line_tension >= 1.0:
        # Line snaps
        current_state = FishState.ESCAPED
        UI.update_fishing_status("The line snapped! Fish escaped.")
        _reset_fishing()
    elif reel_progress >= 1.0:
        # Caught the fish
        _catch_fish()

func _catch_fish() -> void:
    var fish_data = FISH_DATA[hooked_fish]
    var weight = randf_range(fish_data["weight_range"][0], fish_data["weight_range"][1])
    var value = int(fish_data["value"] * weight)
    
    InventorySystem.add_item("raw_%s" % hooked_fish, 1)
    EconomySystem.add_money(value)
    UI.update_fishing_status("Caught a %.1f kg %s! Worth ₹%d" % [weight, hooked_fish, value])
    current_state = FishState.CAUGHT
    _reset_fishing()

func _select_fish() -> String:
    var available_fish = ["trout", "bass", "salmon"]
    return available_fish[randi() % available_fish.size()]

func _reset_fishing() -> void:
    if bobber: bobber.queue_free()
    await get_tree().create_timer(2.0).timeout
    current_state = FishState.IDLE
    UI.hide_fishing_hud()
