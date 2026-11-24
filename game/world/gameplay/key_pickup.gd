## Klíč na zemi (upustil ho vyřazený strážný). Dotyk = sebrat (GameState.add_key).
## Volitelně nese i mince (`coins`), které padly spolu s ním.
@tool
class_name KeyPickup
extends Area3D

@export var key_id: String = ""
@export var coins: int = 0

var taken: bool = false
var _mesh: Node3D
var _t: float = 0.0


func _ready() -> void:
	collision_layer = 64
	collision_mask = 2
	monitorable = false
	_build()
	if Engine.is_editor_hint():
		return
	add_to_group(&"key_pickup")
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_t += delta
	if _mesh != null:
		_mesh.rotation.y += delta * 2.5
		_mesh.position.y = 0.6 + sin(_t * 3.0) * 0.1


func _on_body_entered(body: Node) -> void:
	if taken or not (body is Player):
		return
	taken = true
	if not key_id.is_empty():
		GameState.add_key(key_id)
	if coins > 0:
		GameState.add_coins(coins)
	AudioManager.play(&"checkpoint", 0.0, 1.2, 0.0)
	var tw: Tween = create_tween()
	tw.tween_property(_mesh, "scale", Vector3.ZERO, 0.2)
	tw.tween_callback(queue_free)


func _build() -> void:
	for c: Node in get_children():
		if c.has_meta(&"generated"):
			c.free()
	var shape := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 0.7
	shape.shape = sph
	shape.position.y = 0.6
	shape.set_meta(&"generated", true)
	add_child(shape)
	_mesh = Node3D.new()
	_mesh.set_meta(&"generated", true)
	add_child(_mesh)
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color(1, 0.85, 0.2)
	gold.emission_enabled = true
	gold.emission = Color(1, 0.75, 0.1)
	gold.emission_energy_multiplier = 1.2
	gold.metallic = 0.8
	var shaft := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(0.08, 0.45, 0.06)
	shaft.mesh = sm
	shaft.material_override = gold
	_mesh.add_child(shaft)
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.07
	tm.outer_radius = 0.14
	ring.mesh = tm
	ring.rotation.x = PI * 0.5
	ring.position.y = 0.3
	ring.material_override = gold
	_mesh.add_child(ring)
	var tooth := MeshInstance3D.new()
	var tb := BoxMesh.new()
	tb.size = Vector3(0.14, 0.06, 0.06)
	tooth.mesh = tb
	tooth.position = Vector3(0.07, -0.18, 0)
	tooth.material_override = gold
	_mesh.add_child(tooth)
	var light := OmniLight3D.new()
	light.light_color = Color(1, 0.85, 0.3)
	light.light_energy = 1.0
	light.omni_range = 3.0
	light.position.y = 0.6
	light.set_meta(&"generated", true)
	add_child(light)
