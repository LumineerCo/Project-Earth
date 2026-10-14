# Stage 3.7 — City Districts & Zoning

A real city is not a uniform grid of identical buildings. It has distinct neighborhoods — a bustling downtown, quiet suburbs, an industrial port, and a scenic waterfront. This stage defines Nova City's districts and the zoning rules that govern what can be built where.

---

## Goal
Divide Nova City into functional districts with unique visual identities, population densities, and gameplay purposes.

---

## Step 1 — District Map Overview

Nova City is divided into 6 primary districts:

```text
                    ┌──────────────────────┐
                    │   SUBURBAN HILLS     │
                    │   (Residential)      │
                    ├──────────┬───────────┤
                    │ FINANCIAL │  CENTRAL  │
                    │ DISTRICT  │  PLAZA    │
                    │ (Commerce)│ (Civic)   │
                    ├──────────┼───────────┤
                    │ INDUSTRIAL│  COASTAL  │
                    │ PORT      │  MARINA   │
                    │ (Industry)│ (Leisure) │
                    └──────────┴───────────┘
```

---

## Step 2 — District Profiles

### 1. Central Plaza (Civic Core)
| Attribute | Value |
| :--- | :--- |
| **Theme** | Open parks, fountains, government buildings |
| **Building Height** | 15–40m (mid-rise) |
| **NPC Density** | High (tourists, citizens) |
| **Key Locations** | City Hall, Central Park, Main Bus Terminal |
| **Traffic** | Moderate, pedestrian priority zones |

### 2. Financial District (Commercial)
| Attribute | Value |
| :--- | :--- |
| **Theme** | Glass towers, corporate plazas, upscale shops |
| **Building Height** | 40–120m (high-rise) |
| **NPC Density** | High during day, low at night |
| **Key Locations** | Bank Tower, Stock Exchange, Luxury Shops |
| **Traffic** | Heavy during rush hours |

### 3. Suburban Hills (Residential)
| Attribute | Value |
| :--- | :--- |
| **Theme** | Single-family homes, tree-lined streets, parks |
| **Building Height** | 6–12m (low-rise) |
| **NPC Density** | Low to moderate |
| **Key Locations** | Player's starter home, school, community center |
| **Traffic** | Light, residential speed limits |

### 4. Industrial Port (Industry)
| Attribute | Value |
| :--- | :--- |
| **Theme** | Warehouses, shipping containers, cranes, factories |
| **Building Height** | 10–25m (wide structures) |
| **NPC Density** | Low (workers only) |
| **Key Locations** | Cargo docks, mechanic garage, truck depot |
| **Traffic** | Heavy truck traffic, limited pedestrian access |

### 5. Coastal Marina (Leisure)
| Attribute | Value |
| :--- | :--- |
| **Theme** | Boardwalk, restaurants, yacht club, beach huts |
| **Building Height** | 4–10m (low, scenic) |
| **NPC Density** | Moderate (tourists, joggers) |
| **Key Locations** | Marina pier, seafood restaurant, lighthouse |
| **Traffic** | Very light, pedestrian-only boardwalk |

### 6. Highway Corridor (Transit)
| Attribute | Value |
| :--- | :--- |
| **Theme** | Elevated highway, gas stations, motels, billboards |
| **Building Height** | 6–15m (service buildings) |
| **NPC Density** | Very low |
| **Key Locations** | Gas station, motel, highway on/off ramps |
| **Traffic** | High-speed, heavy vehicle flow |

---

## Step 3 — Zoning System in Godot

Each district is defined by a `DistrictZone` node with bounding box coordinates. The zoning system checks which district a given world position falls within.

### `DistrictZone.gd`

```gdscript
extends Area3D
class_name DistrictZone

@export var district_name: String = ""
@export var district_type: String = ""  # "residential", "commercial", "industrial", "leisure", "civic"
@export var build_height_min: float = 6.0
@export var build_height_max: float = 40.0
@export var speed_limit: float = 30.0
@export var ambient_sound: String = "residential_ambient"

func _ready() -> void:
    # Register with global district system
    DistrictSystem.register_zone(self)

func contains_point(point: Vector3) -> bool:
    var aabb = $CollisionShape3D.shape.get_aabb()
    var local_point = to_local(point)
    return aabb.has_point(local_point)
```

### `DistrictSystem.gd` (Autoload)

```gdscript
extends Node

var zones: Array[DistrictZone] = []

func register_zone(zone: DistrictZone) -> void:
    zones.append(zone)

func get_district_at(point: Vector3) -> DistrictZone:
    for zone in zones:
        if zone.contains_point(point):
            return zone
    return null

func get_speed_limit_at(point: Vector3) -> float:
    var zone = get_district_at(point)
    if zone:
        return zone.speed_limit
    return 50.0  # default city speed limit

func get_ambient_sound_at(point: Vector3) -> String:
    var zone = get_district_at(point)
    if zone:
        return zone.ambient_sound
    return "city_ambient_default"
```

---

## Step 4 — Visual Identity per District

Each district uses a distinct color palette and material set to create instant visual recognition.

| District | Primary Color | Secondary Color | Material Style |
| :--- | :--- | :--- | :--- |
| Central Plaza | Warm beige | Stone gray | Clean, polished stone |
| Financial | Glass blue | Steel gray | Reflective glass, metal |
| Suburban | Warm terracotta | Green foliage | Stucco, brick, wood |
| Industrial | Rust orange | Concrete gray | Corrugated metal, concrete |
| Coastal | Sandy beige | Ocean teal | Wood, painted surfaces |
| Highway | Asphalt black | Neon signage | Concrete, metal, billboards |

### Material Assignment Strategy

```gdscript
# When a building is placed, it queries its district for appropriate materials
func _ready() -> void:
    var zone = DistrictSystem.get_district_at(global_position)
    if zone:
        var mat_set = MaterialLibrary.get_material_set(zone.district_type)
        $MeshInstance3D.material_override = mat_set.wall_material
        $RoofMesh.material_override = mat_set.roof_material
```

This ensures that buildings automatically match their surroundings without manual material assignment for every single structure.
