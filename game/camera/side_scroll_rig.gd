## 2D kamera z boku (Rayman styl). Vlastní transformace rigu = pozice a natočení kamery.
## Sleduje Bruna v jeho 2D rovině, dívá se o kus dopředu ve směru běhu, svisle sleduje pomaleji.
class_name SideScrollRig
extends Node3D

@export var distance: float = 15.0
@export var height: float = 1.8
@export var look_ahead: float = 2.5
@export var follow_sharpness: float = 9.0
@export var vertical_sharpness: float = 5.0

var target: Player
var _ahead: float = 0.0


func _process(delta: float) -> void:
	if target == null or target.mode != Player.Mode.MODE_2D:
		return
	_update(delta, false)


## Okamžitě skočí na správné místo (po vstupu do obrazu, po respawnu).
func snap() -> void:
	if target != null:
		_ahead = 0.0
		_update(0.0, true)


func _update(delta: float, instant: bool) -> void:
	var n: Vector3 = target.plane_normal
	var right: Vector3 = Vector3.UP.cross(n).normalized()
	var vx: float = target.velocity.dot(right)
	if absf(vx) > 0.5:
		_ahead = lerpf(_ahead, signf(vx) * look_ahead, 1.0 - exp(-3.0 * delta))
	var t: Vector3 = target.get_global_transform_interpolated().origin
	var focus: Vector3 = t + Vector3.UP * height + right * _ahead
	var desired: Vector3 = focus + n * distance
	if instant:
		global_position = desired
	else:
		var p: Vector3 = global_position
		var h: float = 1.0 - exp(-follow_sharpness * delta)
		var v: float = 1.0 - exp(-vertical_sharpness * delta)
		var along: Vector3 = p.lerp(desired, h)
		along.y = lerpf(p.y, desired.y, v)
		global_position = along
	look_at(global_position - n, Vector3.UP)
