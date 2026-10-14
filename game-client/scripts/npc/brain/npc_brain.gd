## npc_brain.gd
## The core NPC brain — processes memory events, maintains relationships,
## and drives behavior based on remembered interactions.
class_name NPCBrain

extends Node

## ──────────────────────────────────────────────
##  Signals
## ──────────────────────────────────────────────

signal behavior_changed(new_behavior: String)
signal relationship_changed(entity_id: String, new_score: float)

## ──────────────────────────────────────────────
##  Configuration
## ──────────────────────────────────────────────

const MEMORY_PROCESS_INTERVAL := 0.5  # Seconds between memory processing cycles
const MAX_RELATIONSHIPS_TRACKED := 200

## ──────────────────────────────────────────────
##  State
## ──────────────────────────────────────────────

var npc_id: String = ""
var npc_name: String = ""
var _memories: Array = []
var _relationships: Dictionary = {}  # entity_id → {score, trust, familiarity, last_interaction}
var _personality: Dictionary = {}
var _current_behavior: String = "idle"
var _process_timer: float = 0.0

## ──────────────────────────────────────────────
##  Lifecycle
## ──────────────────────────────────────────────

func _ready() -> void:
	if npc_id.is_empty():
		npc_id = "npc_%d" % randi()
	_initialize_personality()
	# Connect to global memory event bus
	if MemoryEventBus:
		MemoryEventBus.npc_memory_received.connect(_on_memory_received)

func _process(delta: float) -> void:
	_process_timer += delta
	if _process_timer >= MEMORY_PROCESS_INTERVAL:
		_process_timer = 0.0
		_process_memories()

## ──────────────────────────────────────────────
##  Initialization
## ──────────────────────────────────────────────

func _initialize_personality() -> void:
	# Big Five personality model (0.0–1.0 each)
	_personality = {
		"openness": randf(),
		"conscientiousness": randf(),
		"extraversion": randf(),
		"agreeableness": randf(),
		"neuroticism": randf(),
		"memory_capacity": randf_range(0.5, 1.0),  # How many memories they retain
		"emotional_sensitivity": randf_range(0.3, 1.0),
		"grudge_tendency": randf_range(0.0, 0.8),
		"forgiveness_tendency": randf_range(0.2, 1.0),
	}

func set_npc_data(id: String, display_name: String) -> void:
	npc_id = id
	npc_name = display_name

## ──────────────────────────────────────────────
##  Memory Processing
## ──────────────────────────────────────────────

func _on_memory_received(target_id: String, memory_event: Dictionary) -> void:
	if target_id != npc_id:
		return
	_process_memory_event(memory_event)

func _process_memory_event(event: Dictionary) -> void:
	# Calculate significance based on event type, relationship, and history
	var actor_id: String = event.get("actor_id", "")
	var relationship_score := _get_relationship_score(actor_id)
	var interaction_count := _get_interaction_count(actor_id)
	
	var significance := SignificanceScorer.calculate(
		event.get("type", 0),
		event.get("details", {}),
		relationship_score,
		interaction_count
	)
	
	event["significance"] = significance
	event["strength"] = 1.0
	event["tier"] = SignificanceScorer.get_retention_tier(significance)
	
	# Store in local memory
	_memories.append(event)
	
	# Persist to global store
	if MemoryStore:
		MemoryStore.store_memory(npc_id, event)
	
	# Update relationship
	_update_relationship(event)
	
	# Adjust behavior
	_evaluate_behavior(event)

func _process_memories() -> void:
	# Run decay on local memories
	if WorldTime:
		var current_game_time := WorldTime.get_total_seconds()
		var to_prune := MemoryDecay.process_batch(_memories, current_game_time)
		for mem_id in to_prune:
			if not mem_id.is_empty():
				_memories = _memories.filter(func(m): return m.get("event_id", "") != mem_id)

## ──────────────────────────────────────────────
##  Relationship Management
## ──────────────────────────────────────────────

