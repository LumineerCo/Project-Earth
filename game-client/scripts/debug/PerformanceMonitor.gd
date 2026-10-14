## PerformanceMonitor.gd
## Real-time performance overlay (Stage 2.8 Phase 5).
##
## Tracks FPS, frame time, memory, and scene object counts, displaying
## both current values and short-term trends (sparkline-style bars).
## Toggle with F3 or the `perf` console command.
##
## Metrics tracked (per Stage 2.8 plan):
##   - FPS + frame time (CPU)
##   - Static/dynamic memory
##   - Object counts: nodes, physics bodies, NPCs, vehicles, audio sources
extends CanvasLayer
class_name PerformanceMonitor

## ──────────────────────────────────────────────
##  Configuration
## ──────────────────────────────────────────────

const TOGGLE_KEY := KEY_F3
const SAMPLE_INTERVAL := 0.1   # seconds between samples
const TREND_LENGTH := 60      # number of samples kept for trend bars
const REFRESH_INTERVAL := 0.25  # seconds between UI text refreshes

## ──────────────────────────────────────────────
##  State
## ──────────────────────────────────────────────

var _visible: bool = false
var _sample_timer: float = 0.0
var _refresh_timer: float = 0.0

# Trend buffers (ring buffers of floats)
var _fps_trend: Array[float] = []
var _frametime_trend: Array[float] = []
var _mem_trend: Array[float] = []

# Latest sampled values
var _fps: float = 0.0
var _frame_time_ms: float = 0.0
var _mem_static_mb: float = 0.0
var _mem_dynamic_mb: float = 0.0
var _node_count: int = 0
var _body_count: int = 0
var _body3d_count: int = 0
var _area_count: int = 0
var _npc_count: int = 0
var _vehicle_count: int = 0
var _audio_count: int = 0
var _animation_count: int = 0

## ──────────────────────────────────────────────
##  UI References
## ──────────────────────────────────────────────

var _root: PanelContainer = null
var _label: RichTextLabel = null

## ──────────────────────────────────────────────
##  Lifecycle
## ──────────────────────────────────────────────

func _ready() -> void:
	layer = 99  # Just below DebugConsole (100), above HUD (10)
	_build_ui()
	_root.visible = _visible
	DebugManager.log_info("PerformanceMonitor", "Ready (toggle: F3)")

func _process(delta: float) -> void:
	_sample_timer += delta
	_refresh_timer += delta

	if _sample_timer >= SAMPLE_INTERVAL:
		_sample_timer = 0.0
		_sample_metrics()

	if _visible and _refresh_timer >= REFRESH_INTERVAL:
		_refresh_timer = 0.0
		_refresh_display()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == TOGGLE_KEY:
		toggle()
		get_viewport().set_input_as_handled()

## ──────────────────────────────────────────────
##  UI Construction
## ──────────────────────────────────────────────

func _build_ui() -> void:
	_root = PanelContainer.new()
	_root.name = "PerformanceMonitor"
	_root.anchor_right = 1.0
	_root.anchor_bottom = 1.0
	_root.offset_left = 12.0
	_root.offset_top = 12.0
	_root.offset_right = -12.0
	_root.offset_bottom = 12.0
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_theme_stylebox_override("panel", _make_panel_style())
	add_child(_root)

	_label = RichTextLabel.new()
	_label.name = "Stats"
	_label.bbcode_enabled = true
	_label.fit_content = true
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_override("normal_font", _get_mono_font())
	_label.add_theme_font_override("mono_font", _get_mono_font())
	_root.add_child(_label)

func _make_panel_style() -> StyleBox:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.02, 0.04, 0.55)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_color = Color(0.3, 0.6, 0.9, 0.4)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style

func _get_mono_font() -> Font:
	if ResourceLoader.exists("res://addons/default_mono.tres"):
		var mono := load("res://addons/default_mono.tres") as Font
		if mono:
			return mono
	return get_theme_default_font()

## ──────────────────────────────────────────────
##  Visibility
## ──────────────────────────────────────────────

func toggle() -> void:
	_visible = not _visible
	_root.visible = _visible
	if _visible:
		_refresh_display()
	DebugManager.log_debug("PerformanceMonitor", "Overlay %s" % ("on" if _visible else "off"))

func set_visible(v: bool) -> void:
	_visible = v
	_root.visible = v

## ──────────────────────────────────────────────
##  Sampling
## ──────────────────────────────────────────────

