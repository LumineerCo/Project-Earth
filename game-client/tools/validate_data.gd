## validate_data.gd
## Data validation automation tool.
## Stage 2.11 — Development Automation
##
## Validates all JSON data files in game-client/data/ against their schemas.
## Generates a report of errors, warnings, and statistics. Can be run as a
## standalone tool in the editor or invoked by Boot.gd in development builds.
##
## Usage (from editor console):
##   var validator = load("res://tools/validate_data.gd").new()
##   validator.validate_all()
##   validator.print_report()

extends Node
class_name DataValidator

## ──────────────────────────────────────────────
##  Configuration
## ──────────────────────────────────────────────

const DATA_ROOT := "res://data/"

## ──────────────────────────────────────────────
##  Schema Definitions
## ──────────────────────────────────────────────

var _schemas := {
	"cities": {
		"required": ["id", "name", "position"],
		"types": {
			"id": "String",
			"name": "String",
			"position": "Array",
			"population": "int",
			"districts": "Array",
			"time_zone": "String"
		}
	},
	"countries": {
		"required": ["id", "name"],
		"types": {
			"id": "String",
			"name": "String",
			"currency": "String",
			"states": "Array"
		}
	},
	"items": {
		"required": ["id", "name"],
		"types": {
			"id": "String",
			"name": "String",
			"category": "String",
			"base_price": "float",
			"stackable": "bool",
			"weight_kg": "float"
		}
	},
	"jobs": {
		"required": ["id", "name"],
		"types": {
			"id": "String",
			"name": "String",
			"hourly_wage": "float",
			"location_type": "String"
		}
	},
	"shops": {
		"required": ["id", "name", "position"],
		"types": {
			"id": "String",
			"name": "String",
			"type": "String",
			"position": "Array",
			"inventory": "Array"
		}
	},
	"vehicles": {
		"required": ["id", "name", "type"],
		"types": {
			"id": "String",
			"name": "String",
			"type": "String",
			"max_speed_kmh": "float",
			"seats": "int"
		}
	}
}

## ──────────────────────────────────────────────
##  State
## ──────────────────────────────────────────────

var _results := {
	"total_files": 0,
	"valid_records": 0,
	"errors": [],
	"warnings": [],
	"by_folder": {}
}

## ──────────────────────────────────────────────
##  Public API
## ──────────────────────────────────────────────

func validate_all() -> void:
	_results.clear()
	_results["total_files"] = 0
	_results["valid_records"] = 0
	_results["errors"] = []
	_results["warnings"] = []
	_results["by_folder"] = {}

	var dir := DirAccess.open(DATA_ROOT)
	if dir == null:
		_add_error("DATA_ROOT", "Cannot open %s" % DATA_ROOT)
		return

	_scan_directory(dir, DATA_ROOT)

func print_report() -> void:
	print("\n" + "=".repeat(60))
	print("DATA VALIDATION REPORT")
	print("=".repeat(60))
	print("Total files: %d" % _results["total_files"])
	print("Valid records: %d" % _results["valid_records"])
	print("")

	if _results["errors"].is_empty():
		print("[OK] No errors found.")
	else:
		print("[ERROR] %d errors:" % _results["errors"].size())
		for err in _results["errors"]:
			print("  - %s" % err)
	print("")

	if _results["warnings"].is_empty():
		print("[OK] No warnings found.")
	else:
		print("[WARN] %d warnings:" % _results["warnings"].size())
		for warn in _results["warnings"]:
			print("  - %s" % warn)
	print("")

	print("By folder:")
	for folder in _results["by_folder"].keys().sorted():
		var stats = _results["by_folder"][folder]
		print("  %s: %d files, %d valid, %d issues" % [
			folder,
			stats["files"],
			stats["valid"],
			stats["errors"] + stats["warnings"]
		])
	print("=".repeat(60))

## ──────────────────────────────────────────────
##  Validation Logic
## ──────────────────────────────────────────────

func _scan_directory(dir: DirAccess, root_path: String) -> void:
	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue

		var full_path := root_path + file_name
		if dir.current_is_dir():
			var sub_dir := DirAccess.open(full_path)
			if sub_dir != null:
				_scan_directory(sub_dir, full_path + "/")
		elif file_name.ends_with(".json"):
			_validate_file(full_path, file_name)

		file_name = dir.get_next()

func _validate_file(path: String, file_name: String) -> void:
	_results["total_files"] += 1
	var folder := path.get_basename().get_basename()

	if folder not in _results["by_folder"]:
		_results["by_folder"][folder] = {"files": 0, "valid": 0, "errors": 0, "warnings": 0}
	_results["by_folder"][folder]["files"] += 1

	var text := FileAccess.get_file_as_string(path)
	if text == "" or FileAccess.get_open_error() != OK:
		_add_error(path, "Cannot read file")
		_results["by_folder"][folder]["errors"] += 1
		return

	var data = JSON.parse_string(text)
	if data == null:
		_add_error(path, "Invalid JSON")
		_results["by_folder"][folder]["errors"] += 1
		return

	# Handle both single records and arrays
	var records := []
	if data is Array:
		records = data
	elif data is Dictionary:
		records = [data]
	else:
		_add_error(path, "Root must be Object or Array")
		_results["by_folder"][folder]["errors"] += 1
		return

	var folder_schema = _schemas.get(folder)
	for record in records:
		if record is Dictionary:
			_validate_record(record, folder_schema, path, folder)
		else:
			_add_warning(path, "Record is not an object")
			_results["by_folder"][folder]["warnings"] += 1

func _validate_record(record: Dictionary, schema: Variant, path: String, folder: String) -> void:
	if schema == null:
		# No schema for this folder; accept it.
		_results["valid_records"] += 1
		_results["by_folder"][folder]["valid"] += 1
		return

	# Check required fields
	for req in schema.get("required", []):
		if not record.has(req):
			_add_warning(path, "Record missing required field: %s" % req)
			_results["by_folder"][folder]["warnings"] += 1
			return

	# Check field types (loose)
	var types = schema.get("types", {})
	for field in types.keys():
		if field not in record:
			continue  # optional field
		var value = record[field]
		var expected_type = types[field]
		if not _type_matches(value, expected_type):
			_add_warning(path, "Field '%s' type mismatch: expected %s, got %s" % [
				field, expected_type, typeof(value)
			])
			_results["by_folder"][folder]["warnings"] += 1
			return

	_results["valid_records"] += 1
	_results["by_folder"][folder]["valid"] += 1

func _type_matches(value: Variant, expected: String) -> bool:
	match expected:
		"String": return value is String
		"int": return value is int
		"float": return value is float or value is int
		"bool": return value is bool
		"Array": return value is Array
		"Dictionary": return value is Dictionary
		_: return true

func _add_error(path: String, msg: String) -> void:
	_results["errors"].append("%s: %s" % [path, msg])

func _add_warning(path: String, msg: String) -> void:
	_results["warnings"].append("%s: %s" % [path, msg])
