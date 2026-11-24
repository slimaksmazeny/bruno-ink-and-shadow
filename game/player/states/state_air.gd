## Ve vzduchu: skok ze země, dvojskok, pád (i z hrany s coyote time).
## msg {"jump": true} = stav začíná skokem ze země.
extends AirborneState

const MAX_JUMPS: int = 2

var _from_sprint: bool = false
## Odraz z houby se nezkracuje puštěním skoku (dokud Bruno stoupá z odrazu).
var _bounce_rise: bool = false
## 2D odraz od zdi (2D plošinovky): krátká paměť poslední zdi + chvilka bez řízení po odrazu.
const WALL_SLIDE_SPEED: float = 3.0
const WALL_COYOTE: float = 0.12
const WALL_JUMP_LOCK: float = 0.16
var _wall_normal: Vector3 = Vector3.ZERO
var _wall_timer: float = 0.0
var _wall_lock: float = 0.0


func enter(previous: StringName, msg: Dictionary = {}) -> void:
	_from_sprint = previous == &"Sprint"
	# Odraz z houby: zachová se vodorovná rychlost (2D plošinovky feel) a nezkracuje se.
	_bounce_rise = msg.get("bounce", false)
	carried_speed = maxf(horizontal_speed(), player.profile.walk_speed)
	if msg.get("jump", false):
		_ground_jump()


func exit() -> void:
	if _from_sprint:
		player.visual.set_posture(PlayerVisual.Posture.STAND)


func physics_update(delta: float) -> void:
	if Input.is_action_just_pressed(&"action") and try_enter_anchor():
		return
	if Input.is_action_just_pressed(&"attack") and not player.air_attack_used:
		machine.transition_to(&"AirAttack")
		return
	_update_wall(delta)
	if _wall_timer > 0.0 and player.coyote_timer <= 0.0 and player.consume_jump_buffer():
		_wall_jump()
	elif Input.is_action_just_pressed(&"jump"):
		if player.jumps_used == 0 and player.coyote_timer > 0.0:
			_ground_jump()
		elif player.jumps_used < MAX_JUMPS:
			_double_jump()

	# Ušní vrtulník: držet skok během pádu.
	if player.velocity.y < 0.0 and Input.is_action_pressed(&"jump") and not Input.is_action_just_pressed(&"jump"):
		machine.transition_to(&"Glide")
		return

	if player.velocity.y <= 0.0:
		_bounce_rise = false
	apply_gravity(delta, 1.0, not _bounce_rise)
	if _wall_lock > 0.0:
		_wall_lock -= delta
	else:
		air_control(delta, carried_speed)
	# Klouzání po zdi: pomalejší pád, když Bruno tlačí do zdi.
	if _is_wall_sliding():
		player.velocity.y = maxf(player.velocity.y, -WALL_SLIDE_SPEED)
	check_landing()


func _update_wall(delta: float) -> void:
	_wall_timer = maxf(_wall_timer - delta, 0.0)
	if player.mode != Player.Mode.MODE_2D:
		return
	if player.is_on_wall_only():
		var n: Vector3 = player.get_wall_normal()
		n.y = 0.0
		if n.length() > 0.5:
			_wall_normal = n.normalized()
			_wall_timer = WALL_COYOTE


func _is_wall_sliding() -> bool:
	if player.mode != Player.Mode.MODE_2D or not player.is_on_wall_only() or player.velocity.y >= 0.0:
		return false
	return player.get_move_dir().dot(-_wall_normal) > 0.3


func _wall_jump() -> void:
	AudioManager.play(&"jump", 0.0, 1.15)
	_bounce_rise = false
	_wall_timer = 0.0
	_wall_lock = WALL_JUMP_LOCK
	player.velocity = _wall_normal * 6.5
	player.velocity.y = jump_velocity(player.profile.jump_height * 0.9)
	carried_speed = maxf(carried_speed, 6.5)
	# Po odrazu od zdi je dvojskok znovu k dispozici.
	player.jumps_used = 1
	player.jump_buffer_timer = 0.0
	player.visual.face_direction(_wall_normal)


func _ground_jump() -> void:
	AudioManager.play(&"jump")
	player.velocity.y = jump_velocity(player.profile.jump_height)
	player.jumps_used = 1
	player.coyote_timer = 0.0
	player.jump_buffer_timer = 0.0


func _double_jump() -> void:
	AudioManager.play(&"double_jump")
	_bounce_rise = false
	player.velocity.y = jump_velocity(player.profile.double_jump_height)
	# Po pádu z hrany bez skoku je dvojskok poslední možný skok.
	player.jumps_used = MAX_JUMPS
	player.jump_buffer_timer = 0.0
	if _from_sprint:
		player.visual.set_posture(PlayerVisual.Posture.STAND)
		_from_sprint = false
