extends Node2D

const NpcAgentScript := preload("res://scripts/npc_agent.gd")
const DATA_ROOT := "res://data"
const NPC_DIR := DATA_ROOT + "/npcs"
const SCHEDULE_DIR := DATA_ROOT + "/schedules"

@export var full_simulation_radius := 900.0
@export var active_tick_seconds := 0.25
@export var abstract_tick_seconds := 2.0

var schedules := {}
var npcs: Array[Node] = []
var elapsed := 0.0
var simulated_minutes := 8 * 60
var active_tick_accumulator := 0.0
var abstract_tick_accumulator := 0.0
var target_positions := {
	"business_grocery_01": Vector2(520, 280),
	"courier_hub_old_market": Vector2(860, 280),
	"workshop_old_market_01": Vector2(880, 520),
	"park_old_market_01": Vector2(400, 520),
	"poi_food_stall_02": Vector2(650, 250),
	"service_bus_stop_old_market": Vector2(240, 360),
	"home_old_market_03": Vector2(200, 180),
	"home_old_market_04": Vector2(250, 180),
	"home_old_market_05": Vector2(300, 180),
	"home_old_market_06": Vector2(350, 180),
	"home_old_market_07": Vector2(400, 180),
	"home_old_market_08": Vector2(450, 180),
	"home_old_market_09": Vector2(500, 180),
	"home_old_market_10": Vector2(550, 180),
	"home_old_market_11": Vector2(600, 180),
	"home_old_market_12": Vector2(650, 180),
}

func _ready() -> void:
	_load_schedules()
	_spawn_npcs()

func _process(delta: float) -> void:
	elapsed += delta
	simulated_minutes = (8 * 60 + int(elapsed * 8.0)) % (24 * 60)
	active_tick_accumulator += delta
	abstract_tick_accumulator += delta
	if active_tick_accumulator >= active_tick_seconds:
		_tick_nearby_npcs(active_tick_accumulator)
		active_tick_accumulator = 0.0
	if abstract_tick_accumulator >= abstract_tick_seconds:
		_tick_distant_npcs(abstract_tick_accumulator)
		abstract_tick_accumulator = 0.0

func get_npc_count() -> int:
	return npcs.size()

func get_active_npc_count(player_position: Vector2) -> int:
	var count := 0
	for npc in npcs:
		if npc.global_position.distance_to(player_position) <= full_simulation_radius:
			count += 1
	return count

func get_debug_summaries(limit := 3) -> Array:
	var summaries := []
	for npc in npcs.slice(0, limit):
		if npc.has_method("get_debug_summary"):
			summaries.append(npc.get_debug_summary())
	return summaries

func _tick_nearby_npcs(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	var player_position := Vector2.ZERO if player == null else player.global_position
	for npc in npcs:
		if npc.global_position.distance_to(player_position) <= full_simulation_radius:
			npc.tick_schedule(simulated_minutes, delta)

func _tick_distant_npcs(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	var player_position := Vector2.ZERO if player == null else player.global_position
	for npc in npcs:
		if npc.global_position.distance_to(player_position) > full_simulation_radius:
			npc.tick_schedule(simulated_minutes, delta)

func _load_schedules() -> void:
	for path in _list_json_files(SCHEDULE_DIR):
		var data := _load_json(path)
		if not data.is_empty():
			schedules[str(data.get("id", path))] = data

func _spawn_npcs() -> void:
	var spawn_index := 0
	for path in _list_json_files(NPC_DIR):
		var npc_data := _load_json(path)
		var schedule_data: Dictionary = schedules.get(str(npc_data.get("schedule_id", "")), {})
		var npc: CharacterBody2D = NpcAgentScript.new()
		npc.name = str(npc_data.get("id", "npc"))
		npc.global_position = _spawn_position_for_index(spawn_index)
		add_child(npc)
		npc.configure(npc_data, schedule_data, target_positions, simulated_minutes)
		npcs.append(npc)
		spawn_index += 1

func _spawn_position_for_index(index: int) -> Vector2:
	return Vector2(220 + (index % 5) * 80, 420 + int(index / 5) * 70)

func _list_json_files(dir_path: String) -> Array[String]:
	var files: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_warning("Missing data directory: " + dir_path)
		return files
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			files.append(dir_path + "/" + file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	files.sort()
	return files

func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("Unable to open data file: " + path)
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Data file root must be a dictionary: " + path)
		return {}
	return parsed
