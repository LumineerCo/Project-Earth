## NPCSchedule.gd
## Time-based daily routine driver for NPCs.
## Connects to WorldTime.hour_tick and updates NPC behavior based on schedule.
## Stage 3.4 Step 5 (Schedule-Driven Behavior)
extends Node
class_name NPCSchedule

## ──────────────────────────────────────────────
##  Configuration
## ──────────────────────────────────────────────

const SLEEP_HOUR := 22
const WAKE_HOUR := 6

## ──────────────────────────────────────────────
##  State
## ──────────────────────────────────────────────

var _npc: NPCBase = null
var _data: NPCData = null
var _current_activity: String = "idle"
var _activity_target: Vector3 = Vector3.ZERO

## ──────────────────────────────────────────────
##  Lifecycle
## ──────────────────────────────────────────────

func _ready() -> void:
	if has_node("/root/WorldTime"):
		WorldTime.hour_tick.connect(_on_hour_tick)

## ──────────────────────────────────────────────
##  Public API
## ──────────────────────────────────────────────

func initialize(npc: NPCBase) -> void:
	_npc = npc
	_data = npc.data
	if _data:
		_update_activity_for_hour(WorldTime.get_hour() if has_node("/root/WorldTime") else 8)

func get_current_activity() -> String:
	return _current_activity

func get_activity_target() -> Vector3:
	return _activity_target

## ──────────────────────────────────────────────
##  Schedule Processing
## ──────────────────────────────────────────────

func _on_hour_tick(game_hour: int) -> void:
	_update_activity_for_hour(game_hour)

func _update_activity_for_hour(hour: int) -> void:
	if not _data or not _data.schedule:
		_current_activity = "wander"
		return
	# Find the most recent schedule entry at or before current hour
	var best_hour := -1
	for sched_hour in _data.schedule.keys():
		if sched_hour <= hour and sched_hour > best_hour:
			best_hour = sched_hour
	if best_hour < 0:
		_current_activity = "wander"
		return
	_current_activity = _data.schedule[best_hour]
	_set_activity_target(_current_activity)
	_log_debug("Activity: %s (hour %d)" % [_current_activity, hour])

func _set_activity_target(activity: String) -> void:
	match activity:
		"work", "commute_to_work":
			_activity_target = _data.work_position if _data else Vector3.ZERO
		"home", "commute_home", "sleep":
			_activity_target = _data.home_position if _data else Vector3.ZERO
		"patrol", "wander", "explore", "errands", "leisure":
			_activity_target = Vector3.ZERO  # NPCBase picks random wander target
		"lunch", "break", "rest", "off_duty":
			_activity_target = Vector3.ZERO
		_:
			_activity_target = Vector3.ZERO

## Check if the NPC should be sleeping (reduced activity).
func is_sleeping() -> bool:
	return _current_activity == "sleep"

## Get a movement speed multiplier based on current activity.
func get_speed_multiplier() -> float:
	match _current_activity:
		"commute_to_work", "commute_home":
			return 1.2  # Walk slightly faster when commuting
		"patrol":
			return 1.1
		"sleep":
			return 0.0  # Don't move while sleeping
		"rest":
			return 0.3  # Slow movement
		_:
			return 1.0

## ──────────────────────────────────────────────
##  Helpers
## ──────────────────────────────────────────────

func _log_debug(msg: String) -> void:
	if has_node("/root/DebugManager"):
		DebugManager.log_debug("NPCSchedule", "%s: %s" % [_data.full_name() if _data else "?", msg])
