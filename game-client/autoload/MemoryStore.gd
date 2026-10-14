## MemoryStore.gd
## Persistent storage for NPC memories. Uses SQLite for local/offline mode.
## In online mode, syncs to PostgreSQL via WorldServerBridge.
extends Node
class_name MemoryStore

## ──────────────────────────────────────────────
##  Signals
## ──────────────────────────────────────────────

signal memory_stored(npc_id: String, memory_id: String)
signal memory_pruned(npc_id: String, memory_id: String)
signal store_ready()

## ──────────────────────────────────────────────
##  Configuration
## ──────────────────────────────────────────────

const DB_PATH := "user://npc_memories.sqlite"
const MAX_MEMORIES_PER_NPC := 500
const DECAY_CHECK_INTERVAL_SECONDS := 60.0  # Check decay every real minute

## ──────────────────────────────────────────────
##  State
## ──────────────────────────────────────────────

var _db: Object = null  # SQLiteDatabase instance (loaded dynamically)
var _is_initialized: bool = false
var _decay_timer: float = 0.0
var _total_memories: int = 0

## ──────────────────────────────────────────────
##  Lifecycle
## ──────────────────────────────────────────────

func _ready() -> void:
	_initialize_db()
	store_ready.emit()

func _process(delta: float) -> void:
	_decay_timer += delta
	if _decay_timer >= DECAY_CHECK_INTERVAL_SECONDS:
		_decay_timer = 0.0
		_process_decay()

func _exit_tree() -> void:
	if _db:
		_db.close()
		_db = null

## ──────────────────────────────────────────────
##  Database Initialization
## ──────────────────────────────────────────────

func _initialize_db() -> void:
	# Try to load the SQLite module (Godot SQLite addon or built-in)
	# For now, use a JSON-based fallback if SQLite addon isn't available
	var sqlite_class := ClassDB.instantiate("SQLiteDatabase") if ClassDB.class_exists("SQLiteDatabase") else null
	if sqlite_class:
		_db = sqlite_class
		_db.open_db(DB_PATH)
		_create_schema()
		_is_initialized = true
		DebugManager.log_info("MemoryStore", "SQLite database initialized at %s" % DB_PATH)
	else:
		# Fallback: use JSON files per NPC
		_is_initialized = true
		DebugManager.log_warn("MemoryStore", "SQLite addon not found — using JSON fallback storage")

func _create_schema() -> void:
	if not _db:
		return
	_db.query("""
CREATE TABLE IF NOT EXISTS npc_memories (
	id TEXT PRIMARY KEY,
	npc_id TEXT NOT NULL,
	event_type INTEGER NOT NULL,
	actor_id TEXT,
	target_id TEXT,
	location_x REAL, location_y REAL, location_z REAL,
	timestamp REAL NOT NULL,
	game_time REAL NOT NULL,
	significance REAL NOT NULL,
	strength REAL NOT NULL DEFAULT 1.0,
	tier TEXT NOT NULL DEFAULT 'short_term',
	details TEXT,
	last_accessed_game_time REAL,
	created_at REAL DEFAULT (strftime('%s', 'now'))
);
	""")
	_db.query("""
CREATE INDEX IF NOT EXISTS idx_npc_memories_npc_id ON npc_memories(npc_id);
CREATE INDEX IF NOT EXISTS idx_npc_memories_target_id ON npc_memories(target_id);
CREATE INDEX IF NOT EXISTS idx_npc_memories_strength ON npc_memories(strength);
	""")

## ──────────────────────────────────────────────
##  Store / Retrieve
## ──────────────────────────────────────────────

## Store a memory event for an NPC
func store_memory(npc_id: String, memory_event: Dictionary) -> String:
	var memory_id: String = memory_event.get("event_id", _generate_id())
	var significance: float = memory_event.get("significance", 0.5)
	var tier: String = SignificanceScorer.get_retention_tier(significance)
	
	var memory := {
		"id": memory_id,
		"npc_id": npc_id,
		"type": memory_event.get("type", 0),
		"type_name": memory_event.get("type_name", ""),
		"actor_id": memory_event.get("actor_id", ""),
		"target_id": memory_event.get("target_id", ""),
		"location": memory_event.get("location", Vector3.ZERO),
		"timestamp": memory_event.get("timestamp", Time.get_unix_time_from_system()),
		"game_time": memory_event.get("game_time", 0.0),
		"significance": significance,
		"strength": 1.0,
		"tier": tier,
		"details": memory_event.get("details", {}),
		"last_accessed_game_time": memory_event.get("game_time", 0.0),
	}
	
	if _db:
		_store_sqlite(memory)
	else:
		_store_json(npc_id, memory)
	
	_total_memories += 1
	memory_stored.emit(npc_id, memory_id)
	DebugManager.log_debug("MemoryStore", "Stored memory %s for NPC %s (sig=%.2f, tier=%s)" % [memory_id, npc_id, significance, tier])
	
	# Enforce per-NPC memory cap
	_enforce_memory_cap(npc_id)
	
	return memory_id

