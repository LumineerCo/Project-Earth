## WorldInspector.gd
## Autoload singleton providing a real-time world/environment overlay.
## Stage 2.8 Phase 6 — World Inspector
##
## Surfaces the player's current world context: continent/country/state/city/
## district/chunk, coordinates, elevation, time of day, weather, and nearby
## entity counts. Invaluable for testing streamed worlds.
extends CanvasLayer
class_name WorldInspector

## ──────────────────────────────────────────────
##  Configuration
## ──────────────────────────────────────────────

const TOGGLE_KEY := KEY_F4
const REFRESH_INTERVAL := 0.25  # seconds between display refreshes
const NEARBY_RADIUS := 100.0    # meters considered "nearby"

## ──────────────────────────────────────────────
##  State
## ──────────────────────────────────────────────

var _visible := false
var _refresh_timer := 0.0
var _player: Node = null

## ──────────────────────────────────────────────
##  UI References
## ──────────────────────────────────────────────

var _root: PanelContainer
var _label: RichTextLabel

## ──────────────────────────────────────────────
##  Lifecycle
## ──────────────────────────────────────────────

func _ready() -> void:
	layer = 98
	_build_ui()
	_root.visible = _visible
	DebugManager.log_info("WorldInspector", "Ready (toggle: F4)")

func _process(delta: float) -> void:
	if not _visible:
		return
	_refresh_timer += delta
	if _refresh_timer >= REFRESH_INTERVAL:
		_refresh_timer = 0.0
		_refresh_display()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == TOGGLE_KEY:
			toggle()

## ──────────────────────────────────────────────
##  Public API
## ──────────────────────────────────────────────

func toggle() -> void:
	set_visible(not _visible)

func set_visible(v: bool) -> void:
	_visible = v
	_root.visible = v
	if v:
		_refresh_timer = REFRESH_INTERVAL  # force immediate refresh
	console_toggled.emit(v)
	DebugManager.log_debug("WorldInspector", "Visible=%s" % v)

func is_visible() -> bool:
	return _visible

func set_player(player: Node) -> void:
	_player = player

## ──────────────────────────────────────────────
##  UI Construction
## ──────────────────────────────────────────────

func _build_ui() -> void:
	_root = PanelContainer.new()
	_root.name = "WorldInspectorRoot"
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.offset_left = 10.0
	_root.offset_top = 310.0  # below PerformanceMonitor
	_root.offset_right = 330.0
	_root.offset_bottom = 560.0

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.07, 0.10, 0.82)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.3, 0.5, 0.7, 0.6)
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	_root.add_theme_stylebox_override("panel", style)

	_label = RichTextLabel.new()
	_label.name = "InspectorLabel"
	_label.bbcode_enabled = true
	_label.fit_content = true
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.scroll_active = false
	_root.add_child(_label)

	add_child(_root)

## ──────────────────────────────────────────────
##  Data Gathering
## ──────────────────────────────────────────────

func _get_player_position() -> Vector3:
	if _player and is_instance_valid(_player) and _player.has_method("get_global_position"):
		return _player.get_global_position()
	if _player and is_instance_valid(_player) and "global_position" in _player:
		return _player.global_position
	return Vector3.ZERO

func _get_player_elevation() -> float:
	return _get_player_position().y

## Returns the chunk key for a world position (256m chunks per Stage 1.6).
func _get_chunk_key(pos: Vector3) -> Vector2i:
	const CHUNK_SIZE := 256
	return Vector2i(int(floor(pos.x / CHUNK_SIZE)), int(floor(pos.z / CHUNK_SIZE)))

## Returns the nearest city name from loaded world data, if available.
func _get_nearest_city(pos: Vector3) -> String:
	var cities_dir := "res://data/cities/"
	if not DirAccess.dir_exists_absolute(cities_dir):
		return "—"
	var nearest := "—"
	var nearest_dist := INF
	var dir := DirAccess.open(cities_dir)
	if dir == null:
		return "—"
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if fname.ends_with(".json") and not dir.current_is_dir():
			var path := cities_dir + fname
			var text := FileAccess.get_file_as_string(path)
			if text != "":
				var data = JSON.parse_string(text)
				if data is Dictionary and data.has("position"):
					var cpos = data["position"]
					if cpos is Array and cpos.size() >= 2:
						var cvec := Vector3(float(cpos[0]), 0.0, float(cpos[1]))
						var d := pos.distance_to(cvec)
						if d < nearest_dist:
							nearest_dist = d
							nearest = data.get("name", fname.get_basename())
		fname = dir.get_next()
	return nearest if nearest != "—" else "—"

func _get_weather_summary() -> String:
	# WeatherManager not yet implemented in Stage 2; surface a placeholder.
	if not has_node("/root/WeatherManager"):
		return "[color=#888]not loaded[/color]"
	var wm = get_node("/root/WeatherManager")
	if wm.has_method("get_summary"):
		return wm.get_summary()
	return "[color=#888]available[/color]"

func _count_nearby_npcs(pos: Vector3) -> int:
	if not has_node("/root/NPCManager"):
		return 0
	var nm = get_node("/root/NPCManager")
	if not nm.has_method("get_active_count"):
		return 0
	return nm.get_active_count()

func _count_nearby_vehicles(pos: Vector3) -> int:
	return get_tree().get_nodes_in_group("vehicles").size()

## ──────────────────────────────────────────────
##  Display
## ──────────────────────────────────────────────

func _refresh_display() -> void:
	var pos := _get_player_position()
	var chunk := _get_chunk_key(pos)
	var lines: Array[String] = []
	lines.append("[color=#6cb0e0][b]World Inspector[/b][/color]")
	lines.append("")
	lines.append("[color=#a0c0e0]Location[/color]")
	lines.append("  Continent: [color=#888]—[/color]")
	lines.append("  Country:   [color=#888]—[/color]")
	lines.append("  State:     [color=#888]—[/color]")
	lines.append("  City:      [color=#e0d86c]%s[/color]" % _get_nearest_city(pos))
	lines.append("  District:  [color=#888]—[/color]")
	lines.append("  Chunk:     [color=#e0d86c](%d, %d)[/color]" % [chunk.x, chunk.y])
	lines.append("")
	lines.append("[color=#a0c0e0]Coordinates[/color]")
	lines.append("  X: [color=#e0d86c]%.2f[/color]  Y: [color=#e0d86c]%.2f[/color]  Z: [color=#e0d86c]%.2f[/color]" % [pos.x, pos.y, pos.z])
	lines.append("  Elevation: [color=#e0d86c]%.1f m[/color]" % _get_player_elevation())
	lines.append("")
	lines.append("[color=#a0c0e0]Environment[/color]")
	lines.append("  Time:      [color=#e0d86c]%s[/color]" % WorldTime.get_time_string())
	lines.append("  Day:       [color=#e0d86c]%d[/color]" % WorldTime.get_day())
	lines.append("  Weather:   %s" % _get_weather_summary())
	lines.append("")
	lines.append("[color=#a0c0e0]Entities (nearby)[/color]")
	lines.append("  NPCs:      [color=#6ce06c]%d[/color]" % _count_nearby_npcs(pos))
	lines.append("  Vehicles:  [color=#6ce06c]%d[/color]" % _count_nearby_vehicles(pos))
	_label.text = "\n".join(lines)

## ──────────────────────────────────────────────
##  Signals
## ──────────────────────────────────────────────

signal console_toggled(is_open: bool)
