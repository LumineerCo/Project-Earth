## MainMenu.gd
## Main menu — new game, load game, settings, quit.
extends Control

## ──────────────────────────────────────────────
##  Scene Paths
## ──────────────────────────────────────────────

const GAME_SCENE := "res://scenes/main/Game.tscn"
const SETTINGS_SCENE := "res://scenes/menus/Settings.tscn"

## ──────────────────────────────────────────────
##  UI References (assigned in scene)
## ──────────────────────────────────────────────

@onready var title_label: Label = $VBox/Title
@onready var version_label: Label = $VBox/Version
@onready var new_game_btn: Button = $VBox/Menu/NewGame
@onready var load_game_btn: Button = $VBox/Menu/LoadGame
@onready var settings_btn: Button = $VBox/Menu/Settings
@onready var quit_btn: Button = $VBox/Menu/Quit
@onready var status_label: Label = $VBox/Status

## ──────────────────────────────────────────────
##  Lifecycle
## ──────────────────────────────────────────────

func _ready() -> void:
	# Connect button signals
	new_game_btn.pressed.connect(_on_new_game)
	load_game_btn.pressed.connect(_on_load_game)
	settings_btn.pressed.connect(_on_settings)
	quit_btn.pressed.connect(_on_quit)
	
	# Display version
	version_label.text = "v%s" % GameManager.game_version
	
	# Check for existing saves (SaveManager is an autoload singleton)
	var saves := SaveManager.list_saves()
	load_game_btn.disabled = saves.is_empty()
	if saves.is_empty():
		status_label.text = "No saves found"
	else:
		status_label.text = "%d save(s) found" % saves.size()
	
	DebugManager.log_info("MainMenu", "Main menu ready")

## ──────────────────────────────────────────────
##  Button Handlers
## ──────────────────────────────────────────────

func _on_new_game() -> void:
	DebugManager.log_info("MainMenu", "Starting new game")
	GameManager.start_new_game()
	get_tree().change_scene_to_file(GAME_SCENE)

func _on_load_game() -> void:
	DebugManager.log_info("MainMenu", "Loading game")
	# For prototype — load slot 0 using the SaveManager autoload singleton
	if SaveManager.load_game(0):
		get_tree().change_scene_to_file(GAME_SCENE)
	else:
		status_label.text = "Load failed!"

func _on_settings() -> void:
	DebugManager.log_info("MainMenu", "Opening settings")
	get_tree().change_scene_to_file(SETTINGS_SCENE)

func _on_quit() -> void:
	DebugManager.log_info("MainMenu", "Quitting game")
	get_tree().quit()
