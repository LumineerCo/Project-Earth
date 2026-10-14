## memory_event_types.gd
## Defines all interaction event types that NPCs can remember.
## Extensible — add new types at the end to maintain enum stability.
class_name MemoryEventType

enum {
	GREETED,
	IGNORED,
	PURCHASED_ITEM,
	SOLD_ITEM,
	GAVE_GIFT,
	RECEIVED_GIFT,
	INSULTED,
	COMPLIMENTED,
	HELPED,
	WAS_HELPED,
	HARMED,
	WAS_HARMED,
	COLLIDED,
	BLOCKED_PATH,
	TRESPASSED,
	STOLE_FROM,
	CAUGHT_STEALING,
	SAVED_LIFE,
	BETRAYED,
	KEPT_PROMISE,
	BROKE_PROMISE,
	COMPLETED_FAVOR,
	FAILED_FAVOR,
	WITNESSED_EVENT,
	CONVERSATION,
	CUSTOM
}

## Returns a human-readable name for an event type
static func get_name(event_type: int) -> String:
	var keys := _get_keys()
	if event_type >= 0 and event_type < keys.size():
		return keys[event_type]
	return "UNKNOWN"

## Returns the base significance (0.0–1.0) for an event type
static func get_base_significance(event_type: int) -> float:
	const TABLE := {
		GREETED: 0.1,
		IGNORED: 0.05,
		PURCHASED_ITEM: 0.3,
		SOLD_ITEM: 0.3,
		GAVE_GIFT: 0.7,
		RECEIVED_GIFT: 0.7,
		INSULTED: 0.6,
		COMPLIMENTED: 0.4,
		HELPED: 0.65,
		WAS_HELPED: 0.65,
		HARMED: 0.95,
		WAS_HARMED: 0.95,
		COLLIDED: 0.05,
		BLOCKED_PATH: 0.1,
		TRESPASSED: 0.4,
		STOLE_FROM: 0.9,
		CAUGHT_STEALING: 0.85,
		SAVED_LIFE: 1.0,
		BETRAYED: 0.9,
		KEPT_PROMISE: 0.5,
		BROKE_PROMISE: 0.8,
		COMPLETED_FAVOR: 0.6,
		FAILED_FAVOR: 0.5,
		WITNESSED_EVENT: 0.3,
		CONVERSATION: 0.2,
		CUSTOM: 0.2,
	}
	return TABLE.get(event_type, 0.2)

## Returns the base emotional weight (-1.0 to +1.0) for an event type
static func get_base_emotional_weight(event_type: int) -> float:
	const TABLE := {
		GREETED: 0.1,
		IGNORED: -0.05,
		PURCHASED_ITEM: 0.1,
		SOLD_ITEM: 0.1,
		GAVE_GIFT: 0.6,
		RECEIVED_GIFT: 0.6,
		INSULTED: -0.6,
		COMPLIMENTED: 0.4,
		HELPED: 0.5,
		WAS_HELPED: 0.5,
		HARMED: -0.9,
		WAS_HARMED: -0.9,
		COLLIDED: -0.05,
		BLOCKED_PATH: -0.1,
		TRESPASSED: -0.3,
		STOLE_FROM: -0.8,
		CAUGHT_STEALING: -0.7,
		SAVED_LIFE: 1.0,
		BETRAYED: -0.85,
		KEPT_PROMISE: 0.4,
		BROKE_PROMISE: -0.6,
		COMPLETED_FAVOR: 0.5,
		FAILED_FAVOR: -0.3,
		WITNESSED_EVENT: 0.0,
		CONVERSATION: 0.1,
		CUSTOM: 0.0,
	}
	return TABLE.get(event_type, 0.0)

static func _get_keys() -> PackedStringArray:
	return PackedStringArray([
		"GREETED", "IGNORED", "PURCHASED_ITEM", "SOLD_ITEM",
		"GAVE_GIFT", "RECEIVED_GIFT", "INSULTED", "COMPLIMENTED",
		"HELPED", "WAS_HELPED", "HARMED", "WAS_HARMED",
		"COLLIDED", "BLOCKED_PATH", "TRESPASSED", "STOLE_FROM",
		"CAUGHT_STEALING", "SAVED_LIFE", "BETRAYED",
		"KEPT_PROMISE", "BROKE_PROMISE", "COMPLETED_FAVOR",
		"FAILED_FAVOR", "WITNESSED_EVENT", "CONVERSATION", "CUSTOM"
	])
