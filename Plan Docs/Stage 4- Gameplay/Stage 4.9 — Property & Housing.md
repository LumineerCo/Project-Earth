# Stage 4.9 — Property & Housing

Property ownership gives the player a permanent base of operations. Homes provide storage, sleeping, and customization.

---

## Goal
Create a property system with buying, renting, furniture placement, storage, and property management.

---

## Step 1 — Property Types

| Property | Type | Price (Cr) | Rent (Cr/mo) | Storage | Beds | Garage |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Studio Apartment** | Rent | — | 800 | 10 slots | 1 | 0 |
| **1-Bedroom Apartment** | Rent | — | 1,200 | 15 slots | 1 | 1 |
| **2-Bedroom Apartment** | Rent | — | 1,800 | 20 slots | 2 | 1 |
| **Suburban House** | Buy | 150,000 | — | 40 slots | 3 | 2 |
| **Downtown Condo** | Buy | 250,000 | — | 30 slots | 2 | 1 |
| **Beach House** | Buy | 400,000 | — | 50 slots | 3 | 2 |
| **Luxury Penthouse** | Buy | 750,000 | — | 60 slots | 4 | 3 |
| **Countryside Estate** | Buy | 1,200,000 | — | 100 slots | 5 | 4 |

---

## Step 2 — Property Data Model

### `PropertyData.gd`

```gdscript
extends Resource
class_name PropertyData

@export var property_id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var address: String = ""
@export var district: String = ""
@export var is_rental: bool = false
@export var price: int = 0
@export var monthly_rent: int = 0
@export var storage_slots: int = 10
@export var bedroom_count: int = 1
@export var garage_spaces: int = 0
@export var interior_scene: PackedScene
@export var exterior_position: Vector3 = Vector3.ZERO
@export var furniture_grid_size: Vector2i = Vector2i(10, 10)
```

---

## Step 3 — Property Manager

### `PropertyManager.gd` (Autoload)

```gdscript
extends Node

signal property_acquired(property_id: String)
signal property_sold(property_id: String, amount: int)
signal rent_paid(property_id: String)
signal rent_overdue(property_id: String)
signal furniture_placed(property_id: String, furniture_id: String, position: Vector2i)
signal furniture_removed(property_id: String, furniture_id: String)

var all_properties: Dictionary = {}  # property_id -> PropertyData
var owned_properties: Dictionary = {}  # property_id -> {furniture, storage, rent_due_date}
var active_home: String = ""  # property_id of current home

func _ready() -> void:
    _load_properties()
    TimeSystem.day_changed.connect(_on_day_changed)

func _load_properties() -> void:
    var dir = DirAccess.open("res://data/properties")
    if dir:
        dir.list_dir_begin()
        var file = dir.get_next()
        while file != "":
            if file.ends_with(".tres"):
                var prop = load(dir.get_current_dir() + "/" + file) as PropertyData
                if prop:
                    all_properties[prop.property_id] = prop
            file = dir.get_next()

func acquire_property(property_id: String) -> bool:
    if not all_properties.has(property_id): return false
    if property_id in owned_properties: return false
    
    var prop = all_properties[property_id] as PropertyData
    if prop.is_rental:
        # First month + deposit
        var cost = prop.monthly_rent * 2
        if not MoneySystem.spend_cash(cost):
            PhoneSystem.add_notification("Property", "Insufficient Funds",
                "Need %d Cr (first month + deposit)" % cost)
            return false
    else:
        if not MoneySystem.spend_cash(prop.price):
            PhoneSystem.add_notification("Property", "Insufficient Funds",
                "Need %d Cr" % prop.price)
            return false
    
    owned_properties[property_id] = {
        "furniture": {},  # furniture_instance_id -> {data, grid_pos, rotation}
        "storage": [],  # Array of ItemData
        "rent_due_date": TimeSystem.get_day() + 30 if prop.is_rental else 0,
        "acquired_date": TimeSystem.get_day(),
    }
    
    if active_home == "":
        active_home = property_id
    
    property_acquired.emit(property_id)
    PhoneSystem.add_notification("Property", "Acquired!",
        "You now own/rent: %s" % prop.display_name)
    return true

func sell_property(property_id: String) -> int:
    if not owned_properties.has(property_id): return 0
    if property_id == active_home:
        PhoneSystem.add_notification("Property", "Cannot Sell",
            "Set another property as active home first.")
        return 0
    
    var prop = all_properties[property_id] as PropertyData
    var sell_price = int(prop.price * 0.8)
    MoneySystem.add_cash(sell_price)
    owned_properties.erase(property_id)
    property_sold.emit(property_id, sell_price)
    PhoneSystem.add_notification("Property", "Sold",
        "Sold for %d Cr" % sell_price)
    return sell_price

func pay_rent(property_id: String) -> bool:
    if not owned_properties.has(property_id): return false
    var prop = all_properties[property_id] as PropertyData
    if not prop.is_rental: return false
    if not MoneySystem.spend_cash(prop.monthly_rent):
        PhoneSystem.add_notification("Property", "Insufficient Funds",
            "Rent is %d Cr" % prop.monthly_rent)
        return false
    
    owned_properties[property_id]["rent_due_date"] = TimeSystem.get_day() + 30
    rent_paid.emit(property_id)
    PhoneSystem.add_notification("Property", "Rent Paid",
        "%d Cr for %s" % [prop.monthly_rent, prop.display_name])
    return true

func _on_day_changed() -> void:
    for property_id in owned_properties:
        var prop = all_properties[property_id] as PropertyData
        if not prop.is_rental: continue
        var due = owned_properties[property_id]["rent_due_date"]
        if TimeSystem.get_day() >= due:
            rent_overdue.emit(property_id)
            PhoneSystem.add_notification("Property", "Rent Overdue!",
                "Pay rent for %s or risk eviction." % prop.display_name)

func set_active_home(property_id: String) -> void:
    if property_id in owned_properties:
        active_home = property_id
        PhoneSystem.add_notification("Property", "Home Set",
            "Active home: %s" % all_properties[property_id].display_name)
```

