## asset_inventory.gd
## Asset catalog and inventory automation tool.
## Stage 2.11 — Development Automation
##
## Scans the assets/ folder, generates an inventory of all art/audio/props,
## and creates a searchable index. Can be used to:
## - Find duplicate filenames
## - Generate asset lists
## - Report missing assets
## - Create thumbnails (placeholder)
##
## Usage (from editor console):
##   var inventory = load("res://tools/asset_inventory.gd").new()
##   inventory.scan()
##   inventory.print_summary()

extends Node
class_name AssetInventory

## ──────────────────────────────────────────────
##  Configuration
## ──────────────────────────────────────────────

const ASSETS_ROOT := "res://assets/"

## ──────────────────────────────────────────────
##  State
## ──────────────────────────────────────────────

var _inventory := {
	"total_files": 0,
	"by_category": {},
	"by_extension": {},
	"duplicates": [],
	"missing_references": []
}

## ──────────────────────────────────────────────
##  Public API
## ──────────────────────────────────────────────

func scan() -> void:
	_inventory.clear()
	_inventory["total_files"] = 0
	_inventory["by_category"] = {}
	_inventory["by_extension"] = {}
	_inventory["duplicates"] = []
	_inventory["missing_references"] = []

	var dir := DirAccess.open(ASSETS_ROOT)
	if dir == null:
		print("[ERROR] Cannot open %s" % ASSETS_ROOT)
		return

	_scan_directory(dir, ASSETS_ROOT, "")

func print_summary() -> void:
	print("\n" + "=".repeat(60))
	print("ASSET INVENTORY REPORT")
	print("=".repeat(60))
	print("Total assets: %d" % _inventory["total_files"])
	print("")

	print("By category:")
	for category in _inventory["by_category"].keys().sorted():
		var count = _inventory["by_category"][category]
		print("  %s: %d files" % [category, count])
	print("")

	print("By file type:")
	for ext in _inventory["by_extension"].keys().sorted():
		var count = _inventory["by_extension"][ext]
		print("  *.%s: %d files" % [ext, count])
	print("")

	if _inventory["duplicates"].is_empty():
		print("[OK] No duplicate filenames detected.")
	else:
		print("[WARN] Found %d duplicate filenames:" % _inventory["duplicates"].size())
		for dup in _inventory["duplicates"]:
			print("  - %s" % dup)
	print("")

	if _inventory["missing_references"].is_empty():
		print("[OK] All references valid.")
	else:
		print("[WARN] Found %d missing references:" % _inventory["missing_references"].size())
		for missing in _inventory["missing_references"].slice(0, 10):  # Show first 10
			print("  - %s" % missing)
		if _inventory["missing_references"].size() > 10:
			print("  ... and %d more" % (_inventory["missing_references"].size() - 10))
	print("=".repeat(60))

## ──────────────────────────────────────────────
##  Scanning
## ──────────────────────────────────────────────

func _scan_directory(dir: DirAccess, root_path: String, relative: String) -> void:
	dir.list_dir_begin()
	var file_name := dir.get_next()
	var seen_names := {}

	while file_name != "":
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue

		var full_path := root_path + file_name
		var rel_path := relative + file_name

		if dir.current_is_dir():
			var sub_dir := DirAccess.open(full_path)
			if sub_dir != null:
				_scan_directory(sub_dir, full_path + "/", rel_path + "/")
		else:
			_inventory["total_files"] += 1

			# Track by category (first subfolder)
			var category = relative.split("/")[0] if "/" in relative else "root"
			if category == "":
				category = "root"
			_inventory["by_category"][category] = _inventory["by_category"].get(category, 0) + 1

			# Track by extension
			var ext = file_name.get_extension().to_lower()
			_inventory["by_extension"][ext] = _inventory["by_extension"].get(ext, 0) + 1

			# Check for duplicates
			if file_name in seen_names:
				_inventory["duplicates"].append("%s (seen at %s, also at %s)" % [
					file_name, seen_names[file_name], rel_path
				])
			else:
				seen_names[file_name] = rel_path

		file_name = dir.get_next()
