## TrafficLightController.gd
## A timed traffic light controller for intersections. Cycles through
## green → yellow → red phases and exposes is_green() for AI vehicles.
## Stage 3.6 — Traffic System & Vehicles
extends Node3D
class_name TrafficLightController

## ──────────────────────────────────────────────
##  Signals
## ──────────────────────────────────────────────

signal phase_changed(new_phase: String)

## ──────────────────────────────────────────────
##  Exports
## ──────────────────────────────────────────────

@export var green_duration: float = 15.0
@export var yellow_duration: float = 3.0
@export var red_duration: float = 15.0
@export var intersection_id: String = ""

## ──────────────────────────────────────────────
##  State
## ──────────────────────────────────────────────

var current_phase: String = "green"  # green, yellow, red
var phase_timer: float = 0.0
var _light_meshes: Dictionary = {}  # phase → MeshInstance3D

## ──────────────────────────────────────────────
##  Lifecycle
## ──────────────────────────────────────────────

func _ready() -> void:
	phase_timer = green_duration
	_build_light_meshes()
	_update_light_meshes()
	add_to_group("TrafficLight")

func _process(delta: float) -> void:
	phase_timer -= delta
	if phase_timer <= 0.0:
		_advance_phase()

## ──────────────────────────────────────────────
##  Phase Management
## ──────────────────────────────────────────────

func _advance_phase() -> void:
	match current_phase:
		"green":
			current_phase = "yellow"
			phase_timer = yellow_duration
		"yellow":
			current_phase = "red"
			phase_timer = red_duration
		"red":
			current_phase = "green"
			phase_timer = green_duration
	_update_light_meshes()
	phase_changed.emit(current_phase)
	if DebugManager:
		DebugManager.log_trace("TrafficLight", "Intersection %s → %s" % [intersection_id, current_phase])

## ──────────────────────────────────────────────
##  Queries
## ──────────────────────────────────────────────

func is_green() -> bool:
	return current_phase == "green"

func is_yellow() -> bool:
	return current_phase == "yellow"

func is_red() -> bool:
	return current_phase == "red"

func get_current_phase() -> String:
	return current_phase

## ──────────────────────────────────────────────
##  Visuals
## ──────────────────────────────────────────────

func _build_light_meshes() -> void:
	# Create three small spheres representing green, yellow, red lights
	var colors := {
		"green": Color(0.1, 0.9, 0.1),
		"yellow": Color(0.9, 0.9, 0.1),
		"red": Color(0.9, 0.1, 0.1),
	}
	var y_offset := 0.0
	for phase in ["red", "yellow", "green"]:
		var mesh_instance := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.25
		sphere.height = 0.5
		mesh_instance.mesh = sphere
		mesh_instance.position = Vector3(0, y_offset, 0)
		# Emissive material
		var mat := StandardMaterial3D.new()
		mat.albedo_color = colors[phase]
		mat.emission_enabled = true
		mat.emission = colors[phase]
		mat.emission_energy_multiplier = 0.5
		mesh_instance.material_override = mat
		add_child(mesh_instance)
		_light_meshes[phase] = mesh_instance
		y_offset += 0.6

func _update_light_meshes() -> void:
	for phase in _light_meshes.keys():
		var mesh: MeshInstance3D = _light_meshes[phase]
		if mesh:
			mesh.visible = (phase == current_phase)
			if mesh.material_override and mesh.material_override is StandardMaterial3D:
				var mat: StandardMaterial3D = mesh.material_override
				mat.emission_energy_multiplier = 1.5 if phase == current_phase else 0.1

## ──────────────────────────────────────────────
##  Persistence
## ──────────────────────────────────────────────

func serialize() -> Dictionary:
	return {
		"intersection_id": intersection_id,
		"current_phase": current_phase,
		"phase_timer": phase_timer,
		"green_duration": green_duration,
		"yellow_duration": yellow_duration,
		"red_duration": red_duration,
	}

func deserialize(data: Dictionary) -> void:
	intersection_id = data.get("intersection_id", "")
	current_phase = data.get("current_phase", "green")
	phase_timer = data.get("phase_timer", green_duration)
	green_duration = data.get("green_duration", green_duration)
	yellow_duration = data.get("yellow_duration", yellow_duration)
	red_duration = data.get("red_duration", red_duration)
	_update_light_meshes()
