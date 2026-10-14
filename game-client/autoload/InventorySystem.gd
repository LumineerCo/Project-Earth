## InventorySystem.gd
## Grid-based inventory, stacking, weight limits, and persistence.
## Stage 4.3 — Inventory System
extends Node
class_name InventorySystem

signal inventory_changed
signal item_added(item_id: String, count: int)
signal item_removed(item_id: String, count: int)
signal weight_changed(current: float, maximum: float)

const DEFAULT_SLOTS := 20

var slots: Array = []
var max_slots: int = DEFAULT_SLOTS
var max_weight: float = 50.0

func _ready() -> void:
	reset_inventory()
	DebugManager.log_info("InventorySystem", "Inventory system initialized")

func reset_inventory() -> void:
	slots.clear()
	for i in range(DEFAULT_SLOTS):
		slots.append({"item_id": "", "count": 0, "item_data": null})
	update_weight_capacity()
	_emit_changes()

func clear_inventory() -> void:
	reset_inventory()

func add_item(item_data: ItemData, count: int = 1) -> int:
	if item_data == null or count <= 0:
		return count

	var remaining := count
	if item_data.max_stack > 1:
		for slot in slots:
			if slot["item_id"] == item_data.item_id and slot["count"] < item_data.max_stack:
				var space := item_data.max_stack - slot["count"]
				var to_add := min(remaining, space)
				slot["count"] += to_add
				remaining -= to_add
				if remaining <= 0:
					_emit_changes()
					item_added.emit(item_data.item_id, count)
					return 0

	for slot in slots:
		if slot["item_id"] == "":
			var addable := remaining
			var available_weight := max_weight - _get_current_weight()
			if available_weight <= 0.0:
				break
			var max_count := int(floor(available_weight / item_data.weight))
			if max_count <= 0:
				break
			if item_data.max_stack > 1:
				max_count = min(max_count, item_data.max_stack)
			var to_add := min(remaining, max_count)
			slot["item_id"] = item_data.item_id
			slot["count"] = to_add
			slot["item_data"] = item_data
			remaining -= to_add
			if remaining <= 0:
				break

	_emit_changes()
	if remaining < count:
		item_added.emit(item_data.item_id, count - remaining)
	return remaining

func remove_item(item_id: String, count: int = 1) -> bool:
	if item_id == "" or count <= 0:
		return false
	var remaining := count
	for slot in slots:
		if slot["item_id"] == item_id:
			var to_remove := min(remaining, slot["count"])
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
	var total := 0
	for slot in slots:
		if slot["item_id"] == item_id:
			total += slot["count"]
	return total >= count

func get_item_count(item_id: String) -> int:
	var total := 0
	for slot in slots:
		if slot["item_id"] == item_id:
			total += slot["count"]
	return total

func use_item(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= slots.size():
		return
	var slot := slots[slot_index]
	if slot["item_id"] == "" or slot["item_data"] == null:
		return
	var item_data := slot["item_data"] as ItemData
	if not item_data.usable:
		return
	# Apply use effects (e.g. hunger +25, energy +10) as additive modifiers
	for stat in item_data.use_effects.keys():
		var current := PlayerStats.get_stat(stat)
		PlayerStats.set_stat(stat, current + float(item_data.use_effects[stat]))
	DebugManager.log_info("InventorySystem", "Used item: %s" % item_data.display_name)
	remove_item(item_data.item_id, 1)

func _get_current_weight() -> float:
	var weight = 0.0
	for slot in slots:
		if slot["item_data"] != null:
			weight += slot["item_data"].weight * slot["count"]
	return weight

func update_weight_capacity() -> void:
	max_weight = PlayerStats.get_weight_capacity()
	weight_changed.emit(_get_current_weight(), max_weight)

func _emit_changes() -> void:
	inventory_changed.emit()
	weight_changed.emit(_get_current_weight(), max_weight)

func get_all_items() -> Array:
	var items := []
	for slot in slots:
		if slot["item_id"] != "":
			items.append(slot)
	return items

func serialize() -> Dictionary:
	var slot_data := []
	for slot in slots:
		slot_data.append({
			"item_id": slot["item_id"],
			"count": slot["count"],
		})
	return {
		"max_slots": max_slots,
		"max_weight": max_weight,
		"slots": slot_data,
	}

func deserialize(data: Dictionary) -> void:
	max_slots = data.get("max_slots", max_slots)
	max_weight = data.get("max_weight", max_weight)
	slots.clear()
	var slot_data := data.get("slots", [])
	for slot_dict in slot_data:
		var item_id := slot_dict.get("item_id", "")
		var count := slot_dict.get("count", 0)
		var item_data := ItemDatabase.get_item(item_id)
		slots.append({"item_id": item_id, "count": count, "item_data": item_data})
	update_weight_capacity()
	_emit_changes()
