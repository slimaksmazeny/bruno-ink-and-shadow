## Stoupavý vítr / pára (Rayman). Když Bruno uvnitř plachtí ušima, vynese ho nahoru.
## Bez plachtění jen trochu zpomalí pád. Funguje ve 2D i 3D.
@tool
class_name WindColumn
extends Area3D

@export var size: Vector3 = Vector3(2, 8, 3):
	set(v):
		size = v
		if is_inside_tree():
			_build()
## Rychlost stoupání při plachtění (m/s).
@export var lift_speed: float = 7.0

var _particles: Array[MeshInstance3D] = []
var _t: float = 0.0


func _ready() -> void:
	collision_layer = 64
	collision_mask = 2
	monitorable = false
	_build()


func _physics_process(delta: float) -> void:
	_t += delta
	for i: int in _particles.size():
		var m: MeshInstance3D = _particles[i]
		var y: float = fmod(_t * 3.0 + float(i) * 1.37, size.y)
		m.position = Vector3(sin(float(i) * 2.3 + _t) * size.x * 0.35, y, cos(float(i) * 1.7) * size.z * 0.3)
	if Engine.is_editor_hint():
		return
	for b: Node3D in get_overlapping_bodies():
		var p: Player = b as Player
		if p != null:
			p.wind_lift = lift_speed


func _build() -> void:
	for c: Node in get_children():
		if c.has_meta(&"generated"):
			c.free()
	_particles.clear()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position.y = size.y * 0.5
	shape.set_meta(&"generated", true)
	add_child(shape)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.85, 0.95, 1.0, 0.35)
	for i: int in int(size.y * 1.5):
		var m := MeshInstance3D.new()
		var q := BoxMesh.new()
		q.size = Vector3(0.05, 0.6, 0.05)
		m.mesh = q
		m.material_override = mat
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m.set_meta(&"generated", true)
		add_child(m)
		_particles.append(m)
	var base := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = size.x * 0.45
	bm.bottom_radius = size.x * 0.55
	bm.height = 0.3
	base.mesh = bm
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.4, 0.35, 0.3)
	base.material_override = bmat
	base.position.y = 0.15
	base.set_meta(&"generated", true)
	add_child(base)
