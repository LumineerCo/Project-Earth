## Door.gd
## A simple door that opens/closes on interaction.
## Stage 2.12 Milestone 8 (Basic Interaction)
extends Interactable

@export var open_angle: float = 90.0  # degrees
@export var open_speed: float = 3.0   # radians/sec

var _is_open: bool = false
var _target_angle: float = 0.0
var _pivot: Node3D

func _ready() -> void:
	super._ready()
	prompt_text = "Press E to open/close"
	# Create a pivot at the hinge edge
	_pivot = Node3D.new()
	_pivot.name = "DoorPivot"
	# Move this door's mesh/visuals under the pivot
	var visuals: Array[Node] = []
	for child in get_children():
		visuals.append(child)
	for child in visuals:
		var c := child as Node
		remove_child(c)
		_pivot.add_child(c)
	add_child(_pivot)
	# Offset pivot to hinge (left edge)
	_pivot.position = Vector3(-1.0, 0, 0)

func _process(delta: float) -> void:
	var current := _pivot.rotation.y
	var diff := _target_angle - current
	if abs(diff) > 0.01:
		_pivot.rotation.y = current + sign(diff) * min(abs(diff), open_speed * delta)

func _on_interact(_player: Node) -> void:
	_is_open = not _is_open
	_target_angle = deg_to_rad(open_angle) if _is_open else 0.0
	DebugManager.log_debug("Door", "%s %s" % [name, "opened" if _is_open else "closed"])
