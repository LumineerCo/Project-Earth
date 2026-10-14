# Stage 5.4 — Countryside & Farms

Beyond the cities lies the countryside — rolling hills, farmland, orchards, and quiet villages. This stage creates the rural backbone of the world, offering a completely different pace of life and new gameplay activities.

---

## Goal
Build a countryside region with farms, agriculture, rural villages, and farming activities that contrast with the urban city experience.

---

## Step 1 — Countryside Region Overview

| Region | Size | Biome | Key Features |
| :--- | :--- | :--- | :--- |
| **Greenfield Valley** | 3.0 km² | Temperate farmland | Crop farms, orchards, village |
| **Hillside Pastures** | 2.0 km² | Rolling hills | Livestock, dairy, windmills |
| **Riverside Meadows** | 1.5 km² | River delta | Rice paddies, fishing huts |

---

## Step 2 — Farm Types & Layout

### Crop Farm Layout

```text
Greenfield Valley Farm (50m x 50m plot)
┌──────────────────────────────────────────┐
│  ┌────────┐  ┌────────┐  ┌────────┐     │
│  │ Field 1│  │ Field 2│  │ Field 3│     │
│  │ (Wheat)│  │ (Corn) │  │(Soybean)│    │
│  └────────┘  └────────┘  └────────┘     │
│  ┌────────┐  ┌────────┐  ┌────────┐     │
│  │ Field 4│  │ Field 5│  │ Field 6│     │
│  │(Potato)│  │(Tomato)│  │(Carrot)│     │
│  └────────┘  └────────┘  └────────┘     │
│         ┌──────────────┐                  │
│         │  Farmhouse   │                  │
│         │  + Storage   │                  │
│         └──────────────┘                  │
│              ┌────┐                       │
│              │Well │                      │
│              └────┘                       │
└──────────────────────────────────────────┘
```

### Farm Types

| Farm Type | Crops/Produce | Investment | Daily Income | Season |
| :--- | :--- | :--- | :--- | :--- |
| **Grain Farm** | Wheat, Corn, Barley | ₹50,000 | ₹2,000 | Summer/Autumn |
| **Vegetable Farm** | Tomato, Potato, Carrot | ₹30,000 | ₹1,500 | Spring–Autumn |
| **Orchard** | Apples, Oranges, Peaches | ₹80,000 | ₹3,000 | Autumn |
| **Dairy Farm** | Milk, Cheese, Butter | ₹100,000 | ₹3,500 | Year-round |
| **Poultry Farm** | Eggs, Chicken | ₹40,000 | ₹1,800 | Year-round |
| **Rice Paddy** | Rice | ₹35,000 | ₹1,200 | Monsoon |

---

## Step 3 — Crop Growth System

Crops pass through growth stages over in-game days.

### Growth Stages

```text
Planted → Seedling → Growing → Mature → Harvest → (Replant)
   Day 0    Day 1-3    Day 4-7    Day 8-10  Day 11
```

### `CropSystem.gd`

```gdscript
extends Node
class_name CropSystem

enum CropType { WHEAT, CORN, TOMATO, POTATO, CARROT, RICE, APPLE, ORANGE }
enum GrowthStage { EMPTY, PLANTED, SEEDLING, GROWING, MATURE, WITHERED }

const GROWTH_DURATION = {
    CropType.WHEAT: 10,
    CropType.CORN: 12,
    CropType.TOMATO: 8,
    CropType.POTATO: 14,
    CropType.CARROT: 7,
    CropType.RICE: 15,
    CropType.APPLE: 20,
    CropType.ORANGE: 22,
}

const CROP_VALUE = {
    CropType.WHEAT: 50,
    CropType.CORN: 60,
    CropType.TOMATO: 80,
    CropType.POTATO: 70,
    CropType.CARROT: 65,
    CropType.RICE: 90,
    CropType.APPLE: 120,
    CropType.ORANGE: 130,
}

var active_crops: Dictionary = {}  # field_id -> CropData

class CropData:
    var crop_type: int
    var planted_day: int
    var stage: int = GrowthStage.PLANTED
    var water_level: float = 100.0
    var field_node: Node3D

func plant_crop(field_id: String, crop_type: int, field_node: Node3D) -> void:
    var crop = CropData.new()
    crop.crop_type = crop_type
    crop.planted_day = TimeSystem.current_day
    crop.field_node = field_node
    active_crops[field_id] = crop
    _update_visuals(field_id)

func update_crops() -> void:
    for field_id in active_crops:
        var crop = active_crops[field_id]
        var days_elapsed = TimeSystem.current_day - crop.planted_day
        var total_duration = GROWTH_DURATION[crop.crop_type]
        
        if days_elapsed >= total_duration:
            crop.stage = GrowthStage.MATURE
        elif days_elapsed >= total_duration * 0.7:
            crop.stage = GrowthStage.GROWING
        elif days_elapsed >= total_duration * 0.3:
            crop.stage = GrowthStage.SEEDLING
        
        # Water depletion
        crop.water_level = max(crop.water_level - 5.0, 0.0)
        if crop.water_level < 20.0 and crop.stage != GrowthStage.MATURE:
            crop.stage = GrowthStage.WITHERED
        
        _update_visuals(field_id)

func harvest_crop(field_id: String) -> int:
    if not active_crops.has(field_id): return 0
    var crop = active_crops[field_id]
    if crop.stage != GrowthStage.MATURE: return 0
    
    var value = CROP_VALUE[crop.crop_type]
    var quantity = randi_range(20, 50)  # units harvested
    active_crops.erase(field_id)
    _update_visuals(field_id)
    return value * quantity

func water_crop(field_id: String) -> void:
    if active_crops.has(field_id):
        active_crops[field_id].water_level = 100.0
        _update_visuals(field_id)

func _update_visuals(field_id: String) -> void:
    if not active_crops.has(field_id): return
    var crop = active_crops[field_id]
    var mesh = crop.field_node.get_node("CropMesh")
    match crop.stage:
        GrowthStage.PLANTED: mesh.visible = false
        GrowthStage.SEEDLING:
            mesh.visible = true
            mesh.scale = Vector3(0.3, 0.3, 0.3)
        GrowthStage.GROWING:
            mesh.scale = Vector3(0.7, 0.7, 0.7)
        GrowthStage.MATURE:
            mesh.scale = Vector3(1.0, 1.0, 1.0)
        GrowthStage.WITHERED:
            mesh.scale = Vector3(0.5, 0.5, 0.5)
```

