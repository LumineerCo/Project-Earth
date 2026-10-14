## HUD.gd
## In-game heads-up display — interaction prompt, crosshair, debug overlay.
## Stage 2.12 Milestone 10 (HUD) + Milestone 14 (Debug Integration)
extends CanvasLayer

## ──────────────────────────────────────────────
##  Configuration
## ──────────────────────────────────────────────

const DEBUG_UPDATE_INTERVAL := 0.25  # seconds between debug text refreshes

## ──────────────────────────────────────────────
##  Nodes (created in _ready)
## ──────────────────────────────────────────────

var _root: Control
var _crosshair: CenterContainer
var _prompt: Label
var _debug_panel: VBoxContainer
var _debug_fps: Label
var _debug_coords: Label
var _debug_state: Label
var _debug_time: Label
var _debug_streaming: Label
var _save_indicator: Label

var _debug_timer: float = 0.0
var _player: Node = null

## ──────────────────────────────────────────────
##  Lifecycle
## ──────────────────────────────────────────────

func _ready() -> void:
	layer = 10
	_build_ui()
	_save_indicator.visible = false

func _process(delta: float) -> void:
	_debug_timer += delta
	if _debug_timer >= DEBUG_UPDATE_INTERVAL:
		_debug_timer = 0.0
		_update_debug()

	# Toggle debug overlay with F3
	if Input.is_action_just_pressed("toggle_debug"):
		_debug_panel.visible = not _debug_panel.visible

## ──────────────────────────────────────────────
##  Public API
## ──────────────────────────────────────────────

## Show an interaction prompt (e.g. "Press E to open door")
func show_prompt(text: String) -> void:
	_prompt.text = text
	_prompt.visible = true

func hide_prompt() -> void:
	_prompt.visible = false

## Flash the save indicator briefly
func show_save_indicator() -> void:
	_save_indicator.visible = true
	_save_indicator.modulate.a = 1.0
	# Fade out via tween
	var tw := create_tween()
	tw.tween_interval(0.5)
	tw.tween_property(_save_indicator, "modulate:a", 0.0, 1.0)
	tw.tween_callback(func(): _save_indicator.visible = false)

## Bind the player node for coordinate display
func set_player(player: Node) -> void:
	_player = player

## ──────────────────────────────────────────────
##  UI Construction
## ──────────────────────────────────────────────

func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	# Crosshair (center dot)
	_crosshair = CenterContainer.new()
	_crosshair.set_anchors_preset(Control.PRESET_FULL_RECT)
	_crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_crosshair)
	var dot := Panel.new()
	dot.custom_minimum_size = Vector2(4, 4)
	_crosshair.add_child(dot)

	# Interaction prompt (bottom center)
	_prompt = Label.new()
	_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.position = Vector2(-100, -80)
	_prompt.size = Vector2(200, 30)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override("font_size", 18)
	_prompt.add_theme_color_override("font_color", Color.WHITE)
	_prompt.add_theme_color_override("font_shadow_color", Color.BLACK)
	_prompt.add_theme_constant_override("shadow_offset_x", 1)
	_prompt.add_theme_constant_override("shadow_offset_y", 1)
	_prompt.visible = false
	_root.add_child(_prompt)

	# Save indicator (top right)
	_save_indicator = Label.new()
	_save_indicator.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_save_indicator.position = Vector2(-120, 10)
	_save_indicator.size = Vector2(110, 24)
	_save_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_save_indicator.text = "Saving..."
	_save_indicator.add_theme_color_override("font_color", Color.YELLOW)
	_root.add_child(_save_indicator)

	# Debug panel (top left)
	_debug_panel = VBoxContainer.new()
	_debug_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_debug_panel.position = Vector2(10, 10)
	_debug_panel.size = Vector2(300, 120)
	_debug_panel.visible = DebugManager.enabled
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.6)
	bg.border_width_left = 1
	bg.border_width_top = 1
	bg.border_width_right = 1
	bg.border_width_bottom = 1
	bg.border_color = Color(0.4, 0.8, 0.4, 0.8)
	_debug_panel.add_theme_stylebox_override("panel", bg)
	_root.add_child(_debug_panel)

	_debug_fps = Label.new()
	_debug_fps.add_theme_color_override("font_color", Color(0.7, 1.0, 0.7))
	_debug_panel.add_child(_debug_fps)

	_debug_coords = Label.new()
	_debug_coords.add_theme_color_override("font_color", Color(0.7, 1.0, 0.7))
	_debug_panel.add_child(_debug_coords)

	_debug_state = Label.new()
	_debug_state.add_theme_color_override("font_color", Color(0.7, 1.0, 0.7))
	_debug_panel.add_child(_debug_state)

	_debug_time = Label.new()
	_debug_time.add_theme_color_override("font_color", Color(0.7, 1.0, 0.7))
	_debug_panel.add_child(_debug_time)

	var world_label := Label.new()
	world_label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	world_label.name = "WorldDesignLabel"
	_debug_panel.add_child(world_label)

	_debug_streaming = Label.new()
	_debug_streaming.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	_debug_panel.add_child(_debug_streaming)

## ──────────────────────────────────────────────
##  Debug Update
## ──────────────────────────────────────────────

func _update_debug() -> void:
	if not _debug_panel.visible:
		return
	_debug_fps.text = "FPS: %d" % Engine.get_frames_per_second()
	if _player and is_instance_valid(_player):
		var p: Vector3 = _player.global_position
		_debug_coords.text = "Pos: (%.1f, %.1f, %.1f)" % [p.x, p.y, p.z]
	else:
		_debug_coords.text = "Pos: --"
	_debug_state.text = "State: %s" % GameManager.GameState.keys()[GameManager.current_state]
	_debug_time.text = "Time: %s (x%.1f)" % [WorldTime.get_time_string(), WorldTime.time_scale]
	_update_streaming_debug(p if (_player and is_instance_valid(_player)) else Vector3.ZERO)

## ──────────────────────────────────────────────
##  Streaming Debug
## ──────────────────────────────────────────────

func _update_streaming_debug(player_pos: Vector3) -> void:
	if _debug_streaming == null:
		return
	var mgr := _get_scale_manager()
	if mgr == null:
		_debug_streaming.text = "Streaming: --"
		return
	var chunk := mgr.world_to_chunk(player_pos)
	var loaded := 0
	var loading := 0
	var streamer := _get_chunk_streamer()
	if streamer != null:
		loaded = streamer.get_loaded_chunk_count()
		loading = streamer.get_loading_chunk_count()
	_debug_streaming.text = "Chunk: (%d, %d) | Loaded: %d/%d | Loading: %d" % [
		chunk.x, chunk.y, loaded, mgr.get_max_active_chunks(), loading
	]

func _get_scale_manager():
	var root := get_tree().root
	if root.has_node("WorldScaleManager"):
		return root.get_node("WorldScaleManager")
	return null

func _get_chunk_streamer():
	var root := get_tree().root
	if root.has_node("ChunkStreamer"):
		return root.get_node("ChunkStreamer")
	return null
