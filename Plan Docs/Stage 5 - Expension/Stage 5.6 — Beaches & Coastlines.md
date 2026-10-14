# Stage 5.6 — Beaches & Coastlines

Coastal areas bring a relaxed atmosphere with swimming, boating, fishing, and beach activities. Harbor Bay's shoreline serves as the primary beach destination.

---

## Goal
Build beach and coastline biomes with water interaction, swimming mechanics, boats, water sports, and coastal activities.

---

## Step 1 — Coastal Region Overview

| Region | Size | Biome | Key Features |
| :--- | :--- | :--- | :--- |
| **Harbor Bay Beach** | 1.5 km | Sandy beach | Swimming, sunbathing, shops |
| **Coral Reef Cove** | 0.5 km | Rocky cove | Snorkeling, diving, marine life |
| **Lighthouse Point** | 0.3 km | Cliff coast | Fishing, lighthouse landmark |
| **Marina District** | 0.5 km | Harbor docks | Boat rental, yacht club |

---

## Step 2 — Water Interaction System

### Water Zones

```text
Shallow Water (0.0m – 1.5m depth)
  └── Wading only, no swimming animation

Swimming Zone (1.5m – 4.0m depth)
  └── Full swimming, diving enabled

Deep Water (4.0m+ depth)
  └── Swimming only, boats required to go further

Underwater (below surface)
  └── Diving, oxygen meter, marine life
```

### `WaterInteractionSystem.gd`

```gdscript
extends Node
class_name WaterInteractionSystem

var water_plane: Node3D
var player: CharacterBody3D
var is_swimming: bool = false
var is_underwater: bool = false
var oxygen_level: float = 100.0

const SWIM_SPEED = 4.0
const DIVE_SPEED = 3.0
const OXYGEN_DRAIN_RATE = 5.0  # per second underwater
const MAX_DIVE_DEPTH = 15.0

func _process(delta: float) -> void:
    if not player: return
    
    var water_y = water_plane.global_position.y
    var player_y = player.global_position.y
    var depth = water_y - player_y
    
    if depth > 1.5 and not is_swimming:
        _enter_swimming()
    elif depth < 0.5 and is_swimming:
        _exit_swimming()
    
    if is_swimming:
        if depth > 0.5:
            is_underwater = true
            _handle_underwater(delta)
        else:
            is_underwater = false
            oxygen_level = min(oxygen_level + 10.0 * delta, 100.0)
            UI.update_oxygen_bar(oxygen_level)

func _enter_swimming() -> void:
    is_swimming = true
    player.set_movement_mode("swimming")
    PlayerStats.set_stamina_drain_multiplier(1.5)
    UI.show_swimming_hud()
    $Audio/SwimAmbience.play()

func _exit_swimming() -> void:
    is_swimming = false
    is_underwater = false
    player.set_movement_mode("walking")
    PlayerStats.set_stamina_drain_multiplier(1.0)
    UI.hide_swimming_hud()
    UI.hide_underwater_overlay()
    $Audio/SwimAmbience.stop()

func _handle_underwater(delta: float) -> void:
    UI.show_underwater_overlay()
    oxygen_level = max(oxygen_level - OXYGEN_DRAIN_RATE * delta, 0.0)
    UI.update_oxygen_bar(oxygen_level)
    
    if oxygen_level <= 0.0:
        PlayerStats.take_damage(10.0 * delta)  # Drowning damage
        UI.show_warning("Drowning! Return to surface!")
    
    # Post-processing: blue tint, blur
    EnvironmentSystem.set_underwater_effect(true)
```

---

## Step 3 — Swimming Controls

| Input | Action | Description |
| :--- | :--- | :--- |
| **W/↑** | Swim forward | Move in facing direction |
| **S/↓** | Swim backward | Slow backward movement |
| **A/←** | Turn left | Rotate character |
| **D/→** | Turn right | Rotate character |
| **Space** | Surface / Tread water | Rise to surface |
| **Ctrl** | Dive | Descend underwater |
| **Shift** | Sprint swim | Faster but drains stamina |

---

## Step 4 — Boat System

### Boat Types

| Boat | Rental Cost | Capacity | Speed | Features |
| :--- | :--- | :--- | :--- | :--- |
| **Rowboat** | ₹100/hr | 1 | Slow | Free at any dock |
| **Speedboat** | ₹500/hr | 4 | Fast | Fishing, water skiing |
| **Sailboat** | ₹800/hr | 6 | Medium | Leisurely sailing |
| **Yacht** | ₹5,000/hr | 8 | Fast | Luxury, party |
| **Fishing Trawler** | ₹1,200/hr | 2 | Slow | Commercial fishing |

### `BoatController.gd`

```gdscript
extends RigidBody3D
class_name BoatController

@export var boat_type: String = "speedboat"
@export var max_speed: float = 20.0
@export var acceleration: float = 10.0
@export var turn_rate: float = 1.5
@export var passenger_capacity: int = 4

var current_speed: float = 0.0
var is_rented: bool = false
var renter_id: String = ""
var passengers: Array = []

func _physics_process(delta: float) -> void:
    if not is_rented: return
    
    # Forward/backward
    if Input.is_action_pressed("accelerate"):
        current_speed = min(current_speed + acceleration * delta, max_speed)
    elif Input.is_action_pressed("brake"):
        current_speed = max(current_speed - acceleration * delta, 0.0)
    else:
        current_speed = lerp(current_speed, 0.0, 0.5 * delta)
    
    # Steering
    var steer_input = Input.get_axis("move_left", "move_right")
    rotation.y -= steer_input * turn_rate * delta * (current_speed / max_speed)
    
    # Apply movement
    var forward_dir = -global_transform.basis.z
    linear_velocity = forward_dir * current_speed
    
    # Bobbing effect on water
    var bob = sin(Time.get_ticks_msec() * 0.002) * 0.1
    global_position.y = lerp(global_position.y, get_water_height() + bob, 0.1)

func get_water_height() -> float:
    return 0.0  # Water plane Y position

func rent(player_id: String) -> bool:
    var rental_cost = _get_rental_cost()
    if not EconomySystem.can_afford(rental_cost):
        UI.showToast("Not enough money to rent this boat.")
        return false
    
    EconomySystem.spend_money(rental_cost)
    is_rented = true
    renter_id = player_id
    UI.showToast("Boat rented for 1 hour. Enjoy!")
    return true

func _get_rental_cost() -> int:
    var costs = {"rowboat": 100, "speedboat": 500, "sailboat": 800, "yacht": 5000, "trawler": 1200}
    return costs.get(boat_type, 500)

func return_boat() -> void:
    is_rented = false
    renter_id = ""
    passengers.clear()
    UI.showToast("Boat returned. Thank you!")
