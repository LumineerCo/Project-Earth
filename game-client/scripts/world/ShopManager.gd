## ShopManager.gd
## Coordinates all shops in Nova City. Loads shop definitions from JSON,
## registers shop items with the EconomyManager, drives per-shop economy ticks
## on WorldTime.hour_tick, and exposes queries for interaction and UI.
extends Node

## ──────────────────────────────────────────────
##  Signals
## ──────────────────────────────────────────────

signal shops_loaded(count: int)
signal shop_opened(shop_id: String)
signal shop_closed(shop_id: String)
signal shop_transaction(shop_id: String, item_id: String, quantity: int, total: float)

## ──────────────────────────────────────────────
##  Configuration
## ──────────────────────────────────────────────

const SHOPS_DATA_PATH := "res://data/shops/nova_city_shops.json"
const SHOP_INTERACTABLE_SCRIPT := "res://scripts/world/ShopInteractable.gd"

## ──────────────────────────────────────────────
##  State
## ──────────────────────────────────────────────

## shop_id → ShopData
var _shops: Dictionary = {}
var _is_loaded: bool = false
var _interactables: Dictionary = {}  # shop_id → ShopInteractable node

## ──────────────────────────────────────────────
##  Lifecycle
## ──────────────────────────────────────────────

func _ready() -> void:
	if WorldTime and WorldTime.has_signal("hour_tick"):
		WorldTime.hour_tick.connect(_on_hour_tick)
	_log_info("ShopManager ready")

func _on_hour_tick(game_hour: int) -> void:
	# Drive per-shop economy ticks and open/close transitions
	var hour_float: float = WorldTime.get_hour_float() if WorldTime else float(game_hour)
	for shop_id in _shops:
		var shop: ShopData = _shops[shop_id]
		var was_open: bool = shop.is_open(hour_float - 1.0) if hour_float >= 1.0 else shop.is_open(23.0)
		var now_open: bool = shop.is_open(hour_float)
		if now_open and not was_open:
			shop_opened.emit(shop_id)
			_log_debug("Shop opened: %s (%s)" % [shop_id, shop.shop_name])
		elif not now_open and was_open:
			shop_closed.emit(shop_id)
			_log_debug("Shop closed: %s (%s)" % [shop_id, shop.shop_name])
		# Only run economy for open shops
		if now_open:
			shop.process_economy_tick()

## ──────────────────────────────────────────────
##  Data Loading
## ──────────────────────────────────────────────

## Loads shop definitions from JSON. Returns the number of shops loaded.
func load_shop_data() -> int:
	_shops.clear()
	if not FileAccess.file_exists(SHOPS_DATA_PATH):
		_log_warn("Shops data file not found: %s" % SHOPS_DATA_PATH)
		_is_loaded = false
		return 0

	var file := FileAccess.open(SHOPS_DATA_PATH, FileAccess.READ)
	if file == null:
		_log_error("Failed to open shops data: %s" % SHOPS_DATA_PATH)
		_is_loaded = false
		return 0

	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		_log_error("JSON parse error in shops data: %s (line %d)" % [json.get_error_message(), json.get_error_line()])
		_is_loaded = false
		return 0

	var data: Dictionary = json.data
	var shops_arr: Array = data.get("shops", [])
	for shop_dict in shops_arr:
		var shop := ShopData.from_dict(shop_dict)
		if shop.shop_id.is_empty():
			_log_warn("Skipping shop with empty shop_id")
			continue
		_shops[shop.shop_id] = shop
		_register_shop_items_with_economy(shop)

	_is_loaded = true
	_log_info("Loaded %d shops" % _shops.size())
	shops_loaded.emit(_shops.size())
	return _shops.size()

## Register all of a shop's items with the global EconomyManager (if not already).
func _register_shop_items_with_economy(shop: ShopData) -> void:
	if not EconomyManager:
		return
	for item_id in shop.get_item_ids():
		if EconomyManager.get_market_info(item_id).is_empty():
			var base_price: float = shop.get_item_base_price(item_id)
			EconomyManager.register_item(item_id, base_price, 0.1)

## ──────────────────────────────────────────────
##  Interactable Spawning
## ──────────────────────────────────────────────

## Spawns ShopInteractable Area3D nodes for each shop under the given parent.
## Returns the number of interactables created.
func spawn_interactables(parent: Node) -> int:
	if not _is_loaded:
		_log_warn("Cannot spawn interactables — shops not loaded")
		return 0
	if not ResourceLoader.exists(SHOP_INTERACTABLE_SCRIPT):
		_log_warn("ShopInteractable script not found: %s" % SHOP_INTERACTABLE_SCRIPT)
		return 0

	var script := load(SHOP_INTERACTABLE_SCRIPT)
	var count := 0
	for shop_id in _shops:
		var shop: ShopData = _shops[shop_id]
		var interactable := script.new()
		interactable.name = "ShopInteractable_%s" % shop_id
		interactable.setup(shop)
		parent.add_child(interactable)
		_interactables[shop_id] = interactable
		count += 1
	_log_info("Spawned %d shop interactables" % count)
	return count

## Despawns all shop interactables.
func despawn_interactables() -> void:
	for shop_id in _interactables.keys():
		var node: Node = _interactables[shop_id]
		if is_instance_valid(node):
			node.queue_free()
	_interactables.clear()
	_log_debug("Despawned all shop interactables")

## ──────────────────────────────────────────────
##  Queries
## ──────────────────────────────────────────────

