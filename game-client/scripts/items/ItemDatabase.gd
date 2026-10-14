## ItemDatabase.gd
## Simple item registry for inventory and item lookups.
## Stage 4.3 — Inventory System
extends Node
class_name ItemDatabase

var items: Dictionary = {}
const ITEMS_PATH := "res://data/items/"

func _ready() -> void:
	load_items()
	DebugManager.log_info("ItemDatabase", "Loaded %d items" % items.size())

func load_items() -> void:
	items.clear()
	var dir := DirAccess.open(ITEMS_PATH)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue
		if file_name.ends_with(".tres") or file_name.ends_with(".res"):
			var path := ITEMS_PATH + file_name
			var resource := ResourceLoader.load(path)
			if resource is ItemData:
				items[resource.item_id.to_lower()] = resource
		file_name = dir.get_next()

func register_item(item_data: ItemData) -> void:
	if item_data == null or item_data.item_id == "":
		return
	items[item_data.item_id.to_lower()] = item_data

func get_item(item_id: String) -> ItemData:
	return items.get(item_id.to_lower(), null)

func get_all_item_ids() -> Array:
	return items.keys()
