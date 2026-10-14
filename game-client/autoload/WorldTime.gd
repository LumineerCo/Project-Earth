## WorldTime.gd
## Manages the game world clock. Supports real-time mode (1 real sec = 1 game sec)
## and accelerated mode. Drives NPC schedules, economy ticks, and weather.
extends Node
class_name WorldTime

## ──────────────────────────────────────────────
##  Signals
## ──────────────────────────────────────────────

signal minute_tick(game_minutes: int)
signal hour_tick(game_hour: int)
signal day_tick(game_day: int)
signal time_scale_changed(new_scale: float)

## ──────────────────────────────────────────────
##  Constants
## ──────────────────────────────────────────────

const SECONDS_PER_MINUTE := 60
const MINUTES_PER_HOUR := 60
const HOURS_PER_DAY := 24
const SECONDS_PER_DAY := 86400

## ──────────────────────────────────────────────
##  State
## ──────────────────────────────────────────────

## 1.0 = real-time; 60.0 = 1 real sec = 1 game min
## NOTE: Autoloads have no scene context, so @export won't show in the inspector.
## Configure via code or a config file instead.
var time_scale: float = 1.0
## Game time in seconds since epoch (game world)
var game_time_seconds: float = 0.0
## Starting hour (game world starts at 8:00 AM by default)
var start_hour: int = 8

var _accumulated_seconds: float = 0.0
var _last_minute: int = -1
var _last_hour: int = -1
var _last_day: int = -1

## ──────────────────────────────────────────────
##  Lifecycle
## ──────────────────────────────────────────────

func _ready() -> void:
	game_time_seconds = float(start_hour * SECONDS_PER_MINUTE * MINUTES_PER_HOUR)
	_last_minute = get_minute()
	_last_hour = get_hour()
	_last_day = get_day()
	DebugManager.log_info("WorldTime", "Initialized at day %d, %02d:%02d" % [get_day(), get_hour(), get_minute()])

func _process(delta: float) -> void:
	game_time_seconds += delta * time_scale
	_check_ticks()

## ──────────────────────────────────────────────
##  Time Accessors
## ──────────────────────────────────────────────

func get_total_seconds() -> float:
	return game_time_seconds

func get_day() -> int:
	return int(game_time_seconds) / SECONDS_PER_DAY

func get_hour() -> int:
	return (int(game_time_seconds) % SECONDS_PER_DAY) / SECONDS_PER_MINUTE / MINUTES_PER_HOUR

func get_minute() -> int:
	return (int(game_time_seconds) % (SECONDS_PER_MINUTE * MINUTES_PER_HOUR)) / SECONDS_PER_MINUTE

func get_second() -> int:
	return int(game_time_seconds) % SECONDS_PER_MINUTE

func get_time_string() -> String:
	return "%02d:%02d:%02d" % [get_hour(), get_minute(), get_second()]

func get_day_string() -> String:
	return "Day %d" % get_day()

## Returns 0.0 (midnight) to 1.0 (next midnight) for sun position
func get_day_progress() -> float:
	var sec_in_day := fmod(game_time_seconds, float(SECONDS_PER_DAY))
	return sec_in_day / float(SECONDS_PER_DAY)

## Returns hour as float (e.g., 14.5 = 2:30 PM)
func get_hour_float() -> float:
	var sec_in_day := fmod(game_time_seconds, float(SECONDS_PER_DAY))
	return sec_in_day / float(SECONDS_PER_MINUTE * MINUTES_PER_HOUR)

## ──────────────────────────────────────────────
##  Time Scale Control
## ──────────────────────────────────────────────

func set_time_scale(new_scale: float) -> void:
	time_scale = clamp(new_scale, 0.0, 3600.0)
	time_scale_changed.emit(time_scale)
	DebugManager.log_info("WorldTime", "Time scale set to %.1f" % time_scale)

func pause_time() -> void:
	set_time_scale(0.0)

func resume_time() -> void:
	set_time_scale(1.0)

## ──────────────────────────────────────────────
##  Tick System
## ──────────────────────────────────────────────

func _check_ticks() -> void:
	var current_minute := get_minute()
	var current_hour := get_hour()
	var current_day := get_day()
	
	if current_minute != _last_minute:
		_last_minute = current_minute
		minute_tick.emit(current_minute)
	
	if current_hour != _last_hour:
		_last_hour = current_hour
		hour_tick.emit(current_hour)
	
	if current_day != _last_day:
		_last_day = current_day
		day_tick.emit(current_day)

## ──────────────────────────────────────────────
##  Serialization
## ──────────────────────────────────────────────

func serialize() -> Dictionary:
	return {
		"game_time_seconds": game_time_seconds,
		"time_scale": time_scale,
	}

func deserialize(data: Dictionary) -> void:
	game_time_seconds = data.get("game_time_seconds", 0.0)
	time_scale = data.get("time_scale", 1.0)
	_last_minute = get_minute()
	_last_hour = get_hour()
	_last_day = get_day()
