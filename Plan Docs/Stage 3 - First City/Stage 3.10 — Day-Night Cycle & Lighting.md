# Stage 3.10 — Day-Night Cycle & Lighting

The transition from day to night transforms a city. Streets glow under streetlights, building windows illuminate, shadows stretch long at golden hour. This stage defines the day-night cycle system and dynamic lighting for Nova City.

---

## Goal
Implement a continuous 24-hour day-night cycle with a moving sun, dynamic sky, and automated streetlight/building light activation.

---

## Step 1 — Time System Overview

The `TimeSystem` autoload manages the in-game clock. By default, 1 real-world minute = 1 in-game hour (24-minute full day), adjustable by the player.

| Setting | Real-Time per In-Game Day | Time Scale |
| :--- | :--- | :--- |
| **Default** | 24 minutes | 60x |
| **Fast** | 12 minutes | 120x |
| **Slow** | 48 minutes | 30x |
| **Real-time** | 24 hours | 1x |

### `TimeSystem.gd` (Autoload)

```gdscript
extends Node

signal hour_changed(hour: int)
signal time_of_day_changed(period: String)

@export var time_scale: float = 60.0  # 1 real sec = 60 in-game sec
var current_hour: float = 8.0  # Start at 8:00 AM
var current_period: String = "morning"

func _process(delta: float) -> void:
    current_hour += (delta * time_scale) / 3600.0
    if current_hour >= 24.0:
        current_hour -= 24.0
    
    var whole_hour = int(current_hour)
    if whole_hour != int(current_hour - (delta * time_scale) / 3600.0):
        hour_changed.emit(whole_hour)
    
    var new_period = _get_period(current_hour)
    if new_period != current_period:
        current_period = new_period
        time_of_day_changed.emit(new_period)

func _get_period(hour: float) -> String:
    if hour >= 5.0 and hour < 7.0: return "dawn"
    if hour >= 7.0 and hour < 10.0: return "morning"
    if hour >= 10.0 and hour < 17.0: return "day"
    if hour >= 17.0 and hour < 20.0: return "evening"
    if hour >= 20.0 and hour < 22.0: return "dusk"
    return "night"

func get_time_string() -> String:
    var h = int(current_hour)
    var m = int((current_hour - h) * 60.0)
    return "%02d:%02d" % [h, m]

func get_normalized_time() -> float:
    return current_hour / 24.0
```

---

## Step 2 — Sun & Sky System

### `DayNightCycle.gd`

```gdscript
extends DirectionalLight3D

@onready var world_env: WorldEnvironment = get_node("/root/NovaCity/WorldEnvironment")
var sun_color_day := Color(1.0, 0.95, 0.85)
var sun_color_golden := Color(1.0, 0.6, 0.3)
var sun_color_night := Color(0.2, 0.25, 0.4)

func _process(_delta: float) -> void:
    var t = TimeSystem.get_normalized_time()
    
    # Sun angle: 0.25 = sunrise (6:00), 0.75 = sunset (18:00)
    var sun_angle = (t - 0.25) * 360.0
    rotation_degrees.x = sun_angle
    
    # Sun intensity based on height above horizon
    var elevation = sin(deg_to_rad(sun_angle))
    light_energy = clamp(elevation * 1.5, 0.0, 1.2)
    
    # Sun color shifts at golden hour
    if elevation > 0.2:
        light_color = sun_color_day
    elif elevation > 0.0:
        light_color = sun_color_golden
    else:
        light_color = sun_color_night
        light_energy = 0.15  # moonlight
    
    # Update sky
    _update_sky(t, elevation)

func _update_sky(t: float, elevation: float) -> void:
    var sky = world_env.environment.sky
    if sky and sky.sky_material is ProceduralSkyMaterial:
        var mat = sky.sky_material
        mat.sun_angle_max = 30.0
        
        # Day sky
        if elevation > 0.2:
            mat.sky_top_color = Color(0.3, 0.5, 0.8)
            mat.sky_horizon_color = Color(0.7, 0.8, 0.9)
            mat.ground_bottom_color = Color(0.4, 0.4, 0.4)
        # Golden hour
        elif elevation > 0.0:
            mat.sky_top_color = Color(0.2, 0.3, 0.6)
            mat.sky_horizon_color = Color(1.0, 0.5, 0.2)
            mat.ground_bottom_color = Color(0.3, 0.2, 0.2)
        # Night
        else:
            mat.sky_top_color = Color(0.02, 0.02, 0.05)
            mat.sky_horizon_color = Color(0.05, 0.05, 0.1)
            mat.ground_bottom_color = Color(0.01, 0.01, 0.02)
```

