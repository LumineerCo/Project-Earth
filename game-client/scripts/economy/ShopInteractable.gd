## ShopInteractable.gd
## An Area3D placed at a shop entrance. Detects player proximity and
## triggers shop UI interaction. Stage 3.5 Step 4.
extends Area3D
class_name ShopInteractable

## ──────────────────────────────────────────────
##  Exports
## ──────────────────────────────────────────────

@export var shop_id: String = ""
@export var shop_name: String = ""
@export var shop_type: String = ""
@export var interaction_prompt: String = "Press E to enter"

## ──────────────────────────────────────────────
##  State
## ──────────────────────────────────────────────

var _shop_data: ShopData = null
var _player_inside: bool = false
var _prompt_label: Label3D = null

## ──────────────────────────────────────────────
##  Signals
## ──────────────────────────────────────────────

signal shop_entered(shop_data: ShopData)
signal shop_exited(shop_data: ShopData)

## ──────────────────────────────────────────────
##  Lifecycle
## ──────────────────────────────────────────────

func _ready() -> void:
	# Create prompt label if not present
	_prompt_label = get_node_or_null("PromptLabel")
	if _prompt_label == null:
		_prompt_label = Label3D.new()
		_prompt_label.name = "PromptLabel"
		_prompt_label.font_size = 48
		_prompt_label.outline_size = 12
		_prompt_label.outline_modulate = Color.BLACK
		_prompt_label.position = Vector3(0, 3.0, 0)
		_prompt_label.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(_prompt_label)
	_prompt_label.visible = false
	# Connect body signals
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)
	# Load shop data from ShopManager if available
	if shop_id != "" and has_node("/root/ShopManager"):
		_shop_data = ShopManager.get_shop(shop_id)
		if _shop_data:
			shop_name = _shop_data.shop_name
			shop_type = _shop_data.shop_type

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and _player_inside:
		_open_shop()

## ──────────────────────────────────────────────
##  Public API
## ──────────────────────────────────────────────

func set_shop_data(data: ShopData) -> void:
	_shop_data = data
	if data:
		shop_id = data.shop_id
		shop_name = data.shop_name
		shop_type = data.shop_type

func get_shop_data() -> ShopData:
	return _shop_data

## ──────────────────────────────────────────────
##  Interaction
## ──────────────────────────────────────────────

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("Player"):
		return
	_player_inside = true
	_update_prompt()
	shop_entered.emit(_shop_data)

func _on_body_exited(body: Node3D) -> void:
	if not body.is_in_group("Player"):
		return
	_player_inside = false
	if _prompt_label:
		_prompt_label.visible = false
	shop_exited.emit(_shop_data)

func _update_prompt() -> void:
	if not _prompt_label:
		return
	if _shop_data == null:
		_prompt_label.text = "%s\n(Closed)" % shop_name
		_prompt_label.visible = true
		return
	var hour := _get_current_hour()
	if _shop_data.is_open(hour):
		_prompt_label.text = "%s\n%s" % [shop_name, interaction_prompt]
		_prompt_label.modulate = Color.WHITE
	else:
		_prompt_label.text = "%s\n(Closed)" % shop_name
		_prompt_label.modulate = Color(0.7, 0.7, 0.7)
	_prompt_label.visible = true

func _open_shop() -> void:
	if _shop_data == null:
		_show_notification("This shop is not available.")
		return
	var hour := _get_current_hour()
	if not _shop_data.is_open(hour):
		_show_notification("The shop is closed right now.")
		return
	# Emit signal for UI system to handle
	shop_entered.emit(_shop_data)
	# If ShopManager exists, let it handle UI
	if has_node("/root/ShopManager"):
		ShopManager.open_shop_ui(_shop_data)
	_log_debug("Player opened shop: %s" % _shop_data.shop_name)

## ──────────────────────────────────────────────
##  Helpers
## ──────────────────────────────────────────────

func _get_current_hour() -> float:
	if has_node("/root/WorldTime"):
		return WorldTime.get_hour_float()
	return 12.0  # Default to noon

func _show_notification(msg: String) -> void:
	_log_debug(msg)

func _log_debug(msg: String) -> void:
	if has_node("/root/DebugManager"):
		DebugManager.log_debug("ShopInteractable", msg)
