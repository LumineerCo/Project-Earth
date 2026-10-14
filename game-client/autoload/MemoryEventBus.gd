## MemoryEventBus.gd
## Global event bus for NPC memory events. Any system can emit an interaction
## and all interested NPCs / systems receive it. Decouples event producers from consumers.
extends Node
class_name MemoryEventBus

## ──────────────────────────────────────────────
##  Signals
## ──────────────────────────────────────────────

## Emitted when any memory-worthy interaction occurs.
## memory_event: Dictionary with keys — type, actor_id, target_id, location, timestamp, details
signal memory_event_created(memory_event: Dictionary)

## Emitted when a specific NPC should process a memory
signal npc_memory_received(npc_id: String, memory_event: Dictionary)

## ──────────────────────────────────────────────
##  State
## ──────────────────────────────────────────────

var _event_count: int = 0
var _events_this_minute: int = 0
var _max_events_per_frame: int = 100

## ──────────────────────────────────────────────
##  Public API
## ──────────────────────────────────────────────

## Record an interaction between entities.
## type: int (MemoryEventType enum value)
## actor_id: String (who performed the action)
## target_id: String (who received the action, can be "" for environment events)
## location: Vector3 (where it happened)
## details: Dictionary (additional context — item_id, dialogue, amount, etc.)
func record_interaction(
	event_type: int,
	actor_id: String,
	target_id: String,
	location: Vector3,
	details: Dictionary = {}
) -> Dictionary:
	var memory_event := {
		"event_id": _generate_event_id(),
		"type": event_type,
		"type_name": MemoryEventType.get_name(event_type),
		"actor_id": actor_id,
		"target_id": target_id,
		"location": location,
		"timestamp": Time.get_unix_time_from_system(),
		"game_time": WorldTime.get_total_seconds() if WorldTime else 0.0,
		"details": details,
	}
	
	memory_event_created.emit(memory_event)
	_event_count += 1
	
	# If there's a target NPC, notify them directly
	if target_id != "":
		npc_memory_received.emit(target_id, memory_event)
	
	# Also notify the actor (they remember their own actions)
	if actor_id != "":
		npc_memory_received.emit(actor_id, memory_event)
	
	DebugManager.log_debug("MemoryEventBus", "Event #%d: %s by %s → %s" % [
		_event_count, memory_event.type_name, actor_id, target_id if target_id != "" else "(environment)"
	])
	
	return memory_event

## Convenience: record a simple interaction with no extra details
func record_simple(event_type: int, actor_id: String, target_id: String) -> Dictionary:
	return record_interaction(event_type, actor_id, target_id, Vector3.ZERO)

## Get total events recorded this session
func get_event_count() -> int:
	return _event_count

## ──────────────────────────────────────────────
##  Internal
## ──────────────────────────────────────────────

func _generate_event_id() -> String:
	# NOTE: _event_count is incremented in record_interaction() to avoid double-counting.
	return "evt_%d_%d" % [Time.get_unix_time_from_system(), _event_count + 1]
