## Game.gd
## Main game scene — hosts the world, player, NPCs, and UI.
extends Node

## ──────────────────────────────────────────────
##  Configuration
## ──────────────────────────────────────────────

const PLAYER_SCENE := "res://scenes/player/Player.tscn"
const HUD_SCRIPT := "res://scripts/ui/HUD.gd"
const PAUSE_MENU_SCRIPT := "res://scripts/ui/PauseMenu.gd"
const ATM_UI_SCENE := "res://scenes/ui/ATMUI.tscn"
const INVENTORY_UI_SCENE := "res://scenes/ui/InventoryUI.tscn"

## ──────────────────────────────────────────────
##  State
## ──────────────────────────────────────────────

var _player: CharacterBody3D = null
var _elapsed: float = 0.0
var _hud: CanvasLayer = null
var _pause_menu: CanvasLayer = null
var _atm_ui: Control = null
var _inventory_ui: Control = null

## ──────────────────────────────────────────────
##  Lifecycle
## ──────────────────────────────────────────────

func _ready() -> void:
	GameManager.set_state(GameManager.GameState.PLAYING)
	_setup_ui()
	_spawn_player()
	_setup_world()
	_setup_prototype_content()
	_setup_npc_manager()
	_setup_day_night_cycle()
	DebugManager.log_info("Game", "Game scene started")

func _process(_delta: float) -> void:
	# ESC handled by PauseMenu now — no duplicate toggle here
	pass

## ──────────────────────────────────────────────
##  Setup
## ──────────────────────────────────────────────

func _setup_ui() -> void:
	# HUD
	_hud = CanvasLayer.new()
	_hud.name = "HUD"
	_hud.set_script(load(HUD_SCRIPT))
	add_child(_hud)
	# Pause menu
	_pause_menu = CanvasLayer.new()
	_pause_menu.name = "PauseMenu"
	_pause_menu.set_script(load(PAUSE_MENU_SCRIPT))
	add_child(_pause_menu)
	# ATM UI
	var atm_scene := load(ATM_UI_SCENE)
	if atm_scene:
		_atm_ui = atm_scene.instantiate()
		_atm_ui.name = "ATMUI"
		add_child(_atm_ui)
		if has_node("/root/ShopUIManager"):
			ShopUIManager.register_atm_ui(_atm_ui)
	# Inventory UI
	var inventory_scene := load(INVENTORY_UI_SCENE)
	if inventory_scene:
		_inventory_ui = inventory_scene.instantiate()
		_inventory_ui.name = "InventoryUI"
		add_child(_inventory_ui)
		if has_node("/root/ShopUIManager"):
			ShopUIManager.register_inventory_ui(_inventory_ui)

func _spawn_player() -> void:
	var player_scene := load(PLAYER_SCENE)
	if player_scene:
		_player = player_scene.instantiate()
		_player.position = Vector3(0, 1.0, 0)
		add_child(_player)
		if _hud:
			_hud.set_player(_player)
		DebugManager.log_info("Game", "Player spawned")
	else:
		DebugManager.log_error("Game", "Cannot load player scene: %s" % PLAYER_SCENE)

func _setup_world() -> void:
	# Ground collision
	var ground := StaticBody3D.new()
	ground.name = "Ground"
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(200, 1, 200)
	col.shape = box
	ground.add_child(col)
	ground.position = Vector3(0, -0.5, 0)
	add_child(ground)
	
	# Visual floor
	var mesh_instance := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(200, 200)
	mesh_instance.mesh = plane
	mesh_instance.position = Vector3(0, 0, 0)
	add_child(mesh_instance)
	
	# Sun (directional light)
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation = Vector3(deg_to_rad(-45), deg_to_rad(30), 0)
	sun.light_energy = 1.5
	sun.shadow_enabled = true
	add_child(sun)
	
	# Sky environment
	var sky := WorldEnvironment.new()
	sky.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky_mat := Sky.new()
	var proc_sky := ProceduralSkyMaterial.new()
	sky_mat.sky_material = proc_sky
	env.sky = sky_mat
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.3
	sky.environment = env
	add_child(sky)
	
	DebugManager.log_info("Game", "World setup complete")

## ──────────────────────────────────────────────
##  Prototype Content (Stage 2.12 Milestone 4)
## ──────────────────────────────────────────────

func _setup_prototype_content() -> void:
	# Road segment
	_create_road(Vector3(0, 0.01, 20), Vector2(8, 40))
	# A few trees
	for i in range(8):
		var x := -15.0 + (i % 4) * 10.0
		var z := -15.0 + (i / 4) * 10.0
		_create_tree(Vector3(x, 0, z))
	# A simple building (box)
	_create_building(Vector3(15, 0, -10), Vector3(8, 6, 8))
	# Interactable door on the building
	_create_door(Vector3(15, 1.5, -6))
	# Light switch inside
	_create_light_switch(Vector3(14, 1.5, -8))
	# ATM terminal
	_create_atm(Vector3(5, 0.5, 8))
	# Pickup items
	_create_pickup(Vector3(-5, 0.5, 5), "apple", "Apple", 1)
	_create_pickup(Vector3(-3, 0.5, 5), "coin", "Coin", 5)
	_create_pickup(Vector3(-1, 0.5, 5), "key", "Key", 1)
	DebugManager.log_info("Game", "Prototype content spawned")

