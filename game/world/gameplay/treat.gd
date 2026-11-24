## Psí piškot – doplní jeden život (jen když Bruno nemá plno, jinak zůstane ležet).
@tool
class_name Treat
extends Area3D

var _mesh: Node3D
var _t: float = 0.0
var taken: bool = false


func _ready() -> void:
	collision_layer = 64
	collision_mask = 2
	monitorable = false
	_build()
	if Engine.is_editor_hint():
		return
	add_to_group(&"treat")


func _physics_process(delta: float) -> void:
	_t += delta
	if _mesh != null:
		_mesh.rotation.y += delta * 1.5
		_mesh.position.y = 0.35 + sin(_t * 2.4) * 0.08
	if Engine.is_editor_hint() or taken:
		return
	for b: Node3D in get_overlapping_bodies():
		var p: Player = b as Player
		if p != null and p.health < p.max_health and p.health > 0:
			taken = true
			p.heal(1)
			AudioManager.play(&"pickup", 0.0, 0.7, 0.0)
			var tw: Tween = create_tween()
			tw.tween_property(_mesh, "scale", Vector3.ZERO, 0.2)
			tw.tween_callback(func() -> void: visible = false)
			return


func _build() -> void:
	for c: Node in get_children():
		if c.has_meta(&"generated"):
			c.free()
	var shape := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 0.55
	shape.shape = sph
	shape.position.y = 0.35
	shape.set_meta(&"generated", true)
	add_child(shape)
	_mesh = Node3D.new()
	_mesh.set_meta(&"generated", true)
	add_child(_mesh)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.6, 0.3)
	# Piškot ve tvaru kostičky: válec + dvě kuličky na každém konci.
	var mid := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.07
	cyl.bottom_radius = 0.07
	cyl.height = 0.4
	mid.mesh = cyl
	mid.rotation.z = PI * 0.5
	mid.material_override = mat
	_mesh.add_child(mid)
	for x: float in [-0.2, 0.2]:
		for y: float in [-0.06, 0.06]:
			var b := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.09
			sm.height = 0.18
			b.mesh = sm
			b.material_override = mat
			b.position = Vector3(x, y, 0)
			_mesh.add_child(b)
