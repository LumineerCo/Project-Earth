# Stage 3.9 — Soundscape & City Ambience

A city without sound feels dead. The hum of traffic, distant sirens, pedestrian chatter, and the crash of ocean waves at the marina — these layers of ambient audio create immersion. This stage defines the soundscape system for Nova City.

---

## Goal
Build a multi-layered ambient audio system with district-specific sound zones, positional 3D audio, and dynamic mixing based on time of day and weather.

---

## Step 1 — Audio System Architecture

```text
AudioManager (Autoload)
├── AmbientLayer (2D looped beds)
│   ├── CityBed_Loop
│   ├── TrafficBed_Loop
│   └── WindBed_Loop
├── DistrictAudioZones (3D positioned)
│   ├── CentralPlaza_Zone
│   ├── Financial_Zone
│   ├── Suburban_Zone
│   ├── Industrial_Zone
│   └── Coastal_Zone
└── OneShotEmitter (3D random sounds)
    ├── SirenSpawner
    ├── ChatterSpawner
    └── BirdSpawner
```

---

## Step 2 — Audio Bus Layout

| Bus Name | Volume (dB) | Purpose |
| :--- | :--- | :--- |
| **Master** | 0.0 | Final output |
| **Music** | -6.0 | Background music |
| **Ambient** | -3.0 | City bed loops |
| **SFX** | 0.0 | One-shot sound effects |
| **Voice** | 0.0 | NPC dialogue |
| **UI** | -3.0 | Menu sounds |
| **Vehicle** | -3.0 | Engine, horn sounds |

---

## Step 3 — District Audio Zones

Each district has a unique ambient bed that plays when the player enters the zone.

### `DistrictAudioZone.gd`

```gdscript
extends Area3D
class_name DistrictAudioZone

@export var ambient_stream: AudioStream
@export var ambient_volume: float = -12.0
@export var one_shot_sounds: Array[AudioStream] = []
@export var one_shot_interval_min: float = 5.0
@export var one_shot_interval_max: float = 15.0

var ambient_player: AudioStreamPlayer3D
var one_shot_timer: float = 0.0
var next_one_shot_time: float = 5.0

func _ready() -> void:
    ambient_player = AudioStreamPlayer3D.new()
    ambient_player.stream = ambient_stream
    ambient_player.unit_size = 20.0
    ambient_player.autoplay = true
    ambient_player.volume_db = ambient_volume
    ambient_player.bus = &"Ambient"
    add_child(ambient_player)
    
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
    if body.is_in_group("Player"):
        AudioManager.set_district_ambient(ambient_stream, ambient_volume)

func _on_body_exited(body: Node3D) -> void:
    if body.is_in_group("Player"):
        AudioManager.fade_out_district_ambient()

func _process(delta: float) -> void:
    one_shot_timer += delta
    if one_shot_timer >= next_one_shot_time:
        _play_random_one_shot()
        one_shot_timer = 0.0
        next_one_shot_time = randf_range(one_shot_interval_min, one_shot_interval_max)

func _play_random_one_shot() -> void:
    if one_shot_sounds.is_empty(): return
    var sound = one_shot_sounds.pick_random()
    var player = AudioStreamPlayer3D.new()
    player.stream = sound
    player.unit_size = 10.0
    player.bus = &"SFX"
    
    # Random position within zone
    var aabb = $CollisionShape3D.shape.get_aabb()
    var random_pos = Vector3(
        randf_range(aabb.position.x, aabb.position.x + aabb.size.x),
        0.0,
        randf_range(aabb.position.z, aabb.position.z + aabb.size.z)
    )
    player.global_position = global_position + random_pos
    add_child(player)
    player.play()
    player.finished.connect(player.queue_free)
```

---

## Step 4 — District Sound Profiles

