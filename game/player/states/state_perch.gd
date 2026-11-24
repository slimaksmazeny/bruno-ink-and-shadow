## Magnetické přitažení na špičku a balancování na ní (stealth styl).
## Skok = odraz ze špičky (dvojskok zůstává), akce = pustit se dolů.
extends AnchorState

const PULL_TIME: float = 0.18

var _t: float = 0.0
var _start: Vector3


func enter(previous: StringName, msg: Dictionary = {}) -> void:
	super.enter(previous, msg)
	_t = 0.0
	_start = player.global_position
	player.velocity = Vector3.ZERO
	player.visual.set_posture(PlayerVisual.Posture.STAND)
	player.visual.set_perched(true)


func exit() -> void:
	player.visual.set_perched(false)
	super.exit()


func physics_update(delta: float) -> void:
	if anchor == null or not is_instance_valid(anchor):
		drop_off()
		return
	var target: Vector3 = anchor.get_snap_position(player.global_position)
	player.velocity = Vector3.ZERO
	if _t < PULL_TIME:
		_t += delta
		var k: float = ease(clampf(_t / PULL_TIME, 0.0, 1.0), -2.0)
		var arc: float = sin(k * PI) * 0.6
		player.global_position = _start.lerp(target, k) + Vector3.UP * arc
		return
	player.global_position = target

	if player.consume_jump_buffer():
		jump_off()
		return
	if Input.is_action_just_pressed(&"action"):
		drop_off()
