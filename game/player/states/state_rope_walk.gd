## Chůze po laně (Sly). Pohyb podél lana podle kamery; balancování řeší PlayerVisual (set_perched).
## Na konci lana sejde dolů na střechu. Skok = odraz (dvojskok zůstává), akce = seskočit.
extends AnchorState

const PULL_TIME: float = 0.16
const WALK_SPEED: float = 3.4

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
	player.visual.set_perched(true)


func exit() -> void:
	player.visual.set_perched(false)
	super.exit()


func physics_update(delta: float) -> void:
	if _line == null or not is_instance_valid(_line):
		drop_off()
		return
	player.velocity = Vector3.ZERO
	if _t < PULL_TIME:
		_t += delta
		var k: float = ease(clampf(_t / PULL_TIME, 0.0, 1.0), -2.0)
		player.global_position = _start.lerp(_feet(), k) + Vector3.UP * sin(k * PI) * 0.5
		return

	var dir: Vector3 = player.get_move_dir()
	var ax: Vector3 = _line.global_axis()
	var along: float = dir.dot(ax)
	_pos_t += along * WALK_SPEED * delta
	if _pos_t > _line.length + 0.1 or _pos_t < -0.1:
		# Konec lana – krok dolů z lana dál ve směru chůze.
		var step_dir: Vector3 = Vector3(ax.x, 0.0, ax.z).normalized() * signf(along)
		_pos_t = clampf(_pos_t, 0.0, _line.length)
		player.global_position = _feet() + step_dir * 0.6 + Vector3.UP * 0.1
		player.jumps_used = 0
		machine.transition_to(&"Air", {})
		return
	player.global_position = _feet()
	if absf(along) > 0.1:
		var flat: Vector3 = Vector3(ax.x, 0.0, ax.z) * signf(along)
		player.visual.face_direction(flat)

	if player.consume_jump_buffer():
		jump_off()
		return
	if Input.is_action_just_pressed(&"action"):
		drop_off()


func _feet() -> Vector3:
	return _line.point_at(_pos_t) + Vector3.UP * 0.04
