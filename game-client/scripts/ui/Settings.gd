## Settings.gd
## Settings menu — audio, video, and gameplay options. For prototype, exposes
## time scale and a few debug toggles. Saves preferences to user://settings.json.
extends Control

## ──────────────────────────────────────────────
##  Scene Paths
## ──────────────────────────────────────────────

const MAIN_MENU_SCENE := "res://scenes/menus/MainMenu.tscn"
const SETTINGS_PATH := "user://settings.json"

## ──────────────────────────────────────────────
##  UI References (assigned in scene)
## ──────────────────────────────────────────────

@onready var master_volume_slider: HSlider = $VBox/Content/MasterVolume/Slider
@onready var master_volume_label: Label = $VBox/Content/MasterVolume/Value
@onready var time_scale_slider: HSlider = $VBox/Content/TimeScale/Slider
@onready var time_scale_label: Label = $VBox/Content/TimeScale/Value
@onready var debug_toggle: CheckBox = $VBox/Content/DebugToggle
@onready var back_btn: Button = $VBox/Content/Back
@onready var status_label: Label = $VBox/Status

## ──────────────────────────────────────────────
##  State
## ──────────────────────────────────────────────

var _settings: Dictionary = {}

## ──────────────────────────────────────────────
##  Lifecycle
## ──────────────────────────────────────────────

func _ready() -> void:
	_load_settings()
	_apply_settings_to_ui()
	
	master_volume_slider.value_changed.connect(_on_master_volume_changed)
	time_scale_slider.value_changed.connect(_on_time_scale_changed)
	debug_toggle.toggled.connect(_on_debug_toggled)
	back_btn.pressed.connect(_on_back)
	
	DebugManager.log_info("Settings", "Settings menu ready")

## ──────────────────────────────────────────────
##  UI Handlers
## ──────────────────────────────────────────────

func _on_master_volume_changed(value: float) -> void:
	_settings["master_volume"] = value
	master_volume_label.text = "%d%%" % int(value)
	# Apply to AudioServer bus 0 (Master)
	var idx := AudioServer.get_bus_index("Master")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(value / 100.0))
	_save_settings()

func _on_time_scale_changed(value: float) -> void:
	_settings["time_scale"] = value
	time_scale_label.text = "%.1fx" % value
	if WorldTime:
		WorldTime.set_time_scale(value)
	_save_settings()

func _on_debug_toggled(pressed: bool) -> void:
	_settings["debug_enabled"] = pressed
	if DebugManager:
		DebugManager.enabled = pressed
	_save_settings()

func _on_back() -> void:
	DebugManager.log_info("Settings", "Returning to main menu")
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

## ──────────────────────────────────────────────
##  Settings Persistence
## ──────────────────────────────────────────────

func _load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		_settings = _default_settings()
		return
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if not file:
		_settings = _default_settings()
		return
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	_settings = parsed if parsed is Dictionary else _default_settings()

func _save_settings() -> void:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_settings))
		file.close()
		status_label.text = "Settings saved"
	else:
		status_label.text = "Failed to save settings"

func _default_settings() -> Dictionary:
	return {
		"master_volume": 100.0,
		"time_scale": 1.0,
		"debug_enabled": false,
	}

func _apply_settings_to_ui() -> void:
	master_volume_slider.value = _settings.get("master_volume", 100.0)
	master_volume_label.text = "%d%%" % int(master_volume_slider.value)
	time_scale_slider.value = _settings.get("time_scale", 1.0)
	time_scale_label.text = "%.1fx" % time_scale_slider.value
	debug_toggle.button_pressed = _settings.get("debug_enabled", false)
