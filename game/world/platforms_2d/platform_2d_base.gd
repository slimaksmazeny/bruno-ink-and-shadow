## Společný základ 2D plošin: box s kolizí na vrstvě world, vzhled stavěný z kódu (@tool).
@tool
class_name Platform2DBase
extends AnimatableBody3D

@export var size: Vector3 = Vector3(3, 0.4, 3):
	set(v):
		size = v
		if is_inside_tree():
			_build()
@export var color: Color = Color(0.55, 0.42, 0.3):
	set(v):
		color = v
		if is_inside_tree():
			_build()

var shape: CollisionShape3D
var mesh: MeshInstance3D
var mat: StandardMaterial3D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	sync_to_physics = false
	_build()


func top_y() -> float:
	return global_position.y + size.y * 0.5


func player_on_top(p: Player) -> bool:
	if p == null or not p.is_on_floor():
		return false
	var local: Vector3 = p.global_position - global_position
	return absf(local.x) < size.x * 0.5 + 0.3 and absf(local.z) < size.z * 0.5 + 0.3 \
		and absf(p.global_position.y - top_y()) < 0.25


func _build() -> void:
	for c: Node in get_children():
		if c.has_meta(&"generated"):
			c.free()
	shape = CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.set_meta(&"generated", true)
	add_child(shape)
	mesh = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mesh.mesh = bm
	mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	mesh.set_meta(&"generated", true)
	add_child(mesh)
