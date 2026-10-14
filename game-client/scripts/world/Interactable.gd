## Interactable.gd
## Base class for objects the player can interact with.
## Stage 2.12 Milestone 8 (Basic Interaction)
## Attach to any Node3D that should respond to the player's interact action.
extends Node3D

## Display text shown in the HUD prompt when the player looks at this object.
@export var prompt_text: String = "Interact"

## Whether this object can currently be interacted with.
@export var enabled: bool = true

## Unique entity ID for the memory system (auto-set to name if blank).
@export var entity_id: String = ""

signal interacted(player: Node)

## Called by PlayerController._try_interact()
func interact(player: Node) -> void:
	if not enabled:
		return
	interacted.emit(player)
	_on_interact(player)
	# Record in memory system
	var my_id := entity_id if entity_id != "" else name
	MemoryEventBus.record_simple(
		MemoryEventType.CONVERSATION,
		GameManager.player_data.get("player_id", "player"),
		my_id,
		global_position,
		{"object": name, "type": get_class()}
	)

## Override in subclasses for custom behavior.
func _on_interact(_player: Node) -> void:
	pass

## Returns the prompt text for the HUD.
func get_prompt() -> String:
	return prompt_text
