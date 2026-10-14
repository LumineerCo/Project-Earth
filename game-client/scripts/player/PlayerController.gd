## PlayerController.gd
## Third-person player controller — movement, camera, interaction.
extends CharacterBody3D

## ──────────────────────────────────────────────
##  Configuration
## ──────────────────────────────────────────────

const MOVE_SPEED := 5.0
const SPRINT_SPEED := 8.0
const JUMP_VELOCITY := 4.5
const MOUSE_SENSITIVITY := 0.003
const CAMERA_DISTANCE := 6.0
const CAMERA_HEIGHT := 2.5
const INTERACTION_RANGE := 3.0

## ──────────────────────────────────────────────
##  State
## ──────────────────────────────────────────────

var _camera_pivot: Node3D = null
var _camera: Camera3D = null
var _yaw: float = 0.0
var _pitch: float = -0.3
var _is_sprinting: bool = false

## ──────────────────────────────────────────────
##  Lifecycle
## ──────────────────────────────────────────────

func _ready() -> void:
	# Add to Player group so interactables can detect us
	add_to_group("Player")
	# Setup camera
	_camera_pivot = Node3D.new()
	add_child(_camera_pivot)
	_camera = Camera3D.new()
	_camera_pivot.add_child(_camera)
	_camera.position = Vector3(0, CAMERA_HEIGHT, CAMERA_DISTANCE)
	_camera.look_at(position)
	
	# Lock mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Register with server (prototype: offline only, no RPC needed)
	DebugManager.log_info("PlayerController", "Player spawned at %s" % position)

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	
	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Movement
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	_is_sprinting = Input.is_action_pressed("sprint")
	var speed := SPRINT_SPEED if _is_sprinting else MOVE_SPEED
	
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed * delta * 10)
		velocity.z = move_toward(velocity.z, 0, speed * delta * 10)
	
	move_and_slide()
	
	# Update camera pivot to follow
	_camera_pivot.global_position = global_position
	# Update interaction prompt
	_update_interaction_prompt()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * MOUSE_SENSITIVITY
		_pitch = clamp(_pitch - event.relative.y * MOUSE_SENSITIVITY, -1.2, 0.5)
		_camera_pivot.rotation = Vector3(_pitch, _yaw, 0)
	
	if event.is_action_pressed("interact"):
		_try_interact()
	
	if event.is_action_pressed("inventory"):
		if has_node("/root/ShopUIManager"):
			ShopUIManager.open_inventory_ui()

## ──────────────────────────────────────────────
##  Interaction
## ──────────────────────────────────────────────

var _current_interactable: Node = null

func _get_hud() -> CanvasLayer:
	return get_node_or_null("/root/Game/HUD") as CanvasLayer

func _update_interaction_prompt() -> void:
	var hud := _get_hud()
	if not hud:
		return
	var hit := _raycast_interactable()
	if hit != _current_interactable:
		_current_interactable = hit
		if hit and hit.has_method("get_prompt"):
			hud.show_prompt(hit.get_prompt())
		else:
			hud.hide_prompt()

func _raycast_interactable() -> Node:
	var space_state := get_world_3d().direct_space_state
	var from := global_position + Vector3(0, 1.5, 0)
	var to := from - _camera_pivot.global_transform.basis.z * INTERACTION_RANGE
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	var result := space_state.intersect_ray(query)
	if result and result.collider:
		var c = result.collider
		if c.has_method("interact"):
			return c
		# Check parent for interactable
		var parent := c.get_parent()
		while parent:
			if parent.has_method("interact"):
				return parent
			parent = parent.get_parent()
	return null

func _try_interact() -> void:
	var target := _current_interactable if _current_interactable else _raycast_interactable()
	if target and target.has_method("interact"):
		target.interact(self)
		DebugManager.log_debug("PlayerController", "Interacted with %s" % target.name)
