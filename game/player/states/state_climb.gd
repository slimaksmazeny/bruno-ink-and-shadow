## Šplhání po trubce / okapu (Sly). Nahoru/dolů = pohyb vpřed/vzad, do stran = obcházení trubky.
## Nahoře: tlač dál nahoru = vylézt na střechu. Dole: tlač dolů = seskočit.
## Skok = odraz od trubky (dvojskok zůstává), akce = pustit se.
extends AnchorState

const PULL_TIME: float = 0.16
const CLIMB_SPEED: float = 3.2
const ORBIT_SPEED: float = 2.4
const BODY_OFFSET: float = 0.42
## Úchop rukou je nad chodidly – nejnižší možný úchop.
const MIN_GRIP: float = 0.6

var _t: float = 0.0
var _start: Vector3
var _height: float = 0.0
var _side: Vector3 = Vector3.BACK
var _line: LineAnchor


func enter(previous: StringName, msg: Dictionary = {}) -> void:
	super.enter(previous, msg)
	_line = anchor as LineAnchor
	_t = 0.0
	_start = player.global_position
	player.velocity = Vector3.ZERO
	if _line == null:
		return
	_height = clampf(_line.closest_t(player.global_position) + MIN_GRIP, MIN_GRIP, _line.length - 0.4)
	var to_player: Vector3 = player.global_position - _line.point_at(_height)
	to_player.y = 0.0
	_side = to_player.normalized() if to_player.length() > 0.05 else _line.global_outward()
	AudioManager.play(&"land", -8.0, 1.4)


func physics_update(delta: float) -> void:
	if _line == null or not is_instance_valid(_line):
		drop_off()
		return
	player.velocity = Vector3.ZERO
	var target: Vector3 = _body_pos()
	if _t < PULL_TIME:
		_t += delta
		player.global_position = _start.lerp(target, ease(clampf(_t / PULL_TIME, 0.0, 1.0), -2.0))
		player.visual.face_direction(-_side)
		return

	var raw: Vector2 = InputManager.get_move_vector()
	var up: float = -raw.y
	# Kamera za Brunem: „vpřed“ = nahoru po trubce.
	_height += up * CLIMB_SPEED * delta
	if absf(raw.x) > 0.2:
		_side = _side.rotated(Vector3.UP, -raw.x * ORBIT_SPEED * delta)
	if _height >= _line.length - 0.2 and up > 0.3:
		_climb_over()
		return
	if _height <= MIN_GRIP and up < -0.3:
		drop_off()
		return
	_height = clampf(_height, MIN_GRIP, _line.length - 0.2)
	player.global_position = _body_pos()
	player.visual.face_direction(-_side)

	if player.consume_jump_buffer():
		# Odraz od trubky směrem od ní.
		machine.transition_to(&"Air", {"jump": true})
		player.velocity.x = _side.x * 5.0
		player.velocity.z = _side.z * 5.0
		return
	if Input.is_action_just_pressed(&"action"):
		drop_off()


func _body_pos() -> Vector3:
	# Chodidla trochu pod úchopem rukou.
	return _line.point_at(_height) + _side * BODY_OFFSET + Vector3.DOWN * 0.6


## Vylézt nahoře přes hranu (na střechu za trubkou).
func _climb_over() -> void:
	var top: Vector3 = _line.seg_b() - _side * 0.7 + Vector3.UP * 0.1
	player.global_position = top
	player.reset_physics_interpolation()
	player.visual.land_squash(0.85)
	machine.transition_to(&"Idle", {"force": true})