---

## Step 4 — Farming Activities

| Activity | How To Play | Reward |
| :--- | :--- | :--- |
| **Plowing** | Drive tractor over field tiles | Prepares soil for planting |
| **Planting** | Select crop, walk over field tiles | Starts crop growth |
| **Watering** | Use watering can or sprinkler system | Maintains crop health |
| **Harvesting** | Walk over mature crops, press interact | Sells crops automatically |
| **Milking** | Approach cow, minigame (rhythm taps) | Milk → sell or make cheese |
| **Egg Collecting** | Visit chicken coop, collect eggs | Eggs → sell or cook |
| **Tractor Driving** | Ride tractor between fields | Faster plowing & harvesting |

---

## Step 5 — Rural Village (Greenfield Village)

```text
Greenfield Village
├── Buildings
│   ├── General Store (seeds, tools, supplies)
│   ├── Farmer's Market (sell produce)
│   ├── Village Hall (property purchase)
│   ├── Tavern (food, rest, socialize)
│   ├── Blacksmith (tool upgrades)
│   └── Farmhouses (player can buy)
├── Infrastructure
│   ├── Dirt Roads
│   ├── Stone Bridge (over river)
│   ├── Windmill (landmark)
│   └── Water Well (community)
└── Activities
    ├── Farmer's Market (every Sunday)
    ├── Village Festival (seasonal event)
    ├── Fishing at River
    └── Horseback Riding
```

---

## Step 6 — Farm Ownership System

Players can purchase and manage their own farm as a business.

### `FarmBusiness.gd`

```gdscript
extends Node
class_name FarmBusiness

var farm_id: String
var farm_name: String
var owner_id: String  # "player" or NPC ID
var fields: Array = []  # Array of field nodes
var livestock: Dictionary = {}  # animal_type -> count
var daily_expenses: float = 500.0  # maintenance, feed, water
var daily_income: float = 0.0
var total_profit: float = 0.0
var farm_level: int = 1

func process_daily_economy() -> void:
    daily_income = 0.0
    
    # Crop income
    for field in fields:
        if field.has_method("get_harvest_value"):
            daily_income += field.get_harvest_value()
    
    # Livestock income
    for animal_type in livestock:
        daily_income += livestock[animal_type] * _get_animal_daily_value(animal_type)
    
    var profit = daily_income - daily_expenses
    total_profit += profit
    
    if owner_id == "player":
        if profit > 0:
            EconomySystem.add_money(profit)
            UI.showToast("Farm earned ₹%d today" % profit)
        else:
            if EconomySystem.can_afford(abs(profit)):
                EconomySystem.spend_money(abs(profit))
            else:
                UI.showToast("Warning: Farm operating at a loss!")

func upgrade_farm() -> void:
    var upgrade_cost = farm_level * 25000
    if EconomySystem.can_afford(upgrade_cost):
        EconomySystem.spend_money(upgrade_cost)
        farm_level += 1
        daily_expenses *= 1.2
        # Unlock new field slots and crop types
        UI.showToast("Farm upgraded to Level %d!" % farm_level)
```
