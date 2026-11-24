## Ruské kolo: gondoly (plošiny) obíhají po svislé kružnici a zůstávají vodorovně.
## Kolo stojí v rovině XY (lokálně); gondoly jsou AnimatableBody3D, Bruna vezou.
@tool
class_name FerrisWheel
extends Node3D

@export var radius: float = 7.0:
	set(v):
		radius = v
		if is_inside_tree():
			_build()
@export var gondolas: int = 6:
	set(v):
		gondolas = maxi(v, 2)
		if is_inside_tree():
			_build()
## Otáčky (rad/s).
@export var spin_speed: float = 0.25

var _cars: Array[AnimatableBody3D] = []
var _wheel: Node3D
var _angle: float = 0.0


func _ready() -> void:
	_build()


func _physics_process(delta: float) -> void:
	_angle += spin_speed * delta if not Engine.is_editor_hint() else 0.0
	if _wheel != null:
		_wheel.rotation.z = _angle
	for i: int in _cars.size():
		var a: float = _angle + float(i) / float(_cars.size()) * TAU
		_cars[i].position = Vector3(cos(a), sin(a), 0) * radius - Vector3.UP * 0.6


func _build() -> void:
	for c: Node in get_children():
		if c.has_meta(&"generated"):
			c.free()
	_cars.clear()
	var steel := StandardMaterial3D.new()
	steel.albedo_color = Color(0.85, 0.85, 0.95)
	steel.metallic = 0.6
	# Stojany.
	for side: float in [-1.0, 1.0]:
		var leg := MeshInstance3D.new()
		var lm := BoxMesh.new()
		lm.size = Vector3(0.3, radius + 1.0, 0.3)
		leg.mesh = lm
		leg.material_override = steel
		leg.position = Vector3(side * radius * 0.35, -(radius + 1.0) * 0.5, side * 0.0 - 0.8)
		leg.rotation.z = side * 0.32
		leg.set_meta(&"generated", true)
		add_child(leg)
	_wheel = Node3D.new()
	_wheel.set_meta(&"generated", true)
	add_child(_wheel)
	var rim := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = radius - 0.12
	tm.outer_radius = radius + 0.12
	tm.rings = 48
	rim.mesh = tm
	rim.rotation.x = PI * 0.5
	var bulbs := StandardMaterial3D.new()
	bulbs.albedo_color = Color(1, 0.85, 0.5)
	bulbs.emission_enabled = true
	bulbs.emission = Color(1, 0.7, 0.35)
	bulbs.emission_energy_multiplier = 1.5
	rim.material_override = bulbs
	_wheel.add_child(rim)
	for i: int in gondolas:
		var a: float = float(i) / float(gondolas) * TAU
		var spoke := MeshInstance3D.new()
		var sm := CylinderMesh.new()
		sm.top_radius = 0.05
		sm.bottom_radius = 0.05
		sm.height = radius
		spoke.mesh = sm
		spoke.material_override = steel
		spoke.position = Vector3(cos(a), sin(a), 0) * radius * 0.5
		spoke.rotation.z = a - PI * 0.5
		_wheel.add_child(spoke)
	var car_mat := StandardMaterial3D.new()
	car_mat.albedo_color = Color(0.3, 0.6, 0.85)
	for i: int in gondolas:
		var car := AnimatableBody3D.new()
		car.collision_layer = 1
		car.collision_mask = 0
		car.sync_to_physics = not Engine.is_editor_hint()
		car.set_meta(&"generated", true)
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(2.2, 0.3, 2.0)
		cs.shape = bs
		car.add_child(cs)
		var mesh := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = bs.size
		mesh.mesh = bm
		mesh.material_override = car_mat
		car.add_child(mesh)
		add_child(car)
		_cars.append(car)
	_physics_process(0.0)
