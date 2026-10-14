## DebugConsole.gd
## In-game developer console (Stage 2.8 Phase 3).
##
## Provides a togglable command-line interface for quick testing without
## creating temporary UI. Commands are registered by name with a callable,
## a description, and an optional argument hint. The console is disabled in
## release builds via DebugManager.developer_mode.
##
## Usage:
##   DebugConsole.register("help", _cmd_help, "Show available commands")
##   DebugConsole.register("teleport", _cmd_teleport, "Teleport player", "<x> <z>")
##   DebugConsole.execute("teleport 10 20")
extends CanvasLayer
class_name DebugConsole

## ──────────────────────────────────────────────
##  Signals
## ──────────────────────────────────────────────

signal command_executed(command: String, success: bool)
signal console_toggled(open: bool)

## ──────────────────────────────────────────────
##  Configuration
## ──────────────────────────────────────────────

const TOGGLE_KEY := KEY_QUOTELEFT  # Backtick (`)
const MAX_HISTORY := 50
const MAX_OUTPUT_LINES := 200
const CONSOLE_HEIGHT := 280

## ──────────────────────────────────────────────
##  State
## ──────────────────────────────────────────────

var _commands: Dictionary = {}  # name -> { "callable": Callable, "desc": String, "args": String }
var _history: Array[String] = []
var _history_index: int = -1
var _is_open: bool = false

## ──────────────────────────────────────────────
##  UI References
## ──────────────────────────────────────────────

var _root: PanelContainer = null
var _output: RichTextLabel = null
var _input: LineEdit = null
var _hint: Label = null

## ──────────────────────────────────────────────
##  Lifecycle
## ──────────────────────────────────────────────

func _ready() -> void:
	layer = 100  # Above HUD/pause menu
	_build_ui()
	_register_default_commands()
	_close()
	DebugManager.log_info("DebugConsole", "Console ready (%d commands)" % _commands.size())

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug") or \
			(event is InputEventKey and event.pressed and event.keycode == TOGGLE_KEY):
		if _is_open:
			_close()
		else:
			_open()
		get_viewport().set_input_as_handled()

## ──────────────────────────────────────────────
##  UI Construction
## ──────────────────────────────────────────────

func _build_ui() -> void:
	_root = PanelContainer.new()
	_root.name = "DebugConsole"
	_root.custom_minimum_size = Vector2(0, CONSOLE_HEIGHT)
	_root.add_theme_stylebox_override("panel", _make_panel_style())
	add_child(_root)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	_root.add_child(vbox)

	# Output area
	_output = RichTextLabel.new()
	_output.name = "Output"
	_output.bbcode_enabled = true
	_output.scroll_following = true
	_output.selection_enabled = true
	_output.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_output.add_theme_font_override("normal_font", _get_mono_font())
	_output.add_theme_font_override("mono_font", _get_mono_font())
	vbox.add_child(_output)

	# Hint line (shows current command's arg hint)
	_hint = Label.new()
	_hint.name = "Hint"
	_hint.add_theme_font_override("font", _get_mono_font())
	_hint.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))
	vbox.add_child(_hint)

	# Input line
	_input = LineEdit.new()
	_input.name = "Input"
	_input.placeholder_text = "Type a command (try `help`)…"
	_input.add_theme_font_override("font", _get_mono_font())
	_input.text_submitted.connect(_on_input_submitted)
	_input.text_changed.connect(_on_input_changed)
	vbox.add_child(_input)

func _make_panel_style() -> StyleBox:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.08, 0.92)
	style.border_width_top = 2
	style.border_color = Color(0.3, 0.6, 0.9)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style

func _get_mono_font() -> Font:
	# Try a project monospace font first, then fall back to the engine default.
	if ResourceLoader.exists("res://addons/default_mono.tres"):
		var mono := load("res://addons/default_mono.tres") as Font
		if mono:
			return mono
	return get_theme_default_font()

## ──────────────────────────────────────────────
##  Open / Close
## ──────────────────────────────────────────────

