## DebugManager.gd
## Centralized debug logging and diagnostics. Toggleable at runtime.
extends Node
class_name DebugManager

## ──────────────────────────────────────────────
##  Enums & Signals
## ──────────────────────────────────────────────

enum LogLevel {
	TRACE,
	DEBUG,
	INFO,
	WARN,
	ERROR,
	FATAL
}

signal log_emitted(level: LogLevel, category: String, message: String)

## ──────────────────────────────────────────────
##  Configuration
## ──────────────────────────────────────────────

## NOTE: Autoloads have no scene context, so @export won't show in the inspector.
## Configure via code or a config file instead.
var enabled: bool = true
var min_log_level: LogLevel = LogLevel.DEBUG
var log_to_file: bool = true
var log_to_console: bool = true
var max_log_entries: int = 1000

## ──────────────────────────────────────────────
##  State
## ──────────────────────────────────────────────

var _log_entries: Array[Dictionary] = []
var _log_file_path: String = "user://logs/game.log"
var _frame_log_count: int = 0
var _max_logs_per_frame: int = 50

## ──────────────────────────────────────────────
##  Lifecycle
## ──────────────────────────────────────────────

func _ready() -> void:
	_ensure_log_dir()
	if log_to_file:
		_write_to_file("=== Project Earth Log Session Started ===")

func _process(_delta: float) -> void:
	_frame_log_count = 0

## ──────────────────────────────────────────────
##  Public Logging API
## ──────────────────────────────────────────────

func log_trace(category: String, message: String) -> void:
	_emit_log(LogLevel.TRACE, category, message)

func log_debug(category: String, message: String) -> void:
	_emit_log(LogLevel.DEBUG, category, message)

func log_info(category: String, message: String) -> void:
	_emit_log(LogLevel.INFO, category, message)

func log_warn(category: String, message: String) -> void:
	_emit_log(LogLevel.WARN, category, message)

func log_error(category: String, message: String) -> void:
	_emit_log(LogLevel.ERROR, category, message)

func log_fatal(category: String, message: String) -> void:
	_emit_log(LogLevel.FATAL, category, message)
	push_error("[FATAL] %s: %s" % [category, message])

## ──────────────────────────────────────────────
##  Log Retrieval
## ──────────────────────────────────────────────

func get_recent_logs(count: int = 50) -> Array[Dictionary]:
	var start := max(0, _log_entries.size() - count)
	return _log_entries.slice(start)

func clear_logs() -> void:
	_log_entries.clear()

func get_log_count() -> int:
	return _log_entries.size()

## ──────────────────────────────────────────────
##  Internal
## ──────────────────────────────────────────────

func _emit_log(level: LogLevel, category: String, message: String) -> void:
	if not enabled or level < min_log_level:
		return
	if _frame_log_count >= _max_logs_per_frame:
		return
	_frame_log_count += 1
	
	var entry := {
		"timestamp": Time.get_unix_time_from_system(),
		"level": level,
		"level_name": LogLevel.keys()[level],
		"category": category,
		"message": message,
	}
	
	_log_entries.append(entry)
	if _log_entries.size() > max_log_entries:
		_log_entries.pop_front()
	
	var formatted := _format_entry(entry)
	if log_to_console:
		print(formatted)
	if log_to_file:
		_write_to_file(formatted)
	
	log_emitted.emit(level, category, message)

func _format_entry(entry: Dictionary) -> String:
	var time_str := Time.get_datetime_string_from_unix_time(entry.timestamp)
	return "[%s] [%s] [%s] %s" % [time_str, entry.level_name, entry.category, entry.message]

func _ensure_log_dir() -> void:
	var dir := DirAccess.open("user://")
	if dir and not dir.dir_exists("logs"):
		dir.make_dir("logs")

func _write_to_file(text: String) -> void:
	var file := FileAccess.open(_log_file_path, FileAccess.READ_WRITE)
	if not file:
		file = FileAccess.open(_log_file_path, FileAccess.WRITE)
	if file:
		file.seek_end()
		file.store_line(text)
		file.close()
