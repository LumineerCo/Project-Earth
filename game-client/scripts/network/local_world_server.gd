## local_world_server.gd
## Embedded world server — runs the same authoritative logic as the remote
## headless server, but locally for offline single-player mode.
class_name LocalWorldServer

extends Node

## ──────────────────────────────────────────────
##  Signals
## ──────────────────────────────────────────────

signal entity_spawned(entity_id: String, data: Dictionary)
signal entity_despawned(entity_id: String)
signal world_state_updated(state: Dictionary)

## ──────────────────────────────────────────────
##  Configuration
## ──────────────────────────────────────────────

const TICK_RATE := 10.0  # 10 ticks/sec
const MAX_ENTITIES := 10000

## ──────────────────────────────────────────────
##  State
## ──────────────────────────────────────────────

var _entities: Dictionary = {}  # entity_id → Dictionary
var _interest_manager: InterestManager = null
var _tick_accumulator: float = 0.0
var _world_seed: int = 0
var _running: bool = false

## ──────────────────────────────────────────────
##  Lifecycle
## ──────────────────────────────────────────────

func _ready() -> void:
	_interest_manager = InterestManager.new()
	add_child(_interest_manager)
	start_server()

func _process(delta: float) -> void:
	if not _running:
		return
	_tick_accumulator += delta
	var tick_interval := 1.0 / TICK_RATE
	while _tick_accumulator >= tick_interval:
		_tick_accumulator -= tick_interval
		_tick()

## ──────────────────────────────────────────────
##  Server Lifecycle
## ──────────────────────────────────────────────

func start_server() -> void:
	_world_seed = GameManager.world_seed if GameManager else 0
	_running = true
	DebugManager.log_info("LocalWorldServer", "Started (seed=%d, tick_rate=%.0f)" % [_world_seed, TICK_RATE])

func stop_server() -> void:
	_running = false
	DebugManager.log_info("LocalWorldServer", "Stopped")

## ──────────────────────────────────────────────
##  Tick Logic
## ──────────────────────────────────────────────

func _tick() -> void:
	# Update entity positions, NPC behaviors, economy, etc.
	_update_npcs()
	_update_economy()

func _update_npcs() -> void:
	# NPC tick — let NPC brains process
	pass  # NPC brains are individual nodes and self-process

func _update_economy() -> void:
	# Economy ticks are handled by EconomyManager autoload
	pass

## ──────────────────────────────────────────────
##  Entity Management
## ──────────────────────────────────────────────

func spawn_entity(entity_id: String, entity_type: String, position: Vector3, data: Dictionary = {}) -> void:
	if _entities.size() >= MAX_ENTITIES:
		DebugManager.log_warn("LocalWorldServer", "Max entities reached — cannot spawn %s" % entity_id)
		return
	var entity := {
		"id": entity_id,
		"type": entity_type,
		"position": position,
		"rotation": Vector3.ZERO,
		"velocity": Vector3.ZERO,
		"data": data,
		"spawn_time": Time.get_unix_time_from_system(),
	}
	_entities[entity_id] = entity
	if _interest_manager:
		_interest_manager.register_entity(entity_id, position, entity_type)
	entity_spawned.emit(entity_id, entity)
	DebugManager.log_debug("LocalWorldServer", "Spawned %s (%s) at %s" % [entity_id, entity_type, position])

func despawn_entity(entity_id: String) -> void:
	if not _entities.has(entity_id):
		return
	_entities.erase(entity_id)
	if _interest_manager:
		_interest_manager.unregister_entity(entity_id)
	entity_despawned.emit(entity_id)
	DebugManager.log_debug("LocalWorldServer", "Despawned %s" % entity_id)

func update_entity_position(entity_id: String, position: Vector3) -> void:
	if not _entities.has(entity_id):
		return
	_entities[entity_id]["position"] = position
	if _interest_manager:
		_interest_manager.update_entity_position(entity_id, position)

func get_entity(entity_id: String) -> Dictionary:
	return _entities.get(entity_id, {})

func get_entities_near(position: Vector3, radius: float) -> Array:
	var results: Array = []
	for entity in _entities.values():
		var ent_pos: Vector3 = entity["position"]
		if ent_pos.distance_to(position) <= radius:
			results.append(entity)
	return results

## ──────────────────────────────────────────────
##  Player Management
## ──────────────────────────────────────────────

func register_player(player_id: String, position: Vector3) -> void:
	if _interest_manager:
		_interest_manager.register_player(player_id, position)
	DebugManager.log_info("LocalWorldServer", "Player registered: %s" % player_id)

func unregister_player(player_id: String) -> void:
	if _interest_manager:
		_interest_manager.unregister_player(player_id)
	DebugManager.log_info("LocalWorldServer", "Player unregistered: %s" % player_id)

func get_player_interest(player_id: String) -> Array[String]:
	if _interest_manager:
		return _interest_manager.get_entities_for_player(player_id)
	return []

## ──────────────────────────────────────────────
##  World State
## ──────────────────────────────────────────────

func get_world_state() -> Dictionary:
	return {
		"entities": _entities.size(),
		"regions": _interest_manager.get_region_count() if _interest_manager else 0,
		"world_seed": _world_seed,
		"game_time": WorldTime.get_total_seconds() if WorldTime else 0,
	}

## ──────────────────────────────────────────────
##  Serialization
## ──────────────────────────────────────────────

func serialize() -> Dictionary:
	return {
		"world_seed": _world_seed,
		"entities": _entities,
	}

func deserialize(data: Dictionary) -> void:
	_world_seed = data.get("world_seed", 0)
	_entities = data.get("entities", {})
	# Rebuild interest manager index
	if _interest_manager:
		for eid in _entities:
			var ent: Dictionary = _entities[eid]
			_interest_manager.register_entity(eid, ent.get("position", Vector3.ZERO), ent.get("type", "generic"))