func _open() -> void:
	_is_open = true
	_root.visible = true
	_input.grab_focus()
	console_toggled.emit(true)
	DebugManager.log_debug("DebugConsole", "Console opened")

func _close() -> void:
	_is_open = false
	_root.visible = false
	console_toggled.emit(false)

func is_open() -> bool:
	return _is_open

## ──────────────────────────────────────────────
##  Command Registration
## ──────────────────────────────────────────────

## Register a console command.
## `cmd_callable` receives an Array[String] of arguments and returns a String (output).
func register(name: String, cmd_callable: Callable, description: String = "", arg_hint: String = "") -> void:
	name = name.to_lower()
	_commands[name] = {
		"callable": cmd_callable,
		"desc": description,
		"args": arg_hint,
	}

func unregister(name: String) -> void:
	_commands.erase(name.to_lower())

func has_command(name: String) -> bool:
	return _commands.has(name.to_lower())

func get_commands() -> Dictionary:
	return _commands.duplicate()

## ──────────────────────────────────────────────
##  Execution
## ──────────────────────────────────────────────

func execute(input_text: String) -> void:
	var trimmed := input_text.strip_edges()
	if trimmed.is_empty():
		return
	_print_line("[color=#7a9ec2]> %s[/color]" % trimmed)
	_history.append(trimmed)
	if _history.size() > MAX_HISTORY:
		_history.pop_front()
	_history_index = _history.size()

	var parts := _tokenize(trimmed)
	if parts.is_empty():
		return
	var cmd_name := parts[0].to_lower()
	var args := parts.slice(1) as Array[String]

	if not _commands.has(cmd_name):
		_print_line("[color=#e06c6c]Unknown command: %s (try `help`)[/color]" % cmd_name)
		command_executed.emit(cmd_name, false)
		return

	var entry: Dictionary = _commands[cmd_name]
	var callable: Callable = entry["callable"]
	var result := _safe_call(callable, args)
	var ok := true
	if not result.is_empty():
		_print_line(result)
	command_executed.emit(cmd_name, ok)
	DebugManager.log_debug("DebugConsole", "Exec: %s -> %s" % [trimmed, "ok" if ok else "fail"])

func _safe_call(callable: Callable, args: Array[String]) -> String:
	var ret = callable.call(args)
	if ret is String:
		return ret
	return ""

func _tokenize(text: String) -> PackedStringArray:
	# Simple whitespace tokenizer with basic quote support.
	var tokens: PackedStringArray = []
	var current := ""
	var in_quotes := false
	for ch in text:
		if ch == "\"":
			in_quotes = not in_quotes
		elif ch == " " and not in_quotes:
			if not current.is_empty():
				tokens.append(current)
				current = ""
		else:
			current += ch
	if not current.is_empty():
		tokens.append(current)
	return tokens

## ──────────────────────────────────────────────
##  Output
## ──────────────────────────────────────────────

func _print_line(text: String) -> void:
	_output.append_text(text + "\n")
	# Trim old lines to keep memory bounded.
	while _output.get_line_count() > MAX_OUTPUT_LINES:
		_output.remove_line(0)

func clear_output() -> void:
	_output.clear()

## ──────────────────────────────────────────────
##  Input Handling
## ──────────────────────────────────────────────

func _on_input_submitted(text: String) -> void:
	execute(text)
	_input.clear()
	_hint.text = ""

func _on_input_changed(text: String) -> void:
	# Live hint: show arg hint for the command being typed.
	var parts := _tokenize(text)
	if parts.is_empty():
		_hint.text = ""
		return
	var cmd_name := parts[0].to_lower()
	if _commands.has(cmd_name):
		var entry: Dictionary = _commands[cmd_name]
		var hint := entry["args"] as String
		_hint.text = "%s  %s — %s" % [cmd_name, hint, entry["desc"]]
	else:
		_hint.text = ""

func _input(event: InputEvent) -> void:
	# History navigation when console is open.
	if not _is_open:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_UP:
			_navigate_history(-1)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_DOWN:
			_navigate_history(1)
			get_viewport().set_input_as_handled()

