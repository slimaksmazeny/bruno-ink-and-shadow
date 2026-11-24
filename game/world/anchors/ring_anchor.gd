## Kruh na houpání (stealth hry hák / 2D plošinovky kruh). Bruno se zahákne holí a houpe se jako kyvadlo.
## Funguje ve 3D i ve 2D (only_in_3d = false). Vzhled se staví z kódu (@tool).
@tool
class_name RingAnchor
extends Anchor


func _init() -> void:
	type = Type.RING
	only_in_3d = false


func _ready() -> void:
	type = Type.RING
	_build()
	super._ready()


func _build() -> void:
	for c: Node in get_children():
		if c.has_meta(&"generated"):
			c.free()
	var shape := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 0.8
	shape.shape = sph
	shape.set_meta(&"generated", true)
	add_child(shape)
	var ring := MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = 0.28
	tor.outer_radius = 0.38
	ring.mesh = tor
	ring.rotation.x = PI * 0.5
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.7, 0.3)
	mat.metallic = 0.7
	mat.roughness = 0.3
	ring.material_override = mat
	ring.set_meta(&"generated", true)
	add_child(ring)
	var holder := Node3D.new()
	holder.name = "SparklesHolder"
	holder.set_meta(&"generated", true)
	add_child(holder)
	var sp := Node3D.new()
	sp.name = "Sparkles"
	holder.add_child(sp)
	var smat := StandardMaterial3D.new()
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.albedo_color = Color(0.35, 0.65, 1.0)
	for i: int in 6:
		var s := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.06
		sm.height = 0.12
		s.mesh = sm
		s.material_override = smat
		var a: float = float(i) / 6.0 * TAU
		s.position = Vector3(cos(a), 0.0, sin(a)) * 0.55
		sp.add_child(s)
	_sparkles = sp