| District | Ambient Bed | One-Shot Sounds | 3D Emitters |
| :--- | :--- | :--- | :--- |
| **Central Plaza** | Park birds, distant traffic | Fountain splash, footsteps, chatter | Fountain loop, street musician |
| **Financial** | Low city hum, AC units | Car horns, door slams, footsteps | Vent hum, traffic bed |
| **Suburban** | Birds, wind in trees | Dog bark, lawn mower, kids playing | Bird chirps, wind |
| **Industrial** | Machinery hum, metal clanks | Container slam, truck reverse beep, crane | Factory loop, generator |
| **Coastal** | Ocean waves, seagulls | Boat horn, water lapping, footsteps on wood | Wave loop, seagull |
| **Highway** | Road noise, wind | Tire pass, horn, rumble strip | Continuous traffic bed |

---

## Step 5 — Time-of-Day Audio Variation

The soundscape changes based on the time of day.

| Time Period | Ambient Mix | One-Shot Frequency |
| :--- | :--- | :--- |
| **Dawn (5:00–7:00)** | Birds, light wind | Low (sparse) |
| **Morning (7:00–10:00)** | Traffic ramp-up, chatter | Medium |
| **Day (10:00–17:00)** | Full city hum, traffic | High |
| **Evening (17:00–20:00)** | Traffic, distant music | Medium |
| **Night (20:00–5:00)** | Reduced traffic, crickets | Low (sparse) |

### `AudioManager.gd` (Autoload)

```gdscript
extends Node

var district_ambient_player: AudioStreamPlayer
var master_ambient_player: AudioStreamPlayer

func _ready() -> void:
    district_ambient_player = AudioStreamPlayer.new()
    district_ambient_player.bus = &"Ambient"
    add_child(district_ambient_player)
    
    master_ambient_player = AudioStreamPlayer.new()
    master_ambient_player.bus = &"Ambient"
    master_ambient_player.stream = load("res://audio/ambient/city_bed_loop.ogg")
    master_ambient_player.volume_db = -8.0
    master_ambient_player.autoplay = true
    add_child(master_ambient_player)
    
    TimeSystem.hour_changed.connect(_on_hour_changed)

func set_district_ambient(stream: AudioStream, volume: float) -> void:
    district_ambient_player.stream = stream
    district_ambient_player.volume_db = volume
    if not district_ambient_player.playing:
        district_ambient_player.play()

func fade_out_district_ambient() -> void:
    var tween = create_tween()
    tween.tween_property(district_ambient_player, "volume_db", -40.0, 2.0)
    tween.tween_callback(district_ambient_player.stop)

func _on_hour_changed(hour: int) -> void:
    # Adjust master ambient based on time of day
    if hour >= 5 and hour < 7:
        _set_ambient_mix("dawn")
    elif hour >= 7 and hour < 10:
        _set_ambient_mix("morning")
    elif hour >= 10 and hour < 17:
        _set_ambient_mix("day")
    elif hour >= 17 and hour < 20:
        _set_ambient_mix("evening")
    else:
        _set_ambient_mix("night")

func _set_ambient_mix(period: String) -> void:
    var volumes = {
        "dawn": -14.0,
        "morning": -10.0,
        "day": -8.0,
        "evening": -10.0,
        "night": -16.0
    }
    var tween = create_tween()
    tween.tween_property(master_ambient_player, "volume_db", volumes[period], 5.0)
```

---

## Step 6 — Vehicle & Traffic Sounds

Each AI vehicle emits engine and tire sounds that scale with speed.

```gdscript
# In AIVehicle.gd
var engine_player: AudioStreamPlayer3D

func _ready() -> void:
    engine_player = AudioStreamPlayer3D.new()
    engine_player.stream = load("res://audio/vehicles/engine_loop.ogg")
    engine_player.unit_size = 5.0
    engine_player.bus = &"Vehicle"
    engine_player.autoplay = true
    add_child(engine_player)

func _physics_process(_delta: float) -> void:
    # Pitch shifts with speed
    var speed_ratio = speed / 16.0
    engine_player.pitch_scale = lerp(0.8, 1.5, clamp(speed_ratio, 0.0, 1.0))
    # Volume scales with acceleration
    engine_player.volume_db = lerp(-20.0, -8.0, clamp(speed_ratio, 0.0, 1.0))
```

This layered approach — ambient beds, district zones, one-shot emitters, and per-vehicle audio — creates a living soundscape that responds to the player's location and the time of day.
