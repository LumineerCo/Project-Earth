extends Node2D

const SaveManagerScript := preload("res://scripts/save_manager.gd")

@onready var player: CharacterBody2D = $Player
@onready var debug_label = $DebugLabel
@onready var interactables_root: Node2D = $Interactables
@onready var npc_manager = $NPCManager

var save_manager
var world_state := {
	"clock_minutes": 8 * 60,
	"active_zone": "district_old_market",
	"quality_profile": "desktop_dev",
}
var save_key_was_down := false
var load_key_was_down := false

func _ready() -> void:
	save_manager = SaveManagerScript.new()
	add_child(save_manager)
	debug_label.save_status = "F5 save | F9 load | E interact"

func _process(_delta: float) -> void:
	var save_key_is_down := Input.is_key_pressed(KEY_F5)
	var load_key_is_down := Input.is_key_pressed(KEY_F9)
	if save_key_is_down and not save_key_was_down:
		_save_game()
	if load_key_is_down and not load_key_was_down:
		_load_game()
	save_key_was_down = save_key_is_down
	load_key_was_down = load_key_is_down
	if Input.is_action_just_pressed("interact"):
		_interact_with_nearest()
	debug_label.update_overlay(
		player.global_position,
		save_manager.get_schema_version(),
		interactables_root.get_child_count(),
		npc_manager.get_npc_count(),
		npc_manager.get_active_npc_count(player.global_position),
		npc_manager.get_debug_summaries()
	)

func _save_game() -> void:
	var result: Dictionary = save_manager.save_game(player, world_state)
	debug_label.save_status = str(result.get("message", "Unknown save result"))

func _load_game() -> void:
	var result: Dictionary = save_manager.load_game(player)
	if result.get("ok", false):
		world_state = result.get("world", world_state)
	debug_label.save_status = str(result.get("message", "Unknown load result"))

func _interact_with_nearest() -> void:
	var nearest: Node = null
	var nearest_distance := INF
	for child in interactables_root.get_children():
		if not child.has_method("interact"):
			continue
		var distance := player.global_position.distance_to(child.global_position)
		if distance < nearest_distance:
			nearest = child
			nearest_distance = distance
	if nearest != null and nearest_distance <= 96.0:
		debug_label.save_status = nearest.interact(player)
	else:
		debug_label.save_status = "No interactable nearby."
