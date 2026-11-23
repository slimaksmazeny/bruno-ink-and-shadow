extends SceneTree
var p: Node
var f: int = 0
var r: Dictionary = {}
var max_y: float = -100.0
var max_vy: float = 0.0
var z_dev: float = 0.0
func _initialize() -> void:
	change_scene_to_file("res://levels/greybox/greybox_street.tscn")
func face(target: Vector3) -> void:
	var d: Vector3 = target - p.global_position
	p.camera.rig_3d.yaw = atan2(-d.x, -d.z)
func _physics_process(_d: float) -> bool:
	if p == null:
		if current_scene != null: p = current_scene.get_node_or_null("Player")
		return false
	f += 1
	var ink = root.get_node("/root/InkWipe")
	if p.mode == 1:
		z_dev = maxf(z_dev, absf(p.global_position.z))
	match f:
		5:
			# open the gate via the bell event, stand in front of the painting
			root.get_node("/root/Events").bell_hit.emit(&"bell_main")
			p.global_position = Vector3(24, 0.02, 1.5)
			p.velocity = Vector3.ZERO
		90:
			r["gate_open"] = current_scene.get_node("PaintingGate").is_open
			face(Vector3(24, 0, -6))
			Input.action_press("move_forward")
		190:
			r["during_dive"] = "%s blend=%.2f" % [p.state_machine.current_name(), p.camera.blend]
		230:
			r["dive_end"] = "%s blend=%.2f" % [p.state_machine.current_name(), p.camera.blend]
			Input.action_release("move_forward")
		340:
			r["in_2d"] = "mode=%d state=%s pos=%s" % [p.mode, p.state_machine.current_name(), str(p.global_position.snapped(Vector3(0.1,0.1,0.1)))]
			r["cam_2d"] = "blend=%.2f target=%s fov=%.0f ink=%.2f" % [p.camera.blend, p.camera.blend_target.name, p.camera.cam.fov, ink._get_progress()]
			# try to escape the plane (forward) – must stay at z=0
			Input.action_press("move_forward")
		360:
			Input.action_release("move_forward")
			# drop Bruno onto mushroom 1 and hold right
			p.global_position = Vector3(210.6, 3.0, 0)
			p.velocity = Vector3.ZERO
			Input.action_press("move_right")
	if f > 360 and f < 500:
		max_vy = maxf(max_vy, p.velocity.y)
		max_y = maxf(max_y, p.global_position.y)
		if max_vy > 15.0 and p.velocity.y < 2.0 and not has_meta("dj"):
			set_meta("dj", f)
			Input.action_press("jump")
		if has_meta("dj") and f == int(get_meta("dj")) + 6:
			Input.action_release("jump")
	match f:
		500:
			r["mushroom"] = "max_vy=%.1f max_y=%.2f" % [max_vy, max_y]
			r["on_high_ledge"] = "x=%.1f y=%.2f floor=%s" % [p.global_position.x, p.global_position.y, p.is_on_floor()]
			r["plane_z_deviation"] = "%.4f" % z_dev
			Input.action_release("move_right")
			# fall into the pit between ledge and floor3
			p.global_position = Vector3(224.5, 1.0, 0)
			p.velocity = Vector3.ZERO
		600:
			r["pit_respawn"] = "mode=%d pos=%s" % [p.mode, str(p.global_position.snapped(Vector3(0.1,0.1,0.1)))]
			# go to exit portal
			p.global_position = Vector3(243.5, 5.05, 0)
			p.velocity = Vector3.ZERO
			Input.action_press("move_right")
		620:
			Input.action_release("move_right")
		780:
			r["back_3d"] = "mode=%d state=%s pos=%s" % [p.mode, p.state_machine.current_name(), str(p.global_position.snapped(Vector3(0.1,0.1,0.1)))]
			r["cam_back"] = "blend=%.2f ink=%.2f" % [p.camera.blend, ink._get_progress()]
			for k in r: print(k, ": ", r[k])
			quit()
	return false
