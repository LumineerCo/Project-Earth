## WorldScaleManager.gd
## Loads and exposes world scale, streaming, LOD, and technical planning data.
## Stage 1.6 (World Scale, Streaming & Technical Planning)
extends Node

const SCALE_PATH := "res://data/world/world_scale_technical.json"

## ──────────────────────────────────────────────
##  Loaded Data
## ──────────────────────────────────────────────

var world_scale: Dictionary = {}
var hierarchy: Dictionary = {}
var chunk_system: Dictionary = {}
var lod: Dictionary = {}
var asset_reuse: Dictionary = {}
var terrain_layers: Dictionary = {}
var performance_budgets: Dictionary = {}
var data_driven_design: Dictionary = {}
var free_resources: Dictionary = {}
var version_plan: Dictionary = {}
var streaming_technical: Dictionary = {}

## ──────────────────────────────────────────────
##  Convenience Accessors (cached scalars)
## ──────────────────────────────────────────────

var chunk_size_m: float = 256.0
var load_radius_m: float = 512.0
var unload_radius_m: float = 768.0
var max_active_chunks: int = 25
var scale_factor: float = 0.01
var region_size_m: float = 1024.0

## ──────────────────────────────────────────────
##  Lifecycle
## ──────────────────────────────────────────────

func _ready() -> void:
	load_scale_data()

func load_scale_data() -> void:
	var file := FileAccess.open(SCALE_PATH, FileAccess.READ)
	if file == null:
		DebugManager.log_error("WorldScaleManager", "Unable to load %s" % SCALE_PATH)
		return
	var text := file.get_as_text()
	file.close()
	var parsed := JSON.parse_string(text)
	if not parsed is Dictionary:
		DebugManager.log_error("WorldScaleManager", "Failed to parse %s" % SCALE_PATH)
		return

	world_scale = parsed.get("world_scale", {})
	hierarchy = parsed.get("hierarchy", {})
	chunk_system = parsed.get("chunk_system", {})
	lod = parsed.get("lod", {})
	asset_reuse = parsed.get("asset_reuse", {})
	terrain_layers = parsed.get("terrain_layers", {})
	performance_budgets = parsed.get("performance_budgets", {})
	data_driven_design = parsed.get("data_driven_design", {})
	free_resources = parsed.get("free_resources", {})
	version_plan = parsed.get("version_plan", {})
	streaming_technical = parsed.get("streaming_technical", {})

	# Cache frequently-used scalars
	chunk_size_m = float(chunk_system.get("chunk_size_m", 256.0))
	load_radius_m = float(chunk_system.get("load_radius_m", 512.0))
	unload_radius_m = float(chunk_system.get("unload_radius_m", 768.0))
	max_active_chunks = int(chunk_system.get("max_active_chunks", 25))
	scale_factor = float(world_scale.get("scale_factor", 0.01))
	region_size_m = float(world_scale.get("region_size_m", 1024.0))

	DebugManager.log_info("WorldScaleManager", "Loaded world scale data (chunk=%dm, load=%dm, unload=%dm)" % [int(chunk_size_m), int(load_radius_m), int(unload_radius_m)])

## ──────────────────────────────────────────────
##  World Scale Queries
## ──────────────────────────────────────────────

func get_scale_type() -> String:
	return world_scale.get("type", "compressed_earth_inspired")

func get_scale_factor() -> float:
	return scale_factor

func get_compressed_diameter_m() -> float:
	return float(world_scale.get("compressed_diameter_m", 127420.0))

## ──────────────────────────────────────────────
##  Hierarchy Queries
## ──────────────────────────────────────────────

func get_hierarchy_levels() -> Array:
	return hierarchy.get("levels", [])

func get_hierarchy_level(level: int) -> Dictionary:
	for lvl in get_hierarchy_levels():
		if int(lvl.get("level", -1)) == level:
			return lvl
	return {}

## ──────────────────────────────────────────────
##  Chunk System Queries
## ──────────────────────────────────────────────

func get_chunk_size() -> float:
	return chunk_size_m

func get_load_radius() -> float:
	return load_radius_m

func get_unload_radius() -> float:
	return unload_radius_m

func get_max_active_chunks() -> int:
	return max_active_chunks

func get_chunk_contents() -> Array:
	return chunk_system.get("chunk_contents", [])

func get_state_preservation() -> Dictionary:
	return chunk_system.get("state_preservation", {})

