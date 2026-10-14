## interest_manager.gd
## Region-based interest management — determines which entities are relevant
## to which players based on spatial proximity and region boundaries.
class_name InterestManager

extends Node

## ──────────────────────────────────────────────
##  Configuration
## ──────────────────────────────────────────────

const REGION_SIZE := 256.0  # Meters per region side
const INTEREST_RADIUS := 512.0  # How far a player can "see"
const MAX_ENTITIES_PER_PLAYER := 500

## ──────────────────────────────────────────────
##  State
## ──────────────────────────────────────────────

## player_id → { region: Vector2i, entities: Array[String] }
var _player_interest: Dictionary = {}
## entity_id → { position: Vector3, region: Vector2i, type: String }
var _entities: Dictionary = {}
## region → Array[entity_id] — spatial index
var _region_index: Dictionary = {}

## ──────────────────────────────────────────────
##  Entity Registration
## ──────────────────────────────────────────────

func register_entity(entity_id: String, position: Vector3, entity_type: String = "generic") -> void:
	var region := world_to_region(position)
	_entities[entity_id] = {
		"position": position,
		"region": region,
		"type": entity_type,
	}
	_add_to_region(region, entity_id)

func unregister_entity(entity_id: String) -> void:
	if not _entities.has(entity_id):
		return
	var region: Vector2i = _entities[entity_id]["region"]
	_remove_from_region(region, entity_id)
	_entities.erase(entity_id)

func update_entity_position(entity_id: String, new_position: Vector3) -> void:
	if not _entities.has(entity_id):
		register_entity(entity_id, new_position)
		return
	var old_region: Vector2i = _entities[entity_id]["region"]
	var new_region := world_to_region(new_position)
	_entities[entity_id]["position"] = new_position
	if old_region != new_region:
		_remove_from_region(old_region, entity_id)
		_entities[entity_id]["region"] = new_region
		_add_to_region(new_region, entity_id)

## ──────────────────────────────────────────────
##  Player Interest
## ──────────────────────────────────────────────

func register_player(player_id: String, position: Vector3) -> void:
	_player_interest[player_id] = {
		"region": world_to_region(position),
		"entities": [],
		"position": position,
	}

func unregister_player(player_id: String) -> void:
	_player_interest.erase(player_id)

func update_player_position(player_id: String, position: Vector3) -> void:
	if not _player_interest.has(player_id):
		register_player(player_id, position)
		return
	_player_interest[player_id]["position"] = position
	_player_interest[player_id]["region"] = world_to_region(position)

func get_entities_for_player(player_id: String) -> Array[String]:
	if not _player_interest.has(player_id):
		return []
	var player_pos: Vector3 = _player_interest[player_id]["position"]
	var player_region: Vector2i = _player_interest[player_id]["region"]
	
	# Gather entities from nearby regions (3x3 grid around player)
	var nearby_entities: Array[String] = []
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var region := Vector2i(player_region.x + dx, player_region.y + dy)
			var entity_ids: Array = _region_index.get(region, [])
			for eid in entity_ids:
				if nearby_entities.size() >= MAX_ENTITIES_PER_PLAYER:
					break
				if _entities.has(eid):
					var ent_pos: Vector3 = _entities[eid]["position"]
					if ent_pos.distance_to(player_pos) <= INTEREST_RADIUS:
						nearby_entities.append(eid)
	
	_player_interest[player_id]["entities"] = nearby_entities
	return nearby_entities

## ──────────────────────────────────────────────
##  Region Helpers
## ──────────────────────────────────────────────

func world_to_region(position: Vector3) -> Vector2i:
	return Vector2i(
		int(position.x / REGION_SIZE),
		int(position.z / REGION_SIZE)
	)

func region_to_world_center(region: Vector2i) -> Vector3:
	return Vector3(
		region.x * REGION_SIZE + REGION_SIZE * 0.5,
		0.0,
		region.y * REGION_SIZE + REGION_SIZE * 0.5
	)

func get_entities_in_region(region: Vector2i) -> Array:
	return _region_index.get(region, [])

func _add_to_region(region: Vector2i, entity_id: String) -> void:
	if not _region_index.has(region):
		_region_index[region] = []
	_region_index[region].append(entity_id)

func _remove_from_region(region: Vector2i, entity_id: String) -> void:
	if not _region_index.has(region):
		return
	var arr: Array = _region_index[region]
	arr.erase(entity_id)
	if arr.is_empty():
		_region_index.erase(region)

## ──────────────────────────────────────────────
##  Diagnostics
## ──────────────────────────────────────────────

func get_entity_count() -> int:
	return _entities.size()

func get_region_count() -> int:
	return _region_index.size()

func get_player_count() -> int:
	return _player_interest.size()
