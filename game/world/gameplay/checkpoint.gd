## Checkpoint (praporek). Když se ho Bruno dotkne: nové místo návratu, doplní zdraví, uloží hru.
@tool
class_name Checkpoint
extends Area3D

@export var checkpoint_id: String = ""
## Doplnit zdraví při aktivaci.
@export var heal_on_activate: bool = true
## Checkpoint leží ve 2D světě (obraz) – při „Pokračovat“ se Bruno obnoví ve 2D.
@export var plane_2d: bool = false
@export var plane_normal: Vector3 = Vector3.BACK

var active: bool = false
var _flag: MeshInstance3D
var _flag_mat: StandardMaterial3D


func _ready() -> void:
	collision_layer = 64
	collision_mask = 2
	monitorable = false
	_build()
	if Engine.is_editor_hint():
		return
	add_to_group(&"checkpoint")
	body_entered.connect(_on_body_entered)
	if not checkpoint_id.is_empty() and GameState.resume_checkpoint == checkpoint_id:
		_restore.call_deferred()


## „Pokračovat“ z hlavního menu: Bruno se objeví tady (bez zvuku a bez nového uložení).
func _restore() -> void:
	GameState.resume_checkpoint = ""
	var p: Player = get_tree().get_first_node_in_group(&"player") as Player
	if p == null:
		return
	for other: Node in get_tree().get_nodes_in_group(&"checkpoint"):
		if other is Checkpoint:
			(other as Checkpoint).set_active(other == self)
	p.global_position = global_position + Vector3.UP * 0.1
	p.velocity = Vector3.ZERO
	p.set_checkpoint(global_transform.translated(Vector3.UP * 0.1))
	p.reset_physics_interpolation()
	var cam: HybridCamera = p.camera
	if plane_2d:
		p.enter_2d(global_position, plane_normal)
		p.visual.face_direction(Vector3.UP.cross(plane_normal))
		if cam != null:
			cam.side_rig.target = p
			cam.side_rig.snap()
			cam.set_blend_target(cam.side_rig, cam.fov_2d)
			cam.blend = 1.0
	elif cam != null:
		cam.snap_to_target()


func _on_body_entered(body: Node) -> void:
	var p: Player = body as Player
	if p == null or active:
		return
	activate(p)


func activate(p: Player) -> void:
	for other: Node in get_tree().get_nodes_in_group(&"checkpoint"):
		if other != self and other is Checkpoint:
			(other as Checkpoint).set_active(false)
	set_active(true)
	p.set_checkpoint(global_transform.translated(Vector3.UP * 0.1))
	if heal_on_activate and p.health < p.max_health:
		p.heal(p.max_health - p.health)
	AudioManager.play(&"checkpoint")
	Events.checkpoint_reached.emit(checkpoint_id)
	GameState.data["progress"]["last_checkpoint"] = checkpoint_id
	SaveManager.save_game()


func set_active(on: bool) -> void:
	active = on
	if _flag_mat != null:
		_flag_mat.albedo_color = Color(1.0, 0.75, 0.15) if on else Color(0.45, 0.45, 0.5)
		_flag_mat.emission_enabled = on
	if on and _flag != null:
		var tw: Tween = create_tween()
		_flag.position.y = 0.9
		tw.tween_property(_flag, "position:y", 1.75, 0.35).set_trans(Tween.TRANS_BACK)


func _build() -> void:
	for c: Node in get_children():
		if c.has_meta(&"generated"):
			c.free()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.6, 2.4, 1.6)
	shape.shape = box
	shape.position.y = 1.2
	shape.set_meta(&"generated", true)
	add_child(shape)
	var pole := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.04
	cyl.bottom_radius = 0.05
	cyl.height = 2.2
	pole.mesh = cyl
	pole.position.y = 1.1
	var pm := StandardMaterial3D.new()
	pm.albedo_color = Color(0.2, 0.15, 0.12)
	pole.material_override = pm
	pole.set_meta(&"generated", true)
	add_child(pole)
	_flag = MeshInstance3D.new()
	var fb := BoxMesh.new()
	fb.size = Vector3(0.7, 0.45, 0.04)
	_flag.mesh = fb
	_flag.position = Vector3(0.38, 1.75, 0)
	_flag_mat = StandardMaterial3D.new()
	_flag_mat.albedo_color = Color(0.45, 0.45, 0.5)
	_flag_mat.emission = Color(1.0, 0.6, 0.1)
	_flag_mat.emission_energy_multiplier = 0.6
	_flag.material_override = _flag_mat
	_flag.set_meta(&"generated", true)
	add_child(_flag)