---

## Step 4 — Furniture System

### `FurnitureData.gd`

```gdscript
extends Resource
class_name FurnitureData

@export var furniture_id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var price: int = 0
@export var category: String = "general"  # bed, chair, table, storage, decor, appliance
@export var scene: PackedScene
@export var grid_size: Vector2i = Vector2i(1, 1)  # tiles occupied
@export var provides_storage: int = 0  # extra storage slots
@export var provides_sleep: bool = false
@export var sleep_quality: float = 1.0
@export var provides_cooking: bool = false
@export var provides_hygiene: bool = false
```

### Furniture Categories

| Category | Examples | Price Range |
| :--- | :--- | :--- |
| **Bed** | Single, Double, Bunk, Luxury King | 300–3,000 Cr |
| **Seating** | Chair, Sofa, Bar Stool, Recliner | 100–1,500 Cr |
| **Table** | Coffee, Dining, Desk, Nightstand | 150–1,200 Cr |
| **Storage** | Bookshelf, Wardrobe, Chest, Cabinet | 200–2,000 Cr |
| **Decor** | Lamp, Plant, Painting, Rug, TV | 50–2,500 Cr |
| **Appliance** | Fridge, Stove, Microwave, Shower | 500–3,500 Cr |

---

## Step 5 — Furniture Placement

### `FurnitureManager.gd`

