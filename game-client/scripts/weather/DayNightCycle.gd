## DayNightCycle.gd
## Drives sun rotation and sky color based on WorldTime.
## Stage 3.6 (Day-Night Cycle Lighting)
extends Node3D

## ──────────────────────────────────────────────
##  Exports
## ──────────────────────────────────────────────

@export var sun_path: NodePath = "DirectionalLight3D"
@export var sky_path: NodePath = "WorldEnvironment"

## ──────────────────────────────────────────────
##  State
## ──────────────────────────────────────────────

var _sun: DirectionalLight3D = null
var _world_env: WorldEnvironment = null
var _sky_material: ProceduralSkyMaterial = null

## Day/night color palette
const DAY_SUN_COLOR := Color(1.0, 0.95, 0.85)
const DUSK_SUN_COLOR := Color(1.0, 0.6, 0.3)
const NIGHT_SUN_COLOR := Color(0.4, 0.45, 0.6)
const DAY_SKY_TOP := Color(0.25, 0.55, 0.9)
const DAY_SKY_HORIZON := Color(0.55, 0.75, 0.95)
const DUSK_SKY_TOP := Color(0.15, 0.1, 0.3)
const DUSK_SKY_HORIZON := Color(0.9, 0.4, 0.2)
const NIGHT_SKY_TOP := Color(0.02, 0.02, 0.05)
const NIGHT_SKY_HORIZON := Color(0.05, 0.05, 0.1)

## ──────────────────────────────────────────────
##  Lifecycle
## ──────────────────────────────────────────────

func _ready() -> void:
	_sun = get_node_or_null(sun_path)
	_world_env = get_node_or_null(sky_path)
	if _world_env and _world_env.environment and _world_env.environment.sky:
		_sky_material = _world_env.environment.sky.sky_material
	_update_cycle()

func _process(_delta: float) -> void:
	if not WorldTime:
		return
	_update_cycle()

## ──────────────────────────────────────────────
##  Cycle Update
## ──────────────────────────────────────────────

func _update_cycle() -> void:
	# WorldTime.hours is 0.0-24.0
	var hour := WorldTime.hours
	# Sun angle: 0 at midnight (below horizon), 90 at noon (overhead)
	var sun_angle := (hour - 6.0) / 12.0 * 180.0  # 6am=0°, 6pm=180°
	if _sun:
		_sun.rotation_degrees.x = -sun_angle + 90.0
		_sun.light_energy = _compute_sun_energy(hour)
		_sun.light_color = _compute_sun_color(hour)
	if _sky_material:
		_sky_material.sky_top_color = _compute_sky_top(hour)
		_sky_material.sky_horizon_color = _compute_sky_horizon(hour)

func _compute_sun_energy(hour: float) -> float:
	# 0 at midnight, peak at noon
	if hour < 6.0 or hour > 18.0:
		return 0.1  # moonlight
	var t := sin((hour - 6.0) / 12.0 * PI)
	return clamp(t, 0.0, 1.0) * 1.2

func _compute_sun_color(hour: float) -> Color:
	if hour < 5.0 or hour > 19.0:
		return NIGHT_SUN_COLOR
	if hour < 7.0 or hour > 17.0:
		return DUSK_SUN_COLOR
	return DAY_SUN_COLOR

func _compute_sky_top(hour: float) -> Color:
	if hour < 5.0 or hour > 19.0:
		return NIGHT_SKY_TOP
	if hour < 7.0 or hour > 17.0:
		return DUSK_SKY_TOP
	return DAY_SKY_TOP

func _compute_sky_horizon(hour: float) -> Color:
	if hour < 5.0 or hour > 19.0:
		return NIGHT_SKY_HORIZON
	if hour < 7.0 or hour > 17.0:
		return DUSK_SKY_HORIZON
	return DAY_SKY_HORIZON
