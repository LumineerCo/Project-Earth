## EconomyManager.gd
## Simulates a living economy — prices fluctuate based on supply/demand,
## NPC transactions feed back into market state. Supports real-life activities
## like jobs, shopping, property, and banking.
extends Node
class_name EconomyManager

## ──────────────────────────────────────────────
##  Signals
## ──────────────────────────────────────────────

signal price_changed(item_id: String, old_price: float, new_price: float)
signal transaction_completed(buyer_id: String, seller_id: String, item_id: String, amount: float)
signal market_tick()

## ──────────────────────────────────────────────
##  Configuration
## ──────────────────────────────────────────────

const MARKET_TICK_INTERVAL := 3600.0  # Game seconds between market updates (1 game hour)
const PRICE_VOLATILITY := 0.05  # Max % change per tick
const MAX_PRICE_HISTORY := 24  # Keep 24 ticks of price history

## ──────────────────────────────────────────────
##  State
## ──────────────────────────────────────────────

## item_id → {base_price, current_price, supply, demand, volatility, history: Array[float]}
var _market: Dictionary = {}
var _tick_timer: float = 0.0
var _total_transactions: int = 0

## ──────────────────────────────────────────────
##  Lifecycle
## ──────────────────────────────────────────────

func _ready() -> void:
	_load_market_data()
	DebugManager.log_info("EconomyManager", "Initialized with %d items" % _market.size())

func _process(delta: float) -> void:
	if not WorldTime:
		return
	_tick_timer += delta * WorldTime.time_scale
	if _tick_timer >= MARKET_TICK_INTERVAL:
		_tick_timer = 0.0
		_update_market()

## ──────────────────────────────────────────────
##  Market Data Management
## ──────────────────────────────────────────────

func register_item(item_id: String, base_price: float, volatility: float = 0.1) -> void:
	_market[item_id] = {
		"base_price": base_price,
		"current_price": base_price,
		"supply": 100.0,
		"demand": 100.0,
		"volatility": volatility,
		"history": [base_price],
	}
	DebugManager.log_debug("EconomyManager", "Registered item %s at base price %.2f" % [item_id, base_price])

func get_price(item_id: String) -> float:
	if not _market.has(item_id):
		return 0.0
	return _market[item_id].current_price

func get_market_info(item_id: String) -> Dictionary:
	return _market.get(item_id, {})

## ──────────────────────────────────────────────
##  Transactions
## ──────────────────────────────────────────────

## Execute a purchase. Returns true if successful.
func purchase(buyer_id: String, seller_id: String, item_id: String, quantity: int = 1) -> bool:
	if not _market.has(item_id):
		DebugManager.log_warn("EconomyManager", "Unknown item: %s" % item_id)
		return false
	
	var item := _market[item_id]
	var total_cost := item.current_price * quantity
	
	# Check buyer funds
	if buyer_id == GameManager.player_data.get("player_id", ""):
		if GameManager.get_player_money() < total_cost:
			DebugManager.log_warn("EconomyManager", "Insufficient funds: %.2f < %.2f" % [GameManager.get_player_money(), total_cost])
			return false
		GameManager.add_player_money(-total_cost)
	
	# Update supply/demand
	item.demand += quantity * 0.5
	item.supply -= quantity * 0.3
	
	_total_transactions += 1
	transaction_completed.emit(buyer_id, seller_id, item_id, total_cost)
	
	# Record in memory system
	if MemoryEventBus:
		MemoryEventBus.record_interaction(
			MemoryEventType.PURCHASED_ITEM,
			buyer_id, seller_id, Vector3.ZERO,
			{"item_id": item_id, "quantity": quantity, "price": total_cost}
		)
	
	DebugManager.log_info("EconomyManager", "Transaction: %s bought %d× %s for %.2f from %s" % [buyer_id, quantity, item_id, total_cost, seller_id])
	return true

## Execute a sale (player selling to shop/NPC)
func sell(seller_id: String, buyer_id: String, item_id: String, quantity: int = 1) -> bool:
	if not _market.has(item_id):
		return false
	
	var item := _market[item_id]
	var total_value := item.current_price * quantity * 0.7  # Shops buy at 70% market price
	
	if buyer_id == GameManager.player_data.get("player_id", ""):
		GameManager.add_player_money(-total_value)
	if seller_id == GameManager.player_data.get("player_id", ""):
		GameManager.add_player_money(total_value)
	
	item.supply += quantity * 0.3
	item.demand -= quantity * 0.2
	
	_total_transactions += 1
	transaction_completed.emit(buyer_id, seller_id, item_id, total_value)
	
	if MemoryEventBus:
		MemoryEventBus.record_interaction(
			MemoryEventType.SOLD_ITEM,
			seller_id, buyer_id, Vector3.ZERO,
			{"item_id": item_id, "quantity": quantity, "price": total_value}
		)
	
	return true

## ──────────────────────────────────────────────
##  Market Simulation
## ──────────────────────────────────────────────

func _update_market() -> void:
	for item_id in _market.keys():
		var item: Dictionary = _market[item_id]
		# Price moves toward equilibrium based on supply/demand ratio
		var ratio: float = item.demand / max(item.supply, 1.0)
		var target_price := item.base_price * ratio
		# Apply volatility — random walk toward target
		var drift := (target_price - item.current_price) * 0.1
		var noise := (randf() - 0.5) * 2.0 * item.volatility * item.current_price * PRICE_VOLATILITY
		var old_price: float = item.current_price
		item.current_price = max(0.01, old_price + drift + noise)
		
		# Normalize supply/demand back toward 100
		item.supply = lerp(item.supply, 100.0, 0.05)
		item.demand = lerp(item.demand, 100.0, 0.05)
		
		# Track history
		item.history.append(item.current_price)
		if item.history.size() > MAX_PRICE_HISTORY:
			item.history.pop_front()
		
		if abs(item.current_price - old_price) > 0.01:
			price_changed.emit(item_id, old_price, item.current_price)
	
	market_tick.emit()

## ──────────────────────────────────────────────
##  Jobs & Income
## ──────────────────────────────────────────────

## Pay a salary to an entity (called by job system)
func pay_salary(entity_id: String, amount: float, job_id: String = "") -> void:
	if entity_id == GameManager.player_data.get("player_id", ""):
		GameManager.add_player_money(amount)
	DebugManager.log_debug("EconomyManager", "Salary paid: %s received %.2f for job %s" % [entity_id, amount, job_id])

## ──────────────────────────────────────────────
##  Persistence
## ──────────────────────────────────────────────

func serialize() -> Dictionary:
	return {
		"market": _market,
		"total_transactions": _total_transactions,
	}

func deserialize(data: Dictionary) -> void:
	_market = data.get("market", {})
	_total_transactions = data.get("total_transactions", 0)

func _load_market_data() -> void:
	# In a full implementation, load from data/economy/items/
	# For now, register a few starter items
	register_item("bread", 2.50, 0.08)
	register_item("water_bottle", 1.50, 0.05)
	register_item("gasoline", 1.80, 0.15)
	register_item("coffee", 3.50, 0.10)
	register_item("clothing_basic", 25.00, 0.12)

## ──────────────────────────────────────────────
##  Stats
## ──────────────────────────────────────────────

func get_transaction_count() -> int:
	return _total_transactions

func get_registered_item_count() -> int:
	return _market.size()
