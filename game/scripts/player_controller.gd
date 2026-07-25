extends CharacterBody2D

@export var speed := 220.0

var last_interaction: String = ""

func _ready() -> void:
	add_to_group("player")

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()

func get_save_state() -> Dictionary:
	return {
		"position": {"x": global_position.x, "y": global_position.y},
		"speed": speed,
		"last_interaction": last_interaction,
	}

func apply_save_state(state: Dictionary) -> void:
	var position_state: Dictionary = state.get("position", {})
	global_position = Vector2(float(position_state.get("x", global_position.x)), float(position_state.get("y", global_position.y)))
	speed = float(state.get("speed", speed))
	last_interaction = str(state.get("last_interaction", ""))
