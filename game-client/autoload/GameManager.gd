## GameManager.gd
## Central game orchestrator — manages game lifecycle, state, and all subsystems.
## Autoload singleton registered as "GameManager".
extends Node
class_name GameManager

## ──────────────────────────────────────────────
##  Enums & Signals
## ──────────────────────────────────────────────

enum GameState {
	BOOTING,
	MAIN_MENU,
	LOADING,
	PLAYING,
	PAUSED,
	SAVING,
	ERROR
}

signal state_changed(new_state: GameState)
signal game_loaded()
signal game_saved()

## ──────────────────────────────────────────────
##  State
## ──────────────────────────────────────────────

var current_state: GameState = GameState.BOOTING
var player_data: Dictionary = {}
var world_seed: int = 0
var game_version: String = "0.0.1-alpha"
var is_online: bool = false

## ──────────────────────────────────────────────
##  Lifecycle
## ──────────────────────────────────────────────

func _ready() -> void:
	_randomize_seed()
	_connect_signals()
	set_state(GameState.BOOTING)
	DebugManager.log_info("GameManager", "Project Earth v%s initialized" % game_version)
	if WorldDesignManager:
		WorldDesignManager.load_design()

func _process(_delta: float) -> void:
	# Pause logic is handled in set_state() on transitions — nothing to do per-frame.
	pass

## ──────────────────────────────────────────────
##  State Management
## ──────────────────────────────────────────────

func set_state(new_state: GameState) -> void:
	if new_state == current_state:
		return
	var old := current_state
	current_state = new_state
	# Handle global pause only on transitions (not every frame)
	get_tree().paused = (new_state == GameState.PAUSED)
	state_changed.emit(new_state)
	DebugManager.log_info("GameManager", "State: %s → %s" % [_state_name(old), _state_name(new_state)])

func _state_name(s: GameState) -> String:
	return GameState.keys()[s]

## ──────────────────────────────────────────────
##  Game Lifecycle
## ──────────────────────────────────────────────

func start_new_game(player_name: String = "Player") -> void:
	set_state(GameState.LOADING)
	player_data = {
		"player_id": _generate_uuid(),
		"name": player_name,
		"position": Vector3.ZERO,
		"owned_properties": [],
		"owned_vehicles": [],
		"money": 0.0,
		"bank_balance": 0.0,
	}
	if PlayerStats:
		PlayerStats.reset_to_default()
	if MoneySystem:
		MoneySystem.reset_to_default()
	if InventorySystem:
		InventorySystem.reset_inventory()
	if ItemDatabase:
		ItemDatabase.load_items()
	WorldServerBridge.start_offline()
	set_state(GameState.PLAYING)
	game_loaded.emit()
	DebugManager.log_info("GameManager", "New game started for player: %s" % player_name)

func get_player_money() -> float:
	if MoneySystem:
		return float(MoneySystem.cash)
	return player_data.get("money", 0.0)

func get_player_bank_balance() -> float:
	if MoneySystem:
		return float(MoneySystem.bank_balance)
	return player_data.get("bank_balance", 0.0)

func add_player_money(amount: float) -> void:
	if MoneySystem:
		if amount >= 0:
			MoneySystem.add_cash(int(amount))
		else:
			MoneySystem.spend_cash(int(-amount))
	player_data["money"] = get_player_money()
	player_data["bank_balance"] = get_player_bank_balance()
	DebugManager.log_info("GameManager", "Money: %+.2f → %.2f" % [amount, get_player_money()])

func load_game(save_slot: int = 0) -> void:
	set_state(GameState.LOADING)
	var success := SaveManager.load_game(save_slot)
	if success:
		set_state(GameState.PLAYING)
		game_loaded.emit()
		DebugManager.log_info("GameManager", "Game loaded from slot %d" % save_slot)
	else:
		set_state(GameState.ERROR)
		DebugManager.log_error("GameManager", "Failed to load game from slot %d" % save_slot)

func save_game(save_slot: int = 0) -> void:
	set_state(GameState.SAVING)
	var success := SaveManager.save_game(save_slot)
	if success:
		DebugManager.log_info("GameManager", "Game saved to slot %d" % save_slot)
	else:
		DebugManager.log_error("GameManager", "Failed to save game to slot %d" % save_slot)
	set_state(GameState.PLAYING)
	game_saved.emit()

func pause_game() -> void:
	if current_state == GameState.PLAYING:
		set_state(GameState.PAUSED)

func resume_game() -> void:
	if current_state == GameState.PAUSED:
		set_state(GameState.PLAYING)

func quit_game() -> void:
	if current_state == GameState.PLAYING:
		save_game(0)
	get_tree().quit()

## ──────────────────────────────────────────────
##  Player Data Accessors
## ──────────────────────────────────────────────

func get_player_stat(stat_name: String) -> float:
	return player_data.get(stat_name, 0.0)

func set_player_stat(stat_name: String, value: float) -> void:
	player_data[stat_name] = clamp(value, 0.0, 100.0)

## ──────────────────────────────────────────────
##  Internal Helpers
## ──────────────────────────────────────────────

func _randomize_seed() -> void:
	world_seed = randi()
	seed(world_seed)

func _connect_signals() -> void:
	# Will connect to other managers as they are built
	pass

func _generate_uuid() -> String:
	# Simple UUID v4 generator
	var bytes := PackedByteArray()
	for i in 16:
		bytes.append(randi() % 256)
	# Set version (4) and variant bits
	bytes[6] = (bytes[6] & 0x0F) | 0x40
	bytes[8] = (bytes[8] & 0x3F) | 0x80
	var hex := bytes.hex_encode()
	return "%s-%s-%s-%s-%s" % [hex.substr(0, 8), hex.substr(8, 4), hex.substr(12, 4), hex.substr(16, 4), hex.substr(20, 12)]
