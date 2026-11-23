## Bruno stojí. Brzdí na nulu a čeká na vstup.
extends GroundedState


func enter(previous: StringName, msg: Dictionary = {}) -> void:
	super.enter(previous, msg)
	player.is_sneaking = false
	player.visual.set_posture(PlayerVisual.Posture.STAND)


func physics_update(delta: float) -> void:
	if handle_common(delta):
		return
	accelerate_horizontal(Vector3.ZERO, player.profile.ground_decel, delta)
	stick_to_floor()
	var next: StringName = pick_ground_state(player)
	if next != &"Idle":
		machine.transition_to(next)
