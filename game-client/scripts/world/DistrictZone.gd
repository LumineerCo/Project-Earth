## DistrictZone.gd
## A spatial Area3D zone that defines a city district's gameplay properties.
## Registers itself with DistrictSystem on ready. Supplements JSON district data
## for scene-placed zones (parks, plazas, special areas).
## Stage 3.7 (City Districts & Zoning)
extends Area3D
class_name DistrictZone

@export var district_name: String = ""
@export var district_id: String = ""
@export var zone_type: String = ""  # "residential_low", "commercial_high", "industrial", "civic", "park", "leisure", "highway"
@export var build_height_min: float = 6.0
@export var build_height_max: float = 40.0
@export var speed_limit: float = 30.0
@export var ambient_sound: String = "city_ambient_default"
@export var building_density: float = 0.5
@export var population_density: float = 0.5

func _ready() -> void:
	add_to_group("district_zone")
	# Ensure a collision shape exists for Area3D validity
	if not has_node("CollisionShape3D"):
		var cs := CollisionShape3D.new()
		cs.name = "CollisionShape3D"
		var box := BoxShape3D.new()
		box.size = Vector3(100.0, 50.0, 100.0)
		cs.shape = box
		add_child(cs)
	# Register with global district system
	var ds := get_tree().get_root().get_node_or_null("DistrictSystem")
	if ds != null and ds.has_method("register_zone"):
		ds.register_zone(self)

func _exit_tree() -> void:
	var ds := get_tree().get_root().get_node_or_null("DistrictSystem") if get_tree() != null else null
	if ds != null and ds.has_method("unregister_zone"):
		ds.unregister_zone(self)

## Returns true if the world point falls within this zone's bounding box.
func contains_point(point: Vector3) -> bool:
	var cs := get_node_or_null("CollisionShape3D")
	if cs == null or cs.shape == null:
		return false
	var shape := cs.shape
	if shape is BoxShape3D:
		var local_point := to_local(point)
		var half := (shape as BoxShape3D).size * 0.5
		return abs(local_point.x) <= half.x and abs(local_point.y) <= half.y and abs(local_point.z) <= half.z
	return false

## Returns the build height range as a Vector2(min, max).
func get_build_height_range() -> Vector2:
	return Vector2(build_height_min, build_height_max)
