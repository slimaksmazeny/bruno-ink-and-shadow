## Houpání na kruhu (stealth hry hák holí / 2D plošinovky kruh). Kyvadlo kolem kruhu.
## Pohyb vpřed/vzad (ve 2D doleva/doprava) rozhoupává, skok = vyhoupnutí s rychlostí
## kyvadla (dvojskok zůstává), akce = pustit se.
extends AnchorState

const MIN_LEN: float = 2.0
const MAX_LEN: float = 3.6
const HAND_HEIGHT: float = 1.0
const PUSH: float = 12.0
const DAMPING: float = 0.25
const RELEASE_BOOST: float = 5.0
## Vyhoupnutí přidá rychlost ve směru, kam hráč tlačí (a zesílí rozhoupání).
const RELEASE_FORWARD: float = 3.0
const RELEASE_MULT: float = 1.25

var _pivot: Vector3
var _len: float = 3.0
var _vel: Vector3
var _hand: Vector3
var _rope: MeshInstance3D


func enter(previous: StringName, msg: Dictionary = {}) -> void:
	super.enter(previous, msg)
	if anchor == null:
		return
	_pivot = anchor.global_position
	_hand = player.global_position + Vector3.UP * HAND_HEIGHT
	var to: Vector3 = _hand - _pivot
	_len = clampf(to.length(), MIN_LEN, MAX_LEN)
	if to.length() < 0.1:
		to = Vector3.DOWN
	_hand = _pivot + to.normalized() * _len
	# Zachovat rychlost, jen bez složky ve směru lana.
	_vel = player.velocity
	_vel -= to.normalized() * _vel.dot(to.normalized())
	player.velocity = Vector3.ZERO
	_make_rope()
	AudioManager.play(&"shoot", -6.0, 0.7)


func exit() -> void:
	if _rope != null:
		_rope.queue_free()
		_rope = null
	super.exit()


func physics_update(delta: float) -> void:
	if anchor == null or not is_instance_valid(anchor):
		drop_off()
		return
	# Rozhoupávání ve směru pohybu (ve 2D jen v rovině).
	var push: Vector3 = player.get_move_dir()
	push.y = 0.0
	_vel += Vector3.DOWN * player.profile.gravity * delta
	_vel += push * PUSH * delta
	_vel *= 1.0 - DAMPING * delta
	var next: Vector3 = _hand + _vel * delta
	if player.mode == Player.Mode.MODE_2D:
		next -= player.plane_normal * (next - player.plane_origin).dot(player.plane_normal)
	var dir: Vector3 = (next - _pivot).normalized()
	# Nepřehoupnout se přes kruh (max ~100° od svislice).
	if dir.y > 0.15:
		dir = Vector3(dir.x, 0.15, dir.z).normalized()
	next = _pivot + dir * _len
	_vel = (next - _hand) / delta
	_vel -= dir * _vel.dot(dir)
	_hand = next
	player.global_position = _hand - Vector3.UP * HAND_HEIGHT
	player.velocity = Vector3.ZERO
	var flat := Vector3(_vel.x, 0.0, _vel.z)
	if flat.length() > 0.5:
		player.visual.face_direction(flat)
	_update_rope()

	if player.consume_jump_buffer():
		_release(true)
		return
	if Input.is_action_just_pressed(&"action"):
		_release(false)


func _release(jump: bool) -> void:
	var v: Vector3 = _vel
	if jump:
		v.x *= RELEASE_MULT
		v.z *= RELEASE_MULT
		var push: Vector3 = player.get_move_dir()
		push.y = 0.0
		v += push * RELEASE_FORWARD
		v.y = maxf(v.y, 0.0) + RELEASE_BOOST
		AudioManager.play(&"jump", 0.0, 1.1)
	player.jumps_used = 1
	machine.transition_to(&"Air", {})
	player.velocity = v
	var air: AirborneState = machine.current as AirborneState
	if air != null:
		air.carried_speed = maxf(Vector2(v.x, v.z).length(), player.profile.walk_speed)


func _make_rope() -> void:
	_rope = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.025
	cyl.bottom_radius = 0.025
	cyl.height = 1.0
	_rope.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.25, 0.15)
	_rope.material_override = mat
	player.get_parent().add_child(_rope)
	_update_rope()


func _update_rope() -> void:
	if _rope == null:
		return
	var a: Vector3 = _hand
	var b: Vector3 = _pivot
	var mid: Vector3 = (a + b) * 0.5
	var up: Vector3 = (b - a).normalized()
	var basis := Basis(Quaternion(Vector3.UP, up)) if up.length() > 0.5 else Basis()
	_rope.global_transform = Transform3D(basis.scaled(Vector3(1, a.distance_to(b), 1)), mid)