func get_shop(shop_id: String) -> ShopData:
	return _shops.get(shop_id, null)

func get_shop_count() -> int:
	return _shops.size()

func get_all_shops() -> Array[ShopData]:
	var arr: Array[ShopData] = []
	for shop_id in _shops:
		arr.append(_shops[shop_id])
	return arr

func get_shops_in_district(district_id: String) -> Array[ShopData]:
	var arr: Array[ShopData] = []
	for shop_id in _shops:
		var shop: ShopData = _shops[shop_id]
		if shop.district_id == district_id:
			arr.append(shop)
	return arr

func get_shops_by_type(shop_type: String) -> Array[ShopData]:
	var arr: Array[ShopData] = []
	for shop_id in _shops:
		var shop: ShopData = _shops[shop_id]
		if shop.shop_type == shop_type:
			arr.append(shop)
	return arr

## Find the nearest open shop to a world position. Returns null if none open.
func get_nearest_open_shop(pos: Vector3) -> ShopData:
	var best: ShopData = null
	var best_dist: float = INF
	var hour: float = WorldTime.get_hour_float() if WorldTime else 12.0
	for shop_id in _shops:
		var shop: ShopData = _shops[shop_id]
		if not shop.is_open(hour):
			continue
		var dist: float = shop.position.distance_to(pos)
		if dist < best_dist:
			best_dist = dist
			best = shop
	return best

## Find the nearest shop of a given type to a world position.
func get_nearest_shop_of_type(shop_type: String, pos: Vector3) -> ShopData:
	var best: ShopData = null
	var best_dist: float = INF
	for shop_id in _shops:
		var shop: ShopData = _shops[shop_id]
		if shop.shop_type != shop_type:
			continue
		var dist: float = shop.position.distance_to(pos)
		if dist < best_dist:
			best_dist = dist
			best = shop
	return best

func get_interactable(shop_id: String) -> Node:
	return _interactables.get(shop_id, null)

func is_loaded() -> bool:
	return _is_loaded

## ──────────────────────────────────────────────
##  Player Transactions
## ──────────────────────────────────────────────

## Player buys an item from a shop. Returns true on success.
func player_buy(shop_id: String, item_id: String, quantity: int = 1) -> bool:
	var shop: ShopData = get_shop(shop_id)
	if shop == null:
		_log_warn("player_buy: unknown shop %s" % shop_id)
		return false
	var hour: float = WorldTime.get_hour_float() if WorldTime else 12.0
	if not shop.is_open(hour):
		_log_warn("player_buy: shop %s is closed" % shop_id)
		return false
	var cost: float = shop.purchase_item(item_id, quantity)
	if cost < 0.0:
		_log_warn("player_buy: %s out of stock or unavailable" % item_id)
		return false
	if GameManager:
		GameManager.add_player_money(-cost)
	# Record with global economy
	if EconomyManager:
		var player_id: String = GameManager.player_data.get("player_id", "player") if GameManager else "player"
		EconomyManager.purchase(player_id, shop_id, item_id, quantity)
	shop_transaction.emit(shop_id, item_id, quantity, cost)
	_log_info("Player bought %d× %s from %s for %.2f" % [quantity, item_id, shop_id, cost])
	return true

## Player sells an item to a shop. Returns true on success.
func player_sell(shop_id: String, item_id: String, quantity: int = 1) -> bool:
	var shop: ShopData = get_shop(shop_id)
	if shop == null:
		_log_warn("player_sell: unknown shop %s" % shop_id)
		return false
	var hour: float = WorldTime.get_hour_float() if WorldTime else 12.0
	if not shop.is_open(hour):
		_log_warn("player_sell: shop %s is closed" % shop_id)
		return false
	var payout: float = shop.sell_item_to_shop(item_id, quantity)
	if payout < 0.0:
		_log_warn("player_sell: %s cannot accept sale (insufficient reserve)" % shop_id)
		return false
	if GameManager:
		GameManager.add_player_money(payout)
	if EconomyManager:
		var player_id: String = GameManager.player_data.get("player_id", "player") if GameManager else "player"
		EconomyManager.sell(player_id, shop_id, item_id, quantity)
	shop_transaction.emit(shop_id, item_id, -quantity, payout)
	_log_info("Player sold %d× %s to %s for %.2f" % [quantity, item_id, shop_id, payout])
	return true

## ──────────────────────────────────────────────
##  Persistence
## ──────────────────────────────────────────────

func serialize() -> Dictionary:
	var shops_arr: Array = []
	for shop_id in _shops:
		shops_arr.append(_shops[shop_id].serialize())
	return {
		"shops": shops_arr,
	}

func deserialize(data: Dictionary) -> void:
	_shops.clear()
	for shop_dict in data.get("shops", []):
		var shop := ShopData.from_dict(shop_dict)
		if not shop.shop_id.is_empty():
			_shops[shop.shop_id] = shop
	_is_loaded = _shops.size() > 0
	_log_info("Deserialized %d shops" % _shops.size())

## ──────────────────────────────────────────────
##  Logging
## ──────────────────────────────────────────────

func _log_debug(msg: String) -> void:
	if DebugManager: DebugManager.log_debug("ShopManager", msg)

func _log_info(msg: String) -> void:
	if DebugManager: DebugManager.log_info("ShopManager", msg)

func _log_warn(msg: String) -> void:
	if DebugManager: DebugManager.log_warn("ShopManager", msg)

func _log_error(msg: String) -> void:
	if DebugManager: DebugManager.log_error("ShopManager", msg)
