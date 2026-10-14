# Stage 3.5 — Shops & Economy Integration

A city is not just roads and buildings — it is a place where people buy, sell, and trade. This stage defines how shops work, how the player interacts with them, and how the local economy of Nova City functions.

---

## Goal
Create a shop interaction system with purchasable items, shop inventories, and a basic local economy model that responds to supply and demand.

---

## Step 1 — Shop Categories

Nova City will feature several shop types, each with its own inventory pool.

| Shop Type | Items Sold | Location | Open Hours |
| :--- | :--- | :--- | :--- |
| **Grocery Store** | Food, drinks, snacks | Residential districts | 06:00–23:00 |
| **Clothing Store** | Shirts, pants, shoes, accessories | Commercial district | 09:00–21:00 |
| **Hardware Store** | Tools, building materials, paint | Industrial district | 08:00–18:00 |
| **Pharmacy** | Medicine, first aid, vitamins | All districts | 08:00–22:00 |
| **Restaurant** | Cooked meals, coffee | All districts | 07:00–24:00 |
| **Gas Station** | Fuel, snacks, car items | Highway exits | 24/7 |
| **Electronics Store** | Phones, laptops, gadgets | Commercial district | 10:00–20:00 |

---

## Step 2 — Shop Data Model

Each shop is a `ShopInteractable` node placed in the world. It holds a reference to a shop database entry.

```gdscript
class_name ShopData

var shop_id: String
var shop_name: String
var shop_type: String
var inventory: Array[Dictionary] = []  # [{item_id, price, stock}]
var open_hours: Vector2 = Vector2(6.0, 23.0)  # start, end
var money_reserve: float = 5000.0  # cash the shop has for buying from player
var price_modifier: float = 1.0  # economy-driven multiplier

func is_open(current_hour: float) -> bool:
    if open_hours.x <= open_hours.y:
        return current_hour >= open_hours.x and current_hour <= open_hours.y
    else:
        # Handles 24/7 or overnight (e.g., gas station 22:00–06:00)
        return current_hour >= open_hours.x or current_hour <= open_hours.y

func get_item_price(item_id: String) -> float:
    for item in inventory:
        if item["item_id"] == item_id:
            return item["price"] * price_modifier
    return 0.0

func purchase_item(item_id: String, quantity: int = 1) -> bool:
    for item in inventory:
        if item["item_id"] == item_id and item["stock"] >= quantity:
            item["stock"] -= quantity
            return true
    return false
```

---

## Step 3 — Shop Interaction Flow

When the player approaches a shop door, an interaction prompt appears.

```text
Player approaches shop door
        │
        ▼
[Area3D detects "Player" group]
        │
        ▼
Show prompt: "Press E to enter [Shop Name]"
        │
        ▼
Player presses E
        │
        ▼
Open Shop UI (CanvasLayer)
        │
        ▼
Player browses items → clicks "Buy"
        │
        ▼
Check player money → Deduct → Add to inventory → Reduce shop stock
```

---

## Step 4 — Shop Interactable Script (`ShopInteractable.gd`)

```gdscript
extends Area3D
class_name ShopInteractable

@export var shop_data: Resource  # ShopData resource
@onready var prompt_label: Label3D = $PromptLabel

var player_inside: bool = false

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)
    prompt_label.visible = false

func _on_body_entered(body: Node3D) -> void:
    if body.is_in_group("Player"):
        player_inside = true
        var hour = TimeSystem.get_current_hour()
        if shop_data.is_open(hour):
            prompt_label.text = "Press E to enter " + shop_data.shop_name
            prompt_label.visible = true
        else:
            prompt_label.text = "Closed"
            prompt_label.visible = true

func _on_body_exited(body: Node3D) -> void:
    if body.is_in_group("Player"):
        player_inside = false
        prompt_label.visible = false

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("interact") and player_inside:
        var hour = TimeSystem.get_current_hour()
        if shop_data.is_open(hour):
            ShopUIManager.open_shop(shop_data)
        else:
            HUDManager.show_notification("The shop is closed right now.")
```

---

## Step 5 — Local Economy Model

Nova City has a lightweight economy simulation that adjusts prices over time.

### Economy Parameters

| Parameter | Default | Description |
| :--- | :--- | :--- |
| **Base Demand** | 1.0 | How much citizens buy per day |
| **Supply Rate** | 1.0 | How fast shops restock |
| **Price Elasticity** | 0.1 | How much price changes per stock unit |
| **Restock Interval** | 24h | Game hours between restocks |

### Economy Tick (`EconomyManager.gd`)

```gdscript
extends Node

var registered_shops: Array[ShopData] = []

func register_shop(shop: ShopData) -> void:
    registered_shops.append(shop)

func _on_hour_tick() -> void:
    for shop in registered_shops:
        _process_shop_economy(shop)

func _process_shop_economy(shop: ShopData) -> void:
    for item in shop.inventory:
        # Simulate NPC demand reducing stock
        var demand = randf_range(0.5, 2.0) * item.get("base_demand", 1.0)
        item["stock"] = max(0, item["stock"] - int(demand))
        
        # Adjust price based on scarcity
        var base_price = item["base_price"]
        var stock_ratio = float(item["stock"]) / float(item.get("max_stock", 50))
        if stock_ratio < 0.2:
            item["price"] = base_price * 1.3  # scarce = expensive
        elif stock_ratio > 0.8:
            item["price"] = base_price * 0.9  # surplus = cheaper
        
        # Restock slowly
        item["stock"] = min(item.get("max_stock", 50), item["stock"] + 5)
```

This creates a dynamic economy where prices fluctuate naturally, giving the player reasons to visit different shops at different times.
