# Stage 4.8 — Vehicles & Garage

Vehicles are the player's primary means of fast travel across Nova City. This stage covers vehicle ownership, purchasing, customization, and garage storage.

---

## Goal
Create a vehicle ownership system with a dealership, garage storage, customization, and persistent vehicle state.

---

## Step 1 — Vehicle Types

| Vehicle | Class | Price (Cr) | Top Speed | Seats | Storage |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **City Compact** | Economy | 15,000 | 120 km/h | 4 | Small |
| **Sedan** | Mid-size | 25,000 | 140 km/h | 5 | Medium |
| **SUV** | Utility | 35,000 | 130 km/h | 5 | Large |
| **Sports Car** | Performance | 80,000 | 220 km/h | 2 | Small |
| **Super Car** | Exotic | 200,000 | 280 km/h | 2 | Small |
| **Pickup Truck** | Utility | 30,000 | 110 km/h | 3 | Large |
| **Motorcycle** | Bike | 12,000 | 180 km/h | 2 | Tiny |
| **Taxi** | Commercial | 20,000 | 130 km/h | 4 | Medium |
| **Delivery Van** | Commercial | 28,000 | 100 km/h | 2 | XL |

---

## Step 2 — Vehicle Data Model

### `VehicleData.gd`

```gdscript
extends Resource
class_name VehicleData

@export var vehicle_id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var price: int = 0
@export var scene: PackedScene
@export var top_speed: float = 120.0  # km/h
@export var acceleration: float = 5.0  # m/s²
@export var handling: float = 0.5  # 0-1
@export var seats: int = 4
@export var storage_capacity: float = 50.0  # kg
@export var fuel_capacity: float = 50.0  # liters
@export var fuel_efficiency: float = 10.0  # km per liter
@export var body_color: Color = Color.WHITE
@export var trim_color: Color = Color.BLACK
@export var wheel_type: int = 0  # 0=standard, 1=sport, 2=offroad
```

---

## Step 3 — Vehicle Manager

### `VehicleManager.gd` (Autoload)

```gdscript
extends Node

signal vehicle_purchased(vehicle_id: String)
signal vehicle_sold(vehicle_id: String, amount: int)
signal vehicle_spawned(vehicle_id: String)
signal vehicle_stored(vehicle_id: String)

var owned_vehicles: Dictionary = {}  # vehicle_id -> {data, fuel, condition, mods}
var active_vehicle: Node3D = null
var active_vehicle_id: String = ""
var garage_capacity: int = 5

func purchase_vehicle(vehicle_data: VehicleData) -> bool:
    if owned_vehicles.size() >= garage_capacity:
        PhoneSystem.add_notification("Garage", "Garage Full",
            "Sell a vehicle or upgrade your garage.")
        return false
    if not MoneySystem.spend_cash(vehicle_data.price):
        PhoneSystem.add_notification("Garage", "Insufficient Funds",
            "You need %d Cr" % vehicle_data.price)
        return false
    
    owned_vehicles[vehicle_data.vehicle_id] = {
        "data": vehicle_data,
        "fuel": vehicle_data.fuel_capacity,
        "condition": 100.0,
        "odometer": 0.0,
        "mods": {},
    }
    vehicle_purchased.emit(vehicle_data.vehicle_id)
    PhoneSystem.add_notification("Garage", "Purchased!",
        "You bought a %s" % vehicle_data.display_name)
    return true

func sell_vehicle(vehicle_id: String) -> int:
    if not owned_vehicles.has(vehicle_id): return 0
    if vehicle_id == active_vehicle_id:
        PhoneSystem.add_notification("Garage", "Cannot Sell",
            "Exit the vehicle first.")
        return 0
    
    var vehicle = owned_vehicles[vehicle_id]
    var condition_mult = vehicle["condition"] / 100.0
    var sell_price = int(vehicle["data"].price * 0.6 * condition_mult)
    MoneySystem.add_cash(sell_price)
    owned_vehicles.erase(vehicle_id)
    vehicle_sold.emit(vehicle_id, sell_price)
    PhoneSystem.add_notification("Garage", "Sold",
        "Sold for %d Cr" % sell_price)
    return sell_price

func spawn_vehicle(vehicle_id: String, position: Vector3, rotation: float = 0.0) -> Node3D:
    if not owned_vehicles.has(vehicle_id): return null
    if active_vehicle != null:
        despawn_active_vehicle()
    
    var vehicle = owned_vehicles[vehicle_id]
    var instance = vehicle["data"].scene.instantiate()
    get_tree().current_scene.add_child(instance)
    instance.global_position = position
    instance.rotation.y = rotation
    instance.set_fuel(vehicle["fuel"])
    instance.set_condition(vehicle["condition"])
    
    active_vehicle = instance
    active_vehicle_id = vehicle_id
    vehicle_spawned.emit(vehicle_id)
    return instance

func despawn_active_vehicle() -> void:
    if active_vehicle == null: return
    _store_vehicle_state()
    active_vehicle.queue_free()
    active_vehicle = null
    active_vehicle_id = ""

func _store_vehicle_state() -> void:
    if not owned_vehicles.has(active_vehicle_id): return
    var vehicle = owned_vehicles[active_vehicle_id]
    vehicle["fuel"] = active_vehicle.get_fuel()
    vehicle["condition"] = active_vehicle.get_condition()
    vehicle["odometer"] += active_vehicle.get_distance_traveled()

func store_active_vehicle() -> void:
    if active_vehicle == null: return
    despawn_active_vehicle()
    vehicle_stored.emit(active_vehicle_id)
    PhoneSystem.add_notification("Garage", "Stored",
        "Vehicle parked in garage.")
```

