## Útok holí ve vzduchu: krátká otočka s holí, malé nadlehčení. Jednou za skok.
extends AirborneState

const DURATION: float = 0.3
const ACTIVE_FROM: float = 0.04
const ACTIVE_TO: float = 0.24

var _t: float = 0.0
var _active: bool = false


func enter(_previous: StringName, _msg: Dictionary = {}) -> void:
	_t = 0.0
	_active = false
	player.air_attack_used = true
	carried_speed = maxf(horizontal_speed(), player.profile.walk_speed)
	player.velocity.y = maxf(player.velocity.y, 2.5)
	player.visual.play_air_attack(DURATION)


func exit() -> void:
	player.cane_hitbox.end_swing()


func physics_update(delta: float) -> void:
	_t += delta
	if not _active and _t >= ACTIVE_FROM and _t < ACTIVE_TO:
		_active = true
		player.cane_hitbox.begin_swing({"damage": 1, "knockback": 5.0, "combo": 1, "dir": player.visual.get_forward(), "from": player.global_position, "air": true})
	elif _active and _t >= ACTIVE_TO:
		_active = false
		player.cane_hitbox.end_swing()
	apply_gravity(delta, 0.6)
	air_control(delta, carried_speed)
	if check_landing():
		return
	if _t >= DURATION:
		machine.transition_to(&"Air", {"keep_jumps": true})
