## Míření tenisákem (L2 / pravé tlačítko myši držet). Kamera se přiblíží přes rameno,
## Bruno se natočí ve směru kamery a pomalu se pohybuje. Výstřel: R2 / levé tlačítko myši.
extends GroundedState

const FIRE_COOLDOWN: float = 0.3
const AIM_MOVE_SPEED: float = 3.0

var _cooldown: float = 0.0


func enter(previous: StringName, msg: Dictionary = {}) -> void:
	super.enter(previous, msg)
	_cooldown = 0.0
	player.is_sneaking = false
	player.visual.set_posture(PlayerVisual.Posture.STAND)
	player.visual.facing_locked = true
	if player.camera != null:
		player.camera.set_aiming(true)
	Events.aim_changed.emit(true)


func exit() -> void:
	player.visual.facing_locked = false
	if player.camera != null:
		player.camera.set_aiming(false)
	Events.aim_changed.emit(false)


func physics_update(delta: float) -> void:
	if not player.is_on_floor():
		machine.transition_to(&"Air", {})
		return
	if player.consume_jump_buffer():
		machine.transition_to(&"Air", {"jump": true})
		return
	if not Input.is_action_pressed(&"aim"):
		machine.transition_to(pick_ground_state(player))
		return

	var dir: Vector3 = player.get_move_dir()
	accelerate_horizontal(dir * AIM_MOVE_SPEED, player.profile.ground_accel, delta)
	stick_to_floor()
	var yaw: float = player.camera.get_control_yaw() if player.camera != null else 0.0
	player.visual.face_direction(Basis(Vector3.UP, yaw) * Vector3.FORWARD)

	_cooldown = maxf(_cooldown - delta, 0.0)
	if Input.is_action_just_pressed(&"fire") and _cooldown <= 0.0:
		_cooldown = FIRE_COOLDOWN
		player.visual.play_swing(0.3)
		TennisLauncher.launch(player, TennisLauncher.compute_aim_dir(player))
