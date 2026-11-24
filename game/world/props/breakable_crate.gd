## Rozbitelná bedna. Po `max_hp` zásazích se rozletí na kusy a po chvíli se obnoví (greybox test).
class_name BreakableCrate
extends StaticBody3D

@export var max_hp: int = 2
@export var respawn_time: float = 6.0

var hp: int = 2
var broken: bool = false

@onready var _mesh: MeshInstance3D = $Mesh
@onready var _shape: CollisionShape3D = $Shape


func _ready() -> void:
	add_to_group(&"hittable")
	hp = max_hp


func on_cane_hit(info: Dictionary) -> void:
	if broken:
		return
	hp -= int(info.get("damage", 1))
	if hp > 0:
		var tw: Tween = create_tween()
		tw.tween_property(_mesh, "scale", Vector3(1.12, 0.88, 1.12), 0.05)
		tw.tween_property(_mesh, "scale", Vector3.ONE, 0.12).set_trans(Tween.TRANS_BACK)
		return
	_break(info.get("dir", Vector3.FORWARD), float(info.get("knockback", 4.0)))


func _break(dir: Vector3, force: float) -> void:
	broken = true
	AudioManager.play_at(&"crate_break", global_position)
	_mesh.visible = false
	_shape.set_deferred("disabled", true)
	var mat: Material = _mesh.material_override
	for i: int in 6:
		var piece := RigidBody3D.new()
		piece.collision_layer = 0
		piece.collision_mask = 1
		piece.mass = 0.3
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(randf_range(0.2, 0.4), randf_range(0.08, 0.15), randf_range(0.2, 0.4))
		mi.mesh = bm
		mi.material_override = mat
		piece.add_child(mi)
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = bm.size
		cs.shape = bs
		piece.add_child(cs)
		get_parent().add_child(piece)
		piece.global_position = global_position + Vector3(randf_range(-0.3, 0.3), randf_range(0.2, 0.8), randf_range(-0.3, 0.3))
		piece.linear_velocity = dir * force * randf_range(0.6, 1.2) + Vector3(randf_range(-2, 2), randf_range(2.5, 5.0), randf_range(-2, 2))
		piece.angular_velocity = Vector3(randf_range(-8, 8), randf_range(-8, 8), randf_range(-8, 8))
		get_tree().create_timer(2.5).timeout.connect(piece.queue_free)
	await get_tree().create_timer(respawn_time).timeout
	_restore()


func _restore() -> void:
	broken = false
	hp = max_hp
	_mesh.visible = true
	_mesh.scale = Vector3.ZERO
	_shape.set_deferred("disabled", false)
	create_tween().tween_property(_mesh, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK)
