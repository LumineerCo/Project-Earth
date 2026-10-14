# Stage 5.2 — New Cities

Three new cities expand the world beyond Nova City, each with unique character, architecture, and activities.

---

## Goal
Design and build three additional cities — Harbor Bay, Summit Peak, and Greenfield — each with distinct identity, landmarks, and gameplay opportunities.

---

## Step 1 — City Overview

| City | Biome | Population | Size | Theme | Key Feature |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Harbor Bay** | Coastal | 80,000 | 1.5 km² | Maritime, tourism | Beaches, port, boats |
| **Summit Peak** | Mountain | 30,000 | 1.0 km² | Alpine, adventure | Skiing, hiking, mining |
| **Greenfield** | Rural | 15,000 | 2.0 km² | Agricultural, peaceful | Farms, orchards, markets |

---

## Step 2 — Harbor Bay

### City Profile

```
Harbor Bay
├── Districts
│   ├── Marina District (boats, yachts, fishing)
│   ├── Beachfront (tourism, hotels, restaurants)
│   ├── Downtown (shops, offices)
│   ├── Industrial Port (cargo, shipping)
│   └── Residential Cliffs (wealthy homes)
├── Landmarks
│   ├── Harbor Bay Lighthouse
│   ├── Grand Pier (amusement park)
│   ├── Maritime Museum
│   └── Cliffside Boardwalk
├── Unique Jobs
│   ├── Fisherman
│   ├── Boat Tour Guide
│   ├── Lifeguard
│   └── Port Worker
└── Unique Activities
    ├── Swimming
    ├── Boating
    ├── Fishing
    └── Beach volleyball
```

### `HarborBayGenerator.gd`

```gdscript
extends Node3D
class_name HarborBayGenerator

const BUILDING_PREFABS = {
    "beach_house": preload("res://scenes/world/harbor_bay/buildings/beach_house.tscn"),
    "hotel": preload("res://scenes/world/harbor_bay/buildings/hotel.tscn"),
    "warehouse": preload("res://scenes/world/harbor_bay/buildings/warehouse.tscn"),
    "shop": preload("res://scenes/world/harbor_bay/buildings/shop.tscn"),
    "lighthouse": preload("res://scenes/world/harbor_bay/buildings/lighthouse.tscn"),
}

func generate_city() -> void:
    _generate_marina_district()
    _generate_beachfront()
    _generate_downtown()
    _generate_industrial_port()
    _generate_residential_cliffs()
    _place_landmarks()
    _generate_beaches()
    _generate_roads()

func _generate_marina_district() -> void:
    # Docks, boat slips, marina buildings
    for i in range(20):
        var dock = preload("res://scenes/world/harbor_bay/dock.tscn").instantiate()
        dock.position = Vector3(100 + i * 15, 0, -200)
        add_child(dock)

func _generate_beachfront() -> void:
    # Hotels and shops along the beach
    for i in range(15):
        var hotel = BUILDING_PREFABS["hotel"].instantiate()
        hotel.position = Vector3(-200 + i * 30, 0, -150)
        add_child(hotel)

func _generate_beaches() -> void:
    var beach = preload("res://scenes/world/harbor_bay/beach.tscn").instantiate()
    beach.position = Vector3(0, 0, -250)
    beach.size = Vector2(500, 200)
    add_child(beach)
```

### Harbor Bay Unique Jobs

| Job | Location | Pay/hr | Requirements | Description |
| :--- | :--- | :--- | :--- | :--- |
| **Fisherman** | Marina | 18 Cr | None | Catch fish, sell at market |
| **Boat Tour Guide** | Pier | 22 Cr | Social 3+ | Give tours to tourists |
| **Lifeguard** | Beach | 20 Cr | Fitness 3+ | Watch swimmers, rescue |
| **Port Worker** | Industrial | 15 Cr | None | Load/unload cargo |

---

## Step 3 — Summit Peak

### City Profile

```
Summit Peak
├── Districts
│   ├── Town Center (shops, lodges, visitor center)
│   ├── Ski Resort (slopes, lifts, chalets)
│   ├── Mining Camp (old mines, quarry)
│   ├── Hiking Trails (trailheads, campsites)
│   └── Residential Cabins (mountain homes)
├── Landmarks
│   ├── Summit Peak Summit (highest point)
│   ├── Ice Cave
│   ├── Mining Museum
│   └── Observation Tower
├── Unique Jobs
│   ├── Ski Instructor
│   ├── Mountain Guide
│   ├── Miner
│   └── Park Ranger
└── Unique Activities
    ├── Skiing
    ├── Hiking
    ├── Camping
    ├── Rock climbing
    └── Mining
```

### `SummitPeakGenerator.gd`

