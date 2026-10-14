## LightSwitch.gd
## A wall switch that toggles a nearby light on/off.
## Stage 2.12 Milestone 8 (Basic Interaction)
extends Interactable

@export var light_node_path: NodePath = ""

var _light: Light3D
var _is_on: bool = true

func _ready() -> void:
	super._ready()
	prompt_text = "Press E to toggle light"
	if light_node_path != "":
		_light = get_node(light_node_path) as Light3D

func _on_interact(_player: Node) -> void:
	_is_on = not _is_on
	if _light:
		_light.visible = _is_on
	DebugManager.log_debug("LightSwitch", "%s %s" % [name, "on" if _is_on else "off"])