## Retrieve all memories for an NPC
func get_memories(npc_id: String) -> Array:
	if _db:
		return _get_memories_sqlite(npc_id)
	else:
		return _get_memories_json(npc_id)

## Retrieve memories about a specific entity (as target or actor)
func get_memories_about(npc_id: String, entity_id: String) -> Array:
	var all := get_memories(npc_id)
	return MemoryRecall.about_entity(all, entity_id)

## ──────────────────────────────────────────────
##  Decay Processing
## ──────────────────────────────────────────────

func _process_decay() -> void:
	if not WorldTime:
		return
	var current_game_time := WorldTime.get_total_seconds()
	# In a full implementation, this would batch-process all NPCs
	# For now, log that decay processing ran
	DebugManager.log_trace("MemoryStore", "Decay processing tick (game_time=%.1f)" % current_game_time)

## ──────────────────────────────────────────────
##  Memory Cap Management
## ──────────────────────────────────────────────

func _enforce_memory_cap(npc_id: String) -> void:
	var memories := get_memories(npc_id)
	if memories.size() <= MAX_MEMORIES_PER_NPC:
		return
	# Sort by strength ascending and prune weakest
	memories.sort_custom(func(a, b): return a.get("strength", 0.0) < b.get("strength", 0.0))
	var to_remove := memories.size() - MAX_MEMORIES_PER_NPC
	for i in to_remove:
		var mem_id: String = memories[i].get("id", "")
		if not mem_id.is_empty():
			delete_memory(npc_id, mem_id)

## ──────────────────────────────────────────────
##  Delete / Clear
## ──────────────────────────────────────────────

func delete_memory(npc_id: String, memory_id: String) -> void:
	if _db:
		_db.query_with_args("DELETE FROM npc_memories WHERE id = ? AND npc_id = ?", [memory_id, npc_id])
	else:
		_delete_memory_json(npc_id, memory_id)
	memory_pruned.emit(npc_id, memory_id)
	_total_memories = max(0, _total_memories - 1)

func clear_npc_memories(npc_id: String) -> void:
	if _db:
		_db.query_with_args("DELETE FROM npc_memories WHERE npc_id = ?", [npc_id])
	else:
		_clear_json(npc_id)
	DebugManager.log_info("MemoryStore", "Cleared all memories for NPC %s" % npc_id)

## ──────────────────────────────────────────────
##  SQLite Implementation
## ──────────────────────────────────────────────

func _store_sqlite(memory: Dictionary) -> void:
	if not _db:
		return
	var loc: Vector3 = memory.get("location", Vector3.ZERO)
	_db.query_with_args("""
INSERT INTO npc_memories (id, npc_id, event_type, actor_id, target_id, location_x, location_y, location_z, timestamp, game_time, significance, strength, tier, details, last_accessed_game_time)
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
	""", [
		memory["id"], memory["npc_id"], memory["type"],
		memory.get("actor_id", ""), memory.get("target_id", ""),
		loc.x, loc.y, loc.z,
		memory["timestamp"], memory["game_time"],
		memory["significance"], memory["strength"], memory["tier"],
		JSON.stringify(memory.get("details", {})),
		memory.get("last_accessed_game_time", 0.0)
	])

func _get_memories_sqlite(npc_id: String) -> Array:
	if not _db:
		return []
	# Use parameterized query to prevent SQL injection
	var result := _db.query_with_args("SELECT * FROM npc_memories WHERE npc_id = ?", [npc_id])
	if not result or not result is Array:
		return []
	var memories: Array = []
	for row in result:
		memories.append(_row_to_memory(row))
	return memories