---

## Step 4 — Fuel System

Vehicles consume fuel based on distance driven.

### `FuelSystem.gd`

```gdscript
extends Node

var fuel_price_per_liter: float = 1.5  # Cr per liter

func refuel_vehicle(vehicle_id: String, liters: float) -> bool:
    if not VehicleManager.owned_vehicles.has(vehicle_id): return false
    var vehicle = VehicleManager.owned_vehicles[vehicle_id]
    var data = vehicle["data"] as VehicleData
    var current_fuel = vehicle["fuel"]
    var space = data.fuel_capacity - current_fuel
    var to_fill = min(liters, space)
    var cost = int(to_fill * fuel_price_per_liter)
    
    if not MoneySystem.spend_cash(cost):
        PhoneSystem.add_notification("Fuel", "Insufficient Funds",
            "Need %d Cr for fuel" % cost)
        return false
    
    vehicle["fuel"] = current_fuel + to_fill
    PhoneSystem.add_notification("Fuel", "Refueled",
        "+%.1f L for %d Cr" % [to_fill, cost])
    return true
```

### Gas Station Interactable

```gdscript
extends Area3D
class_name GasStationInteractable

func interact(player: Node3D) -> void:
    if VehicleManager.active_vehicle == null:
        HUDManager.show_message("No vehicle to refuel")
        return
    ShopUIManager.open_fuel_ui(VehicleManager.active_vehicle_id)
```

---

## Step 5 — Customization

### Customization Options

| Part | Options | Price Range |
| :--- | :--- | :--- |
| **Paint Color** | 20 presets + custom | 500–2,000 Cr |
| **Wheels** | Standard, Sport, Offroad, Luxury | 1,000–5,000 Cr |
| **Trim** | Chrome, Black, Gold | 500–3,000 Cr |
| **Window Tint** | None, Light, Dark, Limo | 300–1,500 Cr |
| **Spoiler** | None, Low, High, Racing | 800–4,000 Cr |
| **Exhaust** | Standard, Sport, Loud | 600–2,500 Cr |
| **Engine Tune** | Stock, Stage 1, Stage 2, Stage 3 | 2,000–15,000 Cr |

### `VehicleCustomizer.gd`

```gdscript
extends Node

func apply_mod(vehicle_id: String, mod_type: String, mod_value: Variant, cost: int) -> bool:
    if not VehicleManager.owned_vehicles.has(vehicle_id): return false
    if not MoneySystem.spend_cash(cost): return false
    
    var vehicle = VehicleManager.owned_vehicles[vehicle_id]
    vehicle["mods"][mod_type] = mod_value
    
    # Apply visual/performance changes
    match mod_type:
        "paint_color":
            vehicle["data"].body_color = mod_value
        "wheel_type":
            vehicle["data"].wheel_type = mod_value
        "engine_tune":
            _apply_engine_tune(vehicle, mod_value)
    
    return true

func _apply_engine_tune(vehicle: Dictionary, stage: int) -> void:
    var data = vehicle["data"] as VehicleData
    var mult = 1.0 + (stage * 0.1)
    data.top_speed *= mult
    data.acceleration *= mult
```

---

## Step 6 — Garage System

