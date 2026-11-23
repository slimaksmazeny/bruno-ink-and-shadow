extends SceneTree
var p: Node
var f: int = 0
var r: Dictionary = {}
func _initialize() -> void:
	change_scene_to_file("res://levels/greybox/greybox_street.tscn")
func put(x: float, y: float) -> void:
	p.global_position = Vector3(x, y, 0)
	p.velocity = Vector3.ZERO
	p.visual.face_direction(Vector3.RIGHT)
func _physics_process(_d: float) -> bool:
	if p == null:
		if current_scene != null: p = current_scene.get_node_or_null("Player")
		return false
	f += 1
	var rig = p.camera.side_rig
	match f:
		3:
			put(203, 0.05)
			p.enter_2d(Vector3(203, 0, 0), Vector3.BACK)
			rig.target = p; rig.snap()
			p.camera.set_blend_target(rig, p.camera.fov_2d); p.camera.blend = 1.0
		90:
			r["flat_floor"] = "drop=%.1f cam_y=%.2f dist=%.1f" % [rig.last_drop, rig.global_position.y, rig.global_position.z]
			put(220.8, 4.55)   # right edge of the high ledge, pit ahead
		200:
			r["ledge_edge_pit"] = "drop=%.1f cam_y=%.2f dist=%.1f player_y=%.1f" % [rig.last_drop, rig.global_position.y, rig.global_position.z, p.global_position.y]
			put(216.0, 4.55)   # middle of ledge
		320:
			r["ledge_middle"] = "drop=%.1f cam_y=%.2f dist=%.1f" % [rig.last_drop, rig.global_position.y, rig.global_position.z]
			for k in r: print(k, ": ", r[k])
			quit()
	return false