func _navigate_history(direction: int) -> void:
	if _history.is_empty():
		return
	_history_index = clamp(_history_index + direction, 0, _history.size() - 1)
	if _history_index >= 0 and _history_index < _history.size():
		_input.text = _history[_history_index]
		_input.caret_column = _input.text.length()

## ──────────────────────────────────────────────
##  Default Commands
## ──────────────────────────────────────────────

func _register_default_commands() -> void:
	register("help", _cmd_help, "List available commands")
	register("clear", _cmd_clear, "Clear console output")
	register("quit", _cmd_quit, "Quit the game")
	register("fps", _cmd_fps, "Show current FPS")
	register("time", _cmd_time, "Set or show world time", "[hh:mm]")
	register("loglevel", _cmd_loglevel, "Set min log level (0-5)", "<level>")
	register("state", _cmd_state, "Show current game state")
	register("seed", _cmd_seed, "Show or set world seed", "[value]")
	register("perf", _cmd_perf, "Toggle performance monitor overlay")
	register("inspector", _cmd_inspector, "Toggle world inspector overlay")

func _cmd_help(_args: Array[String]) -> String:
	var lines: Array[String] = []
	lines.append("[color=#6cb0e0]Available commands:[/color]")
	var names := _commands.keys()
	names.sort()
	for name in names:
		var entry: Dictionary = _commands[name]
		var hint: String = entry["args"]
		var desc: String = entry["desc"]
		var line := "  [color=#c0d8e8]%s[/color]" % name
		if not hint.is_empty():
			line += " [color=#888]%s[/color]" % hint
		if not desc.is_empty():
			line += "  — %s" % desc
		lines.append(line)
	return "\n".join(lines)

func _cmd_clear(_args: Array[String]) -> String:
	clear_output()
	return ""

func _cmd_quit(_args: Array[String]) -> String:
	get_tree().quit()
	return "Quitting…"

func _cmd_fps(_args: Array[String]) -> String:
	var fps := Engine.get_frames_per_second()
	return "FPS: [color=#6cb0e0]%d[/color]  |  frame: %.2f ms" % [fps, 1000.0 / max(fps, 1)]

func _cmd_time(args: Array[String]) -> String:
	if args.is_empty():
		return "World time: %s  (scale: %.1fx)" % [WorldTime.get_time_string(), WorldTime.time_scale]
	# Parse hh:mm
	var parts := args[0].split(":")
	if parts.size() < 2:
		return "[color=#e06c6c]Usage: time hh:mm[/color]"
	var h := int(parts[0])
	var m := int(parts[1])
	WorldTime.game_time_seconds = float(h * 3600 + m * 60)
	return "Time set to %s" % WorldTime.get_time_string()

func _cmd_loglevel(args: Array[String]) -> String:
	if args.is_empty():
		return "Min log level: %d (%s)" % [DebugManager.min_log_level, DebugManager.LogLevel.keys()[DebugManager.min_log_level]]
	var lvl := int(args[0])
	lvl = clamp(lvl, 0, DebugManager.LogLevel.size() - 1)
	DebugManager.min_log_level = lvl
	return "Min log level set to %d (%s)" % [lvl, DebugManager.LogLevel.keys()[lvl]]

func _cmd_state(_args: Array[String]) -> String:
	return "Game state: %s" % GameManager.GameState.keys()[GameManager.current_state]

func _cmd_seed(args: Array[String]) -> String:
	if args.is_empty():
		return "World seed: %d" % GameManager.world_seed
	var s := int(args[0])
	GameManager.world_seed = s
	return "World seed set to %d" % s

func _cmd_perf(_args: Array[String]) -> String:
	PerformanceMonitor.toggle()
	return "Performance monitor: %s" % ("ON" if PerformanceMonitor._visible else "OFF")

func _cmd_inspector(_args: Array[String]) -> String:
	if not has_node("/root/WorldInspector"):
		return "WorldInspector not loaded"
	var wi = get_node("/root/WorldInspector")
	wi.toggle()
	return "World inspector: %s" % ("ON" if wi.is_visible() else "OFF")
