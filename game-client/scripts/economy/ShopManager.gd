## ShopManager.gd
## Coordinates shop registration, economy ticks, and UI interaction.
## Stage 3.5 Step 5 (Local Economy Model) — shop-side coordinator.
extends Node
class_name ShopManager

## ──────────────────────────────────────────────
##  Constants
## ──────────────────────────────────────────────

const SHOPS_DATA_PATH := "res://data/shops/nova_city_shops.json"

## ──────────────────────────────────────────────
##  Signals
## ──────────────────────────────────────────────

signal shops_loaded(count: int)
signal shop_ui_opened(shop_data: ShopData)
signal shop_ui_closed()

## ──────────────────────────────────────────────
##  State
## ──────────────────────────────────────────────

var _shops: Dictionary = {}  # shop_id → ShopData
var _is_loaded: bool = false

## ──────────────────────────────────────────────
##  Lifecycle
## ──────────────────────────────────────────────

func _ready() -> void:
	# Connect to WorldTime hour_tick for economy processing
	if has_node("/root/WorldTime"):
		if not WorldTime.hour_tick.is_connected(_on_hour_tick):
			WorldTime.hour_tick.connect(_on_hour_tick)
	# Load shop data
	load_shop_data()

func _exit_tree() -> void:
	if has_node("/root/WorldTime"):
		if WorldTime.hour_tick.is_connected(_on_hour_tick):
			WorldTime.hour_tick.disconnect(_on_hour_tick)

## ──────────────────────────────────────────────
##  Data Loading
## ──────────────────────────────────────────────

func load_shop_data() -> int:
	_shops.clear()
	if not FileAccess.file_exists(SHOPS_DATA_PATH):
		_log_warn("Shop data file not found: %s" % SHOPS_DATA_PATH)
		_is_loaded = false
		return 0
	var file := FileAccess.open(SHOPS_DATA_PATH, FileAccess.READ)
	if file == null:
		_log_error("Failed to open shop data file: %s" % SHOPS_DATA_PATH)
		_is_loaded = false
		return 0
	var json_text := file.get_as_text()
	file.close()
	var json := JSON.new()
	var err := json.parse(json_text)
	if err != OK:
		_log_error("JSON parse error in shop data: %s (line %d)" % [json.get_error_message(), json.get_error_line()])
		_is_loaded = false
		return 0
	var data: Dictionary = json.data
	var shops_array: Array = data.get("shops", [])
	for shop_dict in shops_array:
		var shop := ShopData.from_dict(shop_dict)
		if shop.shop_id != "":
			_shops[shop.shop_id] = shop
			# Register items in EconomyManager market if not already registered
			_register_shop_items_in_market(shop)
	_is_loaded = true
	_log_info("Loaded %d shops from %s" % [_shops.size(), SHOPS_DATA_PATH])
	shops_loaded.emit(_shops.size())
	return _shops.size()

func _register_shop_items_in_market(shop: ShopData) -> void:
	if not has_node("/root/EconomyManager"):
		return
	for item in shop.inventory:
		var item_id: String = item["item_id"]
		if EconomyManager.get_market_info(item_id) == null:
			EconomyManager.register_item(item_id, item["base_price"], 0.1)

## ──────────────────────────────────────────────
##  Shop Queries
## ──────────────────────────────────────────────

func get_shop(shop_id: String) -> ShopData:
	return _shops.get(shop_id, null)

func get_shops() -> Array:
	return _shops.values()

func get_shop_count() -> int:
	return _shops.size()

func get_shops_by_type(shop_type: String) -> Array:
	var result: Array = []
	for shop in _shops.values():
		if shop.shop_type == shop_type:
			result.append(shop)
	return result

func get_shops_in_district(district_id: String) -> Array:
	var result: Array = []
	for shop in _shops.values():
		if shop.district_id == district_id:
			result.append(shop)
	return result

func is_loaded() -> bool:
	return _is_loaded

