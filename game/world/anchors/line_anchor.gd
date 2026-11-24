## Kotva ve tvaru úsečky (Sly parkour): trubka (PIPE), římsa (LEDGE), lano (ROPE).
## Úsečka vede od pozice uzlu ve směru lokální osy `axis` o délce `length`.
## Bruno se chytí nejbližšího bodu úsečky. Vzhled a modré jiskry se staví z kódu (@tool),
## takže v editoru stačí přidat Area3D s tímto skriptem, nastavit typ, délku a otočení.
@tool
class_name LineAnchor
extends Anchor

@export var length: float = 6.0:
	set(v):
		length = maxf(v, 0.5)
		if is_inside_tree():
			_build()
## Směr úsečky v lokálních souřadnicích (trubka = nahoru, římsa/lano = do strany).
@export var axis: Vector3 = Vector3.RIGHT:
	set(v):
		axis = v.normalized() if v.length() > 0.01 else Vector3.RIGHT
		if is_inside_tree():
			_build()
## Pro římsu: kam „ven“ od zdi Bruno visí (lokálně). Pro trubku: výchozí strana.
@export var outward: Vector3 = Vector3.BACK


func _ready() -> void:
	_build()
	super._ready()


## Jiskry na úsečce se netočí kolem osy Y (to by je odneslo z trubky) – jen pulzují.
func _process(delta: float) -> void:
	if _sparkles == null or Engine.is_editor_hint():
		return
	_time += delta * (3.0 if _highlighted else 1.2)
	var i: int = 0
	for c: Node in _sparkles.get_children():
		var n: Node3D = c as Node3D
		n.scale = Vector3.ONE * (0.75 + 0.35 * sin(_time * 2.0 + float(i)))
		i += 1


func seg_a() -> Vector3:
	return global_position


func seg_b() -> Vector3:
	return global_position + global_axis() * length


func global_axis() -> Vector3:
	return (global_transform.basis * axis).normalized()


func global_outward() -> Vector3:
	var o: Vector3 = global_transform.basis * outward
	o -= global_axis() * o.dot(global_axis())
	return o.normalized() if o.length() > 0.01 else Vector3.BACK


## Parametr 0..length nejbližšího bodu úsečky k `pos`.
func closest_t(pos: Vector3) -> float:
	return clampf((pos - seg_a()).dot(global_axis()), 0.0, length)


func point_at(t: float) -> Vector3:
	return seg_a() + global_axis() * clampf(t, 0.0, length)


func get_snap_position(from: Vector3) -> Vector3:
	return point_at(closest_t(from))


func _build() -> void:
	for c: Node in get_children():
		if c.has_meta(&"generated"):
			c.free()
	var mid: Vector3 = axis * length * 0.5
	var basis_to_axis := Basis(Quaternion(Vector3.UP, axis))
	# Kolize pro detektor kotev (vrstva anchors).
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.5
	cap.height = length + 1.0
	shape.shape = cap
	shape.transform = Transform3D(basis_to_axis, mid)
	shape.set_meta(&"generated", true)
	add_child(shape)
	# Vzhled.
	var m := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	var mat := StandardMaterial3D.new()
	match type:
		Type.PIPE:
			cyl.top_radius = 0.09
			cyl.bottom_radius = 0.09
			mat.albedo_color = Color(0.35, 0.45, 0.5)
			mat.metallic = 0.6
		Type.ROPE:
			cyl.top_radius = 0.035
			cyl.bottom_radius = 0.035
			mat.albedo_color = Color(0.75, 0.62, 0.4)
		_:
			cyl.top_radius = 0.06
			cyl.bottom_radius = 0.06
			mat.albedo_color = Color(0.55, 0.5, 0.45)
	cyl.height = length
	cyl.radial_segments = 10
	m.mesh = cyl
	m.material_override = mat
	m.transform = Transform3D(basis_to_axis, mid)
	m.set_meta(&"generated", true)
	add_child(m)
	# Modré jiskry podél úsečky (Sly).
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
	smat.emission_enabled = true
	smat.emission = Color(0.3, 0.6, 1.0)
	var count: int = clampi(int(length / 1.2), 2, 12)
	for i: int in count:
		var s := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.07
		sm.height = 0.14
		s.mesh = sm
		s.material_override = smat
		var t: float = (float(i) + 0.5) / float(count) * length
		s.position = axis * t + Vector3(sin(float(i) * 2.1), 0.0, cos(float(i) * 2.1)).slide(axis).normalized() * 0.18
		sp.add_child(s)
	_sparkles = sp
