## ChunkStreamer.gd
## Runtime chunk streaming system — loads/unloads world chunks around the player
## based on the WorldScaleManager configuration.
## Stage 1.6 (World Scale, Streaming & Technical Planning)
extends Node

## ──────────────────────────────────────────────
##  Signals
## ──────────────────────────────────────────────

signal chunk_loaded(chunk: Vector2i)
signal chunk_unloaded(chunk: Vector2i)
signal streaming_updated(loaded_count: int, loading_count: int)

## ──────────────────────────────────────────────
##  State
## ──────────────────────────────────────────────

## chunk (Vector2i) → loaded Node3D instance
var _loaded_chunks: Dictionary = {}
## chunk (Vector2i) → bool (currently loading)
var _loading_chunks: Dictionary = {}
## chunk (Vector2i) → float (time when unload was requested, for hysteresis)
var _pending_unloads: Dictionary = {}

## The node that loaded chunk scenes are parented to.
var _chunk_container: Node3D = null

## Player tracking
var _player: Node3D = null
var _player_position: Vector3 = Vector3.ZERO
var _last_update_chunk: Vector2i = Vector2i.MIN

## ──────────────────────────────────────────────
##  Configuration (cached from WorldScaleManager)
## ──────────────────────────────────────────────

var _chunk_size: float = 256.0
var _load_radius: float = 512.0
var _unload_radius: float = 768.0
var _max_active_chunks: int = 25
var _hysteresis_m: float = 64.0
var _chunk_scene_path: String = "res://worlds/blocks/"
var _chunk_naming: String = "chunk_{x}_{z}.tscn"
var _state_storage: String = "res://cache/chunk_states/"

## ──────────────────────────────────────────────
##  Lifecycle
## ──────────────────────────────────────────────

func _ready() -> void:
	_cache_config()
	_ensure_container()
	_ensure_state_dir()

func _process(_delta: float) -> void:
	if _player == null:
		return
	_player_position = _player.global_position
	var current_chunk := _world_to_chunk(_player_position)
	if current_chunk != _last_update_chunk:
		_last_update_chunk = current_chunk
		_update_streaming(current_chunk)
	_process_pending_unloads()

## ──────────────────────────────────────────────
##  Setup
## ──────────────────────────────────────────────

func _cache_config() -> void:
	var mgr := _get_scale_manager()
	if mgr == null:
		DebugManager.log_warning("ChunkStreamer", "WorldScaleManager not found; using defaults")
		return
	_chunk_size = mgr.get_chunk_size()
	_load_radius = mgr.get_load_radius()
	_unload_radius = mgr.get_unload_radius()
	_max_active_chunks = mgr.get_max_active_chunks()
	_hysteresis_m = mgr.get_hysteresis_m()
	_chunk_scene_path = mgr.get_chunk_scene_path()
	_chunk_naming = mgr.get_chunk_naming_pattern()
	var preservation := mgr.get_state_preservation()
	_state_storage = preservation.get("storage", "res://cache/chunk_states/")
	DebugManager.log_info("ChunkStreamer", "Config cached (chunk=%dm, load=%dm, unload=%dm)" % [int(_chunk_size), int(_load_radius), int(_unload_radius)])

func _ensure_container() -> void:
	if _chunk_container == null:
		_chunk_container = Node3D.new()
		_chunk_container.name = "ChunkContainer"
		add_child(_chunk_container)

func _ensure_state_dir() -> void:
	var dir := DirAccess.open("res://")
	if dir != null:
		var path := _state_storage.replace("res://", "")
		if not dir.dir_exists(path):
			dir.make_dir_recursive(path)

func _get_scale_manager():
	if Engine.has_singleton("WorldScaleManager"):
		return Engine.get_singleton("WorldScaleManager")
	var root := get_tree().root
	if root.has_node("WorldScaleManager"):
		return root.get_node("WorldScaleManager")
	return null

## ──────────────────────────────────────────────
##  Player Registration
## ──────────────────────────────────────────────

