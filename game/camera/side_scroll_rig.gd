## 2D kamera z boku (Rayman styl). Vlastní transformace rigu = pozice a natočení kamery.
## Vodorovně: plynulý výhled dopředu ve směru běhu.
## Svisle: drží výšku, na které Bruno naposledy stál – při běžném skoku se nehoupe;
## posune se jen když Bruno vyletí / spadne mimo „mrtvou zónu“ (houba, pád do hloubky).
class_name SideScrollRig
extends Node3D

@export var distance: float = 12.5
@export var height: float = 1.4
@export var look_ahead: float = 3.0
## Jak rychle se výhled dopředu přepne při otočení (menší = plynulejší).
@export var look_ahead_speed: float = 2.2
@export var follow_sharpness: float = 7.0
@export var vertical_sharpness: float = 3.5
## Polovina výšky mrtvé zóny – v ní kamera svisle nesleduje skok.
@export var vertical_dead_zone: float = 2.2
## Mírný pohled shora (stupně) – plošiny pod Brunem jsou lépe vidět.
@export var tilt_deg: float = 4.0

var target: Player
var _ahead: float = 0.0
var _ground_y: float = 0.0


func _process(delta: float) -> void:
	if target == null or target.mode != Player.Mode.MODE_2D:
		return
	_update(delta, false)


## Okamžitě skočí na správné místo (po vstupu do obrazu, po respawnu).
func snap() -> void:
	if target != null:
		_ahead = 0.0
		_ground_y = target.global_position.y
		_update(0.0, true)


func _update(delta: float, instant: bool) -> void:
	var n: Vector3 = target.plane_normal
	var right: Vector3 = Vector3.UP.cross(n).normalized()
	var t: Vector3 = target.get_global_transform_interpolated().origin

	# Výhled dopředu podle směru, kterým se Bruno dívá / běží.
	var vx: float = target.velocity.dot(right)
	var facing: float = signf(target.visual.get_forward().dot(right))
	var want: float = (signf(vx) if absf(vx) > 0.5 else facing) * look_ahead
	_ahead = lerpf(_ahead, want, 1.0 - exp(-look_ahead_speed * delta))

	# Svislá referenční výška: na zemi = aktuální výška, ve vzduchu jen mimo mrtvou zónu.
	if target.is_on_floor():
		_ground_y = t.y
	elif t.y > _ground_y + vertical_dead_zone:
		_ground_y = t.y - vertical_dead_zone
	elif t.y < _ground_y - vertical_dead_zone * 0.5:
		_ground_y = t.y + vertical_dead_zone * 0.5

	var focus: Vector3 = Vector3(t.x, _ground_y + height, t.z) + right * _ahead
	var tilt: float = deg_to_rad(tilt_deg)
	var desired: Vector3 = focus + n * (distance * cos(tilt)) + Vector3.UP * (distance * sin(tilt))
	if instant:
		global_position = desired
	else:
		var p: Vector3 = global_position
		var h: float = 1.0 - exp(-follow_sharpness * delta)
		var v: float = 1.0 - exp(-vertical_sharpness * delta)
		var next: Vector3 = p.lerp(desired, h)
		next.y = lerpf(p.y, desired.y, v)
		global_position = next
	look_at(global_position - n * cos(tilt) - Vector3.UP * sin(tilt), Vector3.UP)