---

## Step 3 — Streetlight System

Streetlights activate automatically when ambient light drops below a threshold.

### `Streetlight.gd`

```gdscript
extends Node3D
class_name Streetlight

@onready var light: OmniLight3D = $OmniLight3D
@onready var bulb_mesh: MeshInstance3D = $BulbMesh

@export var activation_threshold: float = 0.3  # sun energy level
var is_on: bool = false

func _process(_delta: float) -> void:
    var sun_energy = DayNightCycle.light_energy
    var should_be_on = sun_energy < activation_threshold
    
    if should_be_on != is_on:
        is_on = should_be_on
        _toggle_light(is_on)

func _toggle_light(on: bool) -> void:
    light.visible = on
    light.light_energy = 1.5 if on else 0.0
    bulb_mesh.material_override.emission = Color(1.0, 0.9, 0.6) * (1.0 if on else 0.0)
    bulb_mesh.material_override.emission_energy_multiplier = 2.0 if on else 0.0
```

---

## Step 4 — Building Window Illumination

At night, building windows light up to simulate occupied rooms.

### `BuildingWindowController.gd`

```gdscript
extends Node

@export var window_materials: Array[Material]
var lit_windows: Array[int] = []

func _ready() -> void:
    TimeSystem.time_of_day_changed.connect(_on_period_changed)
    _on_period_changed(TimeSystem.current_period)

func _on_period_changed(period: String) -> void:
    match period:
        "dusk":
            _light_windows(0.3)  # 30% of windows lit
        "night":
            _light_windows(0.6)  # 60% of windows lit
        "dawn":
            _light_windows(0.2)
        _:
            _light_windows(0.0)  # all off during day

func _light_windows(ratio: float) -> void:
    lit_windows.clear()
    var total = window_materials.size()
    var lit_count = int(total * ratio)
    for i in range(lit_count):
        var idx = randi() % total
        lit_windows.append(idx)
        window_materials[idx].emission = Color(1.0, 0.85, 0.5)
        window_materials[idx].emission_energy_multiplier = 1.5
    # Turn off unlit windows
    for i in range(total):
        if not lit_windows.has(i):
            window_materials[i].emission_energy_multiplier = 0.0
```

---

## Step 5 — Shadow Quality & Performance

| Time Period | Shadow Setting | Shadow Distance | Reason |
| :--- | :--- | :--- | :--- |
| **Day** | Soft shadows, high quality | 100m | Long shadows visible |
| **Golden Hour** | Soft shadows, high quality | 100m | Dramatic long shadows |
| **Night** | Disabled or very low | 30m | Streetlights use cheap shadows |

```gdscript
# In DayNightCycle.gd
func _process(_delta: float) -> void:
    # ... sun rotation code ...
    
    # Adjust shadow quality
    if elevation > 0.1:
        shadow_enabled = true
        directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
    else:
        shadow_enabled = false  # streetlights handle night shadows
```

---

## Step 6 — Lighting Summary Table

| Light Type | Node | Activation | Purpose |
| :--- | :--- | :--- | :--- |
| **Sun** | DirectionalLight3D | Always (intensity varies) | Primary daylight |
| **Moon** | DirectionalLight3D (dim) | Night only | Faint night illumination |
| **Streetlights** | OmniLight3D | Dusk–Dawn | Road illumination |
| **Building Windows** | Emissive materials | Night | City glow |
| **Vehicle Headlights** | SpotLight3D | Night / tunnels | Driving visibility |
| **Neon Signs** | Emissive + OmniLight3D | Always (brighter at night) | District identity |

This system creates a city that visually transforms throughout the day, giving players a strong sense of time passing and making night-time exploration feel distinct from daytime play.
