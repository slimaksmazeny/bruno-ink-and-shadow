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

@export_group("Situační pohled")
## Jak daleko před Brunem kamera „ohmatává“ terén (sráz, díra).
@export var probe_ahead: float = 3.5
## Od jakého převýšení se kamera začne dívat dolů.
@export var drop_threshold: float = 1.5
## Max. snížení pohledu a max. oddálení při srázu / díře.
@export var max_peek_down: float = 4.0
@export var max_peek_zoom: float = 5.0
@export var peek_speed: float = 2.5
## Ruční nahlédnutí pravou páčkou / myší nahoru-dolů (metry).
@export var manual_peek: float = 3.0

var target: Player
var _ahead: float = 0.0
var _ground_y: float = 0.0
var _peek_down: float = 0.0
var _peek_zoom: float = 0.0
var _manual: float = 0.0
## Pro ladicí panel / testy: jak hluboko je terén před Brunem.
var last_drop: float = 0.0


func _process(delta: float) -> void:
	if target == null or target.mode != Player.Mode.MODE_2D:
		return
	_update(delta, false)


## Okamžitě skočí na správné místo (po vstupu do obrazu, po respawnu).
func snap() -> void:
	if target != null:
		_ahead = 0.0
		_ground_y = target.global_position.y
		_peek_down = 0.0
		_peek_zoom = 0.0
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

	# Situační pohled: co je před Brunem dole? Sráz / díra → podívat se dolů a oddálit.
	var dir: float = signf(_ahead) if absf(_ahead) > 0.3 else facing
	last_drop = _probe_drop(t, right * dir)
	var want_down: float = 0.0
	var want_zoom: float = 0.0
	if last_drop > drop_threshold:
		var k: float = clampf((last_drop - drop_threshold) / 6.0, 0.0, 1.0)
		want_down = max_peek_down * k
		want_zoom = max_peek_zoom * k
	var blend_k: float = 1.0 if instant else 1.0 - exp(-peek_speed * delta)
	_peek_down = lerpf(_peek_down, want_down, blend_k)
	_peek_zoom = lerpf(_peek_zoom, want_zoom, blend_k)

	# Ruční nahlédnutí (pravá páčka / myš nahoru-dolů).
	var look: Vector2 = InputManager.consume_look(delta) if not instant else Vector2.ZERO
	var stick: float = InputManager.get_look_stick().y
	_manual = clampf(_manual + look.y * 6.0, -1.0, 1.0)
	if absf(stick) > 0.2:
		_manual = stick
	elif absf(look.y) < 0.0001:
		_manual = move_toward(_manual, 0.0, delta * 1.5)

	var focus: Vector3 = Vector3(t.x, _ground_y + height - _peek_down - _manual * manual_peek, t.z) + right * _ahead
	var tilt: float = deg_to_rad(tilt_deg)
	var dist: float = distance + _peek_zoom
	var desired: Vector3 = focus + n * (dist * cos(tilt)) + Vector3.UP * (dist * sin(tilt))
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


## Jak hluboko klesá terén kus před Brunem (díra = velké číslo).
func _probe_drop(t: Vector3, ahead_dir: Vector3) -> float:
	var space: PhysicsDirectSpaceState3D = target.get_world_3d().direct_space_state
	var from: Vector3 = t + ahead_dir * probe_ahead + Vector3.UP * 0.6
	var q := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 20.0, 1)
	q.exclude = [target.get_rid()]
	var hit: Dictionary = space.intersect_ray(q)
	if hit.is_empty():
		return 20.0
	return maxf(_ground_y - (hit["position"] as Vector3).y, 0.0)
