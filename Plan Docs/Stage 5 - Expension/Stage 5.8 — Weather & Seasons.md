# Stage 5.8 — Weather & Seasons

Dynamic weather and seasonal changes make the world feel alive. Weather affects gameplay (visibility, temperature, driving conditions), while seasons transform the landscape visually and mechanically.

---

## Goal
Build a full weather system with rain, storms, fog, and snow, plus a four-season cycle that changes the environment, vegetation, and gameplay opportunities.

---

## Step 1 — Weather Types

| Weather | Visual Effect | Gameplay Effect | Duration |
| :--- | :--- | :--- | :--- |
| **Clear** | Bright sky, sharp shadows | Normal | 4–8 hrs |
| **Cloudy** | Overcast, flat lighting | Slightly cooler | 3–6 hrs |
| **Light Rain** | Rain particles, wet roads | Reduced grip, NPC umbrellas | 2–5 hrs |
| **Heavy Rain** | Dense rain, splashes, darker | Poor visibility, flooding risk | 1–3 hrs |
| **Thunderstorm** | Rain + lightning + thunder | Dangerous outdoors, power flickers | 30 min–2 hrs |
| **Fog** | Dense fog, limited visibility | Dangerous driving, eerie mood | 2–6 hrs |
| **Snow** | Snow particles, white ground | Cold damage, slippery roads | 4–12 hrs |
| **Blizzard** | Heavy snow + wind | Extreme cold, near-zero visibility | 1–4 hrs |
| **Heatwave** | Heat shimmer, bright sun | Heat damage, dehydration risk | 6–12 hrs |

---

## Step 2 — Weather System Architecture

```text
WeatherManager (Autoload)
    ├── Current Weather State
    ├── Weather Transition Controller
    ├── Particle Systems (rain, snow, fog)
    ├── Environment Controller (sky, lighting, fog)
    ├── Audio Controller (rain, thunder, wind)
    └── Gameplay Effect Controller (grip, temperature, visibility)
```

### `WeatherManager.gd`

