## NPCManager.gd
## Autoload singleton managing NPC population around the player.
## Stage 3.4 Step 3 (NPC Manager)
extends Node

## ──────────────────────────────────────────────
##  Signals
## ──────────────────────────────────────────────

signal npc_spawned(npc: Node)
signal npc_despawned(npc_id: String)

## ──────────────────────────────────────────────
##  Configuration
## ──────────────────────────────────────────────

const MAX_ACTIVE_NPCS := 80
const SPAWN_RADIUS := 120.0
const DESPAWN_RADIUS := 200.0
const SPAWN_INTERVAL := 0.5  # seconds between spawn checks
const NPC_SCENE_PATH := "res://scenes/npc/NPC.tscn"

## ──────────────────────────────────────────────
##  State
## ──────────────────────────────────────────────

var _active_npcs: Dictionary = {}  # npc_id → NPCBase
var _spawn_timer: float = 0.0
var _player: Node = null

## ──────────────────────────────────────────────
##  Lifecycle
## ──────────────────────────────────────────────

func _ready() -> void:
	DebugManager.log_info("NPCManager", "Initialized (max=%d, spawn_r=%.0f, despawn_r=%.0f)" %
		[MAX_ACTIVE_NPCS, SPAWN_RADIUS, DESPAWN_RADIUS])

func _process(delta: float) -> void:
	_spawn_timer += delta
	if _spawn_timer >= SPAWN_INTERVAL:
		_spawn_timer = 0.0
		_manage_population()

## ──────────────────────────────────────────────
##  Public API
## ──────────────────────────────────────────────

func set_player(player: Node) -> void:
	_player = player

func get_active_count() -> int:
	return _active_npcs.size()

func get_npc(npc_id: String) -> Node:
	return _active_npcs.get(npc_id)

func despawn_all() -> void:
	for npc_id in _active_npcs.keys():
		_despawn_npc(npc_id)

## ──────────────────────────────────────────────
##  Population Management
## ──────────────────────────────────────────────

func _manage_population() -> void:
	if not _player or not is_instance_valid(_player):
		return
	var player_pos := _player.global_position
	# Despawn NPCs beyond despawn radius
	for npc_id in _active_npcs.keys():
		var npc: Node = _active_npcs[npc_id]
		if not is_instance_valid(npc):
			_active_npcs.erase(npc_id)
			continue
		if npc.global_position.distance_to(player_pos) > DESPAWN_RADIUS:
			_despawn_npc(npc_id)
	# Spawn new NPCs up to max
	if _active_npcs.size() >= MAX_ACTIVE_NPCS:
		return
	var spawn_pos := _find_valid_spawn_point(player_pos)
	if spawn_pos != Vector3.ZERO:
		_spawn_npc(spawn_pos)

func _find_valid_spawn_point(player_pos: Vector3) -> Vector3:
	# Try city spawn points first if NovaCityManager is available
	if has_node("/root/NovaCityManager"):
		var city_spawn := NovaCityManager.get_random_npc_spawn()
		if city_spawn != Vector3.ZERO:
			# Offset slightly so NPCs don't stack
			var offset := Vector3(randf_range(-5, 5), 0, randf_range(-5, 5))
			var pos := city_spawn + offset
			if not _is_in_camera_view(pos):
				return pos
	# Fallback: pick a random point on a ring around the player
	var angle := randf() * TAU
	var dist := randf_range(SPAWN_RADIUS * 0.8, SPAWN_RADIUS)
	var pos := player_pos + Vector3(cos(angle) * dist, 0, sin(angle) * dist)
	# Visibility check: don't spawn in view of camera
	if _is_in_camera_view(pos):
		return Vector3.ZERO
	return pos

func _is_in_camera_view(pos: Vector3) -> bool:
	var camera := get_viewport().get_camera_3d()
	if not camera:
		return false
	return camera.is_position_in_frustum(pos)

func _spawn_npc(spawn_pos: Vector3) -> void:
	var data := NPCGenerator.generate_random(spawn_pos)
	var npc := CharacterBody3D.new()
	npc.set_script(load("res://scripts/npc/NPCBase.gd"))
	npc.global_position = spawn_pos
	# Simple visual: a capsule
	var mesh := MeshInstance3D.new()
	mesh.mesh = CapsuleMesh.new(0.3, 1.6)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(randf(), randf(), randf())
	mesh.material_override = mat
	npc.add_child(mesh)
	# Collision
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new(0.3, 1.6)
	col.shape = shape
	npc.add_child(col)
	# Set data
	npc.set_data(data)
	# Add to scene
	get_tree().current_scene.add_child(npc)
	_active_npcs[data.npc_id] = npc
	npc_spawned.emit(npc)
	DebugManager.log_debug("NPCManager", "Spawned %s at %s (total=%d)" %
		[data.full_name(), spawn_pos, _active_npcs.size()])

func _despawn_npc(npc_id: String) -> void:
	var npc: Node = _active_npcs.get(npc_id)
	if npc and is_instance_valid(npc):
		npc.queue_free()
	_active_npcs.erase(npc_id)
	npc_despawned.emit(npc_id)
	DebugManager.log_debug("NPCManager", "Despawned %s (total=%d)" % [npc_id, _active_npcs.size()])
