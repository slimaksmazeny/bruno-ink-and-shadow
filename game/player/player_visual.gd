## Greybox vzhled Bruna: postoj na 2 nohách vs. sprint na 4 nohách, plížení, natočení do směru pohybu.
## Později se sem napojí skutečný model a AnimationTree – stavy hráče se kvůli tomu měnit nebudou.
class_name PlayerVisual
extends Node3D

enum Posture { STAND, SPRINT }

@onready var _stand: Node3D = $Stand
@onready var _sprint: Node3D = $Sprint
@onready var _ears: Node3D = $Stand/EarsPivot

var posture: Posture = Posture.STAND
var gliding: bool = false
var perched: bool = false
## Při míření se Bruno neotáčí do směru pohybu (úkroky do stran), ale drží směr kamery.
var facing_locked: bool = false
var _yaw: float = 0.0
var _squash: float = 1.0
var _ear_spin: float = 0.0


func set_posture(new_posture: Posture) -> void:
	posture = new_posture
	_stand.visible = posture == Posture.STAND
	_sprint.visible = posture == Posture.SPRINT


## Ušní vrtulník: uši se zvednou do vodorovné polohy a točí se nad hlavou jako vrtule.
func set_gliding(on: bool) -> void:
	gliding = on
	if on:
		set_posture(Posture.STAND)
	else:
		_ears.rotation = Vector3.ZERO


func set_perched(on: bool) -> void:
	perched = on


## Okamžitě natočí Bruna do daného směru (míření tenisákem).
func face_direction(dir: Vector3) -> void:
	if dir.length() > 0.01:
		_yaw = atan2(-dir.x, -dir.z)
		rotation.y = _yaw


## Švih holí jako pálkou.
func play_swing(duration: float) -> void:
	var cane: Node3D = $Stand/Cane
	var tw: Tween = create_tween()
	tw.tween_property(cane, "rotation_degrees", Vector3(-70, 0, -60), duration * 0.35).set_trans(Tween.TRANS_BACK)
	tw.tween_property(cane, "rotation_degrees", Vector3(0, 0, -8), duration * 0.65).set_trans(Tween.TRANS_SINE)


## Odkud tenisák vyletí (hrot hole ve výšce hrudníku).
func get_ball_spawn() -> Vector3:
	return global_position + get_forward() * 0.7 + Vector3.UP * 0.9


## Směr, kterým se Bruno dívá (vodorovně).
func get_forward() -> Vector3:
	return Vector3(-sin(_yaw), 0.0, -cos(_yaw))


## Krátké „zmáčknutí“ při dopadu (squash & stretch).
func land_squash(amount: float = 0.75) -> void:
	_squash = amount


func update_visual(delta: float, player: Player) -> void:
	var horizontal := Vector3(player.velocity.x, 0.0, player.velocity.z)
	if horizontal.length() > 0.3 and not facing_locked:
		var target_yaw: float = atan2(-horizontal.x, -horizontal.z)
		_yaw = lerp_angle(_yaw, target_yaw, 1.0 - exp(-player.profile.turn_speed * delta))
	rotation.y = _yaw

	var hinge_l: Node3D = _ears.get_node("EarHingeL") as Node3D
	var hinge_r: Node3D = _ears.get_node("EarHingeR") as Node3D
	if gliding:
		_ear_spin += delta * 22.0
		_ears.rotation.y = _ear_spin
		hinge_l.rotation_degrees.z = lerpf(hinge_l.rotation_degrees.z, -95.0, 1.0 - exp(-25.0 * delta))
		hinge_r.rotation_degrees.z = lerpf(hinge_r.rotation_degrees.z, 95.0, 1.0 - exp(-25.0 * delta))
	else:
		hinge_l.rotation_degrees.z = lerpf(hinge_l.rotation_degrees.z, -20.0, 1.0 - exp(-15.0 * delta))
		hinge_r.rotation_degrees.z = lerpf(hinge_r.rotation_degrees.z, 20.0, 1.0 - exp(-15.0 * delta))

	if perched:
		# Jemné balancování na špičce.
		rotation.z = sin(Time.get_ticks_msec() * 0.004) * 0.06
	else:
		rotation.z = 0.0

	_squash = lerpf(_squash, 1.0, 1.0 - exp(-10.0 * delta))
	var crouch: float = 0.78 if player.is_sneaking and posture == Posture.STAND else 1.0
	var sy: float = _squash * crouch
	scale = Vector3(1.0 / sqrt(_squash), sy, 1.0 / sqrt(_squash))
