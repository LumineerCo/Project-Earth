## ShopUIManager.gd
## Handles opening and closing shop and ATM UI overlays.
## Stage 4.2 / 4.3 — UI integration scaffolding
extends Node
class_name ShopUIManager

signal shop_ui_opened(shop_data)
signal shop_ui_closed()
signal atm_ui_opened()
signal atm_ui_closed()
signal inventory_ui_opened()
signal inventory_ui_closed()

var _atm_ui: Control = null
var _inventory_ui: Control = null
var _shop_ui: Control = null

func _ready() -> void:
	call_deferred("_connect_shop_manager")

func _connect_shop_manager() -> void:
	if has_node("/root/ShopManager"):
		if not ShopManager.shop_ui_opened.is_connected(_on_shop_ui_opened):
			ShopManager.shop_ui_opened.connect(_on_shop_ui_opened)
		if not ShopManager.shop_ui_closed.is_connected(_on_shop_ui_closed):
			ShopManager.shop_ui_closed.connect(_on_shop_ui_closed)

## Register the instantiated ATM UI node so this manager can toggle it directly.
func register_atm_ui(node: Control) -> void:
	_atm_ui = node
	_log_info("ATM UI node registered")

## Register the instantiated Inventory UI node so this manager can toggle it directly.
func register_inventory_ui(node: Control) -> void:
	_inventory_ui = node
	_log_info("Inventory UI node registered")

## Register the instantiated Shop UI node so this manager can toggle it directly.
func register_shop_ui(node: Control) -> void:
	_shop_ui = node
	_log_info("Shop UI node registered")

func open_shop_ui(shop_data: Dictionary) -> void:
	emit_signal("shop_ui_opened", shop_data)
	if _shop_ui:
		_shop_ui.visible = true
	# Make UI interactive: show mouse and pause the game
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if has_node("/root/GameManager"):
		GameManager.pause_game()
	_log_info("Shop UI opened for %s" % shop_data.get("shop_name", "Unknown"))

func close_shop_ui() -> void:
	emit_signal("shop_ui_closed")
	if _shop_ui:
		_shop_ui.visible = false
	# Restore mouse capture and resume game
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if has_node("/root/GameManager"):
		GameManager.resume_game()
	_log_info("Shop UI closed")

func open_atm_ui() -> void:
	emit_signal("atm_ui_opened")
	if _atm_ui:
		_atm_ui.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if has_node("/root/GameManager"):
		GameManager.pause_game()
	_log_info("ATM UI opened")

func close_atm_ui() -> void:
	emit_signal("atm_ui_closed")
	if _atm_ui:
		_atm_ui.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if has_node("/root/GameManager"):
		GameManager.resume_game()
	_log_info("ATM UI closed")

func open_inventory_ui() -> void:
	emit_signal("inventory_ui_opened")
	if _inventory_ui:
		_inventory_ui.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if has_node("/root/GameManager"):
		GameManager.pause_game()
	_log_info("Inventory UI opened")

func close_inventory_ui() -> void:
	emit_signal("inventory_ui_closed")
	if _inventory_ui:
		_inventory_ui.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if has_node("/root/GameManager"):
		GameManager.resume_game()
	_log_info("Inventory UI closed")

func _on_shop_ui_opened(shop_data: Dictionary) -> void:
	open_shop_ui(shop_data)

func _on_shop_ui_closed() -> void:
	close_shop_ui()

func _log_info(msg: String) -> void:
	if has_node("/root/DebugManager"):
		DebugManager.log_info("ShopUIManager", msg)
