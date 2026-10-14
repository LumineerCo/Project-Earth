## ShopData.gd
## Data model for a shop — inventory, open hours, and economy state.
## Stage 3.5 Step 2 (Shop Data Model)
extends RefCounted
class_name ShopData

## ──────────────────────────────────────────────
##  Fields
## ──────────────────────────────────────────────

var shop_id: String = ""
var shop_name: String = ""
var shop_type: String = ""  # grocery, clothing, hardware, pharmacy, restaurant, gas_station, electronics
var district_id: String = ""
var building_id: String = ""
var position: Vector3 = Vector3.ZERO
var inventory: Array[Dictionary] = []  # [{item_id, base_price, price, stock, max_stock, base_demand}]
var open_hours: Vector2 = Vector2(6.0, 23.0)  # start, end (24.0 = midnight)
var money_reserve: float = 5000.0  # cash the shop has for buying from player
var price_modifier: float = 1.0  # economy-driven multiplier

## ──────────────────────────────────────────────
##  Factory
## ──────────────────────────────────────────────

static func from_dict(d: Dictionary) -> ShopData:
	var shop := ShopData.new()
	shop.shop_id = d.get("shop_id", "")
	shop.shop_name = d.get("shop_name", "")
	shop.shop_type = d.get("shop_type", "")
	shop.district_id = d.get("district_id", "")
	shop.building_id = d.get("building_id", "")
	var pos: Array = d.get("position", [0, 0, 0])
	shop.position = Vector3(pos[0], pos[1], pos[2])
	var oh: Array = d.get("open_hours", [6.0, 23.0])
	shop.open_hours = Vector2(oh[0], oh[1])
	shop.money_reserve = d.get("money_reserve", 5000.0)
	shop.price_modifier = d.get("price_modifier", 1.0)
	# Parse inventory
	for item in d.get("inventory", []):
		var entry: Dictionary = {
			"item_id": item.get("item_id", ""),
			"base_price": item.get("base_price", 1.0),
			"price": item.get("price", item.get("base_price", 1.0)),
			"stock": item.get("stock", 50),
			"max_stock": item.get("max_stock", 50),
			"base_demand": item.get("base_demand", 1.0),
		}
		shop.inventory.append(entry)
	return shop

## ──────────────────────────────────────────────
##  Open Hours
## ──────────────────────────────────────────────

func is_open(current_hour: float) -> bool:
	if open_hours.x <= open_hours.y:
		return current_hour >= open_hours.x and current_hour <= open_hours.y
	else:
		# Handles overnight (e.g., gas station 22:00–06:00 or 24/7 = 0.0–24.0)
		return current_hour >= open_hours.x or current_hour <= open_hours.y

## ──────────────────────────────────────────────
##  Inventory Queries
## ──────────────────────────────────────────────

func get_item_price(item_id: String) -> float:
	for item in inventory:
		if item["item_id"] == item_id:
			return item["price"] * price_modifier
	return 0.0

func get_item_stock(item_id: String) -> int:
	for item in inventory:
		if item["item_id"] == item_id:
			return item["stock"]
	return 0

func has_item(item_id: String, quantity: int = 1) -> bool:
	return get_item_stock(item_id) >= quantity

## ──────────────────────────────────────────────
##  Transactions
## ──────────────────────────────────────────────

## Purchase item from shop (player buys). Returns total cost, or 0 if failed.
func purchase_item(item_id: String, quantity: int = 1) -> float:
	for item in inventory:
		if item["item_id"] == item_id and item["stock"] >= quantity:
			item["stock"] -= quantity
			var cost := item["price"] * price_modifier * quantity
			money_reserve += cost
			return cost
	return 0.0

## Sell item to shop (player sells). Returns payout, or 0 if failed.
func sell_item(item_id: String, quantity: int = 1) -> float:
	# Shops buy at 70% of market price
	for item in inventory:
		if item["item_id"] == item_id:
			var payout := item["price"] * 0.7 * quantity
			if money_reserve < payout:
				return 0.0
			item["stock"] = min(item["max_stock"], item["stock"] + quantity)
			money_reserve -= payout
			return payout
	return 0.0

## ──────────────────────────────────────────────
##  Economy Processing (called by EconomyManager on hour_tick)
## ──────────────────────────────────────────────

func process_economy_tick() -> void:
	for item in inventory:
		# Simulate NPC demand reducing stock
		var demand := randf_range(0.5, 2.0) * item.get("base_demand", 1.0)
		item["stock"] = max(0, int(item["stock"]) - int(demand))
		# Adjust price based on scarcity
		var base_price: float = item["base_price"]
		var stock_ratio := float(item["stock"]) / float(item.get("max_stock", 50))
		if stock_ratio < 0.2:
			item["price"] = base_price * 1.3  # scarce = expensive
		elif stock_ratio > 0.8:
			item["price"] = base_price * 0.9  # surplus = cheaper
		else:
			item["price"] = base_price
		# Restock slowly
		item["stock"] = min(item.get("max_stock", 50), item["stock"] + 5)

## ──────────────────────────────────────────────
##  Serialization
## ──────────────────────────────────────────────

func serialize() -> Dictionary:
	var inv: Array = []
	for item in inventory:
		inv.append(item.duplicate())
	return {
		"shop_id": shop_id,
		"shop_name": shop_name,
		"shop_type": shop_type,
		"district_id": district_id,
		"building_id": building_id,
		"position": [position.x, position.y, position.z],
		"open_hours": [open_hours.x, open_hours.y],
		"money_reserve": money_reserve,
		"price_modifier": price_modifier,
		"inventory": inv,
	}