func set_player(player: Node3D) -> void:
	_player = player
	if _player != null:
		_player_position = _player.global_position
		_last_update_chunk = _world_to_chunk(_player_position)
		_update_streaming(_last_update_chunk)
		DebugManager.log_info("ChunkStreamer", "Player registered at chunk %s" % str(_last_update_chunk))

## ──────────────────────────────────────────────
##  Streaming Core
## ──────────────────────────────────────────────

func _update_streaming(center_chunk: Vector2i) -> void:
	# Determine chunks that should be loaded (within load radius)
	var desired: Array[Vector2i] = []
	var radius_chunks := int(ceil(_load_radius / _chunk_size))
	for dx in range(-radius_chunks, radius_chunks + 1):
		for dz in range(-radius_chunks, radius_chunks + 1):
			var chunk := Vector2i(center_chunk.x + dx, center_chunk.y + dz)
			var chunk_center := _chunk_to_world_center(chunk)
			var dist := Vector2(chunk_center.x - _player_position.x, chunk_center.z - _player_position.z).length()
			if dist <= _load_radius:
				desired.append(chunk)

	# Load desired chunks (respecting max active limit)
	for chunk in desired:
		if not _loaded_chunks.has(chunk) and not _loading_chunks.has(chunk):
			if _loaded_chunks.size() + _loading_chunks.size() >= _max_active_chunks:
				DebugManager.log_warning("ChunkStreamer", "Max active chunks reached (%d); skipping load of %s" % [_max_active_chunks, str(chunk)])
				break
			_load_chunk(chunk)

	# Mark chunks outside unload radius for pending unload (hysteresis)
	for chunk in _loaded_chunks.keys():
		var chunk_center := _chunk_to_world_center(chunk)
		var dist := Vector2(chunk_center.x - _player_position.x, chunk_center.z - _player_position.z).length()
		if dist > _unload_radius:
			if not _pending_unloads.has(chunk):
				_pending_unloads[chunk] = Time.get_ticks_msec()
		else:
			# Player came back; cancel pending unload
			_pending_unloads.erase(chunk)

	streaming_updated.emit(_loaded_chunks.size(), _loading_chunks.size())

func _process_pending_unloads() -> void:
	var now := Time.get_ticks_msec()
	# Hysteresis delay: wait 500ms beyond boundary before unloading
	var hysteresis_ms := 500
	var to_unload: Array[Vector2i] = []
	for chunk in _pending_unloads.keys():
		if now - int(_pending_unloads[chunk]) >= hysteresis_ms:
			to_unload.append(chunk)
	for chunk in to_unload:
		_pending_unloads.erase(chunk)
		_unload_chunk(chunk)

## ──────────────────────────────────────────────
##  Chunk Load / Unload
## ──────────────────────────────────────────────

func _load_chunk(chunk: Vector2i) -> void:
	_loading_chunks[chunk] = true
	var scene_path := _chunk_scene_path_for(chunk)
	if not ResourceLoader.exists(scene_path):
		# Chunk scene doesn't exist yet — skip silently (prototype world is sparse)
		_loading_chunks.erase(chunk)
		return
	DebugManager.log_info("ChunkStreamer", "Loading chunk %s from %s" % [str(chunk), scene_path])
	ResourceLoader.load_threaded_request(scene_path)
	# Polling is handled in _process via _check_loading; for simplicity, complete here
	# using a deferred call to check status.
	call_deferred("_check_chunk_load", chunk, scene_path)