```gdscript
extends Node
class_name WeatherManager

enum WeatherType { CLEAR, CLOUDY, LIGHT_RAIN, HEAVY_RAIN, THUNDERSTORM, FOG, SNOW, BLIZZARD, HEATWAVE }

var current_weather: WeatherType = WeatherType.CLEAR
var previous_weather: WeatherType = WeatherType.CLEAR
var transition_progress: float = 1.0  # 1.0 = fully transitioned
var weather_timer: float = 0.0
var weather_duration: float = 360.0  # seconds

var base_temperature: float = 25.0  # Celsius
var local_temperature: float = 25.0
var wind_speed: float = 0.0
var wind_direction: Vector3 = Vector3.ZERO
var visibility: float = 1000.0  # meters

@onready var rain_particles: GPUParticles3D = $RainParticles
@onready var snow_particles: GPUParticles3D = $SnowParticles
@onready var environment: Environment = $WorldEnvironment.environment
@onready var audio_rain: AudioStreamPlayer = $Audio/Rain
@onready var audio_thunder: AudioStreamPlayer = $Audio/Thunder
@onready var audio_wind: AudioStreamPlayer = $Audio/Wind

signal weather_changed(new_weather: WeatherType)

func _ready() -> void:
    _set_weather(WeatherType.CLEAR)
    _schedule_next_weather()

func _process(delta: float) -> void:
    weather_timer += delta
    
    if transition_progress < 1.0:
        transition_progress = min(transition_progress + delta * 0.2, 1.0)
        _apply_transition()
    
    if weather_timer >= weather_duration:
        _schedule_next_weather()
    
    # Thunderstorm lightning
    if current_weather == WeatherType.THUNDERSTORM:
        if randf() < 0.005:
            _trigger_lightning()

func _schedule_next_weather() -> void:
    previous_weather = current_weather
    var season = TimeSystem.get_current_season()
    current_weather = _pick_weather_for_season(season)
    weather_timer = 0.0
    weather_duration = randf_range(1800.0, 7200.0)  # 30 min to 2 hrs
    transition_progress = 0.0
    weather_changed.emit(current_weather)
    _apply_weather_effects()

func _pick_weather_for_season(season: String) -> WeatherType:
    var weights = {
        "spring":  {CLEAR: 0.3, CLOUDY: 0.25, LIGHT_RAIN: 0.2, HEAVY_RAIN: 0.1, FOG: 0.1, THUNDERSTORM: 0.05},
        "summer":  {CLEAR: 0.5, CLOUDY: 0.2, LIGHT_RAIN: 0.1, HEAVY_RAIN: 0.05, HEATWAVE: 0.1, THUNDERSTORM: 0.05},
        "autumn":  {CLEAR: 0.25, CLOUDY: 0.3, LIGHT_RAIN: 0.2, HEAVY_RAIN: 0.1, FOG: 0.15},
        "winter":  {CLEAR: 0.2, CLOUDY: 0.25, SNOW: 0.25, BLIZZARD: 0.1, FOG: 0.1, LIGHT_RAIN: 0.1},
    }
    var season_weights = weights.get(season, weights["spring"])
    var rand = randf()
    var cumulative = 0.0
    for weather in season_weights:
        cumulative += season_weights[weather]
        if rand <= cumulative:
            return weather
    return WeatherType.CLEAR

func _apply_weather_effects() -> void:
    match current_weather:
        WeatherType.CLEAR:
            rain_particles.emitting = false
            snow_particles.emitting = false
            environment.fog_enabled = false
            audio_rain.stop()
            audio_wind.stop()
            base_temperature = 25.0
            visibility = 1000.0
        WeatherType.LIGHT_RAIN:
            rain_particles.emitting = true
            rain_particles.amount = 500
            audio_rain.stream = preload("res://audio/weather/light_rain.ogg")
            audio_rain.play()
            base_temperature = 20.0
            visibility = 500.0
        WeatherType.HEAVY_RAIN:
            rain_particles.emitting = true
            rain_particles.amount = 2000
            audio_rain.stream = preload("res://audio/weather/heavy_rain.ogg")
            audio_rain.play()
            base_temperature = 18.0
            visibility = 200.0
        WeatherType.THUNDERSTORM:
            rain_particles.emitting = true
            rain_particles.amount = 3000
            audio_rain.stream = preload("res://audio/weather/storm.ogg")
            audio_rain.play()
            base_temperature = 16.0
            visibility = 150.0
        WeatherType.FOG:
            environment.fog_enabled = true
            environment.fog_light_color = Color(0.7, 0.7, 0.7)
            environment.fog_density = 0.05
            visibility = 100.0
        WeatherType.SNOW:
            snow_particles.emitting = true
            snow_particles.amount = 1000
            audio_wind.stream = preload("res://audio/weather/cold_wind.ogg")
            audio_wind.play()
            base_temperature = -2.0
            visibility = 400.0
        WeatherType.BLIZZARD:
            snow_particles.emitting = true
            snow_particles.amount = 5000
            audio_wind.stream = preload("res://audio/weather/blizzard.ogg")
            audio_wind.play()
            base_temperature = -10.0
            visibility = 50.0
        WeatherType.HEATWAVE:
            base_temperature = 40.0
            visibility = 800.0

func _trigger_lightning() -> void:
    $LightningFlash.flash()
    await get_tree().create_timer(randf_range(0.5, 3.0)).timeout
    audio_thunder.play()

func get_base_temperature() -> float:
    return base_temperature

func set_local_temperature(temp: float) -> void:
    local_temperature = temp

func is_storm_active() -> bool:
    return current_weather == WeatherType.THUNDERSTORM or current_weather == WeatherType.BLIZZARD

```

---

## Step 3 — Season System

The world cycles through four seasons, each lasting 30 in-game days (one full year = 120 days).

### Season Calendar

