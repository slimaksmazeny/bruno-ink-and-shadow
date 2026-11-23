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
var _yaw: float = 0.0
var _squash: float = 1.0
var _ear_spin: float = 0.0


func set_posture(new_posture: Posture) -> void:
	posture = new_posture
	_stand.visible = posture == Posture.STAND
	_sprint.visible = posture == Posture.SPRINT


## Ušní vrtulník: uši se roztáhnou do stran a točí se.
func set_gliding(on: bool) -> void:
	gliding = on
	if on:
		set_posture(Posture.STAND)
	else:
		_ears.rotation = Vector3.ZERO
		for ear: Node3D in [_ears.get_node("EarL") as Node3D, _ears.get_node("EarR") as Node3D]:
			ear.rotation_degrees.x = 0.0


func set_perched(on: bool) -> void:
	perched = on


## Směr, kterým se Bruno dívá (vodorovně).
func get_forward() -> Vector3:
	return Vector3(-sin(_yaw), 0.0, -cos(_yaw))


## Krátké „zmáčknutí“ při dopadu (squash & stretch).
func land_squash(amount: float = 0.75) -> void:
	_squash = amount


func update_visual(delta: float, player: Player) -> void:
	var horizontal := Vector3(player.velocity.x, 0.0, player.velocity.z)
	if horizontal.length() > 0.3:
		var target_yaw: float = atan2(-horizontal.x, -horizontal.z)
		_yaw = lerp_angle(_yaw, target_yaw, 1.0 - exp(-player.profile.turn_speed * delta))
	rotation.y = _yaw

	if gliding:
		_ear_spin += delta * 22.0
		_ears.rotation.y = _ear_spin
		for ear: Node3D in [_ears.get_node("EarL") as Node3D, _ears.get_node("EarR") as Node3D]:
			ear.rotation_degrees.x = 0.0
		(_ears.get_node("EarL") as Node3D).rotation_degrees.z = -80.0
		(_ears.get_node("EarR") as Node3D).rotation_degrees.z = 80.0
	else:
		(_ears.get_node("EarL") as Node3D).rotation_degrees.z = -12.0
		(_ears.get_node("EarR") as Node3D).rotation_degrees.z = 12.0

	if perched:
		# Jemné balancování na špičce.
		rotation.z = sin(Time.get_ticks_msec() * 0.004) * 0.06
	else:
		rotation.z = 0.0

	_squash = lerpf(_squash, 1.0, 1.0 - exp(-10.0 * delta))
	var crouch: float = 0.78 if player.is_sneaking and posture == Posture.STAND else 1.0
	var sy: float = _squash * crouch
	scale = Vector3(1.0 / sqrt(_squash), sy, 1.0 / sqrt(_squash))
