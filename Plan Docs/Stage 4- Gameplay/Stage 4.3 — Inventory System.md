# Stage 4.3 — Inventory System

The inventory system lets the player carry, organize, and use items. It must be intuitive, weight-limited, and visually clear.

---

## Goal
Create a grid-based inventory with item stacking, weight limits, drag-and-drop UI, and item categories.

---

## Step 1 — Item Categories

| Category | Examples | Stackable | Avg Weight |
| :--- | :--- | :--- | :--- |
| **Consumable** | Food, drinks, medicine | Yes (up to 99) | 0.1–0.5 kg |
| **Weapon** | Knife, bat, pistol | No | 0.5–3.0 kg |
| **Tool** | Phone, keys, map | No | 0.1–1.0 kg |
| **Clothing** | Shirts, jackets, hats | No | 0.2–1.5 kg |
| **Material** | Wood, metal, cloth | Yes (up to 999) | 0.5–5.0 kg |
| **Key Item** | Mission items, documents | No | 0.1–1.0 kg |
| **Valuable** | Jewelry, watches, art | No | 0.1–2.0 kg |

---

## Step 2 — Item Data Model

### `ItemData.gd`

```gdscript
extends Resource
class_name ItemData

@export var item_id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export var mesh: PackedScene
@export var category: String = "consumable"
@export var max_stack: int = 1
@export var weight: float = 0.1
@export var value: int = 0  # Base sell value in Credits
@export var usable: bool = false
@export var equippable: bool = false
@export var equip_slot: String = ""  # "hand", "head", "body", "feet"
@export var use_effects: Dictionary = {}  # {"health": 10, "hunger": 25}

func get_use_text() -> String:
    if not usable:
        return ""
    var effects = []
    for stat in use_effects:
        effects.append("%s %+d" % [stat.capitalize(), use_effects[stat]])
    return ", ".join(effects)
```

---

## Step 3 — Inventory System

### `InventorySystem.gd` (Autoload)

```gdscript
extends Node

signal inventory_changed
signal item_added(item_id: String, count: int)
signal item_removed(item_id: String, count: int)
signal weight_changed(current: float, maximum: float)

var slots: Array[Dictionary] = []  # Each: {item_id, count, item_data}
var max_slots: int = 20
var max_weight: float = 50.0  # Modified by Strength skill

func _ready() -> void:
    for i in max_slots:
        slots.append({"item_id": "", "count": 0, "item_data": null})

func add_item(item_data: ItemData, count: int = 1) -> int:
    # Returns number of items that couldn't be added
    var remaining = count
    
    # Try stacking first
    if item_data.max_stack > 1:
        for slot in slots:
            if slot["item_id"] == item_data.item_id and slot["count"] < item_data.max_stack:
                var space = item_data.max_stack - slot["count"]
                var to_add = min(remaining, space)
                slot["count"] += to_add
                remaining -= to_add
                if remaining <= 0:
                    _emit_changes()
                    item_added.emit(item_data.item_id, count)
                    return 0
    
    # Find empty slots
    for slot in slots:
        if slot["item_id"] == "":
            if _get_current_weight() + item_data.weight * remaining > max_weight:
                # Can't fit all, add what we can
                var can_fit = int((max_weight - _get_current_weight()) / item_data.weight)
                if can_fit <= 0:
                    _emit_changes()
                    return remaining
                slot["item_id"] = item_data.item_id
                slot["count"] = can_fit
                slot["item_data"] = item_data
                remaining -= can_fit
            else:
                slot["item_id"] = item_data.item_id
                slot["count"] = remaining
                slot["item_data"] = item_data
                remaining = 0
    
    _emit_changes()
    if remaining < count:
        item_added.emit(item_data.item_id, count - remaining)
    return remaining

func remove_item(item_id: String, count: int = 1) -> bool:
    var remaining = count
    for slot in slots:
        if slot["item_id"] == item_id:
            var to_remove = min(remaining, slot["count"])
            slot["count"] -= to_remove
            remaining -= to_remove
            if slot["count"] <= 0:
                slot["item_id"] = ""
                slot["item_data"] = null
            if remaining <= 0:
                _emit_changes()
                item_removed.emit(item_id, count)
                return true
    _emit_changes()
    return remaining == 0

func has_item(item_id: String, count: int = 1) -> bool:
    var total = 0
    for slot in slots:
        if slot["item_id"] == item_id:
            total += slot["count"]
    return total >= count

func get_item_count(item_id: String) -> int:
    var total = 0
    for slot in slots:
        if slot["item_id"] == item_id:
            total += slot["count"]
    return total

func use_item(slot_index: int) -> void:
    if slot_index < 0 or slot_index >= slots.size(): return
    var slot = slots[slot_index]
    if slot["item_id"] == "" or slot["item_data"] == null: return
    var item_data = slot["item_data"] as ItemData
    if not item_data.usable: return
    
    # Apply effects
    for stat in item_data.use_effects:
        PlayerStats._modify_stat(stat, item_data.use_effects[stat])
    
    # Consume one
    remove_item(slot["item_id"], 1)

func _get_current_weight() -> float:
    var weight = 0.0
    for slot in slots:
        if slot["item_data"] != null:
            weight += slot["item_data"].weight * slot["count"]
    return weight

func _emit_changes() -> void:
    inventory_changed.emit()
    weight_changed.emit(_get_current_weight(), max_weight)

func update_weight_capacity() -> void:
    # Strength skill increases weight capacity
    var strength = PlayerStats.skills["strength"]
    max_weight = 50.0 + (strength * 0.5)
    weight_changed.emit(_get_current_weight(), max_weight)
```

