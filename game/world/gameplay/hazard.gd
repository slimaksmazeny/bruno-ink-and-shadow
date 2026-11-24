## Nebezpečná oblast: louže žíravého inkoustu / bodliny. Dokud v ní Bruno stojí, bere životy
## (po každém zásahu chvíli nesmrtelnost – viz Player.invulnerable_time).
@tool
class_name Hazard
extends Area3D

enum Look { INK_PUDDLE, SPIKES }

@export var size: Vector3 = Vector3(3, 0.3, 3):
	set(v):
		size = v
		if is_inside_tree():
			_build()
@export var look: Look = Look.INK_PUDDLE:
	set(v):
		look = v
		if is_inside_tree():
			_build()
@export var damage: int = 1


func _ready() -> void:
	collision_layer = 64
	collision_mask = 2
	monitorable = false
	_build()
	if Engine.is_editor_hint():
		return
	add_to_group(&"hazard")


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	for b: Node3D in get_overlapping_bodies():
		var p: Player = b as Player
		if p != null:
			p.take_damage(damage, global_position)


func _build() -> void:
	for c: Node in get_children():
		if c.has_meta(&"generated"):
			c.free()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(size.x, maxf(size.y, 0.2) + 0.6, size.z)
	shape.shape = box
	shape.position.y = box.size.y * 0.5
	shape.set_meta(&"generated", true)
	add_child(shape)
	var mat := StandardMaterial3D.new()
	if look == Look.INK_PUDDLE:
		var m := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.5
		cyl.bottom_radius = 0.5
		cyl.height = 1.0
		m.mesh = cyl
		m.scale = Vector3(size.x, 0.04, size.z)
		m.position.y = 0.02
		mat.albedo_color = Color(0.05, 0.03, 0.12)
		mat.emission_enabled = true
		mat.emission = Color(0.35, 0.0, 0.5)
		mat.emission_energy_multiplier = 0.5
		mat.roughness = 0.05
		m.material_override = mat
		m.set_meta(&"generated", true)
		add_child(m)
	else:
		mat.albedo_color = Color(0.55, 0.1, 0.12)
		var count: int = maxi(int(size.x / 0.5), 1)
		for i: int in count:
			var spike := MeshInstance3D.new()
			var cone := CylinderMesh.new()
			cone.top_radius = 0.0
			cone.bottom_radius = 0.22
			cone.height = maxf(size.y, 0.5)
			spike.mesh = cone
			spike.material_override = mat
			spike.position = Vector3(-size.x * 0.5 + 0.25 + float(i) * size.x / float(count), cone.height * 0.5, 0)
			spike.set_meta(&"generated", true)
			add_child(spike)
