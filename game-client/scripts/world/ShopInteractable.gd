## ShopInteractable.gd
## An Area3D trigger zone placed at a shop's entrance. Detects the player
## entering/leaving and exposes an interact() method for the interaction
## system to invoke (e.g., when the player presses the use key).
extends Area3D

## ──────────────────────────────────────────────
##  Signals
## ──────────────────────────────────────────────

signal player_entered_shop(shop_id: String)
signal player_exited_shop(shop_id: String)
signal interaction_requested(shop_id: String)

## ──────────────────────────────────────────────
##  Configuration
## ──────────────────────────────────────────────

const INTERACTION_RADIUS := 3.0  # Meters around the shop entrance
const PROMPT_TEXT := "[E] Shop"

## ──────────────────────────────────────────────
##  State
## ──────────────────────────────────────────────

var _shop: ShopData = null
var _shop_id: String = ""
var _player_inside: bool = false
var _prompt_label: Label3D = null

## ──────────────────────────────────────────────
##  Lifecycle
## ──────────────────────────────────────────────

func _ready() -> void:
	# Build collision shape (sphere trigger)
	var col := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = INTERACTION_RADIUS
	col.shape = sphere
	add_child(col)

	# Build a floating prompt label
	_prompt_label = Label3D.new()
	_prompt_label.text = PROMPT_TEXT
	_prompt_label.position = Vector3(0, 2.5, 0)
	_prompt_label.font_size = 48
	_prompt_label.outline_size = 12
	_prompt_label.outline_modulate = Color.BLACK
	_prompt_label.modulate = Color.WHITE
	_prompt_label.visible = false
	_prompt_label.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_prompt_label)

	# Connect body signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Position at the shop entrance
	if _shop:
		global_position = _shop.position

## ──────────────────────────────────────────────
##  Setup
## ──────────────────────────────────────────────

## Configure this interactable with a ShopData instance.
func setup(shop: ShopData) -> void:
	_shop = shop
	_shop_id = shop.shop_id
	# Position will be applied in _ready once in the tree; also set now in case
	# _ready already ran (setup called before add_child).
	global_position = shop.position

## ──────────────────────────────────────────────
##  Interaction
## ──────────────────────────────────────────────

## Called by the player interaction system when the player presses the use key
## while inside this zone. Returns the shop_id so the UI can open the shop.
func interact(_player: Node) -> String:
	if _shop_id.is_empty():
		return ""
	interaction_requested.emit(_shop_id)
	return _shop_id

## Returns true if the shop is currently open for business.
func is_shop_open() -> bool:
	if _shop == null:
		return false
	var hour: float = WorldTime.get_hour_float() if WorldTime else 12.0
	return _shop.is_open(hour)

## Returns the ShopData this interactable represents.
func get_shop() -> ShopData:
	return _shop

## Returns true if the player is currently inside the interaction zone.
func is_player_inside() -> bool:
	return _player_inside

## ──────────────────────────────────────────────
##  Signal Handlers
## ──────────────────────────────────────────────

func _on_body_entered(body: Node) -> void:
	if not _is_player(body):
		return
	_player_inside = true
	if _prompt_label:
		_prompt_label.visible = true
	player_entered_shop.emit(_shop_id)
	if DebugManager:
		DebugManager.log_debug("ShopInteractable", "Player entered %s" % _shop_id)

func _on_body_exited(body: Node) -> void:
	if not _is_player(body):
		return
	_player_inside = false
	if _prompt_label:
		_prompt_label.visible = false
	player_exited_shop.emit(_shop_id)
	if DebugManager:
		DebugManager.log_debug("ShopInteractable", "Player exited %s" % _shop_id)

## Heuristic: detect the player by group, class, or name.
func _is_player(body: Node) -> bool:
	if body == null:
		return false
	if body.is_in_group("player"):
		return true
	if body.get("player_id") != null:
		return true
	if body.name.to_lower().find("player") >= 0:
		return true
	return false
