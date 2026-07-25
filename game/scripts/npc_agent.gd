extends CharacterBody2D

@export var npc_id := ""
@export var display_name := "NPC"
@export var role := "resident"
@export var schedule_id := ""
@export var speed := 95.0

var current_action := "idle"
var current_target_id := ""
var next_action := "idle"
var schedule_entries: Array = []
var target_positions := {}
var simulated_minutes := 0
var stuck_seconds := 0.0
var last_position := Vector2.ZERO

func configure(npc_data: Dictionary, schedule_data: Dictionary, location_positions: Dictionary, start_minutes: int) -> void:
	npc_id = str(npc_data.get("id", npc_id))
	display_name = str(npc_data.get("display_name", display_name))
	role = str(npc_data.get("role", role))
	schedule_id = str(npc_data.get("schedule_id", schedule_id))
	schedule_entries = schedule_data.get("entries", [])
	target_positions = location_positions
	simulated_minutes = start_minutes
	last_position = global_position
	_update_schedule_state()

func tick_schedule(minutes: int, delta: float) -> void:
	simulated_minutes = minutes
	_update_schedule_state()
	_move_toward_current_target(delta)
	_update_stuck_state(delta)

func get_debug_summary() -> Dictionary:
	return {
		"id": npc_id,
		"name": display_name,
		"role": role,
		"action": current_action,
		"target": current_target_id,
		"next_action": next_action,
	}

func _update_schedule_state() -> void:
	if schedule_entries.is_empty():
		current_action = "idle"
		current_target_id = ""
		next_action = "idle"
		return
	var selected: Dictionary = schedule_entries[0]
	var next: Dictionary = schedule_entries[0]
	for index in range(schedule_entries.size()):
		var entry: Dictionary = schedule_entries[index]
		if _time_to_minutes(str(entry.get("start", "00:00"))) <= simulated_minutes:
			selected = entry
			next = schedule_entries[(index + 1) % schedule_entries.size()]
	current_action = str(selected.get("action", "idle"))
	current_target_id = str(selected.get("target", ""))
	next_action = str(next.get("action", "idle"))

func _move_toward_current_target(delta: float) -> void:
	if not target_positions.has(current_target_id):
		velocity = Vector2.ZERO
		return
	var target: Vector2 = target_positions[current_target_id]
	var to_target := target - global_position
	if to_target.length() <= 8.0:
		velocity = Vector2.ZERO
		return
	velocity = to_target.normalized() * speed
	move_and_slide()

func _update_stuck_state(delta: float) -> void:
	if global_position.distance_to(last_position) < 0.5 and velocity.length() > 0.0:
		stuck_seconds += delta
	else:
		stuck_seconds = 0.0
	last_position = global_position
	if stuck_seconds > 5.0 and target_positions.has(current_target_id):
		global_position = target_positions[current_target_id]
		stuck_seconds = 0.0

func _time_to_minutes(value: String) -> int:
	var parts := value.split(":")
	if parts.size() != 2:
		return 0
	return int(parts[0]) * 60 + int(parts[1])
