## Plížení po úzké římse podél zdi, zády ke zdi (stealth hry). Pohyb podél římsy podle kamery.
## Na konci římsy Bruno sejde dolů. Skok = odraz od zdi, akce = seskočit.
extends AnchorState

const PULL_TIME: float = 0.16
const SNEAK_SPEED: float = 2.2
const WALL_GAP: float = 0.3

var _t: float = 0.0
var _start: Vector3
var _pos_t: float = 0.0
var _line: LineAnchor


func enter(previous: StringName, msg: Dictionary = {}) -> void:
	super.enter(previous, msg)
	_line = anchor as LineAnchor
	_t = 0.0
	_start = player.global_position
	player.velocity = Vector3.ZERO
	if _line != null:
		_pos_t = _line.closest_t(player.global_position)


func physics_update(delta: float) -> void:
	if _line == null or not is_instance_valid(_line):
		drop_off()
		return
	player.velocity = Vector3.ZERO
	var out: Vector3 = _line.global_outward()
	if _t < PULL_TIME:
		_t += delta
		var k: float = ease(clampf(_t / PULL_TIME, 0.0, 1.0), -2.0)
		player.global_position = _start.lerp(_feet(), k) + Vector3.UP * sin(k * PI) * 0.4
		player.visual.face_direction(out)
		return
	var ax: Vector3 = _line.global_axis()
	var along: float = player.get_move_dir().dot(ax)
	_pos_t += along * SNEAK_SPEED * delta
	if _pos_t > _line.length + 0.05 or _pos_t < -0.05:
		_pos_t = clampf(_pos_t, 0.0, _line.length)
		player.global_position = _feet() + ax * signf(along) * 0.5
		player.jumps_used = 1
		machine.transition_to(&"Air", {})
		return
	player.global_position = _feet()
	# Zády ke zdi, mírně natočený ve směru plížení.
	var look: Vector3 = out
	if absf(along) > 0.1:
		look = (out + ax * signf(along) * 0.8).normalized()
	player.visual.face_direction(look)

	if player.consume_jump_buffer():
		machine.transition_to(&"Air", {"jump": true})
		player.velocity.x = out.x * 4.0
		player.velocity.z = out.z * 4.0
		return
	if Input.is_action_just_pressed(&"action"):
		drop_off()


func _feet() -> Vector3:
	return _line.point_at(_pos_t) + _line.global_outward() * WALL_GAP + Vector3.UP * 0.05
