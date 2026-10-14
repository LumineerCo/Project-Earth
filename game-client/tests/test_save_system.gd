## test_save_system.gd
## Tests for save and load functionality.
## Stage 2.12 — First Prototype
##
## Run from editor console:
##   var t = load("res://tests/test_save_system.gd").new()
##   t.run_all()

extends Node
class_name SaveSystemTest

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
	print("SAVE SYSTEM TESTS")
	print("=".repeat(60) + "\n")

	_results["passed"] = 0
	_results["failed"] = 0
	_results["tests"] = []

	test_save_manager_exists()
	test_save_path_valid()
	test_list_saves()

	print_results()

func print_results() -> void:
	print("\n" + "=".repeat(60))
	print("SAVE SYSTEM TEST RESULTS")
	print("=".repeat(60))
	print("Passed: %d | Failed: %d" % [_results["passed"], _results["failed"]])

	if _results["failed"] > 0:
		print("\nFailed tests:")
		for test in _results["tests"]:
			if not test["passed"]:
				print("  ✗ %s: %s" % [test["name"], test["message"]])

	print("=".repeat(60) + "\n")

## ──────────────────────────────────────────────
##  Tests
## ──────────────────────────────────────────────

func test_save_manager_exists() -> void:
	var name = "SaveManager exists"
	if not has_node("/root/SaveManager"):
		_fail(name, "SaveManager not found in autoloads")
		return
	_pass(name)

func test_save_path_valid() -> void:
	var name = "Save path is valid"
	if not has_node("/root/SaveManager"):
		_fail(name, "SaveManager not available")
		return

	var sm = get_node("/root/SaveManager")
	# SaveManager should have a save directory constant
	if not "SAVE_DIR" in sm:
		_fail(name, "SAVE_DIR not defined in SaveManager")
		return

	var save_dir = sm.SAVE_DIR
	if not save_dir.begins_with("user://"):
		_fail(name, "SAVE_DIR does not use user:// path: %s" % save_dir)
		return

	_pass(name)

func test_list_saves() -> void:
	var name = "list_saves returns array"
	if not has_node("/root/SaveManager"):
		_fail(name, "SaveManager not available")
		return

	var sm = get_node("/root/SaveManager")
	if not sm.has_method("list_saves"):
		_fail(name, "list_saves method not found")
		return

	var saves = sm.list_saves()
	if not (saves is Array):
		_fail(name, "list_saves did not return Array")
		return

	_pass(name)

## ──────────────────────────────────────────────
##  Utilities
## ──────────────────────────────────────────────

func _pass(test_name: String) -> void:
	_results["passed"] += 1
	_results["tests"].append({"name": test_name, "passed": true})
	print("✓ %s" % test_name)

func _fail(test_name: String, reason: String) -> void:
	_results["failed"] += 1
	_results["tests"].append({"name": test_name, "passed": false, "message": reason})
	print("✗ %s: %s" % [test_name, reason])
