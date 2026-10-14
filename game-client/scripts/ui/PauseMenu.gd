## PauseMenu.gd
## In-game pause menu — Resume, Settings, Save, Main Menu, Quit.
## Stage 2.12 Milestone 11 (Pause Menu)
extends CanvasLayer

signal resume_pressed
signal save_pressed
signal settings_pressed
signal main_menu_pressed

## ──────────────────────────────────────────────
##  Nodes
## ──────────────────────────────────────────────

var _root: Control
var _dim: ColorRect
var _panel: Panel
var _vbox: VBoxContainer
var _title: Label
var _btn_resume: Button
var _btn_save: Button
var _btn_settings: Button
var _btn_main_menu: Button
var _btn_quit: Button

## ──────────────────────────────────────────────
##  Lifecycle
## ──────────────────────────────────────────────

func _ready() -> void:
	layer = 20
	_build_ui()
	# Pause menu should not pause itself
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root.visible = false

func _process(_delta: float) -> void:
	# ESC toggles pause menu (only when playing or paused)
	if Input.is_action_just_pressed("ui_cancel"):
		if _root.visible:
			_close()
		else:
			_open()

## ──────────────────────────────────────────────
##  Public API
## ──────────────────────────────────────────────

func open() -> void:
	_open()

func close() -> void:
	_close()

## ──────────────────────────────────────────────
##  Internal
## ──────────────────────────────────────────────

func _open() -> void:
	_root.visible = true
	GameManager.pause_game()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _close() -> void:
	_root.visible = false
	GameManager.resume_game()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	resume_pressed.emit()

## ──────────────────────────────────────────────
##  UI Construction
## ──────────────────────────────────────────────

func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_root)

	# Dim background
	_dim = ColorRect.new()
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.color = Color(0, 0, 0, 0.5)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_dim)

	# Center panel
	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.position = Vector2(-150, -180)
	_panel.size = Vector2(300, 360)
	_root.add_child(_panel)

	_vbox = VBoxContainer.new()
	_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vbox.offset_left = 20
	_vbox.offset_top = 20
	_vbox.offset_right = -20
	_vbox.offset_bottom = -20
	_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_vbox.add_theme_constant_override("separation", 12)
	_panel.add_child(_vbox)

	_title = Label.new()
	_title.text = "PAUSED"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 28)
	_vbox.add_child(_title)

	_btn_resume = _make_button("Resume")
	_btn_resume.pressed.connect(_close)
	_vbox.add_child(_btn_resume)

	_btn_save = _make_button("Save Game")
	_btn_save.pressed.connect(_on_save)
	_vbox.add_child(_btn_save)

	_btn_settings = _make_button("Settings")
	_btn_settings.pressed.connect(_on_settings)
	_vbox.add_child(_btn_settings)

	_btn_main_menu = _make_button("Main Menu")
	_btn_main_menu.pressed.connect(_on_main_menu)
	_vbox.add_child(_btn_main_menu)

	_btn_quit = _make_button("Quit Game")
	_btn_quit.pressed.connect(_on_quit)
	_vbox.add_child(_btn_quit)

func _make_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 40)
	return b

## ──────────────────────────────────────────────
##  Signal Handlers
## ──────────────────────────────────────────────

func _on_save() -> void:
	save_pressed.emit()
	SaveManager.save_game(0)
	if get_node_or_null("/root/Game/HUD"):
		(/root/Game/HUD as CanvasLayer).show_save_indicator()

func _on_settings() -> void:
	settings_pressed.emit()
	get_tree().change_scene_to_file("res://scenes/menus/Settings.tscn")

func _on_main_menu() -> void:
	main_menu_pressed.emit()
	GameManager.set_state(GameManager.GameState.MENU)
	get_tree().change_scene_to_file("res://scenes/menus/MainMenu.tscn")

func _on_quit() -> void:
	get_tree().quit()
