## NPCBase.gd
## A pedestrian NPC with a finite state machine for wandering behavior.
## Stage 3.4 Step 4 (Wandering AI State Machine)
extends CharacterBody3D

## ──────────────────────────────────────────────
##  Configuration
## ──────────────────────────────────────────────

const GRAVITY := 9.8
const WANDER_RADIUS := 15.0
const IDLE_MIN := 2.0
const IDLE_MAX := 8.0

## ──────────────────────────────────────────────
##  State
## ──────────────────────────────────────────────

var data: NPCData = null
var state: String = "idle"  # idle, walking, fleeing, talking
var target_position: Vector3 = Vector3.ZERO
var idle_timer: float = 0.0
var _brain: NPCBrain = null
var _schedule: NPCSchedule = null
var _navigation_agent: NavigationAgent3D = null

## ──────────────────────────────────────────────
##  Lifecycle
## ──────────────────────────────────────────────

func _ready() -> void:
	add_to_group("npc")
	# Set up NavigationAgent3D
	_navigation_agent = NavigationAgent3D.new()
	_navigation_agent.path_desired_distance = 1.0
	_navigation_agent.target_desired_distance = 1.5
	_navigation_agent.avoidance_enabled = true
	_navigation_agent.radius = 0.4
	_navigation_agent.avoidance_priority = 1.0
	add_child(_navigation_agent)
	_navigation_agent.velocity_computed.connect(_on_velocity_computed)
	
	# Attach a brain for memory/relationship tracking
	_brain = NPCBrain.new()
	_brain.npc_id = data.npc_id if data else "npc_unknown"
	_brain.npc_name = data.full_name() if data else "Unknown"
	add_child(_brain)
	# Attach a schedule for time-based behavior
	_schedule = NPCSchedule.new()
	_schedule.name = "NPCSchedule"
	add_child(_schedule)
	_schedule.initialize(self)
	_pick_new_wander_target()
	DebugManager.log_debug("NPCBase", "Spawned %s (%s)" % [_brain.npc_name, data.npc_type if data else "?"])

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	match state:
		"idle":    _state_idle(delta)
		"walking": _state_walking(delta)
		"fleeing": _state_fleeing(delta)
	move_and_slide()

## ──────────────────────────────────────────────
##  Public API
## ──────────────────────────────────────────────

func set_data(new_data: NPCData) -> void:
	data = new_data

## Flee from a threat position (e.g. player attacking).
func flee_from(threat: Vector3) -> void:
	var away := (global_position - threat).normalized()
	target_position = global_position + away * WANDER_RADIUS
	state = "fleeing"
	if data:
		data.current_state = "fleeing"

## ──────────────────────────────────────────────
##  State Machine
## ──────────────────────────────────────────────

func _state_idle(delta: float) -> void:
	idle_timer -= delta
	if idle_timer <= 0.0:
		_pick_new_wander_target()
		state = "walking"
		if data:
			data.current_state = "walking"

func _state_walking(delta: float) -> void:
	if _navigation_agent.target_position != target_position:
		_navigation_agent.target_position = target_position
		
	if _navigation_agent.is_navigation_finished():
		state = "idle"
		idle_timer = randf_range(IDLE_MIN, IDLE_MAX)
		if data:
			data.current_state = "idle"
		velocity = Vector3.ZERO
		return
		
	var next_pos := _navigation_agent.get_next_path_position()
	var dir := next_pos - global_position
	dir.y = 0
	
	var base_speed := data.walk_speed if data else 1.4
	var speed_mult := 1.0
	if _schedule:
		speed_mult = _schedule.get_speed_multiplier()
	var speed := base_speed * speed_mult
	
	var desired_velocity := dir.normalized() * speed
	_navigation_agent.set_velocity(desired_velocity)
	
	# Face direction
	if dir.length() > 0.1:
		look_at(Vector3(next_pos.x, global_position.y, next_pos.z), Vector3.UP)

func _state_fleeing(delta: float) -> void:
	if _navigation_agent.target_position != target_position:
		_navigation_agent.target_position = target_position
		
	if _navigation_agent.is_navigation_finished():
		state = "idle"
		idle_timer = randf_range(IDLE_MIN, IDLE_MAX)
		if data:
			data.current_state = "idle"
		velocity = Vector3.ZERO
		return
		
	var next_pos := _navigation_agent.get_next_path_position()
	var dir := next_pos - global_position
	dir.y = 0
	
	var speed := data.run_speed if data else 4.0
	var desired_velocity := dir.normalized() * speed
	_navigation_agent.set_velocity(desired_velocity)
	
	if dir.length() > 0.1:
		look_at(Vector3(next_pos.x, global_position.y, next_pos.z), Vector3.UP)

func _on_velocity_computed(safe_velocity: Vector3) -> void:
	velocity.x = safe_velocity.x
	velocity.z = safe_velocity.z

## ──────────────────────────────────────────────
##  Helpers
## ──────────────────────────────────────────────

func _pick_new_wander_target() -> void:
	# If schedule has a specific target (work/home), use it
	if _schedule:
		var sched_target := _schedule.get_activity_target()
		if sched_target != Vector3.ZERO:
			target_position = sched_target
			return
	# Otherwise pick a random wander point nearby
	var offset := Vector3(
		randf_range(-WANDER_RADIUS, WANDER_RADIUS),
		0,
		randf_range(-WANDER_RADIUS, WANDER_RADIUS)
	)
	target_position = global_position + offset