func _row_to_memory(row: Dictionary) -> Dictionary:
	return {
		"id": row.get("id", ""),
		"npc_id": row.get("npc_id", ""),
		"type": int(row.get("event_type", 0)),
		"actor_id": row.get("actor_id", ""),
		"target_id": row.get("target_id", ""),
		"location": Vector3(row.get("location_x", 0.0), row.get("location_y", 0.0), row.get("location_z", 0.0)),
		"timestamp": row.get("timestamp", 0.0),
		"game_time": row.get("game_time", 0.0),
		"significance": row.get("significance", 0.5),
		"strength": row.get("strength", 1.0),
		"tier": row.get("tier", "short_term"),
		"details": JSON.parse_string(row.get("details", "{}")),
		"last_accessed_game_time": row.get("last_accessed_game_time", 0.0),
	}

## ──────────────────────────────────────────────
##  JSON Fallback Implementation
## ──────────────────────────────────────────────

func _json_path(npc_id: String) -> String:
	return "user://memories/%s.json" % npc_id

func _store_json(npc_id: String, memory: Dictionary) -> void:
	var dir := DirAccess.open("user://")
	if dir and not dir.dir_exists("memories"):
		dir.make_dir("memories")
	var memories := _get_memories_json(npc_id)
	memories.append(memory)
	var file := FileAccess.open(_json_path(npc_id), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(memories))
		file.close()

func _get_memories_json(npc_id: String) -> Array:
	var file := FileAccess.open(_json_path(npc_id), FileAccess.READ)
	if not file:
		return []
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	return parsed if parsed is Array else []

func _delete_memory_json(npc_id: String, memory_id: String) -> void:
	var memories := _get_memories_json(npc_id)
	var filtered: Array = []
	for mem in memories:
		if mem.get("id") != memory_id:
			filtered.append(mem)
	var file := FileAccess.open(_json_path(npc_id), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(filtered))
		file.close()

func _clear_json(npc_id: String) -> void:
	var dir := DirAccess.open("user://memories")
	if dir:
		dir.remove("%s.json" % npc_id)

## ──────────────────────────────────────────────
##  Serialization
## ──────────────────────────────────────────────

## Serialize all known NPC memory stores to a saveable dictionary.
## In SQLite mode this queries all distinct npc_ids; in JSON mode it scans the folder.
func serialize() -> Dictionary:
	var data := {}
	if _db:
		var rows = _db.query_with_args("SELECT DISTINCT npc_id FROM npc_memories", [])
		if rows and rows is Array:
			for row in rows:
				var npc_id: String = row.get("npc_id", "") if row is Dictionary else str(row)
				if not npc_id.is_empty():
					data[npc_id] = _serialize_memories_safe(get_memories(npc_id))
	else:
		var dir := DirAccess.open("user://memories")
		if dir:
			dir.list_dir_begin()
			var fname := dir.get_next()
			while fname != "":
				if fname.ends_with(".json"):
					var npc_id := fname.substr(0, fname.length() - 5)
					data[npc_id] = _serialize_memories_safe(get_memories(npc_id))
				fname = dir.get_next()
			dir.list_dir_end()
	return data

## Convert an Array of memory dicts into a JSON-safe Array (Vector3 → Array).
func _serialize_memories_safe(memories: Array) -> Array:
	var safe: Array = []
	for mem in memories:
		var copy := mem.duplicate()
		var loc = copy.get("location", Vector3.ZERO)
		if loc is Vector3:
			copy["location"] = [loc.x, loc.y, loc.z]
		safe.append(copy)
	return safe

## Restore memories from a serialized dictionary (npc_id → Array of memory dicts).
func deserialize(data: Dictionary) -> void:
	if not data or not data is Dictionary:
		return
	for npc_id in data.keys():
		var memories = data[npc_id]
		if not memories is Array:
			continue
		for mem in memories:
			var copy := mem.duplicate() if mem is Dictionary else {}
			# Restore Vector3 from Array if needed
			var loc = copy.get("location", Vector3.ZERO)
			if loc is Array and loc.size() >= 3:
				copy["location"] = Vector3(loc[0], loc[1], loc[2])
			if _db:
				_store_sqlite(copy)
			else:
				_store_json(npc_id, copy)
			_total_memories += 1
	DebugManager.log_info("MemoryStore", "Deserialized memories for %d NPC(s)" % data.size())

## ──────────────────────────────────────────────
##  Stats
## ──────────────────────────────────────────────

func get_total_memory_count() -> int:
	return _total_memories

func is_ready() -> bool:
	return _is_initialized

func _generate_id() -> String:
	return "mem_%d_%d" % [Time.get_unix_time_from_system(), randi()]
