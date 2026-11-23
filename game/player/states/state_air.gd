## Ve vzduchu: skok ze země, dvojskok, pád (i z hrany s coyote time).
## msg {"jump": true} = stav začíná skokem ze země.
extends AirborneState

const MAX_JUMPS: int = 2

var _from_sprint: bool = false


func enter(previous: StringName, msg: Dictionary = {}) -> void:
	_from_sprint = previous == &"Sprint"
	carried_speed = maxf(horizontal_speed(), player.profile.walk_speed)
	if msg.get("jump", false):
		_ground_jump()


func exit() -> void:
	if _from_sprint:
		player.visual.set_posture(PlayerVisual.Posture.STAND)


func physics_update(delta: float) -> void:
	if Input.is_action_just_pressed(&"jump"):
		if player.jumps_used == 0 and player.coyote_timer > 0.0:
			_ground_jump()
		elif player.jumps_used < MAX_JUMPS:
			_double_jump()

	apply_gravity(delta)
	air_control(delta, carried_speed)
	check_landing()


func _ground_jump() -> void:
	player.velocity.y = jump_velocity(player.profile.jump_height)
	player.jumps_used = 1
	player.coyote_timer = 0.0
	player.jump_buffer_timer = 0.0


func _double_jump() -> void:
	player.velocity.y = jump_velocity(player.profile.double_jump_height)
	# Po pádu z hrany bez skoku je dvojskok poslední možný skok.
	player.jumps_used = MAX_JUMPS
	player.jump_buffer_timer = 0.0
	if _from_sprint:
		player.visual.set_posture(PlayerVisual.Posture.STAND)
		_from_sprint = false
