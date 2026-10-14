## PickupItem.gd
## A small item the player can pick up. Adds to a simple inventory.
## Stage 2.12 Milestone 8 (Basic Interaction) + Stage 4.3 (Inventory preview)
extends Interactable

@export var item_id: String = "generic_item"
@export var item_name: String = "Item"
@export var quantity: int = 1

func _ready() -> void:
	super._ready()
	prompt_text = "Press E to pick up %s" % item_name

func _on_interact(_player: Node) -> void:
	var item_data := ItemDatabase.get_item(item_id)
	if item_data != null:
		InventorySystem.add_item(item_data, quantity)
	else:
		var inv: Dictionary = GameManager.player_data.get("inventory", {})
		inv[item_id] = inv.get(item_id, 0) + quantity
		GameManager.player_data["inventory"] = inv
	DebugManager.log_info("PickupItem", "Picked up %dx %s" % [quantity, item_name])
	queue_free()
