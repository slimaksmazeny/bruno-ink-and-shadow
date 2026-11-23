## Greybox vzhled Bruna: postoj na 2 nohách vs. sprint na 4 nohách, plížení, natočení do směru pohybu.
## Později se sem napojí skutečný model a AnimationTree – stavy hráče se kvůli tomu měnit nebudou.
class_name PlayerVisual
extends Node3D

enum Posture { STAND, SPRINT }

@onready var _stand: Node3D = $Stand
@onready var _sprint: Node3D = $Sprint

var posture: Posture = Posture.STAND
var _yaw: float = 0.0
var _squash: float = 1.0


func set_posture(new_posture: Posture) -> void:
	posture = new_posture
	_stand.visible = posture == Posture.STAND
	_sprint.visible = posture == Posture.SPRINT


## Krátké „zmáčknutí“ při dopadu (squash & stretch).
func land_squash(amount: float = 0.75) -> void:
	_squash = amount


func update_visual(delta: float, player: Player) -> void:
	var horizontal := Vector3(player.velocity.x, 0.0, player.velocity.z)
	if horizontal.length() > 0.3:
		var target_yaw: float = atan2(-horizontal.x, -horizontal.z)
		_yaw = lerp_angle(_yaw, target_yaw, 1.0 - exp(-player.profile.turn_speed * delta))
	rotation.y = _yaw

	_squash = lerpf(_squash, 1.0, 1.0 - exp(-10.0 * delta))
	var crouch: float = 0.78 if player.is_sneaking and posture == Posture.STAND else 1.0
	var sy: float = _squash * crouch
	scale = Vector3(1.0 / sqrt(_squash), sy, 1.0 / sqrt(_squash))
