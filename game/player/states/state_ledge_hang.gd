## Visení na římse a ručkování do stran (Sly). Doleva/doprava podle kamery.
## Nahoru nebo skok = vytáhnout se nahoru, dolů nebo akce = pustit se.
extends AnchorState

const PULL_TIME: float = 0.16
const SHIMMY_SPEED: float = 2.4
const HANG_DROP: float = 1.15
const WALL_GAP: float = 0.42
const CLIMB_UP_TIME: float = 0.22

var _t: float = 0.0
var _start: Vector3
var _pos_t: float = 0.0
var _line: LineAnchor
var _climbing: float = -1.0


func enter(previous: StringName, msg: Dictionary = {}) -> void:
	super.enter(previous, msg)
	_line = anchor as LineAnchor
	_t = 0.0
	_climbing = -1.0
	_start = player.global_position
	player.velocity = Vector3.ZERO
	if _line != null:
		_pos_t = clampf(_line.closest_t(player.global_position), 0.3, _line.length - 0.3)
	AudioManager.play(&"land", -6.0, 1.2)


func physics_update(delta: float) -> void:
	if _line == null or not is_instance_valid(_line):
		drop_off()
		return
	player.velocity = Vector3.ZERO
	var out: Vector3 = _line.global_outward()
	if _climbing >= 0.0:
		_climbing += delta
		var k: float = clampf(_climbing / CLIMB_UP_TIME, 0.0, 1.0)
		var top: Vector3 = _line.point_at(_pos_t) - out * 0.6 + Vector3.UP * 0.05
		var mid: Vector3 = _line.point_at(_pos_t) + out * 0.2 + Vector3.UP * 0.4
		player.global_position = _hang_pos().lerp(mid, minf(k * 2.0, 1.0)).lerp(top, maxf(k * 2.0 - 1.0, 0.0))
		if k >= 1.0:
			player.visual.land_squash(0.85)
			machine.transition_to(&"Idle", {"force": true})
		return
	if _t < PULL_TIME:
		_t += delta
		player.global_position = _start.lerp(_hang_pos(), ease(clampf(_t / PULL_TIME, 0.0, 1.0), -2.0))
		player.visual.face_direction(-out)
		return

	# Ručkování: směr pohybu promítnutý na osu římsy.
	var dir: Vector3 = player.get_move_dir()
	var along: float = dir.dot(_line.global_axis())
	_pos_t = clampf(_pos_t + along * SHIMMY_SPEED * delta, 0.3, _line.length - 0.3)
	player.global_position = _hang_pos()
	player.visual.face_direction(-out)

	var raw: Vector2 = InputManager.get_move_vector()
	var toward_wall: float = dir.dot(-out)
	if player.consume_jump_buffer() or (toward_wall > 0.7 and absf(along) < 0.4 and raw.length() > 0.7):
		_climbing = 0.0
		AudioManager.play(&"jump", -4.0, 0.8)
		return
	if Input.is_action_just_pressed(&"action") or toward_wall < -0.7:
		drop_off()


func _hang_pos() -> Vector3:
	return _line.point_at(_pos_t) + _line.global_outward() * WALL_GAP + Vector3.DOWN * HANG_DROP
