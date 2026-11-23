## Jediná skutečná herní kamera. Míchá polohu mezi 3D rigem (za zády) a 2D rigem (z boku).
## blend = 0 → čistě 3D, blend = 1 → čistě 2D. Přechod je tween jednoho čísla (Krok F).
## V Kroku B existuje jen 3D rig; 2D rig se přidá v Kroku F bez změny tohoto API.
class_name HybridCamera
extends Node3D

@export var target: Node3D
@export var fov_3d: float = 70.0
@export var fov_2d: float = 32.0
@export var fov_aim: float = 55.0
@export_range(0.0, 1.0) var blend: float = 0.0

@onready var rig_3d: ThirdPersonRig = $ThirdPersonRig
@onready var cam: Camera3D = $Camera3D
var rig_2d: Node3D = null
var _shake_strength: float = 0.0
var _shake_time: float = 0.0
var _shake_left: float = 0.0


func _ready() -> void:
	rig_3d.target = target
	rig_3d.snap_to_target()
	if has_node("SideScrollRig"):
		rig_2d = get_node("SideScrollRig") as Node3D
	cam.current = true
	_apply()


func _process(delta: float) -> void:
	_apply()
	if _shake_left > 0.0:
		# Zatřesení při zásahu – jemně, ať se nikomu neudělá špatně.
		_shake_left = maxf(_shake_left - delta, 0.0)
		var k: float = _shake_strength * (_shake_left / _shake_time)
		cam.global_position += cam.global_transform.basis * Vector3(randf_range(-k, k), randf_range(-k, k), 0.0)


## Krátké zatřesení kamerou (zásah holí, dopad…).
func shake(strength: float, duration: float) -> void:
	_shake_strength = maxf(strength, _shake_strength if _shake_left > 0.0 else 0.0)
	_shake_time = duration
	_shake_left = duration


func _apply() -> void:
	var a: Transform3D = rig_3d.camera_point.global_transform
	var fov_now: float = lerpf(fov_3d, fov_aim, rig_3d.aim_blend)
	if rig_2d == null or blend <= 0.0:
		cam.global_transform = a
		cam.fov = fov_now
		return
	var b: Transform3D = (rig_2d.get_node("CameraPoint") as Node3D).global_transform
	var rot := Quaternion(a.basis.orthonormalized()).slerp(Quaternion(b.basis.orthonormalized()), blend)
	cam.global_transform = Transform3D(Basis(rot), a.origin.lerp(b.origin, blend))
	cam.fov = lerpf(fov_now, fov_2d, blend)


## Směr „dopředu“ pro ovládání ve 3D – vždy z 3D rigu, nikdy ze skutečné kamery,
## takže se během přechodu do 2D ovládání nepřetočí.
func get_control_yaw() -> float:
	return rig_3d.get_yaw()


func set_aiming(on: bool) -> void:
	rig_3d.set_aiming(on)


func snap_to_target() -> void:
	rig_3d.snap_to_target()
	_apply()
	cam.reset_physics_interpolation()


func blend_to(target_blend: float, duration: float = 0.9) -> void:
	var tw: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "blend", target_blend, duration)
	await tw.finished