The garage stores vehicles and allows the player to switch between them.

### `GarageInteractable.gd`

```gdscript
extends Area3D
class_name GarageInteractable

@export var garage_id: String = "player_home"

func interact(player: Node3D) -> void:
    if VehicleManager.active_vehicle != null:
        VehicleManager.store_active_vehicle()
    ShopUIManager.open_garage_ui()

func spawn_from_garage(vehicle_id: String) -> void:
    var spawn_point = $SpawnPoint.global_position
    var spawn_rot = $SpawnPoint.rotation.y
    VehicleManager.spawn_vehicle(vehicle_id, spawn_point, spawn_rot)
    ShopUIManager.close_garage_ui()
```

### Garage UI

```gdscript
extends Control

@onready var vehicle_list: ItemList = $Panel/VehicleList
@onready var details_panel: RichTextLabel = $Panel/DetailsPanel
@onready var spawn_button: Button = $Panel/SpawnButton
@onready var sell_button: Button = $Panel/SellButton
@onready var customize_button: Button = $Panel/CustomizeButton

var selected_vehicle: String = ""

func _ready() -> void:
    _refresh_list()

func _refresh_list() -> void:
    vehicle_list.clear()
    for vehicle_id in VehicleManager.owned_vehicles:
        var vehicle = VehicleManager.owned_vehicles[vehicle_id]
        var data = vehicle["data"] as VehicleData
        vehicle_list.add_item(data.display_name)
        vehicle_list.set_item_metadata(vehicle_list.item_count - 1, vehicle_id)

func _on_vehicle_selected(index: int) -> void:
    selected_vehicle = vehicle_list.get_item_metadata(index)
    var vehicle = VehicleManager.owned_vehicles[selected_vehicle]
    var data = vehicle["data"] as VehicleData
    details_panel.text = "[b]%s[/b]\n" % data.display_name
    details_panel.text += "Condition: %.0f%%\n" % vehicle["condition"]
    details_panel.text += "Fuel: %.1f / %.1f L\n" % [vehicle["fuel"], data.fuel_capacity]
    details_panel.text += "Odometer: %.0f km\n" % vehicle["odometer"]
    details_panel.text += "Top Speed: %.0f km/h\n" % data.top_speed
    spawn_button.disabled = false
    sell_button.disabled = false
    customize_button.disabled = false

func _on_spawn_pressed() -> void:
    if selected_vehicle != "":
        var garage = get_tree().current_scene.get_node("GarageInteractable")
        garage.spawn_from_garage(selected_vehicle)
```

---

## Step 7 — Dealership

### `DealershipInteractable.gd`

```gdscript
extends Area3D
class_name DealershipInteractable

@export var available_vehicles: Array[VehicleData] = []

func interact(player: Node3D) -> void:
    ShopUIManager.open_dealership_ui(available_vehicles)
```

### Dealership UI

```gdscript
extends Control

@onready var vehicle_grid: GridContainer = $Panel/Scroll/VehicleGrid
@onready var details_panel: RichTextLabel = $Panel/DetailsPanel
@onready var buy_button: Button = $Panel/BuyButton

var available_vehicles: Array[VehicleData] = []
var selected_vehicle: VehicleData = null

func setup(vehicles: Array[VehicleData]) -> void:
    available_vehicles = vehicles
    _populate_grid()

func _populate_grid() -> void:
    for child in vehicle_grid.get_children():
        child.queue_free()
    for vehicle in available_vehicles:
        var card = Panel.new()
        var label = Label.new()
        label.text = "%s\n%d Cr" % [vehicle.display_name, vehicle.price]
        card.add_child(label)
        card.gui_input.connect(func(event): 
            if event is InputEventMouseButton and event.pressed:
                _on_vehicle_clicked(vehicle))
        vehicle_grid.add_child(card)

func _on_vehicle_clicked(vehicle: VehicleData) -> void:
    selected_vehicle = vehicle
    details_panel.text = "[b]%s[/b]\n%s\n\nPrice: %d Cr\nTop Speed: %.0f km/h\nSeats: %d" % [
        vehicle.display_name, vehicle.description, vehicle.price, vehicle.top_speed, vehicle.seats]
    buy_button.disabled = false

func _on_buy_pressed() -> void:
    if selected_vehicle:
        VehicleManager.purchase_vehicle(selected_vehicle)
```

The vehicle system gives players a tangible progression goal — earning money to buy better vehicles — and a reason to maintain and customize their investments.
