## Sprint po čtyřech: hůl na zádech, nejvyšší rychlost na zemi.
extends GroundedState


func enter(previous: StringName, msg: Dictionary = {}) -> void:
	super.enter(previous, msg)
	player.is_sneaking = false
	player.visual.set_posture(PlayerVisual.Posture.SPRINT)


func exit() -> void:
	player.visual.set_posture(PlayerVisual.Posture.STAND)


func physics_update(delta: float) -> void:
	if handle_common(delta):
		return
	var p: MovementProfile = player.profile
	var dir: Vector3 = player.get_move_dir().normalized()
	accelerate_horizontal(dir * p.sprint_speed, p.ground_accel, delta)
	stick_to_floor()

	var next: StringName = pick_ground_state(player)
	if next != &"Sprint":
		machine.transition_to(next)