func _sample_metrics() -> void:
	_fps = float(Engine.get_frames_per_second())
	_frame_time_ms = 1000.0 / max(_fps, 1.0)

	# Memory (Godot performance monitors)
	var static_mem := Performance.get_monitor(Performance.RENDER_MEMORY_MEM_STATIC)
	var dynamic_mem := Performance.get_monitor(Performance.RENDER_MEMORY_MEM_DYNAMIC)
	_mem_static_mb = static_mem / (1024.0 * 1024.0)
	_mem_dynamic_mb = dynamic_mem / (1024.0 * 1024.0)

	# Object counts via performance monitors
	_node_count = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	_body_count = int(Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS))
	_area_count = int(Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_AREAS))

	# Counts not exposed via Performance — query the tree directly.
	_body3d_count = _count_nodes_of_type("PhysicsBody3D")
	_npc_count = _count_nodes_in_group("npcs")
	_vehicle_count = _count_nodes_in_group("vehicles")
	_audio_count = _count_nodes_of_type("AudioStreamPlayer")
	_animation_count = _count_nodes_of_type("AnimationPlayer")

	# Push trends
	_push_trend(_fps_trend, _fps)
	_push_trend(_frametime_trend, _frame_time_ms)
	_push_trend(_mem_trend, _mem_static_mb + _mem_dynamic_mb)

func _push_trend(buffer: Array[float], value: float) -> void:
	buffer.append(value)
	if buffer.size() > TREND_LENGTH:
		buffer.pop_front()

func _count_nodes_of_type(type_name: String) -> int:
	var count := 0
	var root := get_tree().root
	for node in root.get_descendants():
		if node.is_class(type_name) or node.get_class() == type_name:
			count += 1
	return count

func _count_nodes_in_group(group: String) -> int:
	return get_tree().get_nodes_in_group(group).size()

## ──────────────────────────────────────────────
##  Display
## ──────────────────────────────────────────────

func _refresh_display() -> void:
	var lines: Array[String] = []
	lines.append("[color=#6cb0e0][b]Performance Monitor[/b][/color]   [color=#888](F3 to toggle)[/color]")
	lines.append("")

	# FPS with color coding
	var fps_color := _fps_color(_fps)
	lines.append("[color=#aaa]FPS[/color]      [color=%s]%5.1f[/color]  %s" % [fps_color, _fps, _sparkline(_fps_trend, 0.0, 120.0)])
	lines.append("[color=#aaa]Frame[/color]   [color=#c0d8e8]%5.2f ms[/color]  %s" % [_frame_time_ms, _sparkline(_frametime_trend, 0.0, 33.0)])
	lines.append("")

	# Memory
	lines.append("[color=#aaa]Memory[/color]")
	lines.append("  static:   [color=#c0d8e8]%6.1f MB[/color]" % _mem_static_mb)
	lines.append("  dynamic:  [color=#c0d8e8]%6.1f MB[/color]" % _mem_dynamic_mb)
	lines.append("  total:    [color=#6cb0e0]%6.1f MB[/color]  %s" % [_mem_static_mb + _mem_dynamic_mb, _sparkline(_mem_trend, 0.0, max(_mem_trend.max() if not _mem_trend.is_empty() else 1.0, 1.0))])
	lines.append("")

	# Object counts
	lines.append("[color=#aaa]Objects[/color]")
	lines.append("  nodes:        [color=#c0d8e8]%d[/color]" % _node_count)
	lines.append("  bodies 3D:    [color=#c0d8e8]%d[/color]  (active: %d)" % [_body3d_count, _body_count])
	lines.append("  areas 3D:     [color=#c0d8e8]%d[/color]" % _area_count)
	lines.append("  NPCs:          [color=#c0d8e8]%d[/color]" % _npc_count)
	lines.append("  vehicles:      [color=#c0d8e8]%d[/color]" % _vehicle_count)
	lines.append("  audio:         [color=#c0d8e8]%d[/color]" % _audio_count)
	lines.append("  animations:    [color=#c0d8e8]%d[/color]" % _animation_count)

	_label.text = "\n".join(lines)

func _fps_color(fps: float) -> String:
	if fps >= 55.0:
		return "#6ce06c"  # green
	elif fps >= 30.0:
		return "#e0d86c"  # yellow
	return "#e06c6c"      # red

## Render a tiny ASCII sparkline from a buffer of floats.
## `max_val` clamps the scale; values are normalized to 8 vertical bars.
func _sparkline(buffer: Array[float], min_val: float, max_val: float) -> String:
	if buffer.is_empty():
		return ""
	var bars := "▁▂▃▄▅▆▇█"
	var out := ""
	var range_val := max(max_val - min_val, 0.001)
	for v in buffer:
		var normalized := clamp((v - min_val) / range_val, 0.0, 1.0)
		var idx := int(normalized * (bars.length() - 1))
		out += bars[idx]
	return "[color=#6cb0e0]" + out + "[/color]"
