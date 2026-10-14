# Stage 5.3 — Airports & Fast Travel

As the world expands beyond Nova City, players need a way to travel between cities quickly. Airports serve as both fast-travel hubs and explorable locations with their own activities, jobs, and missions.

---

## Goal
Build a functional airport system with fast travel between cities, a flight minigame, and airport-based activities including jobs, shopping, and missions.

---

## Step 1 — Airport Overview

| Airport | Location | Size | Gates | Runways | Role |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Nova City International** | Nova City | Large | 12 | 2 | Main hub, international flights |
| **Harbor Bay Regional** | Harbor Bay | Medium | 6 | 1 | Coastal flights, tourism |
| **Summit Peak Airfield** | Summit Peak | Small | 3 | 1 | Mountain strip, small aircraft |
| **Greenfield Airstrip** | Greenfield | Tiny | 2 | 1 | Rural dirt strip, crop dusters |

---

## Step 2 — Airport Layout (Nova City International)

```text
Nova City International Airport (NCT)
├── Terminal Building
│   ├── Check-in Counters (interactive)
│   ├── Security Checkpoint (minigame)
│   ├── Departure Lounge (shops, restaurants)
│   ├── Arrival Hall (baggage claim)
│   ├── VIP Lounge (premium travel)
│   └── Control Tower (job location)
├── Gates
│   ├── Gates A1–A6 (Domestic)
│   └── Gates B1–B6 (International)
├── Runways
│   ├── Runway 09L/27R (Main)
│   └── Runway 09R/27L (Secondary)
├── Support Facilities
│   ├── Hangars (aircraft storage)
│   ├── Fuel Depot
│   ├── Cargo Terminal
│   └── Parking Garage
└── Ground Vehicles
    ├── Baggage Carts
    ├── Fuel Trucks
    ├── Tugs
    └── Passenger Shuttles
```

---

## Step 3 — Fast Travel System

### Ticket Purchase Flow

```text
Player approaches Ticket Counter
        ↓
Select Destination City
        ↓
Choose Class (Economy / Business / First)
        ↓
Pay Ticket Price
        ↓
[Optional] Flight Minigame (skip for instant travel)
        ↓
Arrive at Destination Airport
        ↓
Exit to Destination City
```

### Ticket Pricing

| Route | Economy | Business | First Class |
| :--- | :--- | :--- | :--- |
| Nova City → Harbor Bay | ₹2,500 | ₹5,000 | ₹10,000 |
| Nova City → Summit Peak | ₹3,000 | ₹6,000 | ₹12,000 |
| Nova City → Greenfield | ₹2,000 | ₹4,000 | ₹8,000 |
| Harbor Bay → Summit Peak | ₹3,500 | ₹7,000 | ₹14,000 |

### `FastTravelSystem.gd`

```gdscript
extends Node
class_name FastTravelSystem

const AIRPORTS = {
    "nova_city": {"scene": "res://scenes/world/airports/nova_city_intl.tscn", "city": "Nova City"},
    "harbor_bay": {"scene": "res://scenes/world/airports/harbor_bay_regional.tscn", "city": "Harbor Bay"},
    "summit_peak": {"scene": "res://scenes/world/airports/summit_peak_airfield.tscn", "city": "Summit Peak"},
    "greenfield": {"scene": "res://scenes/world/airports/greenfield_airstrip.tscn", "city": "Greenfield"},
}

const TICKET_PRICES = {
    "nova_city_harbor_bay": {"economy": 2500, "business": 5000, "first": 10000},
    "nova_city_summit_peak": {"economy": 3000, "business": 6000, "first": 12000},
    "nova_city_greenfield": {"economy": 2000, "business": 4000, "first": 8000},
}

var current_airport: String = "nova_city"

signal travel_started(destination: String)
signal travel_completed(destination: String)

func purchase_ticket(origin: String, destination: String, class_type: String) -> bool:
    var route_key = "%s_%s" % [origin, destination]
    var prices = TICKET_PRICES.get(route_key, {})
    
    if prices.is_empty():
        push_error("No route found: %s to %s" % [origin, destination])
        return false
    
    var price = prices.get(class_type, 0)
    if not EconomySystem.can_afford(price):
        UI.showToast("Not enough money for ticket (₹%d)" % price)
        return false
    
    EconomySystem.spend_money(price)
    _initiate_travel(origin, destination)
    return true

func _initiate_travel(origin: String, destination: String) -> void:
    travel_started.emit(destination)
    
    # Show loading screen
    UILoadingScreen.show("Flying to %s..." % AIRPORTS[destination]["city"])
    
    # Fade out, load destination airport scene
    await get_tree().create_timer(2.0).timeout
    
    var airport_scene = load(AIRPORTS[destination]["scene"])
    get_tree().change_scene_to_packed(airport_scene)
    
    current_airport = destination
    travel_completed.emit(destination)
    
    # Fade in
    UILoadingScreen.hide()
```