func _update_relationship(event: Dictionary) -> void:
	var other_id: String = event.get("actor_id", "")
	if other_id == npc_id:
		other_id = event.get("target_id", "")
	if other_id.is_empty():
		return
	
	var emotional_weight := MemoryEventType.get_base_emotional_weight(event.get("type", 0))
	var significance: float = event.get("significance", 0.5)
	
	# Personality modulates emotional response
	var sensitivity: float = _personality.get("emotional_sensitivity", 0.5)
	var adjusted_emotion := emotional_weight * sensitivity * significance
	
	if not _relationships.has(other_id):
		_relationships[other_id] = {
			"score": 0.0,
			"trust": 0.0,
			"familiarity": 0.0,
			"last_interaction": Time.get_unix_time_from_system(),
			"interaction_count": 0,
		}
	
	var rel: Dictionary = _relationships[other_id]
	rel["score"] = clamp(rel["score"] + adjusted_emotion, -1.0, 1.0)
	rel["familiarity"] = clamp(rel["familiarity"] + 0.01, 0.0, 1.0)
	rel["interaction_count"] = int(rel["interaction_count"]) + 1
	rel["last_interaction"] = Time.get_unix_time_from_system()
	
	# Trust changes slower than sentiment
	if emotional_weight > 0:
		rel["trust"] = clamp(rel["trust"] + significance * 0.05, -1.0, 1.0)
	elif emotional_weight < 0:
		var grudge: float = _personality.get("grudge_tendency", 0.3)
		rel["trust"] = clamp(rel["trust"] - significance * 0.1 * grudge, -1.0, 1.0)
	
	_relationships[other_id] = rel
	relationship_changed.emit(other_id, rel["score"])
	
	# Enforce relationship cap
	if _relationships.size() > MAX_RELATIONSHIPS_TRACKED:
		_prune_relationships()

func _prune_relationships() -> void:
	# Remove relationships with lowest familiarity and most stale
	var sorted := _relationships.keys()
	sorted.sort_custom(func(a, b): 
		return _relationships[a].get("familiarity", 0.0) < _relationships[b].get("familiarity", 0.0)
	)
	while _relationships.size() > MAX_RELATIONSHIPS_TRACKED:
		_relationships.erase(sorted.pop_front())

func get_relationship(entity_id: String) -> Dictionary:
	return _relationships.get(entity_id, {
		"score": 0.0, "trust": 0.0, "familiarity": 0.0,
		"last_interaction": 0, "interaction_count": 0
	})

func _get_relationship_score(entity_id: String) -> float:
	return _relationships.get(entity_id, {}).get("score", 0.0)

func _get_interaction_count(entity_id: String) -> int:
	return int(_relationships.get(entity_id, {}).get("interaction_count", 0))

## ──────────────────────────────────────────────
##  Behavior Evaluation
## ──────────────────────────────────────────────

func _evaluate_behavior(event: Dictionary) -> void:
	var event_type: int = event.get("type", 0)
	var actor_id: String = event.get("actor_id", "")
	var rel_score: float = _get_relationship_score(actor_id)
	
	var new_behavior := "idle"
	
	# React based on event type and relationship
	match event_type:
		MemoryEventType.HARMED, MemoryEventType.WAS_HARMED:
			new_behavior = "hostile" if rel_score < -0.3 else "defensive"
		MemoryEventType.INSULTED:
			new_behavior = "annoyed" if rel_score < 0 else "indifferent"
		MemoryEventType.GAVE_GIFT, MemoryEventType.RECEIVED_GIFT:
			new_behavior = "grateful" if rel_score > 0 else "suspicious"
		MemoryEventType.HELPED, MemoryEventType.WAS_HELPED:
			new_behavior = "friendly" if rel_score > 0 else "neutral"
		MemoryEventType.GREETED:
			new_behavior = "greeting"
		MemoryEventType.STOLE_FROM, MemoryEventType.CAUGHT_STEALING:
			new_behavior = "hostile"
		MemoryEventType.SAVED_LIFE:
			new_behavior = "loyal"
		_:
			new_behavior = "idle"
	
	if new_behavior != _current_behavior:
		_current_behavior = new_behavior
		behavior_changed.emit(new_behavior)
		DebugManager.log_debug("NPCBrain", "%s behavior → %s (event: %s, rel: %.2f)" % [npc_name, new_behavior, event.get("type_name", ""), rel_score])

func get_current_behavior() -> String:
	return _current_behavior

## ──────────────────────────────────────────────
##  Memory Recall (delegates to MemoryRecall)
## ──────────────────────────────────────────────

func recall_about(entity_id: String) -> Array:
	return MemoryRecall.about_entity(_memories, entity_id)

func recall_recent(limit: int = 10) -> Array:
	return MemoryRecall.recent(_memories, limit)

func recall_strongest(limit: int = 10) -> Array:
	return MemoryRecall.strongest(_memories, limit)

func get_relationship_summary(entity_id: String) -> Dictionary:
	return MemoryRecall.relationship_summary(_memories, entity_id)

## ──────────────────────────────────────────────
##  Serialization
## ──────────────────────────────────────────────

func serialize() -> Dictionary:
	return {
		"npc_id": npc_id,
		"npc_name": npc_name,
		"personality": _personality,
		"relationships": _relationships,
		"current_behavior": _current_behavior,
	}

func deserialize(data: Dictionary) -> void:
	npc_id = data.get("npc_id", npc_id)
	npc_name = data.get("npc_name", npc_name)
	_personality = data.get("personality", _personality)
	_relationships = data.get("relationships", {})
	_current_behavior = data.get("current_behavior", "idle")
