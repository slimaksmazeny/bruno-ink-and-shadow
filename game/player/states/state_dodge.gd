## Úhyb (C / L1 / dotykové tlačítko): rychlý kotoul ve směru pohybu (bez směru = dozadu).
## Během kotoulu Bruna nic nezraní. Funguje na zemi i ve 2D; krátká prodleva před dalším.
extends PlayerState

const DURATION: float = 0.32
const SPEED: float = 9.5
const COOLDOWN: float = 0.45

static var _ready_at_ms: int = 0

var _t: float = 0.0
var _dir: Vector3


static func can_dodge() -> bool:
	return Time.get_ticks_msec() >= _ready_at_ms


func enter(previous: StringName, msg: Dictionary = {}) -> void:
	super.enter(previous, msg)
	_t = 0.0
	var d: Vector3 = player.get_move_dir()
	d.y = 0.0
	if d.length() < 0.2:
		d = -player.visual.get_forward()
		d.y = 0.0
	_dir = d.normalized()
	player.dodging = true
	player.visual.set_posture(PlayerVisual.Posture.SPRINT)
	player.visual.face_direction(_dir if d.length() >= 0.2 else -_dir)
	player.visual.play_roll(DURATION)
	AudioManager.play(&"swish", -4.0, 0.7)
	_ready_at_ms = Time.get_ticks_msec() + int((DURATION + COOLDOWN) * 1000.0)


func exit() -> void:
	player.dodging = false


func physics_update(delta: float) -> void:
	_t += delta
	var k: float = 1.0 - clampf(_t / DURATION, 0.0, 1.0) * 0.6
	player.velocity.x = _dir.x * SPEED * k
	player.velocity.z = _dir.z * SPEED * k
	player.velocity.y -= player.profile.gravity * delta
	if _t >= DURATION:
		if player.is_on_floor():
			machine.transition_to(GroundedState.pick_ground_state(player))
		else:
			machine.transition_to(&"Air", {})
