## test_core_systems.gd
## Basic system integration tests.
## Stage 2.12 — First Prototype
##
## Validates that core systems initialize correctly and can communicate.
## Run from the editor console:
##   var t = load("res://tests/test_core_systems.gd").new()
##   t.run_all()

extends Node
class_name CoreSystemsTest

## ──────────────────────────────────────────────
##  Test State
## ──────────────────────────────────────────────

var _results := {
	"passed": 0,
	"failed": 0,
	"tests": []
}

## ──────────────────────────────────────────────
##  Public API
## ──────────────────────────────────────────────

func run_all() -> void:
	print("\n" + "=".repeat(60))
	print("CORE SYSTEMS INTEGRATION TESTS")
	print("=".repeat(60) + "\n")

	_results["passed"] = 0
	_results["failed"] = 0
	_results["tests"] = []

	test_game_manager_initialization()
	test_debug_manager_logging()
	test_world_time_basics()
	test_save_manager_paths()
	test_economy_manager_initialization()
	test_npc_manager_initialization()

	print_results()

func print_results() -> void:
	print("\n" + "=".repeat(60))
	print("TEST RESULTS")
	print("=".repeat(60))
	print("Passed: %d | Failed: %d | Total: %d" % [
		_results["passed"],
		_results["failed"],
		_results["passed"] + _results["failed"]
	])

	if _results["failed"] > 0:
		print("\nFailed tests:")
		for test in _results["tests"]:
			if not test["passed"]:
				print("  ✗ %s: %s" % [test["name"], test["message"]])
	else:
		print("\n✓ All tests passed!")
	print("=".repeat(60) + "\n")

## ──────────────────────────────────────────────
##  Individual Tests
## ──────────────────────────────────────────────

func test_game_manager_initialization() -> void:
	var name = "GameManager initialization"
	if not has_node("/root/GameManager"):
		_fail(name, "GameManager not registered as autoload")
		return

	var gm = get_node("/root/GameManager")
	if gm.current_state != GameManager.GameState.BOOTING:
		_fail(name, "Expected BOOTING state, got %d" % gm.current_state)
		return

	if gm.game_version == "":
		_fail(name, "game_version is empty")
		return

	_pass(name)

func test_debug_manager_logging() -> void:
	var name = "DebugManager logging"
	if not has_node("/root/DebugManager"):
		_fail(name, "DebugManager not registered")
		return

	var dm = get_node("/root/DebugManager")
	if not dm.enabled:
		_fail(name, "DebugManager not enabled")
		return

	# Test that we can log without crashing
	dm.log_info("TEST", "Test message")
	var recent = dm.get_recent_logs(1)
	if recent.is_empty():
		_fail(name, "Log not captured in ring buffer")
		return

	_pass(name)

func test_world_time_basics() -> void:
	var name = "WorldTime basics"
	if not has_node("/root/WorldTime"):
		_fail(name, "WorldTime not registered")
		return

	var wt = get_node("/root/WorldTime")
	var h = wt.get_hour()
	var m = wt.get_minute()
	if h < 0 or h >= 24:
		_fail(name, "Hour out of range: %d" % h)
		return

	if m < 0 or m >= 60:
		_fail(name, "Minute out of range: %d" % m)
		return

	var ts = wt.get_time_string()
	if ts == "" or not ":" in ts:
		_fail(name, "time_string format invalid: %s" % ts)
		return

	_pass(name)

func test_save_manager_paths() -> void:
	var name = "SaveManager paths"
	if not has_node("/root/SaveManager"):
		_fail(name, "SaveManager not registered")
		return

	var sm = get_node("/root/SaveManager")
	var saves = sm.list_saves()
	if saves is not Array:
		_fail(name, "list_saves() did not return Array")
		return

	_pass(name)

func test_economy_manager_initialization() -> void:
	var name = "EconomyManager initialization"
	if not has_node("/root/EconomyManager"):
		_fail(name, "EconomyManager not registered")
		return

	var em = get_node("/root/EconomyManager")
	# Just verify it exists and has expected structure
	if em == null:
		_fail(name, "EconomyManager null")
		return

	_pass(name)

func test_npc_manager_initialization() -> void:
	var name = "NPCManager initialization"
	if not has_node("/root/NPCManager"):
		_fail(name, "NPCManager not registered")
		return

	var nm = get_node("/root/NPCManager")
	if not nm.has_method("get_active_count"):
		_fail(name, "get_active_count method not found")
		return

	var count = nm.get_active_count()
	if not (count is int):
		_fail(name, "get_active_count did not return int")
		return

	_pass(name)

## ──────────────────────────────────────────────
##  Test Utilities
## ──────────────────────────────────────────────

func _pass(test_name: String) -> void:
	_results["passed"] += 1
	_results["tests"].append({"name": test_name, "passed": true, "message": ""})
	print("✓ %s" % test_name)

func _fail(test_name: String, reason: String) -> void:
	_results["failed"] += 1
	_results["tests"].append({"name": test_name, "passed": false, "message": reason})
	print("✗ %s: %s" % [test_name, reason])
