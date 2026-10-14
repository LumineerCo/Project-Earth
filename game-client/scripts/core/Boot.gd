## Boot.gd
## Boot scene — the first scene loaded. Initializes all systems, shows splash,
## then transitions to the main menu.
extends Node

## ──────────────────────────────────────────────
##  Configuration
## ──────────────────────────────────────────────

const SPLASH_DURATION := 2.0  # Seconds to show splash
const MAIN_MENU_SCENE := "res://scenes/menus/MainMenu.tscn"

## ──────────────────────────────────────────────
##  State
## ──────────────────────────────────────────────

var _splash_timer: float = 0.0
var _boot_steps: Array = []
var _current_step: int = 0

## ──────────────────────────────────────────────
##  Lifecycle
## ──────────────────────────────────────────────

func _ready() -> void:
	DebugManager.log_info("Boot", "Project Earth — Boot sequence started")
	_setup_boot_steps()
	_run_boot_sequence()

func _process(delta: float) -> void:
	if _current_step >= _boot_steps.size():
		_splash_timer += delta
		if _splash_timer >= SPLASH_DURATION:
			_goto_main_menu()

## ──────────────────────────────────────────────
##  Boot Sequence
## ──────────────────────────────────────────────

func _setup_boot_steps() -> void:
	_boot_steps = [
		{"name": "Initialize Debug", "func": _step_init_debug},
		{"name": "Initialize Game Manager", "func": _step_init_gamemanager},
		{"name": "Initialize World Time", "func": _step_init_worldtime},
		{"name": "Initialize World Design", "func": _step_init_worlddesign},
		{"name": "Initialize World Map", "func": _step_init_worldmap},
		{"name": "Initialize Geography", "func": _step_init_geography},
		{"name": "Initialize Politics", "func": _step_init_politics},
		{"name": "Initialize World Scale", "func": _step_init_worldscale},
		{"name": "Initialize Memory Systems", "func": _step_init_memory},
		{"name": "Initialize Economy", "func": _step_init_economy},
		{"name": "Initialize Nova City", "func": _step_init_novacity},
		{"name": "Initialize District System", "func": _step_init_districts},
		{"name": "Initialize Traffic System", "func": _step_init_traffic},
		{"name": "Initialize Nav Graph", "func": _step_init_nav_graph},
		{"name": "Initialize Buildings", "func": _step_init_buildings},
		{"name": "Initialize Shops", "func": _step_init_shops},
		{"name": "Initialize Traffic Manager", "func": _step_init_traffic_manager},
		{"name": "Initialize Network", "func": _step_init_network},
	]

func _run_boot_sequence() -> void:
	for step in _boot_steps:
		var step_name: String = step["name"]
		var step_func: Callable = step["func"]
		DebugManager.log_info("Boot", "Step: %s" % step_name)
		var result = step_func.call()
		if result is bool and not result:
			DebugManager.log_error("Boot", "Step failed: %s" % step_name)
			# Continue anyway — non-fatal
		_current_step += 1
	
	DebugManager.log_info("Boot", "All boot steps complete")
	GameManager.set_state(GameManager.GameState.MAIN_MENU)

## ──────────────────────────────────────────────
##  Boot Steps
## ──────────────────────────────────────────────

func _step_init_debug() -> bool:
	DebugManager.log_info("Boot", "Debug system ready (level: %d)" % DebugManager.min_log_level)
	return true

func _step_init_gamemanager() -> bool:
	GameManager.world_seed = randi()
	DebugManager.log_info("Boot", "Game Manager ready (seed: %d)" % GameManager.world_seed)
	return true

func _step_init_worldtime() -> bool:
	WorldTime.set_time_scale(1.0)
	DebugManager.log_info("Boot", "World Time ready (%s)" % WorldTime.get_time_string())
	return true

func _step_init_worlddesign() -> bool:
	if not has_node("/root/WorldDesignManager"):
		var manager := load("res://scripts/world/WorldDesignManager.gd").new()
		manager.name = "WorldDesignManager"
		get_tree().root.add_child(manager)
	if WorldDesignManager:
		WorldDesignManager.load_design()
		DebugManager.log_info("Boot", "World design ready (%s)" % WorldDesignManager.planet_name)
	return true

func _step_init_worldmap() -> bool:
	if not has_node("/root/WorldMapManager"):
		var manager := load("res://scripts/world/WorldMapManager.gd").new()
		manager.name = "WorldMapManager"
		get_tree().root.add_child(manager)
	if WorldMapManager:
		WorldMapManager.load_map()
		DebugManager.log_info("Boot", "World map ready (%s)" % WorldMapManager.world_name)
	return true

func _step_init_geography() -> bool:
	if not has_node("/root/ContinentGeographyManager"):
		var manager := load("res://scripts/world/ContinentGeographyManager.gd").new()
		manager.name = "ContinentGeographyManager"
		get_tree().root.add_child(manager)
	if ContinentGeographyManager:
		ContinentGeographyManager.load_geography()
		DebugManager.log_info("Boot", "Geography ready (%d continents)" % ContinentGeographyManager.continents.size())
	return true

