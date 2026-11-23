## Útok holí ve stylu Sly Cooper: až 3 švihy za sebou (kombo), krátký výpad dopředu,
## automatické natočení na nejbližší cíl před Brunem. Třetí švih = otočka s větším odhozením.
## msg {"combo": 1..3}
extends GroundedState

const MAX_COMBO: int = 3
## [nápřah, konec aktivní fáze, celková délka, rychlost výpadu, poškození, odhození]
const STEPS: Array = [
	[0.05, 0.15, 0.26, 4.5, 1, 4.0],
	[0.05, 0.15, 0.26, 4.5, 1, 4.0],
	[0.08, 0.22, 0.40, 6.5, 2, 9.0],
]
## Další švih jde „nabufferovat“ skoro hned (i během zastavení času po zásahu).
const COMBO_WINDOW_START: float = 0.02
const AUTO_TARGET_RANGE: float = 3.5
const AUTO_TARGET_ANGLE_DEG: float = 70.0

var combo: int = 1
var _t: float = 0.0
var _queued: bool = false
var _dir: Vector3 = Vector3.FORWARD
var _active: bool = false


func enter(previous: StringName, msg: Dictionary = {}) -> void:
	super.enter(previous, msg)
	combo = clampi(int(msg.get("combo", 1)), 1, MAX_COMBO)
	_t = 0.0
	_queued = false
	_active = false
	player.is_sneaking = false
	player.visual.set_posture(PlayerVisual.Posture.STAND)
	_dir = _pick_direction()
	player.visual.face_direction(_dir)
	player.visual.play_attack(combo, _step()[2])
	# Výpad dopředu
	var lunge: float = _step()[3]
	player.velocity.x = _dir.x * lunge
	player.velocity.z = _dir.z * lunge


func exit() -> void:
	player.cane_hitbox.end_swing()


func physics_update(delta: float) -> void:
	if not player.is_on_floor():
		machine.transition_to(&"Air", {})
		return
	var s: Array = _step()
	_t += delta

	# Aktivní snímky – hůl zasahuje
	if not _active and _t >= s[0] and _t < s[1]:
		_active = true
		player.cane_hitbox.begin_swing({"damage": s[4], "knockback": s[5], "combo": combo, "dir": _dir, "from": player.global_position})
	elif _active and _t >= s[1]:
		_active = false
		player.cane_hitbox.end_swing()

	# Výpad postupně dobrzdí
	accelerate_horizontal(Vector3.ZERO, player.profile.ground_decel * 0.6, delta)
	stick_to_floor()

	if Input.is_action_just_pressed(&"attack") and _t >= COMBO_WINDOW_START:
		_queued = true
	# Po aktivní fázi jde útok zrušit skokem (jako ve Slyovi)
	if _t >= s[1] and player.consume_jump_buffer():
		machine.transition_to(&"Air", {"jump": true})
		return

	if _t >= s[2]:
		if _queued and combo < MAX_COMBO:
			machine.transition_to(&"Attack", {"combo": combo + 1, "force": true})
		else:
			machine.transition_to(pick_ground_state(player))


func _step() -> Array:
	return STEPS[combo - 1]


## Směr útoku: nejbližší cíl ve výseči před Brunem, jinak směr páčky, jinak směr kamery.
func _pick_direction() -> Vector3:
	var move: Vector3 = player.get_move_dir()
	var base: Vector3
	if move.length() > 0.3:
		base = move.normalized()
	elif player.camera != null and player.mode == Player.Mode.MODE_3D:
		base = Basis(Vector3.UP, player.camera.get_control_yaw()) * Vector3.FORWARD
	else:
		base = player.visual.get_forward()
	var best: Node3D = null
	var best_d: float = INF
	for n: Node in player.get_tree().get_nodes_in_group(&"hittable"):
		var t: Node3D = n as Node3D
		if t == null:
			continue
		var to: Vector3 = t.global_position - player.global_position
		to.y = 0.0
		var d: float = to.length()
		if d > AUTO_TARGET_RANGE or d < 0.05:
			continue
		if rad_to_deg(to.normalized().angle_to(base)) > AUTO_TARGET_ANGLE_DEG:
			continue
		if d < best_d:
			best_d = d
			best = t
	if best != null:
		var to_best: Vector3 = best.global_position - player.global_position
		to_best.y = 0.0
		return to_best.normalized()
	return base
