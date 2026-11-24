## Kolotoč: kulatá plošina, která se otáčí a veze Bruna (AnimatableBody3D, sync_to_physics).
## Uprostřed sloup se stříškou; barevné koníky jen jako ozdoba.
@tool
class_name Carousel
extends AnimatableBody3D

@export var radius: float = 5.0:
	set(v):
		radius = v
		if is_inside_tree():
			_build()
## Otáčky (rad/s). Záporné = opačný směr.
@export var spin_speed: float = 0.6


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_build()
	if Engine.is_editor_hint():
		return
	sync_to_physics = true


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	rotation.y += spin_speed * delta


func _build() -> void:
	for c: Node in get_children():
		if c.has_meta(&"generated"):
			c.free()
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = radius
	cyl.height = 0.5
	shape.shape = cyl
	shape.position.y = 0.25
	shape.set_meta(&"generated", true)
	add_child(shape)
	var deck := MeshInstance3D.new()
	var dm := CylinderMesh.new()
	dm.top_radius = radius
	dm.bottom_radius = radius
	dm.height = 0.5
	dm.radial_segments = 24
	deck.mesh = dm
	deck.position.y = 0.25
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.75, 0.2, 0.3)
	deck.material_override = mat
	deck.set_meta(&"generated", true)
	add_child(deck)
	var pole := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.25
	pm.bottom_radius = 0.25
	pm.height = 4.0
	pole.mesh = pm
	pole.position.y = 2.5
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color(0.95, 0.75, 0.3)
	gold.metallic = 0.7
	pole.material_override = gold
	pole.set_meta(&"generated", true)
	add_child(pole)
	var roof := MeshInstance3D.new()
	var rm := CylinderMesh.new()
	rm.top_radius = 0.2
	rm.bottom_radius = radius * 0.9
	rm.height = 1.4
	roof.mesh = rm
	roof.position.y = 5.0
	var stripes := StandardMaterial3D.new()
	stripes.albedo_color = Color(0.95, 0.9, 0.8)
	stripes.emission_enabled = true
	stripes.emission = Color(1, 0.8, 0.5)
	stripes.emission_energy_multiplier = 0.3
	roof.material_override = stripes
	roof.set_meta(&"generated", true)
	add_child(roof)
	var horse_mat := StandardMaterial3D.new()
	horse_mat.albedo_color = Color(0.95, 0.95, 1.0)
	for i: int in 6:
		var a: float = float(i) / 6.0 * TAU
		var h := MeshInstance3D.new()
		var hb := BoxMesh.new()
		hb.size = Vector3(0.35, 0.55, 1.0)
		h.mesh = hb
		h.material_override = horse_mat
		h.position = Vector3(cos(a), 0, sin(a)) * radius * 0.72 + Vector3.UP * 1.2
		h.rotation.y = -a
		h.set_meta(&"generated", true)
		add_child(h)
		var rod := MeshInstance3D.new()
		var rdm := CylinderMesh.new()
		rdm.top_radius = 0.04
		rdm.bottom_radius = 0.04
		rdm.height = 4.0
		rod.mesh = rdm
		rod.material_override = gold
		rod.position = Vector3(cos(a), 0, sin(a)) * radius * 0.72 + Vector3.UP * 2.5
		rod.set_meta(&"generated", true)
		add_child(rod)
