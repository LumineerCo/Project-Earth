## automation_manager.gd
## Central automation task manager.
## Stage 2.11 — Development Automation
##
## Provides a registry for automation tools and tasks. Can be run from the
## editor or scheduled during development. Example tasks:
## - Validate all data
## - Scan asset inventory
## - Generate documentation indexes
## - Run tests
##
## Usage (from editor console):
##   var mgr = load("res://tools/automation_manager.gd").new()
##   mgr.run_task("validate_data")
##   mgr.run_all()

extends Node
class_name AutomationManager

## ──────────────────────────────────────────────
##  Configuration
## ──────────────────────────────────────────────

const TOOLS_ROOT := "res://tools/"

## ──────────────────────────────────────────────
##  State
## ──────────────────────────────────────────────

var _tasks := {}  # task_name -> { script, description, enabled }
var _results := {}  # task_name -> { status, output, time }

## ──────────────────────────────────────────────
##  Lifecycle
## ──────────────────────────────────────────────

func _ready() -> void:
	_register_default_tasks()

## ──────────────────────────────────────────────
##  Task Registration
## ──────────────────────────────────────────────

func _register_default_tasks() -> void:
	register_task(
		"validate_data",
		"Validate all JSON data files",
		"res://tools/validate_data.gd",
		true
	)
	register_task(
		"asset_inventory",
		"Scan and catalog all assets",
		"res://tools/asset_inventory.gd",
		true
	)
	register_task(
		"plan_coverage_audit",
		"Audit Plan Docs file references against actual project files",
		"res://tools/plan_coverage_audit.gd",
		true
	)

func register_task(name: String, description: String, script_path: String, enabled: bool = true) -> void:
	_tasks[name] = {
		"script": script_path,
		"description": description,
		"enabled": enabled
	}

## ──────────────────────────────────────────────
##  Task Execution
## ──────────────────────────────────────────────

func run_task(name: String) -> bool:
	if name not in _tasks:
		print("[ERROR] Unknown task: %s" % name)
		return false

	var task_info = _tasks[name]
	if not task_info["enabled"]:
		print("[SKIP] Task disabled: %s" % name)
		return false

	print("\n[TASK] Running: %s" % name)
	print("  Description: %s" % task_info["description"])

	var start_time := Time.get_ticks_msec()

	# Load and instantiate the tool
	var script = load(task_info["script"])
	if script == null:
		print("[ERROR] Cannot load script: %s" % task_info["script"])
		_results[name] = {"status": "ERROR", "output": "Script load failed", "time": 0}
		return false

	var instance = script.new()

	# Run the tool's main methods
	var success := true
	if instance.has_method("scan"):
		instance.scan()
	elif instance.has_method("validate_all"):
		instance.validate_all()
	else:
		print("[WARN] Tool has no scan/validate_all method")
		success = false

	# Print report
	if instance.has_method("print_report"):
		instance.print_report()
	elif instance.has_method("print_summary"):
		instance.print_summary()

	var elapsed := Time.get_ticks_msec() - start_time
	_results[name] = {"status": "OK" if success else "PARTIAL", "elapsed_ms": elapsed}
	print("[TASK] Completed in %.2f seconds\n" % (elapsed / 1000.0))

	return success

func run_all() -> void:
	print("\n" + "=".repeat(60))
	print("RUNNING ALL AUTOMATION TASKS")
	print("=".repeat(60))

	var total_start := Time.get_ticks_msec()
	var passed := 0
	var failed := 0

	for task_name in _tasks.keys():
		if run_task(task_name):
			passed += 1
		else:
			failed += 1

	var total_elapsed := Time.get_ticks_msec() - total_start
	print("\n" + "=".repeat(60))
	print("AUTOMATION SUMMARY")
	print("=".repeat(60))
	print("Passed: %d | Failed: %d | Total time: %.2f seconds" % [
		passed, failed, total_elapsed / 1000.0
	])
	print("=".repeat(60))

## ──────────────────────────────────────────────
##  Inspection
## ──────────────────────────────────────────────

func list_tasks() -> Array[String]:
	return _tasks.keys()

func get_task_info(name: String) -> Dictionary:
	return _tasks.get(name, {})

func get_results() -> Dictionary:
	return _results