## ──────────────────────────────────────────────
##  Player Transactions
## ──────────────────────────────────────────────

## Player buys from shop. Returns true on success.
func player_buy(shop_id: String, item_id: String, quantity: int = 1) -> bool:
	var shop := get_shop(shop_id)
	if shop == null:
		_log_warn("Shop not found: %s" % shop_id)
		return false
	if not shop.has_item(item_id, quantity):
		_log_debug("Shop %s has insufficient stock of %s" % [shop_id, item_id])
		return false
	var cost := shop.purchase_item(item_id, quantity)
	if cost <= 0.0:
		return false
	# Deduct from player
	GameManager.add_player_money(-cost)
	_log_info("Player bought %d× %s from %s for %.2f" % [quantity, item_id, shop.shop_name, cost])
	# Record in EconomyManager
	if has_node("/root/EconomyManager"):
		EconomyManager.purchase(
			GameManager.player_data.get("player_id", "player"),
			shop_id, item_id, quantity
		)
	return true

## Player sells to shop. Returns true on success.
func player_sell(shop_id: String, item_id: String, quantity: int = 1) -> bool:
	var shop := get_shop(shop_id)
	if shop == null:
		_log_warn("Shop not found: %s" % shop_id)
		return false
	var payout := shop.sell_item(item_id, quantity)
	if payout <= 0.0:
		_log_debug("Shop %s cannot buy %s (insufficient reserve or no item)" % [shop_id, item_id])
		return false
	# Add to player
	GameManager.add_player_money(payout)
	_log_info("Player sold %d× %s to %s for %.2f" % [quantity, item_id, shop.shop_name, payout])
	# Record in EconomyManager
	if has_node("/root/EconomyManager"):
		EconomyManager.sell(
			GameManager.player_data.get("player_id", "player"),
			shop_id, item_id, quantity
		)
	return true

## ──────────────────────────────────────────────
##  UI
## ──────────────────────────────────────────────

func open_shop_ui(shop_data: ShopData) -> void:
	shop_ui_opened.emit(shop_data)
	_log_debug("Opening shop UI for: %s" % shop_data.shop_name)

func close_shop_ui() -> void:
	shop_ui_closed.emit()
	_log_debug("Shop UI closed")

## ──────────────────────────────────────────────
##  Economy Tick
## ──────────────────────────────────────────────

func _on_hour_tick(game_hour: int) -> void:
	for shop in _shops.values():
		shop.process_economy_tick()
	_log_debug("Processed economy tick for %d shops (hour %d)" % [_shops.size(), game_hour])

## ──────────────────────────────────────────────
##  Serialization
## ──────────────────────────────────────────────

func serialize() -> Dictionary:
	var shops_data: Dictionary = {}
	for shop_id in _shops.keys():
		shops_data[shop_id] = _shops[shop_id].serialize()
	return {
		"shops": shops_data,
	}

func deserialize(data: Dictionary) -> void:
	var shops_data: Dictionary = data.get("shops", {})
	for shop_id in shops_data.keys():
		var shop := ShopData.from_dict(shops_data[shop_id])
		_shops[shop_id] = shop
	_is_loaded = _shops.size() > 0

func clear_all() -> void:
	_shops.clear()
	_is_loaded = false

## ──────────────────────────────────────────────
##  Logging
## ──────────────────────────────────────────────

func _log_debug(msg: String) -> void:
	if has_node("/root/DebugManager"):
		DebugManager.log_debug("ShopManager", msg)

func _log_info(msg: String) -> void:
	if has_node("/root/DebugManager"):
		DebugManager.log_info("ShopManager", msg)

func _log_warn(msg: String) -> void:
	if has_node("/root/DebugManager"):
		DebugManager.log_warn("ShopManager", msg)

func _log_error(msg: String) -> void:
	if has_node("/root/DebugManager"):
		DebugManager.log_error("ShopManager", msg)
