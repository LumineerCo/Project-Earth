## RoadSegment.gd
## A road segment built along a Path3D spline with lanes and sidewalks.
## Stage 3.2 (Road Network System)
extends Node3D

## ──────────────────────────────────────────────
##  Road Types & Widths (meters)
## ──────────────────────────────────────────────

enum RoadType { HIGHWAY, MAIN_AVENUE, COLLECTOR, ALLEY }

const ROAD_WIDTHS := {
	RoadType.HIGHWAY: 28.0,
	RoadType.MAIN_AVENUE: 20.0,
	RoadType.COLLECTOR: 10.0,
	RoadType.ALLEY: 4.5,
}

const ROAD_COLORS := {
	RoadType.HIGHWAY: Color(0.18, 0.18, 0.18),
	RoadType.MAIN_AVENUE: Color(0.22, 0.22, 0.22),
	RoadType.COLLECTOR: Color(0.28, 0.28, 0.28),
	RoadType.ALLEY: Color(0.35, 0.35, 0.35),
}

## ──────────────────────────────────────────────
##  Exports
## ──────────────────────────────────────────────

@export var road_type: RoadType = RoadType.MAIN_AVENUE
@export var points: Array[Vector3] = []  # Spline control points (local space)

## ──────────────────────────────────────────────
##  State
## ──────────────────────────────────────────────

var _curve: Curve3D = null
var _mesh_instance: MeshInstance3D = null
var _static_body: StaticBody3D = null
var _length: float = 0.0

## ──────────────────────────────────────────────
##  Lifecycle
## ──────────────────────────────────────────────

func _ready() -> void:
	if points.size() >= 2:
		build()

## ──────────────────────────────────────────────
##  Public API
## ──────────────────────────────────────────────

func get_length() -> float:
	return _length

func get_curve() -> Curve3D:
	return _curve

## Build the road mesh and collision from the control points.
func build() -> void:
	# Create curve from control points
	_curve = Curve3D.new()
	for p in points:
		_curve.add_point(p)
	# Compute length
	_length = 0.0
	var baked := _curve.get_baked_points()
	for i in range(1, baked.size()):
		_length += baked[i].distance_to(baked[i - 1])
	_build_road_mesh()
	_build_collision()

## Get a position along the road at offset t (0.0 to 1.0).
func sample_position(t: float) -> Vector3:
	if not _curve:
		return Vector3.ZERO
	return _curve.sample_baked(t * _length)

## ──────────────────────────────────────────────
##  Mesh Construction
## ──────────────────────────────────────────────

func _build_road_mesh() -> void:
	if _mesh_instance:
		_mesh_instance.queue_free()
	var width := ROAD_WIDTHS[road_type]
	var baked := _curve.get_baked_points()
	if baked.size() < 2:
		return
	# Build a ribbon mesh along the curve
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(baked.size()):
		var p := baked[i]
		var tangent := Vector3.FORWARD
		if i < baked.size() - 1:
			tangent = (baked[i + 1] - p).normalized()
		elif i > 0:
			tangent = (p - baked[i - 1]).normalized()
		var normal := tangent.cross(Vector3.UP).normalized()
		var left := p + normal * (width * 0.5)
		var right := p - normal * (width * 0.5)
		st.add_vertex(left)
		st.add_vertex(right)
	# Build triangles between consecutive segments
	for i in range(0, baked.size() - 1):
		var i0 := i * 2
		var i1 := i * 2 + 1
		var i2 := (i + 1) * 2
		var i3 := (i + 1) * 2 + 1
		st.add_index(i0)
		st.add_index(i2)
		st.add_index(i1)
		st.add_index(i1)
		st.add_index(i2)
		st.add_index(i3)
	st.generate_normals()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = ROAD_COLORS[road_type]
	mat.roughness = 0.9
	st.set_material(mat)
	var mesh := st.commit()
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.mesh = mesh
	_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_OFF
	add_child(_mesh_instance)

func _build_collision() -> void:
	if _static_body:
		_static_body.queue_free()
	if not _mesh_instance:
		return
	_static_body = StaticBody3D.new()
	var col := CollisionShape3D.new()
	col.shape = _mesh_instance.mesh.create_trimesh_shape()
	_static_body.add_child(col)
	add_child(_static_body)