```gdscript
extends Node

signal furniture_placed(furniture_id: String, grid_pos: Vector2i)
signal furniture_removed(furniture_id: String)

var placement_mode: bool = false
var current_furniture: FurnitureData = null
var ghost_preview: Node3D = null
var current_property_id: String = ""

func start_placement(furniture: FurnitureData, property_id: String) -> void:
    current_furniture = furniture
    current_property_id = property_id
    placement_mode = true
    _create_ghost_preview()

func _create_ghost_preview() -> void:
    if current_furniture == null: return
    ghost_preview = current_furniture.scene.instantiate()
    ghost_preview.modulate = Color(1, 1, 1, 0.5)
    get_tree().current_scene.add_child(ghost_preview)

func update_preview_position(world_pos: Vector3, grid_pos: Vector2i) -> void:
    if ghost_preview == null: return
    ghost_preview.global_position = world_pos
    var valid = _is_valid_placement(grid_pos)
    ghost_preview.modulate = Color(0, 1, 0, 0.5) if valid else Color(1, 0, 0, 0.5)

func _is_valid_placement(grid_pos: Vector2i) -> bool:
    var prop = PropertyManager.all_properties[current_property_id] as PropertyData
    var furniture = PropertyManager.owned_properties[current_property_id]["furniture"]
    
    # Check bounds
    if grid_pos.x < 0 or grid_pos.y < 0: return false
    if grid_pos.x + current_furniture.grid_size.x > prop.furniture_grid_size.x: return false
    if grid_pos.y + current_furniture.grid_size.y > prop.furniture_grid_size.y: return false
    
    # Check overlap
    for instance_id in furniture:
        var placed = furniture[instance_id]
        var placed_data = placed["data"] as FurnitureData
        var placed_pos = placed["grid_pos"]
        if _rects_overlap(grid_pos, current_furniture.grid_size,
                          placed_pos, placed_data.grid_size):
            return false
    return true

func _rects_overlap(pos1: Vector2i, size1: Vector2i, pos2: Vector2i, size2: Vector2i) -> bool:
    return pos1.x < pos2.x + size2.x and pos1.x + size1.x > pos2.x and \
           pos1.y < pos2.y + size2.y and pos1.y + size1.y > pos2.y

func confirm_placement(grid_pos: Vector2i) -> bool:
    if not _is_valid_placement(grid_pos): return false
    if not MoneySystem.spend_cash(current_furniture.price): return false
    
    var instance_id = str(Time.get_ticks_msec())
    PropertyManager.owned_properties[current_property_id]["furniture"][instance_id] = {
        "data": current_furniture,
        "grid_pos": grid_pos,
        "rotation": 0,
    }
    furniture_placed.emit(instance_id, grid_pos)
    _cleanup_preview()
    return true

func cancel_placement() -> void:
    _cleanup_preview()

func _cleanup_preview() -> void:
    placement_mode = false
    current_furniture = null
    if ghost_preview:
        ghost_preview.queue_free()
        ghost_preview = null

func remove_furniture(property_id: String, instance_id: String) -> void:
    if not PropertyManager.owned_properties.has(property_id): return
    var furniture = PropertyManager.owned_properties[property_id]["furniture"]
    if furniture.has(instance_id):
        furniture.erase(instance_id)
        furniture_removed.emit(instance_id)
```

---

## Step 6 — Home Storage

Home storage is separate from the player's inventory and provides much more space.

### `HomeStorage.gd`

```gdscript
extends Node

func deposit_item(property_id: String, item: ItemData, amount: int = 1) -> bool:
    if not PropertyManager.owned_properties.has(property_id): return false
    var storage = PropertyManager.owned_properties[property_id]["storage"]
    var prop = PropertyManager.all_properties[property_id] as PropertyData
    var furniture = PropertyManager.owned_properties[property_id]["furniture"]
    
    # Calculate total capacity
    var capacity = prop.storage_slots
    for instance_id in furniture:
        var fdata = furniture[instance_id]["data"] as FurnitureData
        capacity += fdata.provides_storage
    
    if storage.size() >= capacity:
        PhoneSystem.add_notification("Storage", "Full",
            "Home storage is at capacity.")
        return false
    
    storage.append({"item": item, "amount": amount})
    return true

func withdraw_item(property_id: String, index: int) -> ItemData:
    if not PropertyManager.owned_properties.has(property_id): return null
    var storage = PropertyManager.owned_properties[property_id]["storage"]
    if index < 0 or index >= storage.size(): return null
    var entry = storage[index]
    storage.remove_at(index)
    return entry["item"]
```

---

## Step 7 — Property Interactable

### `PropertyInteractable.gd`

```gdscript
extends Area3D
class_name PropertyInteractable

@export var property_id: String = ""

func interact(player: Node3D) -> void:
    if PropertyManager.owned_properties.has(property_id):
        ShopUIManager.open_home_ui(property_id)
    else:
        ShopUIManager.open_property_listing(property_id)
```

The property system gives players a long-term investment goal and a personal space to customize, creating a sense of ownership and permanence in the world.