func _step_init_politics() -> bool:
	if not has_node("/root/PoliticalDesignManager"):
		var manager := load("res://scripts/world/PoliticalDesignManager.gd").new()
		manager.name = "PoliticalDesignManager"
		get_tree().root.add_child(manager)
	if PoliticalDesignManager:
		PoliticalDesignManager.load_political_design()
		DebugManager.log_info("Boot", "Politics ready (%d countries)" % PoliticalDesignManager.countries.size())
	return true

func _step_init_worldscale() -> bool:
	if not has_node("/root/WorldScaleManager"):
		var manager := load("res://scripts/world/WorldScaleManager.gd").new()
		manager.name = "WorldScaleManager"
		get_tree().root.add_child(manager)
	if WorldScaleManager:
		WorldScaleManager.load_scale_data()
		DebugManager.log_info("Boot", "World scale ready (chunk=%dm, scale=%.3f)" % [int(WorldScaleManager.chunk_size_m), WorldScaleManager.scale_factor])
	return true

func _step_init_memory() -> bool:
	DebugManager.log_info("Boot", "Memory systems ready")
	return true

func _step_init_economy() -> bool:
	DebugManager.log_info("Boot", "Economy ready (%d items)" % EconomyManager.get_registered_item_count())
	return true

func _step_init_novacity() -> bool:
	if not has_node("/root/NovaCityManager"):
		var manager := load("res://scripts/world/NovaCityManager.gd").new()
		manager.name = "NovaCityManager"
		get_tree().root.add_child(manager)
	if NovaCityManager:
		NovaCityManager.load_city()
		DebugManager.log_info("Boot", "Nova City ready (%s, %d districts)" % [NovaCityManager.city_name, NovaCityManager.get_district_count()])
	return true

func _step_init_districts() -> bool:
	if not has_node("/root/DistrictSystem"):
		var mgr := load("res://scripts/world/DistrictSystem.gd").new()
		mgr.name = "DistrictSystem"
		get_tree().root.add_child(mgr)
	if DistrictSystem:
		DebugManager.log_info("Boot", "District system ready (%d districts)" % DistrictSystem.get_district_count())
	return true

func _step_init_traffic() -> bool:
	if not has_node("/root/TrafficSystem"):
		var traffic := load("res://scripts/world/TrafficSystem.gd").new()
		traffic.name = "TrafficSystem"
		get_tree().root.add_child(traffic)
	if TrafficSystem and NovaCityManager and NovaCityManager.get_road_network().size() > 0:
		TrafficSystem.build_network_from_city_data(NovaCityManager)
		DebugManager.log_info("Boot", "Traffic system ready (%d roads)" % TrafficSystem.get_road_count())
	else:
		DebugManager.log_info("Boot", "Traffic system ready (no city data yet)")
	return true

func _step_init_nav_graph() -> bool:
	if not has_node("/root/NavGraph"):
		var nav := load("res://scripts/world/NavGraph.gd").new()
		nav.name = "NavGraph"
		get_tree().root.add_child(nav)
	if NavGraph:
		NavGraph.bake_navmesh()
		DebugManager.log_info("Boot", "Nav graph ready")
	return true

func _step_init_buildings() -> bool:
	if not has_node("/root/BuildingManager"):
		var mgr := load("res://scripts/world/BuildingManager.gd").new()
		mgr.name = "BuildingManager"
		get_tree().root.add_child(mgr)
	if BuildingManager:
		BuildingManager.load_building_data()
		DebugManager.log_info("Boot", "Buildings ready (%d definitions)" % BuildingManager.get_building_definitions().size())
	return true

func _step_init_shops() -> bool:
	if not has_node("/root/ShopManager"):
		var mgr := load("res://scripts/world/ShopManager.gd").new()
		mgr.name = "ShopManager"
		get_tree().root.add_child(mgr)
	if ShopManager:
		ShopManager.load_shop_data()
		DebugManager.log_info("Boot", "Shops ready (%d shops)" % ShopManager.get_shop_count())
	return true

func _step_init_traffic_manager() -> bool:
	if not has_node("/root/TrafficManager"):
		var mgr := load("res://scripts/vehicle/TrafficManager.gd").new()
		mgr.name = "TrafficManager"
		get_tree().root.add_child(mgr)
	if TrafficManager:
		DebugManager.log_info("Boot", "Traffic manager ready (max=%d vehicles)" % TrafficManager.MAX_VEHICLES)
	return true

func _step_init_network() -> bool:
	WorldServerBridge.start_offline()
	DebugManager.log_info("Boot", "Network ready (offline mode)")
	return true

## ──────────────────────────────────────────────
##  Transition
## ──────────────────────────────────────────────

func _goto_main_menu() -> void:
	set_process(false)
	DebugManager.log_info("Boot", "Transitioning to main menu")
	var err := get_tree().change_scene_to_file(MAIN_MENU_SCENE)
	if err != OK:
		DebugManager.log_error("Boot", "Failed to load main menu: %s" % MAIN_MENU_SCENE)
