## Švih holí. msg {"ball": true} = rychlý odpal tenisáku (Q / dotykové tlačítko),
## bez míčku = hlavní útok holí (□ / levé tlačítko myši).
extends GroundedState

const WINDUP: float = 0.12
const RECOVER: float = 0.22

var _t: float = 0.0
var _hit_done: bool = false
var _with_ball: bool = false
var _aim_dir: Vector3 = Vector3.FORWARD


func enter(previous: StringName, msg: Dictionary = {}) -> void:
	super.enter(previous, msg)
	_t = 0.0
	_hit_done = false
	_with_ball = msg.get("ball", false)
	player.is_sneaking = false
	player.visual.set_posture(PlayerVisual.Posture.STAND)
	if _with_ball:
		_aim_dir = TennisLauncher.compute_aim_dir(player)
		player.visual.face_direction(Vector3(_aim_dir.x, 0.0, _aim_dir.z))
	else:
		# Útok holí míří tam, kam se díváš (jako ve Slyovi), ne nutně kam běžíš.
		var yaw: float = player.camera.get_control_yaw() if player.camera != null else 0.0
		var move: Vector3 = player.get_move_dir()
		var dir: Vector3 = move if move.length() > 0.3 else Basis(Vector3.UP, yaw) * Vector3.FORWARD
		player.visual.face_direction(dir)
	player.visual.play_swing(WINDUP + RECOVER)


func physics_update(delta: float) -> void:
	if not player.is_on_floor():
		machine.transition_to(&"Air", {})
		return
	accelerate_horizontal(Vector3.ZERO, player.profile.ground_decel, delta)
	stick_to_floor()
	_t += delta
	if not _hit_done and _t >= WINDUP:
		_hit_done = true
		if _with_ball:
			TennisLauncher.launch(player, _aim_dir)
	if _t >= WINDUP + RECOVER:
		machine.transition_to(pick_ground_state(player))