func _check_chunk_load(chunk: Vector2i, scene_path: String) -> void:
	var status := ResourceLoader.load_threaded_get_status(scene_path)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var resource := ResourceLoader.load_threaded_get(scene_path)
		_loading_chunks.erase(chunk)
		if resource is PackedScene:
			var instance := resource.instantiate()
			if instance is Node3D:
				instance.global_position = _chunk_to_world_origin(chunk)
				_chunk_container.add_child(instance)
				_loaded_chunks[chunk] = instance
				# Restore persisted state if available
				_restore_chunk_state(chunk, instance)
				chunk_loaded.emit(chunk)
				DebugManager.log_info("ChunkStreamer", "Chunk %s loaded" % str(chunk))
		streaming_updated.emit(_loaded_chunks.size(), _loading_chunks.size())
	elif status == ResourceLoader.THREAD_LOAD_FAILED:
		_loading_chunks.erase(chunk)
		DebugManager.log_error("ChunkStreamer", "Failed to load chunk scene: %s" % scene_path)
	else:
		# Still loading — check again next frame
		call_deferred("_check_chunk_load", chunk, scene_path)

func _unload_chunk(chunk: Vector2i) -> void:
	if not _loaded_chunks.has(chunk):
		return
	var instance: Node3D = _loaded_chunks[chunk]
	# Persist state before unloading
	_save_chunk_state(chunk, instance)
	_chunk_container.remove_child(instance)
	instance.queue_free()
	_loaded_chunks.erase(chunk)
	chunk_unloaded.emit(chunk)
	streaming_updated.emit(_loaded_chunks.size(), _loading_chunks.size())
	DebugManager.log_info("ChunkStreamer", "Chunk %s unloaded" % str(chunk))

## ──────────────────────────────────────────────
##  State Persistence
## ──────────────────────────────────────────────

func _state_path_for(chunk: Vector2i) -> String:
	var path := _state_storage + "chunk_%d_%d.json" % [chunk.x, chunk.y]
	return path

func _save_chunk_state(chunk: Vector2i, instance: Node3D) -> void:
	# Serialize lightweight state (NPC positions, door states, etc.)
	# For now, store a minimal stub. Full serialization is Stage 4.
	var state := {
		"chunk": {"x": chunk.x, "z": chunk.y},
		"saved_at": Time.get_unix_time_from_system(),
		"node_count": instance.get_child_count(),
	}
	var file := FileAccess.open(_state_path_for(chunk), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(state))
		file.close()

func _restore_chunk_state(chunk: Vector2i, _instance: Node3D) -> void:
	var path := _state_path_for(chunk)
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var text := file.get_as_text()
	file.close()
	var parsed := JSON.parse_string(text)
	if parsed is Dictionary:
		# State restoration hook — full implementation in Stage 4
		DebugManager.log_info("ChunkStreamer", "Restored state for chunk %s" % str(chunk))

## ──────────────────────────────────────────────
##  Coordinate Helpers
## ──────────────────────────────────────────────

func _world_to_chunk(position: Vector3) -> Vector2i:
	return Vector2i(
		int(floor(position.x / _chunk_size)),
		int(floor(position.z / _chunk_size))
	)

func _chunk_to_world_center(chunk: Vector2i) -> Vector3:
	return Vector3(
		chunk.x * _chunk_size + _chunk_size * 0.5,
		0.0,
		chunk.y * _chunk_size + _chunk_size * 0.5
	)

func _chunk_to_world_origin(chunk: Vector2i) -> Vector3:
	return Vector3(
		chunk.x * _chunk_size,
		0.0,
		chunk.y * _chunk_size
	)

func _chunk_scene_path_for(chunk: Vector2i) -> String:
	var name := _chunk_naming.replace("{x}", str(chunk.x)).replace("{z}", str(chunk.y))
	return _chunk_scene_path + name

## ──────────────────────────────────────────────
##  Diagnostics
## ──────────────────────────────────────────────

func get_loaded_chunk_count() -> int:
	return _loaded_chunks.size()

func get_loading_chunk_count() -> int:
	return _loading_chunks.size()

func get_pending_unload_count() -> int:
	return _pending_unloads.size()

func get_loaded_chunks() -> Array:
	return _loaded_chunks.keys()

func is_chunk_loaded(chunk: Vector2i) -> bool:
	return _loaded_chunks.has(chunk)

## Force-unload all chunks (used on scene change / save).
func unload_all() -> void:
	for chunk in _loaded_chunks.keys().duplicate():
		_unload_chunk(chunk)
	_pending_unloads.clear()
