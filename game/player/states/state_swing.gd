## Švih holí a odpal neonového tenisáku ve směru zaměřovače (střed obrazovky).
extends GroundedState

const BALL_SCENE: PackedScene = preload("res://world/props/tennis_ball.tscn")
const WINDUP: float = 0.12
const RECOVER: float = 0.22
const BALL_SPEED: float = 28.0
const AIM_RANGE: float = 80.0
const MAX_BALLS: int = 3

var _t: float = 0.0
var _hit_done: bool = false
var _aim_dir: Vector3 = Vector3.FORWARD


func enter(previous: StringName, msg: Dictionary = {}) -> void:
	super.enter(previous, msg)
	_t = 0.0
	_hit_done = false
	_aim_dir = _compute_aim_dir()
	player.is_sneaking = false
	player.visual.set_posture(PlayerVisual.Posture.STAND)
	player.visual.face_direction(Vector3(_aim_dir.x, 0.0, _aim_dir.z))
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
		_launch_ball()
	if _t >= WINDUP + RECOVER:
		machine.transition_to(pick_ground_state(player))


## Směr od hole k bodu, na který míří střed kamery (raycast), aby zaměřovač seděl.
func _compute_aim_dir() -> Vector3:
	var cam: Camera3D = player.camera.cam if player.camera != null else null
	var spawn: Vector3 = player.visual.get_ball_spawn()
	if cam == null:
		return player.visual.get_forward()
	var from: Vector3 = cam.global_position
	var forward: Vector3 = -cam.global_transform.basis.z
	var to: Vector3 = from + forward * AIM_RANGE
	var query := PhysicsRayQueryParameters3D.create(from, to, 1 | 16)
	query.exclude = [player.get_rid()]
	var hit: Dictionary = player.get_world_3d().direct_space_state.intersect_ray(query)
	var target: Vector3 = hit["position"] if not hit.is_empty() else to
	var dir: Vector3 = (target - spawn)
	if dir.length() < 0.5:
		return forward
	return dir.normalized()


func _launch_ball() -> void:
	var balls: Array[Node] = player.get_tree().get_nodes_in_group(&"tennis_ball")
	if balls.size() >= MAX_BALLS:
		balls[0].queue_free()
	var ball: TennisBall = BALL_SCENE.instantiate() as TennisBall
	player.get_parent().add_child(ball)
	ball.global_position = player.visual.get_ball_spawn()
	ball.launch(_aim_dir * BALL_SPEED)
