## ShopData.gd
## Data model for a single shop in Nova City. Holds inventory, open hours,
## and a lightweight per-shop economy state. Loaded from JSON definitions
## in `data/shops/nova_city_shops.json`.
extends RefCounted
class_name ShopData

## ──────────────────────────────────────────────
##  Fields
## ──────────────────────────────────────────────

var shop_id: String = ""
var shop_name: String = ""
var shop_type: String = ""          # grocery, clothing, hardware, pharmacy, restaurant, gas_station, electronics
var district_id: String = ""
var building_id: String = ""
var position: Vector3 = Vector3.ZERO

## open_hours stored as [start_hour, end_hour]. End hour of 24.0 means midnight.
var open_hours: Vector2 = Vector2(6.0, 23.0)

## Cash the shop has available for buying items from the player.
var money_reserve: float = 5000.0

## Economy-driven multiplier applied to all item prices.
var price_modifier: float = 1.0

## Inventory entries: { item_id, base_price, stock, max_stock, base_demand, price }
var inventory: Array[Dictionary] = []

## ──────────────────────────────────────────────
##  Factory
## ──────────────────────────────────────────────

static func from_dict(data: Dictionary) -> ShopData:
	var shop := ShopData.new()
	shop.shop_id = data.get("shop_id", "")
	shop.shop_name = data.get("shop_name", "")
	shop.shop_type = data.get("shop_type", "")
	shop.district_id = data.get("district_id", "")
	shop.building_id = data.get("building_id", "")
	var pos_arr: Array = data.get("position", [0, 0, 0])
	shop.position = Vector3(
		float(pos_arr[0]) if pos_arr.size() > 0 else 0.0,
		float(pos_arr[1]) if pos_arr.size() > 1 else 0.0,
		float(pos_arr[2]) if pos_arr.size() > 2 else 0.0
	)
	var hours: Array = data.get("open_hours", [6.0, 23.0])
	shop.open_hours = Vector2(
		float(hours[0]) if hours.size() > 0 else 6.0,
		float(hours[1]) if hours.size() > 1 else 23.0
	)
	shop.money_reserve = float(data.get("money_reserve", 5000.0))
	shop.price_modifier = float(data.get("price_modifier", 1.0))
	for item in data.get("inventory", []):
		var entry: Dictionary = {
			"item_id": item.get("item_id", ""),
			"base_price": float(item.get("base_price", 0.0)),
			"stock": int(item.get("stock", 0)),
			"max_stock": int(item.get("max_stock", 50)),
			"base_demand": float(item.get("base_demand", 1.0)),
			"price": float(item.get("base_price", 0.0)),  # current dynamic price
		}
		shop.inventory.append(entry)
	return shop

## ──────────────────────────────────────────────
##  Queries
## ──────────────────────────────────────────────

## Returns true if the shop is open at the given hour (0–24 float).
func is_open(current_hour: float) -> bool:
	var start: float = open_hours.x
	var end: float = open_hours.y
	if start <= end:
		return current_hour >= start and current_hour <= end
	else:
		# Handles overnight windows (e.g., gas station 22:00–06:00)
		return current_hour >= start or current_hour <= end

## Get the current dynamic price for an item (base × modifier × scarcity).
func get_item_price(item_id: String) -> float:
	for item in inventory:
		if item["item_id"] == item_id:
			return item["price"] * price_modifier
	return 0.0

## Get the base price for an item (without modifier).
func get_item_base_price(item_id: String) -> float:
	for item in inventory:
		if item["item_id"] == item_id:
			return item["base_price"]
	return 0.0

## Get an inventory entry by item_id, or empty dict.
func get_item_entry(item_id: String) -> Dictionary:
	for item in inventory:
		if item["item_id"] == item_id:
			return item
	return {}

## Returns true if the shop has at least `quantity` of the item in stock.
func has_item(item_id: String, quantity: int = 1) -> bool:
	for item in inventory:
		if item["item_id"] == item_id and item["stock"] >= quantity:
			return true
	return false

## Get a list of all item_ids in this shop's inventory.
func get_item_ids() -> Array[String]:
	var ids: Array[String] = []
	for item in inventory:
		ids.append(item["item_id"])
	return ids

## ──────────────────────────────────────────────
##  Transactions
## ──────────────────────────────────────────────

## Attempt to purchase `quantity` of an item from the shop.
## Returns the total cost on success, or -1.0 on failure.
func purchase_item(item_id: String, quantity: int = 1) -> float:
	for item in inventory:
		if item["item_id"] == item_id and item["stock"] >= quantity:
			item["stock"] -= quantity
			return item["price"] * price_modifier * quantity
	return -1.0

## Player sells an item to the shop. Shops buy at 70% of market price.
## Returns the payout on success, or -1.0 if the shop can't afford it.
func sell_item_to_shop(item_id: String, quantity: int = 1, unit_price: float = 0.0) -> float:
	var price: float = unit_price if unit_price > 0.0 else get_item_base_price(item_id)
	if price <= 0.0:
		return -1.0
	var payout: float = price * 0.7 * quantity
	if money_reserve < payout:
		return -1.0
	money_reserve -= payout
	# Add stock back if the shop carries this item
	for item in inventory:
		if item["item_id"] == item_id:
			item["stock"] = min(item["max_stock"], item["stock"] + quantity)
			return payout
	# Shop doesn't normally carry it — still accept the sale
	return payout

## ──────────────────────────────────────────────
##  Economy Tick (called by ShopManager on hour_tick)
## ──────────────────────────────────────────────

## Simulate NPC demand reducing stock, adjust prices by scarcity, restock.
func process_economy_tick() -> void:
	for item in inventory:
		# Simulate NPC demand reducing stock
		var demand: float = randf_range(0.5, 2.0) * item.get("base_demand", 1.0)
		item["stock"] = max(0, int(item["stock"]) - int(demand))

		# Adjust price based on scarcity
		var base_price: float = item["base_price"]
		var max_stock: int = item.get("max_stock", 50)
		var stock_ratio: float = float(item["stock"]) / float(max_stock) if max_stock > 0 else 0.0
		if stock_ratio < 0.2:
			item["price"] = base_price * 1.3  # scarce = expensive
		elif stock_ratio > 0.8:
			item["price"] = base_price * 0.9  # surplus = cheaper
		else:
			item["price"] = base_price

		# Restock slowly
		item["stock"] = min(max_stock, int(item["stock"]) + 5)

	# Replenish money reserve slowly (shops earn from NPC traffic)
	money_reserve = min(money_reserve + 200.0, money_reserve + 500.0)

## ──────────────────────────────────────────────
##  Persistence
## ──────────────────────────────────────────────

func serialize() -> Dictionary:
	var inv_arr: Array = []
	for item in inventory:
		inv_arr.append({
			"item_id": item["item_id"],
			"base_price": item["base_price"],
			"stock": item["stock"],
			"max_stock": item["max_stock"],
			"base_demand": item["base_demand"],
			"price": item["price"],
		})
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
		"inventory": inv_arr,
	}