```text
┌─────────────────────────────────────────────────────────────────┐
│                      Year Cycle (120 Days)                       │
├───────────┬───────────┬───────────┬──────────────────────────────┤
│  Spring   │  Summer   │  Autumn   │         Winter              │
│ Days 1-30 │ Days 31-60│ Days 61-90│        Days 91-120          │
│           │           │           │                             │
│ • Blooming│ • Hot days│ • Falling │ • Snow on ground           │
│   flowers │ • Heatwave│   leaves  │ • Frozen lakes              │
│ • Mild rain│  risk    │ • Harvest │ • Short days                │
│ • Green   │ • Long   │   season  │ • Cold damage               │
│   grass   │   days   │ • Orange  │ • Indoor activities         │
│           │           │   trees   │   encouraged                │
└───────────┴───────────┴───────────┴──────────────────────────────┘
```

### Season Effects

| Attribute | Spring | Summer | Autumn | Winter |
| :--- | :--- | :--- | :--- | :--- |
| **Base Temp** | 18°C | 30°C | 15°C | 2°C |
| **Day Length** | 12 hrs | 14 hrs | 11 hrs | 8 hrs |
| **Tree Color** | Fresh green | Dark green | Orange/red | Bare/snowy |
| **Grass Color** | Vibrant green | Yellow-green | Brown-green | White (snow) |
| **Sky Color** | Light blue | Deep blue | Warm orange | Pale grey |
| **Fog Frequency** | Moderate | Low | High | Very High |
| **Rain Type** | Light rain | Thunderstorms | Heavy rain | Snow |
| **Crop Growth** | Planting | Growing | Harvest | Dormant |
| **Wildlife** | Active | Active | Preparing | Hibernating |

### `SeasonSystem.gd`

```gdscript
extends Node
class_name SeasonSystem

enum Season { SPRING, SUMMER, AUTUMN, WINTER }

const DAYS_PER_SEASON = 30
const SEASON_CYCLE = DAYS_PER_SEASON * 4  # 120 days = 1 year

var current_season: Season = Season.SPRING
var current_day_of_year: int = 1

const SEASON_DATA = {
    Season.SPRING: {
        "name": "Spring",
        "base_temp": 18.0,
        "day_length_hours": 12.0,
        "tree_color": Color(0.4, 0.8, 0.3),
        "grass_color": Color(0.5, 0.9, 0.4),
        "sky_color": Color(0.5, 0.7, 1.0),
        "sun_intensity": 1.0,
        "fog_frequency": 0.15,
    },
    Season.SUMMER: {
        "name": "Summer",
        "base_temp": 30.0,
        "day_length_hours": 14.0,
        "tree_color": Color(0.2, 0.6, 0.2),
        "grass_color": Color(0.6, 0.7, 0.3),
        "sky_color": Color(0.3, 0.6, 1.0),
        "sun_intensity": 1.3,
        "fog_frequency": 0.05,
    },
    Season.AUTUMN: {
        "name": "Autumn",
        "base_temp": 15.0,
        "day_length_hours": 11.0,
        "tree_color": Color(0.9, 0.5, 0.2),
        "grass_color": Color(0.6, 0.5, 0.3),
        "sky_color": Color(0.8, 0.6, 0.4),
        "sun_intensity": 0.9,
        "fog_frequency": 0.2,
    },
    Season.WINTER: {
        "name": "Winter",
        "base_temp": 2.0,
        "day_length_hours": 8.0,
        "tree_color": Color(0.5, 0.5, 0.5),
        "grass_color": Color(0.9, 0.9, 0.95),
        "sky_color": Color(0.7, 0.7, 0.8),
        "sun_intensity": 0.6,
        "fog_frequency": 0.3,
    },
}

signal season_changed(season: Season)

func _ready() -> void:
    TimeSystem.connect("new_day", _on_new_day)
    _apply_season_effects()

func _on_new_day(day: int) -> void:
    current_day_of_year = day % SEASON_CYCLE
    if current_day_of_year == 0:
        current_day_of_year = SEASON_CYCLE
    
    var new_season = int(current_day_of_year / DAYS_PER_SEASON)
    if current_day_of_year % DAYS_PER_SEASON == 1:
        current_season = new_season
        season_changed.emit(current_season)
        _apply_season_effects()

func _apply_season_effects() -> void:
    var data = SEASON_DATA[current_season]
    
    # Update environment
    var env = $WorldEnvironment.environment
    env.background_color = data["sky_color"]
    env.ambient_light_color = data["sky_color"]
    env.fog_enabled = data["fog_frequency"] > 0.1
    
    # Update sun
    var sun = $DirectionalLight3D
    sun.light_energy = data["sun_intensity"]
    
    # Update day length
    DayNightCycle.set_day_length(data["day_length_hours"])
    
    # Update terrain colors
    TerrainManager.set_season_colors(data["tree_color"], data["grass_color"])
    
    # Update weather base temperature
    WeatherManager.base_temperature = data["base_temp"]
    
    UI.show_season_banner(data["name"])

func get_current_season() -> String:
    return SEASON_DATA[current_season]["name"]
```

