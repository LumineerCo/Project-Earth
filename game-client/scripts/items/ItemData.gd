## ItemData.gd
## Resource representing a single inventory item.
## Stage 4.3 — Inventory System
extends Resource
class_name ItemData

@export var item_id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export var prefab: PackedScene
@export var category: String = "consumable"
@export var max_stack: int = 1
@export var weight: float = 0.1
@export var value: int = 0
@export var usable: bool = false
@export var equippable: bool = false
@export var equip_slot: String = ""
@export var use_effects: Dictionary = {}

func get_use_text() -> String:
	if not usable:
		return ""
	var effects := []
	for stat in use_effects.keys():
		effects.append("%s %+d" % [stat.capitalize(), int(use_effects[stat])])
	return ", ".join(effects)
