## Zvon na věži. Zásah tenisákem ho rozhoupe, rozsvítí a pošle Events.bell_hit(bell_id).
class_name TargetBell
extends Node3D

@export var bell_id: StringName = &"bell_main"

var rung: bool = false

@onready var _hit_area: Area3D = $HitArea
@onready var _bell: Node3D = $BellPivot
@onready var _bell_mesh: MeshInstance3D = $BellPivot/BellMesh


func _ready() -> void:
	_hit_area.collision_layer = 0
	_hit_area.collision_mask = 32 # projectiles
	_hit_area.monitoring = true
	_hit_area.monitorable = false
	_hit_area.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group(&"tennis_ball"):
		return
	_ring()


func _ring() -> void:
	var first: bool = not rung
	AudioManager.play_at(&"bell", global_position)
	rung = true
	var tw: Tween = create_tween()
	tw.tween_property(_bell, "rotation_degrees:x", 28.0, 0.12).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_bell, "rotation_degrees:x", -20.0, 0.24).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_bell, "rotation_degrees:x", 10.0, 0.22).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_bell, "rotation_degrees:x", 0.0, 0.2).set_trans(Tween.TRANS_SINE)
	var mat: StandardMaterial3D = _bell_mesh.material_override as StandardMaterial3D
	if mat != null:
		mat = mat.duplicate() as StandardMaterial3D
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.8, 0.3)
		mat.emission_energy_multiplier = 1.5
		_bell_mesh.material_override = mat
	if first:
		Events.bell_hit.emit(bell_id)
