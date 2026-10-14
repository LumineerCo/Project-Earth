## test_world_time.gd
## Tests for world time functionality.
## Stage 2.12 — First Prototype
##
## Run from editor console:
##   var t = load("res://tests/test_world_time.gd").new()
##   t.run_all()

extends Node
class_name WorldTimeTest

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
	print("WORLD TIME TESTS")
	print("=".repeat(60) + "\n")

	_results["passed"] = 0
	_results["failed"] = 0
	_results["tests"] = []

	test_world_time_exists()
	test_time_getters_valid()
	test_time_string_format()
	test_time_scale_control()
	test_day_progress_range()

	print_results()

func print_results() -> void:
	print("\n" + "=".repeat(60))
	print("WORLD TIME TEST RESULTS")
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

func test_world_time_exists() -> void:
	var name = "WorldTime exists"
	if not has_node("/root/WorldTime"):
		_fail(name, "WorldTime not found in autoloads")
		return
	_pass(name)

func test_time_getters_valid() -> void:
	var name = "Time getters return valid ranges"
	if not has_node("/root/WorldTime"):
		_fail(name, "WorldTime not available")
		return

	var wt = get_node("/root/WorldTime")

	var hour = wt.get_hour()
	if not (hour >= 0 and hour < 24):
		_fail(name, "get_hour() out of range: %d" % hour)
		return

	var minute = wt.get_minute()
	if not (minute >= 0 and minute < 60):
		_fail(name, "get_minute() out of range: %d" % minute)
		return

	var second = wt.get_second()
	if not (second >= 0 and second < 60):
		_fail(name, "get_second() out of range: %d" % second)
		return

	_pass(name)

func test_time_string_format() -> void:
	var name = "get_time_string format valid"
	if not has_node("/root/WorldTime"):
		_fail(name, "WorldTime not available")
		return

	var wt = get_node("/root/WorldTime")
	var ts = wt.get_time_string()

	if ts == "":
		_fail(name, "get_time_string returned empty")
		return

	if not ":" in ts:
		_fail(name, "get_time_string missing colon: %s" % ts)
		return

	_pass(name)

func test_time_scale_control() -> void:
	var name = "time_scale can be set"
	if not has_node("/root/WorldTime"):
		_fail(name, "WorldTime not available")
		return

	var wt = get_node("/root/WorldTime")
	if not wt.has_method("set_time_scale"):
		_fail(name, "set_time_scale method not found")
		return

	# Save original
	var original = wt.time_scale

	# Try to set
	wt.set_time_scale(0.5)
	if wt.time_scale != 0.5:
		_fail(name, "time_scale did not change to 0.5")
		wt.set_time_scale(original)
		return

	# Restore
	wt.set_time_scale(original)
	_pass(name)

func test_day_progress_range() -> void:
	var name = "get_day_progress in valid range"
	if not has_node("/root/WorldTime"):
		_fail(name, "WorldTime not available")
		return

	var wt = get_node("/root/WorldTime")
	if not wt.has_method("get_day_progress"):
		_fail(name, "get_day_progress method not found")
		return

	var progress = wt.get_day_progress()
	if not (progress >= 0.0 and progress <= 1.0):
		_fail(name, "get_day_progress out of 0-1 range: %.2f" % progress)
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