```gdscript
extends Node3D
class_name SummitPeakGenerator

const TERRAIN_HEIGHT = preload("res://scenes/world/summit_peak/terrain.tres")

func generate_city() -> void:
    _generate_terrain()
    _generate_town_center()
    _generate_ski_resort()
    _generate_mining_camp()
    _generate_trails()
    _place_landmarks()

func _generate_terrain() -> void:
    var terrain = Terrain3D.new()
    terrain.data = TERRAIN_HEIGHT
    terrain.position = Vector3.ZERO
    add_child(terrain)
    
    # Snow texture at high altitudes
    var snow_layer = preload("res://scenes/world/summit_peak/snow_layer.tscn").instantiate()
    snow_layer.position = Vector3(0, 200, 0)
    add_child(snow_layer)

func _generate_ski_resort() -> void:
    # Ski lift
    var lift = preload("res://scenes/world/summit_peak/ski_lift.tscn").instantiate()
    lift.position = Vector3(100, 50, 100)
    add_child(lift)
    
    # Chalets
    for i in range(10):
        var chalet = preload("res://scenes/world/summit_peak/chalet.tscn").instantiate()
        chalet.position = Vector3(120 + i * 10, 50, 80)
        add_child(chalet)
```

### Summit Peak Unique Jobs

| Job | Location | Pay/hr | Requirements | Description |
| :--- | :--- | :--- | :--- | :--- |
| **Ski Instructor** | Ski Resort | 25 Cr | Fitness 4+ | Teach skiing lessons |
| **Mountain Guide** | Visitor Center | 28 Cr | Survival 3+ | Lead hiking groups |
| **Miner** | Mining Camp | 20 Cr | Strength 3+ | Extract minerals |
| **Park Ranger** | Town Center | 22 Cr | Fitness 3+ | Patrol, assist visitors |

---

## Step 4 — Greenfield

### City Profile

```
Greenfield
├── Districts
│   ├── Town Square (market, shops, town hall)
│   ├── Farm District (crop fields, barns, silos)
│   ├── Orchard District (fruit trees, processing)
│   ├── Pasture District (livestock, grazing)
│   └── Residential (farmhouses, cottages)
├── Landmarks
│   ├── Old Windmill
│   ├── Farmer's Market
│   ├── Harvest Festival Grounds
│   └── Greenfield River
├── Unique Jobs
│   ├── Farmer
│   ├── Orchard Keeper
│   ├── Ranch Hand
│   └── Market Vendor
└── Unique Activities
    ├── Farming
    ├── Animal husbandry
    ├── Farmers market
    └── Fishing (river)
```

### `GreenfieldGenerator.gd`

```gdscript
extends Node3D
class_name GreenfieldGenerator

func generate_city() -> void:
    _generate_terrain()
    _generate_town_square()
    _generate_farms()
    _generate_orchards()
    _generate_pastures()
    _generate_residential()
    _place_landmarks()
    _generate_river()

func _generate_farms() -> void:
    for i in range(8):
        var farm = preload("res://scenes/world/greenfield/farm.tscn").instantiate()
        farm.position = Vector3(-300 + (i % 4) * 100, 0, 200 + (i / 4) * 100)
        farm.crop_type = ["wheat", "corn", "soy", "pumpkin"].pick_random()
        add_child(farm)

func _generate_orchards() -> void:
    for i in range(5):
        var orchard = preload("res://scenes/world/greenfield/orchard.tscn").instantiate()
        orchard.position = Vector3(200 + i * 80, 0, 200)
        orchard.fruit_type = ["apple", "orange", "cherry", "peach"].pick_random()
        add_child(orchard)
```

### Greenfield Unique Jobs

| Job | Location | Pay/hr | Requirements | Description |
| :--- | :--- | :--- | :--- | :--- |
| **Farmer** | Farm District | 16 Cr | None | Plant, tend, harvest crops |
| **Orchard Keeper** | Orchard District | 18 Cr | None | Maintain fruit trees |
| **Ranch Hand** | Pasture District | 17 Cr | Fitness 2+ | Care for livestock |
| **Market Vendor** | Town Square | 20 Cr | Social 2+ | Sell produce at market |

---

## Step 5 — City Comparison

### Activities by City

| Activity | Nova City | Harbor Bay | Summit Peak | Greenfield |
| :--- | :--- | :--- | :--- | :--- |
| **Shopping** | ✅ | ✅ | ✅ | ✅ |
| **Jobs** | ✅ | ✅ | ✅ | ✅ |
| **Property** | ✅ | ✅ | ✅ | ✅ |
| **Vehicles** | ✅ | ✅ | Limited | Limited |
| **Swimming** | ❌ | ✅ | ❌ | ❌ |
| **Boating** | ❌ | ✅ | ❌ | ❌ |
| **Fishing** | ❌ | ✅ | ❌ | ✅ |
| **Skiing** | ❌ | ❌ | ✅ | ❌ |
| **Hiking** | ❌ | ❌ | ✅ | ✅ |
| **Farming** | ❌ | ❌ | ❌ | ✅ |
| **Mining** | ❌ | ❌ | ✅ | ❌ |
| **Nightlife** | ✅ | ✅ | Limited | ❌ |

### Property Prices by City

| Property Type | Nova City | Harbor Bay | Summit Peak | Greenfield |
| :--- | :--- | :--- | :--- | :--- |
| **Studio** | 50,000 Cr | 40,000 Cr | 35,000 Cr | 20,000 Cr |
| **1BR Apartment** | 80,000 Cr | 65,000 Cr | 55,000 Cr | 35,000 Cr |
| **2BR House** | 150,000 Cr | 120,000 Cr | 100,000 Cr | 60,000 Cr |
| **Luxury Home** | 500,000 Cr | 400,000 Cr | 350,000 Cr | 200,000 Cr |

Each city offers a unique experience, encouraging players to explore and settle in the environment that suits their playstyle.
