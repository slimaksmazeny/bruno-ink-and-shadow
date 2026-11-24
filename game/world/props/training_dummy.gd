## Cvičná figurína na útok holí. Po zásahu se rozhoupe, blikne a ukáže počet zásahů v řadě.
class_name TrainingDummy
extends Node3D

const COMBO_RESET_TIME: float = 1.2

var hits_in_row: int = 0
var total_hits: int = 0
var _since_last: float = 99.0

@onready var _sack: Node3D = $SackPivot
@onready var _sack_mesh: MeshInstance3D = $SackPivot/Sack
@onready var _label: Label3D = $HitLabel


func _ready() -> void:
	add_to_group(&"hittable")
	_label.visible = false


func _process(delta: float) -> void:
	_since_last += delta
	if _since_last > COMBO_RESET_TIME:
		hits_in_row = 0
		_label.visible = false


func on_cane_hit(info: Dictionary) -> void:
	total_hits += 1
	hits_in_row = hits_in_row + 1 if _since_last < COMBO_RESET_TIME else 1
	_since_last = 0.0
	var dir: Vector3 = info.get("dir", Vector3.FORWARD)
	var local: Vector3 = global_transform.basis.inverse() * dir
	var strength: float = 28.0 + float(info.get("knockback", 4.0)) * 3.0
	var tw: Tween = create_tween()
	tw.tween_property(_sack, "rotation_degrees", Vector3(-local.z * strength, 0, local.x * strength), 0.07)
	tw.tween_property(_sack, "rotation_degrees", Vector3(local.z * strength * 0.5, 0, -local.x * strength * 0.5), 0.18).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_sack, "rotation_degrees", Vector3.ZERO, 0.25).set_trans(Tween.TRANS_SINE)
	_flash()
	_label.text = "×%d" % hits_in_row
	_label.visible = true
	_label.scale = Vector3.ONE * 1.6
	create_tween().tween_property(_label, "scale", Vector3.ONE, 0.15)


func _flash() -> void:
	var mat: StandardMaterial3D = _sack_mesh.material_override as StandardMaterial3D
	if mat == null:
		return
	mat.emission_enabled = true
	mat.emission = Color(1, 1, 1)
	mat.emission_energy_multiplier = 1.2
	var tw: Tween = create_tween()
	tw.tween_property(mat, "emission_energy_multiplier", 0.0, 0.15)