---

## Step 4 — Inventory UI

### `InventoryUI.gd`

```gdscript
extends Control

@onready var grid_container: GridContainer = $Panel/GridContainer
@onready var weight_bar: ProgressBar = $Panel/WeightBar
@onready var weight_label: Label = $Panel/WeightLabel
@onready var tooltip: Panel = $Tooltip
@onready var tooltip_label: Label = $Tooltip/Label

var slot_panels: Array[InventorySlot] = []

func _ready() -> void:
    visible = false
    _create_slots()
    InventorySystem.inventory_changed.connect(_refresh)
    InventorySystem.weight_changed.connect(_update_weight)

func _create_slots() -> void:
    for i in InventorySystem.max_slots:
        var slot = InventorySlot.new()
        slot.slot_index = i
        slot.item_dropped.connect(_on_item_dropped)
        grid_container.add_child(slot)
        slot_panels.append(slot)

func _refresh() -> void:
    for i in InventorySystem.slots.size():
        slot_panels[i].set_data(InventorySystem.slots[i])

func _update_weight(current: float, maximum: float) -> void:
    weight_bar.max_value = maximum
    weight_bar.value = current
    weight_label.text = "%.1f / %.1f kg" % [current, maximum]

func _on_item_dropped(from_slot: int, to_slot: int) -> void:
    # Swap slots
    var temp = InventorySystem.slots[from_slot]
    InventorySystem.slots[from_slot] = InventorySystem.slots[to_slot]
    InventorySystem.slots[to_slot] = temp
    InventorySystem.inventory_changed.emit()
```

### `InventorySlot.gd`

```gdscript
extends Panel

signal item_dropped(from: int, to: int)

var slot_index: int = 0
var item_icon: TextureRect
var count_label: Label

func _ready() -> void:
    # Setup UI elements
    var vbox = VBoxContainer.new()
    add_child(vbox)
    item_icon = TextureRect.new()
    item_icon.custom_minimum_size = Vector2(64, 64)
    item_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
    vbox.add_child(item_icon)
    count_label = Label.new()
    count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    vbox.add_child(count_label)
    
    set_drag_forwarding(_can_drag, _get_drag_data, _can_drop)

func set_data(slot_data: Dictionary) -> void:
    if slot_data["item_id"] == "" or slot_data["item_data"] == null:
        item_icon.texture = null
        count_label.text = ""
    else:
        item_icon.texture = slot_data["item_data"].icon
        if slot_data["count"] > 1:
            count_label.text = str(slot_data["count"])
        else:
            count_label.text = ""

func _can_drag(_pos: Vector2) -> bool:
    return InventorySystem.slots[slot_index]["item_id"] != ""

func _get_drag_data(_pos: Vector2) -> Variant:
    return {"from_slot": slot_index}

func _can_drop(_pos: Vector2, data: Variant) -> bool:
    return data is Dictionary and data.has("from_slot")
```

---

## Step 5 — Item Database

Items are stored as `.tres` Resource files in `res://data/items/`.

```
res://data/items/
├── consumables/
│   ├── coffee.tres
│   ├── sandwich.tres
│   ├── water_bottle.tres
│   └── medkit.tres
├── weapons/
│   ├── knife.tres
│   ├── baseball_bat.tres
│   └── pistol.tres
├── tools/
│   ├── phone.tres
│   ├── car_keys.tres
│   └── map.tres
├── materials/
│   ├── wood.tres
│   ├── metal_scrap.tres
│   └── cloth.tres
└── valuables/
    ├── gold_watch.tres
    └── diamond_ring.tres
```

### `ItemDatabase.gd`

```gdscript
extends Node

var items: Dictionary = {}

func _ready() -> void:
    _load_all_items()

func _load_all_items() -> void:
    var dir = DirAccess.open("res://data/items")
    _scan_directory(dir)

func _scan_directory(dir: DirAccess) -> void:
    dir.list_dir_begin()
    var file = dir.get_next()
    while file != "":
        if dir.current_is_dir():
            if file != "." and file != "..":
                var sub = DirAccess.open(dir.get_current_dir() + "/" + file)
                _scan_directory(sub)
        elif file.ends_with(".tres"):
            var path = dir.get_current_dir() + "/" + file
            var item = load(path) as ItemData
            if item:
                items[item.item_id] = item
        file = dir.get_next()

func get_item(item_id: String) -> ItemData:
    return items.get(item_id, null)
```

This inventory system provides the item management foundation that shops, crafting, and missions all rely on.
