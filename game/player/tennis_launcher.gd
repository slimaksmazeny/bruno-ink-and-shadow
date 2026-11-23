## Sdílená logika odpalu tenisáku (rychlý odpal ve Swing i výstřel při míření v Aim).
## Míří se paprskem ze středu kamery, takže míček letí přesně na zaměřovač „+“.
class_name TennisLauncher
extends RefCounted

const BALL_SCENE: PackedScene = preload("res://world/props/tennis_ball.tscn")
const BALL_SPEED: float = 28.0
const AIM_RANGE: float = 80.0
const MAX_BALLS: int = 3


static func compute_aim_dir(player: Player) -> Vector3:
	var cam: Camera3D = player.camera.cam if player.camera != null else null
	var spawn: Vector3 = player.visual.get_ball_spawn()
	if cam == null or player.mode == Player.Mode.MODE_2D:
		return player.visual.get_forward()
	var from: Vector3 = cam.global_position
	var forward: Vector3 = -cam.global_transform.basis.z
	var to: Vector3 = from + forward * AIM_RANGE
	var query := PhysicsRayQueryParameters3D.create(from, to, 1 | 16)
	query.exclude = [player.get_rid()]
	var hit: Dictionary = player.get_world_3d().direct_space_state.intersect_ray(query)
	var target: Vector3 = hit["position"] if not hit.is_empty() else to
	var dir: Vector3 = target - spawn
	if dir.length() < 0.5:
		return forward
	return dir.normalized()


static func launch(player: Player, dir: Vector3) -> void:
	var balls: Array[Node] = player.get_tree().get_nodes_in_group(&"tennis_ball")
	if balls.size() >= MAX_BALLS:
		balls[0].queue_free()
	var ball: TennisBall = BALL_SCENE.instantiate() as TennisBall
	player.get_parent().add_child(ball)
	ball.global_position = player.visual.get_ball_spawn()
	ball.launch(dir * BALL_SPEED)
