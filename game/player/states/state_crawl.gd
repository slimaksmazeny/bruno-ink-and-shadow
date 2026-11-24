## Plazení pod nízkými překážkami (stoly, trubky, škvíry). Spustí se plížením (Ctrl / L3)
## u nízké překážky; pod stropem Bruno zůstane plazit, dokud nevyleze. Nízká kolize, pomalejší pohyb, bez skoku pod stropem.
extends GroundedState

const CRAWL_SPEED: float = 2.4


func enter(previous: StringName, msg: Dictionary = {}) -> void:
	super.enter(previous, msg)
	player.set_low_collision(true)
	player.visual.set_posture(PlayerVisual.Posture.SPRINT)
	player.is_sneaking = true


func exit() -> void:
	player.set_low_collision(false)
	player.is_sneaking = false


func physics_update(delta: float) -> void:
	var dir: Vector3 = player.get_move_dir().normalized()
	var strength: float = player.get_move_strength()
	accelerate_horizontal(dir * CRAWL_SPEED * minf(strength * 1.5, 1.0), player.profile.ground_accel, delta)
	stick_to_floor()
	if not player.is_on_floor():
		machine.transition_to(&"Air", {})
		return
	# Skok jde, jen když strop není přímo nad Brunem (třeba jen před ním – klobouk houby).
	if player.jump_buffer_timer > 0.0 and not player.has_low_ceiling(player.global_position):
		player.consume_jump_buffer()
		machine.transition_to(&"Air", {"jump": true})
		return
	if Input.is_action_just_pressed(&"attack"):
		machine.transition_to(&"Attack", {"combo": 1})
		return
	# Ven až když je nad Brunem volno (jinak by se vstáváním zasekl ve stropě).
	var next: StringName = pick_ground_state(player)
	if next != &"Crawl":
		machine.transition_to(next)