---

## Step 4 — Weather Gameplay Effects

### Driving Conditions

| Weather | Tire Grip | Visibility | NPC Traffic | Accident Risk |
| :--- | :--- | :--- | :--- | :--- |
| Clear | 100% | 1000m | Normal | Low |
| Rain | 70% | 500m | Slower, cautious | Medium |
| Heavy Rain | 50% | 200m | Very slow | High |
| Snow | 40% | 400m | Minimal | Very High |
| Blizzard | 20% | 50m | None | Extreme |
| Fog | 80% | 100m | Slow | High |

### `WeatherGameplayEffects.gd`

```gdscript
extends Node
class_name WeatherGameplayEffects

func _process(_delta: float) -> void:
    var weather = WeatherManager.current_weather
    
    # Driving effects
    match weather:
        WeatherManager.WeatherType.LIGHT_RAIN:
            VehicleSystem.set_tire_grip(0.7)
        WeatherManager.WeatherType.HEAVY_RAIN:
            VehicleSystem.set_tire_grip(0.5)
        WeatherManager.WeatherType.SNOW:
            VehicleSystem.set_tire_grip(0.4)
        WeatherManager.WeatherType.BLIZZARD:
            VehicleSystem.set_tire_grip(0.2)
        _:
            VehicleSystem.set_tire_grip(1.0)
    
    # Temperature effects on player
    var temp = WeatherManager.local_temperature
    if temp < 0.0:
        PlayerStats.add_status_effect("freezing", 2.0)  # damage per second
    elif temp < 5.0:
        PlayerStats.add_status_effect("cold", 0.5)
    elif temp > 35.0:
        PlayerStats.add_status_effect("overheating", 1.0)
        PlayerStats.increase_thirst(0.5)
```

---

## Step 5 — Particle Systems

### Rain Particle Setup

```gdscript
# RainParticles configuration
# Emission Shape: Box (covers player area, follows player)
# Amount: 500 (light) / 2000 (heavy) / 3000 (storm)
# Lifetime: 1.0 seconds
# Gravity: (0, -30, 0)
# Velocity: (0, -20, 0) + wind offset
# Process Material: StandardMaterial3D with transparent blend
# Follows player position via _process()
```

### Snow Particle Setup

```gdscript
# SnowParticles configuration
# Emission Shape: Box (follows player)
# Amount: 1000 (snow) / 5000 (blizzard)
# Lifetime: 5.0 seconds (slow fall)
# Gravity: (0, -2, 0) (gentle)
# Turbulence: enabled for swirling motion
# Process Material: soft white particles
```

---

## Step 6 — Audio System

| Weather | Ambient Sound | Intermittent Sounds |
| :--- | :--- | :--- |
| Clear | Birds chirping | Wind gusts |
| Rain | Rain on surfaces | Thunder (distant) |
| Thunderstorm | Heavy rain | Thunder claps, lightning crack |
| Fog | Eerie silence | Distant foghorn (coastal) |
| Snow | Muffled silence | Wind howling |
| Blizzard | Howling wind | Ice cracking |
| Heatwave | Cicadas | None |