func _create_road(pos: Vector3, size: Vector2) -> void:
	var road := StaticBody3D.new()
	road.name = "Road"
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(size.x, 0.1, size.y)
	col.shape = shape
	road.add_child(col)
	road.position = pos
	add_child(road)
	# Visual
	var mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = size
	mesh.mesh = plane
	mesh.position = pos
	mesh.position.y += 0.02
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.2, 0.2)
	plane.material = mat
	add_child(mesh)

func _create_tree(pos: Vector3) -> void:
	var tree := StaticBody3D.new()
	tree.name = "Tree"
	tree.position = pos
	# Trunk
	var trunk_col := CollisionShape3D.new()
	var trunk_shape := CylinderShape3D.new()
	trunk_shape.radius = 0.3
	trunk_shape.height = 3.0
	trunk_col.shape = trunk_shape
	trunk_col.position = Vector3(0, 1.5, 0)
	tree.add_child(trunk_col)
	# Trunk visual
	var trunk_mesh := MeshInstance3D.new()
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.3
	trunk.bottom_radius = 0.4
	trunk.height = 3.0
	trunk_mesh.mesh = trunk
	trunk_mesh.position = Vector3(0, 1.5, 0)
	var bark := StandardMaterial3D.new()
	bark.albedo_color = Color(0.4, 0.25, 0.1)
	trunk.material = bark
	tree.add_child(trunk_mesh)
	# Foliage
	var foliage_mesh := MeshInstance3D.new()
	var foliage := SphereMesh.new()
	foliage.radius = 2.0
	foliage.height = 4.0
	foliage_mesh.mesh = foliage
	foliage_mesh.position = Vector3(0, 4.5, 0)
	var leaf := StandardMaterial3D.new()
	leaf.albedo_color = Color(0.1, 0.5, 0.1)
	foliage.material = leaf
	tree.add_child(foliage_mesh)
	add_child(tree)

func _create_building(pos: Vector3, size: Vector3) -> void:
	var building := StaticBody3D.new()
	building.name = "Building"
	building.position = pos
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	col.position = Vector3(0, size.y / 2.0, 0)
	building.add_child(col)
	# Visual
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = Vector3(0, size.y / 2.0, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.65, 0.6)
	box.material = mat
	building.add_child(mesh)
	add_child(building)

func _create_door(pos: Vector3) -> void:
	var door := load("res://scripts/world/Door.gd").new()
	door.name = "Door"
	door.position = pos

func _create_atm(pos: Vector3) -> void:
	var atm := load("res://scripts/economy/ATMInteractable.gd").new()
	atm.name = "ATM"
	atm.position = pos
	atm.atm_id = "atm_prototype"
	atm.interaction_prompt = "Press E to use ATM"
	atm.monitoring = true
	# Collision shape for the ATM interactable (Area3D detection zone)
	var col := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(1.2, 1.8, 0.5)
	col.shape = box_shape
	atm.add_child(col)
	# Simple visual for the ATM
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.0, 1.8, 0.4)
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.18, 0.2)
	box.material = mat
	atm.add_child(mesh)
	add_child(atm)
	# Door visual
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(2.0, 3.0, 0.2)
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.3, 0.15)
	box.material = mat
	door.add_child(mesh)
	# Door collision
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.0, 3.0, 0.2)
	col.shape = shape
	door.add_child(col)
	add_child(door)

func _create_light_switch(pos: Vector3) -> void:
	var sw := load("res://scripts/world/LightSwitch.gd").new()
	sw.name = "LightSwitch"
	sw.position = pos
	# Switch visual
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.3, 0.5, 0.1)
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.WHITE
	box.material = mat
	sw.add_child(mesh)
	# A ceiling light that the switch controls
	var light := OmniLight3D.new()
	light.name = "RoomLight"
	light.position = pos + Vector3(1, 2, -1)
	light.light_energy = 1.0
	light.range = 10.0
	add_child(light)
	sw.light_node_path = sw.get_path_to(light)
	add_child(sw)

func _create_pickup(pos: Vector3, item_id: String, item_name: String, qty: int) -> void:
	var pickup := load("res://scripts/world/PickupItem.gd").new()
	pickup.name = "Pickup_%s" % item_id
	pickup.position = pos
	pickup.item_id = item_id
	pickup.item_name = item_name
	pickup.quantity = qty
	# Visual
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.4, 0.4, 0.4)
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0.8, 0.2)
	mat.emission_enabled = true
	mat.emission = Color(0.5, 0.4, 0.1)
	mat.emission_energy_multiplier = 0.5
	box.material = mat
	pickup.add_child(mesh)
	add_child(pickup)

## ──────────────────────────────────────────────
##  Stage 3: NPC Manager & Day-Night Cycle
## ──────────────────────────────────────────────

func _setup_npc_manager() -> void:
	if NPCManager and _player and is_instance_valid(_player):
		NPCManager.set_player(_player)
		DebugManager.log_info("Game", "NPCManager linked to player")

func _setup_day_night_cycle() -> void:
	var cycle := Node3D.new()
	cycle.set_script(load("res://scripts/weather/DayNightCycle.gd"))
	cycle.name = "DayNightCycle"
	# Link to existing sun and world environment
	var sun := get_node_or_null("Sun")
	var env := get_node_or_null("WorldEnvironment")
	if sun:
		cycle.sun_path = cycle.get_path_to(sun)
	if env:
		cycle.sky_path = cycle.get_path_to(env)
	add_child(cycle)
	DebugManager.log_info("Game", "Day-night cycle initialized")

## ──────────────────────────────────────────────
##  Pause (legacy — now handled by PauseMenu)
## ──────────────────────────────────────────────

func _toggle_pause() -> void:
	if _pause_menu:
		_pause_menu.open()
