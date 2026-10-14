## memory_recall.gd
## Recall engine — retrieves relevant memories for an NPC based on context.
## Supports associative recall (finding memories related to a person, place, or topic).
class_name MemoryRecall

## ──────────────────────────────────────────────
##  Recall Queries
## ──────────────────────────────────────────────

## Recall memories about a specific entity (player or NPC)
## memories: Array of memory Dictionaries
## entity_id: the ID to filter by (checks both actor_id and target_id)
## limit: max results
static func about_entity(memories: Array, entity_id: String, limit: int = 10) -> Array:
	var results: Array = []
	for memory in memories:
		if memory.get("actor_id") == entity_id or memory.get("target_id") == entity_id:
			results.append(memory)
	# Sort by strength descending
	results.sort_custom(_compare_strength)
	return results.slice(0, limit)

## Recall memories of a specific type
static func of_type(memories: Array, event_type: int, limit: int = 10) -> Array:
	var results: Array = []
	for memory in memories:
		if memory.get("type") == event_type:
			results.append(memory)
	results.sort_custom(_compare_strength)
	return results.slice(0, limit)

## Recall memories near a location (within radius in meters)
static func near_location(memories: Array, location: Vector3, radius: float = 50.0, limit: int = 10) -> Array:
	var results: Array = []
	for memory in memories:
		var mem_loc: Vector3 = memory.get("location", Vector3.ZERO)
		if mem_loc.distance_to(location) <= radius:
			results.append(memory)
	results.sort_custom(_compare_strength)
	return results.slice(0, limit)

## Recall recent memories (most recent first)
static func recent(memories: Array, limit: int = 10) -> Array:
	var results := memories.duplicate()
	results.sort_custom(_compare_timestamp)
	return results.slice(0, limit)

## Recall strongest memories
static func strongest(memories: Array, limit: int = 10) -> Array:
	var results := memories.duplicate()
	results.sort_custom(_compare_strength)
	return results.slice(0, limit)

## Associative recall — find memories matching multiple criteria
## criteria: Dictionary with optional keys: entity_id, event_type, location, radius, min_strength
static func associative(memories: Array, criteria: Dictionary, limit: int = 10) -> Array:
	var results: Array = []
	for memory in memories:
		if _matches_criteria(memory, criteria):
			results.append(memory)
	results.sort_custom(_compare_strength)
	return results.slice(0, limit)

## ──────────────────────────────────────────────
##  Summary & Analysis
## ──────────────────────────────────────────────

## Get a summary of relationship with an entity
## Returns: Dictionary with keys: interaction_count, net_sentiment, strongest_memory, event_breakdown
static func relationship_summary(memories: Array, entity_id: String) -> Dictionary:
	var about := about_entity(memories, entity_id, 9999)
	if about.is_empty():
		return {
			"interaction_count": 0,
			"net_sentiment": 0.0,
			"strongest_memory": null,
			"event_breakdown": {}
		}
	
	var sentiment := 0.0
	var breakdown: Dictionary = {}
	var strongest_mem: Dictionary = about[0]
	
	for memory in about:
		var emotion := MemoryEventType.get_base_emotional_weight(memory.get("type", 0))
		sentiment += emotion * memory.get("strength", 1.0)
		var type_name := memory.get("type_name", "UNKNOWN")
		breakdown[type_name] = breakdown.get(type_name, 0) + 1
		if memory.get("strength", 0.0) > strongest_mem.get("strength", 0.0):
			strongest_mem = memory
	
	return {
		"interaction_count": about.size(),
		"net_sentiment": clamp(sentiment, -1.0, 1.0),
		"strongest_memory": strongest_mem,
		"event_breakdown": breakdown
	}

## ──────────────────────────────────────────────
##  Internal
## ──────────────────────────────────────────────

static func _compare_strength(a: Dictionary, b: Dictionary) -> bool:
	return a.get("strength", 0.0) > b.get("strength", 0.0)

static func _compare_timestamp(a: Dictionary, b: Dictionary) -> bool:
	return a.get("timestamp", 0.0) > b.get("timestamp", 0.0)

static func _matches_criteria(memory: Dictionary, criteria: Dictionary) -> bool:
	if criteria.has("entity_id"):
		var eid: String = criteria["entity_id"]
		if memory.get("actor_id") != eid and memory.get("target_id") != eid:
			return false
	if criteria.has("event_type") and memory.get("type") != criteria["event_type"]:
		return false
	if criteria.has("min_strength") and memory.get("strength", 0.0) < float(criteria["min_strength"]):
		return false
	if criteria.has("location") and criteria.has("radius"):
		var mem_loc: Vector3 = memory.get("location", Vector3.ZERO)
		var crit_loc: Vector3 = criteria["location"]
		if mem_loc.distance_to(crit_loc) > float(criteria["radius"]):
			return false
	return true