## ──────────────────────────────────────────────
##  LOD Queries
## ──────────────────────────────────────────────

func get_lod_levels() -> Array:
	return lod.get("levels", [])

func get_lod_level_for_distance(distance_m: float) -> Dictionary:
	var best := {}
	var best_dist := -1.0
	for lvl in get_lod_levels():
		var d := float(lvl.get("distance_m", 0.0))
		if distance_m <= d and (best_dist < 0.0 or d < best_dist):
			best = lvl
			best_dist = d
	if best.is_empty() and not get_lod_levels().is_empty():
		best = get_lod_levels()[-1]
	return best

## ──────────────────────────────────────────────
##  Terrain Layer Queries
## ──────────────────────────────────────────────

func get_terrain_layers() -> Array:
	return terrain_layers.get("layers", [])

func get_terrain_layer(layer_id: String) -> Dictionary:
	for layer in get_terrain_layers():
		if layer.get("id", "") == layer_id:
			return layer
	return {}

## ──────────────────────────────────────────────
##  Performance Budget Queries
## ──────────────────────────────────────────────

func get_performance_targets() -> Dictionary:
	return performance_budgets.get("targets", {})

func get_budgets() -> Array:
	return performance_budgets.get("budgets", [])

func get_budget(budget_id: String) -> int:
	for budget in get_budgets():
		if budget.get("id", "") == budget_id:
			return int(budget.get("value", 0))
	return 0

## ──────────────────────────────────────────────
##  Version Plan Queries
## ──────────────────────────────────────────────

func get_milestones() -> Array:
	return version_plan.get("milestones", [])

func get_milestone(milestone_id: String) -> Dictionary:
	for milestone in get_milestones():
		if milestone.get("id", "") == milestone_id:
			return milestone
	return {}

## ──────────────────────────────────────────────
##  Streaming Technical Queries
## ──────────────────────────────────────────────

func get_chunk_scene_path() -> String:
	return streaming_technical.get("chunk_scene_path", "res://worlds/blocks/")

func get_chunk_naming_pattern() -> String:
	return streaming_technical.get("chunk_naming", "chunk_{x}_{z}.tscn")

func get_hysteresis_m() -> float:
	return float(streaming_technical.get("hysteresis_m", 64.0))

func is_async_loading() -> bool:
	return bool(streaming_technical.get("async_loading", true))

## ──────────────────────────────────────────────
##  Coordinate Helpers
## ──────────────────────────────────────────────

## Convert a world position to chunk grid coordinates.
func world_to_chunk(position: Vector3) -> Vector2i:
	return Vector2i(
		int(floor(position.x / chunk_size_m)),
		int(floor(position.z / chunk_size_m))
	)

## Return the world-space center of a chunk.
func chunk_to_world_center(chunk: Vector2i) -> Vector3:
	return Vector3(
		chunk.x * chunk_size_m + chunk_size_m * 0.5,
		0.0,
		chunk.y * chunk_size_m + chunk_size_m * 0.5
	)

## Return the world-space origin (corner) of a chunk.
func chunk_to_world_origin(chunk: Vector2i) -> Vector3:
	return Vector3(
		chunk.x * chunk_size_m,
		0.0,
		chunk.y * chunk_size_m
	)

## Convert a world position to region grid coordinates.
func world_to_region(position: Vector3) -> Vector2i:
	return Vector2i(
		int(floor(position.x / region_size_m)),
		int(floor(position.z / region_size_m))
	)

## List of chunk coordinates within the load radius of a position.
func chunks_around(position: Vector3) -> Array[Vector2i]:
	var center := world_to_chunk(position)
	var radius_chunks := int(ceil(load_radius_m / chunk_size_m))
	var result: Array[Vector2i] = []
	for dx in range(-radius_chunks, radius_chunks + 1):
		for dz in range(-radius_chunks, radius_chunks + 1):
			var chunk := Vector2i(center.x + dx, center.y + dz)
			var chunk_center := chunk_to_world_center(chunk)
			var dist := Vector2(chunk_center.x - position.x, chunk_center.z - position.z).length()
			if dist <= load_radius_m:
				result.append(chunk)
	return result

## Build the chunk scene file path for a given chunk coordinate.
func chunk_scene_path_for(chunk: Vector2i) -> String:
	var naming := get_chunk_naming_pattern()
	var name := naming.replace("{x}", str(chunk.x)).replace("{z}", str(chunk.y))
	return get_chunk_scene_path() + name