---

## Step 4 — Flight Minigame

Players who choose not to skip the flight can play a simplified flight minigame.

### Minigame Flow
```text
Boarding (cutscene)
    ↓
Takeoff Sequence (hold throttle, pull up at right speed)
    ↓
Cruising (optional: look out window, talk to passenger, read magazine)
    ↓
Turbulence Event (quick-time event to stabilize)
    ↓
Landing Approach (adjust altitude and speed)
    ↓
Touchdown (brake at right moment)
    ↓
Arrival (exit plane)
```

### `FlightMinigame.gd`

```gdscript
extends Control

enum Phase { BOARDING, TAKEOFF, CRUISING, TURBULENCE, LANDING, ARRIVAL }

var current_phase: Phase = Phase.BOARDING
var throttle: float = 0.0
var altitude: float = 0.0
var target_altitude: float = 10000.0  # meters
var airspeed: float = 0.0
var target_airspeed: float = 250.0  # km/h
var phase_timer: float = 0.0

func _ready() -> void:
    _start_phase(Phase.BOARDING)

func _process(delta: float) -> void:
    phase_timer += delta
    match current_phase:
        Phase.TAKEOFF:   _phase_takeoff(delta)
        Phase.CRUISING:  _phase_cruising(delta)
        Phase.LANDING:   _phase_landing(delta)

func _start_phase(phase: Phase) -> void:
    current_phase = phase
    phase_timer = 0.0
    match phase:
        Phase.BOARDING:
            $AnimationPlayer.play("boarding")
            await get_tree().create_timer(3.0).timeout
            _start_phase(Phase.TAKEOFF)
        Phase.TAKEOFF:
            $UI/Instructions.text = "Hold SPACE to increase throttle. Pull up (W) at 250 km/h."
        Phase.CRUISING:
            $UI/Instructions.text = "Enjoy the flight. Press F to skip to landing."
        Phase.LANDING:
            $UI/Instructions.text = "Reduce throttle (S) and descend. Touch down gently."

func _phase_takeoff(delta: float) -> void:
    if Input.is_action_pressed("accelerate"):
        throttle = min(throttle + 0.5 * delta, 1.0)
        airspeed = throttle * 300.0
    
    if airspeed >= target_airspeed and Input.is_action_pressed("move_forward"):
        altitude += 50.0 * delta
        $Plane.rotation_degrees.x = -10.0
    
    if altitude >= 500.0:
        _start_phase(Phase.CRUISING)

func _phase_cruising(delta: float) -> void:
    altitude = lerp(altitude, target_altitude, 0.01)
    if Input.is_action_just_pressed("skip_flight"):
        _start_phase(Phase.LANDING)
    # Random turbulence event
    if phase_timer > 15.0 and randf() < 0.3:
        _trigger_turbulence()

func _trigger_turbulence() -> void:
    $UI/TurbulenceWarning.show()
    $Camera.shake(0.5, 0.3)
    await get_tree().create_timer(2.0).timeout
    $UI/TurbulenceWarning.hide()

func _phase_landing(delta: float) -> void:
    if Input.is_action_pressed("brake"):
        throttle = max(throttle - 0.3 * delta, 0.0)
        airspeed = max(airspeed - 50.0 * delta, 0.0)
        altitude = max(altitude - 100.0 * delta, 0.0)
    
    if altitude <= 0.0 and airspeed < 50.0:
        _start_phase(Phase.ARRIVAL)
    
    if altitude <= 0.0 and airspeed >= 50.0:
        $UI/Instructions.text = "Too fast! Press S to brake harder!"
```

---

## Step 5 — Airport Jobs

| Job | Location | Pay | Description |
| :--- | :--- | :--- | :--- |
| **Baggage Handler** | Tarmac | ₹500/shift | Load/unload luggage onto carts |
| **Air Traffic Controller** | Control Tower | ₹1,200/shift | Guide planes to gates (minigame) |
| **Pilot** | Cockpit | ₹2,000/flight | Fly scheduled routes |
| **Security Agent** | Checkpoint | ₹800/shift | Scan passengers (minigame) |
| **Shop Cashier** | Terminal | ₹400/shift | Sell duty-free goods |

---

## Step 6 — Airport Activities

* **Duty-Free Shopping:** Buy items not available in regular city shops
* **Restaurant Dining:** Eat before flights (restores hunger)
* **Plane Spotting:** Photography activity — collect photos of different aircraft
* **VIP Lounge Access:** Premium players can wait in luxury (restores health)
* **Cargo Missions:** Transport goods between airports for money
