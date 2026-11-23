## Chůze na dvou nohách. Při slabém vychýlení páčky nebo držení „sneak“ se Bruno plíží.
extends GroundedState


func enter(previous: StringName, msg: Dictionary = {}) -> void:
	super.enter(previous, msg)
	player.visual.set_posture(PlayerVisual.Posture.STAND)


func exit() -> void:
	player.is_sneaking = false


func physics_update(delta: float) -> void:
	if handle_common(delta):
		return
	var p: MovementProfile = player.profile
	var strength: float = player.get_move_strength()
	player.is_sneaking = player.wants_sneak() or strength < p.sneak_stick_threshold

	var speed: float = p.sneak_speed if player.is_sneaking else p.walk_speed * strength
	var dir: Vector3 = player.get_move_dir().normalized()
	var accel: float = p.ground_accel if strength > 0.05 else p.ground_decel
	accelerate_horizontal(dir * speed, accel, delta)
	stick_to_floor()

	var next: StringName = pick_ground_state(player)
	if next != &"Move":
		machine.transition_to(next)
