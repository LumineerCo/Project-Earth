## BuildingBase.gd
## Base class for all buildings in Nova City.
## Handles modular shell rendering, dynamic interior streaming, and interaction.
## Stage 3.3 (Buildings & Modular Assets)
extends StaticBody3D
class_name BuildingBase

## ──────────────────────────────────────────────
##  Building Categories (from Stage 3.3 plan)
## ──────────────────────────────────────────────

enum Category {
	FULL_INTERIOR,     ## Category A — Player houses, shops, police, banks
	PARTIAL_INTERIOR,  ## Category B — Corner stores, cafés (shop fronts)
	SHELL,             ## Category C — Skyscrapers, warehouses (sealed)
}

## ──────────────────────────────────────────────
##  Exports
## ──────────────────────────────────────────────

@export var building_id: String = ""
@export var building_name: String = "Unnamed Building"
@export var category: Category = Category.SHELL
@export var district_id: String = ""
@export var zone_type: String = ""  ## commercial_high, residential_low, etc.

## Interior scene to load dynamically (Category A only)
@export_file("*.tscn") var interior_scene_path: String = ""

## Building dimensions (meters)
@export var width: float = 12.0
@export var depth: float = 12.0
@export var height: float = 15.0
@export var floors: int = 4

## Interaction
@export var is_enterable: bool = false
@export var interaction_prompt: String = "Enter"

## ──────────────────────────────────────────────
##  State
## ──────────────────────────────────────────────

var loaded_interior: Node = null
var _portal_sensor: Area3D = null
var _shell: Node3D = null
var _is_interior_loaded: bool = false

## ──────────────────────────────────────────────
##  Signals
## ──────────────────────────────────────────────

signal interior_loaded(building_id: String)
signal interior_unloaded(building_id: String)
signal player_entered(building_id: String)
signal player_exited(building_id: String)

## ──────────────────────────────────────────────
##  Lifecycle
## ──────────────────────────────────────────────

func _ready() -> void:
	# Find portal sensor and shell nodes if they exist in the scene
	_portal_sensor = get_node_or_null("PortalSensor")
	_shell = get_node_or_null("Shell")

	if _portal_sensor:
		_portal_sensor.body_entered.connect(_on_body_entered)
		_portal_sensor.body_exited.connect(_on_body_exited)

	# Category A buildings are enterable if they have an interior scene
	if category == Category.FULL_INTERIOR and interior_scene_path != "":
		is_enterable = true

## ──────────────────────────────────────────────
##  Interior Streaming
## ──────────────────────────────────────────────

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("Player"):
		return
	player_entered.emit(building_id)
	if is_enterable and interior_scene_path != "" and not _is_interior_loaded:
		_load_interior()

func _on_body_exited(body: Node3D) -> void:
	if not body.is_in_group("Player"):
		return
	player_exited.emit(building_id)
	if _is_interior_loaded:
		_unload_interior()

func _load_interior() -> void:
	if _is_interior_loaded:
		return
	_log_debug("Loading interior for: %s" % building_id)
	var scene_res := load(interior_scene_path)
	if scene_res == null:
		_log_error("Failed to load interior scene: %s" % interior_scene_path)
		return
	loaded_interior = scene_res.instantiate()
	add_child(loaded_interior)
	_is_interior_loaded = true
	# Hide interior-facing shell surfaces to avoid z-fighting
	if _shell and _shell.has_node("Walls_InteriorBack"):
		_shell.get_node("Walls_InteriorBack").hide()
	interior_loaded.emit(building_id)

func _unload_interior() -> void:
	if not _is_interior_loaded or loaded_interior == null:
		return
	_log_debug("Unloading interior: %s" % building_id)
	loaded_interior.queue_free()
	loaded_interior = null
	_is_interior_loaded = false
	if _shell and _shell.has_node("Walls_InteriorBack"):
		_shell.get_node("Walls_InteriorBack").show()
	interior_unloaded.emit(building_id)

## ──────────────────────────────────────────────
##  Public API
## ──────────────────────────────────────────────

func is_interior_loaded() -> bool:
	return _is_interior_loaded

func get_category_name() -> String:
	match category:
		Category.FULL_INTERIOR: return "full_interior"
		Category.PARTIAL_INTERIOR: return "partial_interior"
		Category.SHELL: return "shell"
	return "unknown"

func get_footprint_area() -> float:
	return width * depth

func get_volume() -> float:
	return width * depth * height

func interact(player: Node) -> bool:
	"""Called when player presses interact key near building."""
	if not is_enterable:
		_log_debug("Building %s is not enterable" % building_id)
		return false
	if not _is_interior_loaded:
		_load_interior()
	return true

## ──────────────────────────────────────────────
##  Serialization
## ──────────────────────────────────────────────

func serialize() -> Dictionary:
	return {
		"building_id": building_id,
		"building_name": building_name,
		"category": get_category_name(),
		"district_id": district_id,
		"zone_type": zone_type,
		"position": [global_position.x, global_position.y, global_position.z],
		"rotation_y": global_rotation.y,
		"width": width,
		"depth": depth,
		"height": height,
		"floors": floors,
		"is_enterable": is_enterable,
		"interior_scene_path": interior_scene_path,
		"is_interior_loaded": _is_interior_loaded,
	}

## ──────────────────────────────────────────────
##  Helpers
## ──────────────────────────────────────────────

func _log_debug(msg: String) -> void:
	if Engine.has_singleton("DebugManager") or has_node("/root/DebugManager"):
		DebugManager.log_debug("Building", msg)

func _log_error(msg: String) -> void:
	if Engine.has_singleton("DebugManager") or has_node("/root/DebugManager"):
		DebugManager.log_error("Building", msg)
