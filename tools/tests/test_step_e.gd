extends SceneTree
var p: Node
var f: int = 0
var r: Dictionary = {}
var bell: Node
var gate: Node
var gate_y0: float
func _initialize() -> void:
	change_scene_to_file("res://levels/greybox/greybox_street.tscn")
func aim_at(target: Vector3) -> void:
	var cam: Camera3D = p.camera.cam
	var d: Vector3 = (target - cam.global_position).normalized()
	p.camera.rig_3d.yaw = atan2(-d.x, -d.z)
	p.camera.rig_3d.pitch = clampf(asin(d.y), deg_to_rad(-65), deg_to_rad(30))
func _physics_process(_d: float) -> bool:
	if p == null:
		if current_scene != null:
			p = current_scene.get_node_or_null("Player")
			bell = current_scene.get_node_or_null("TargetBell")
			gate = current_scene.get_node_or_null("PaintingGate")
		return false
	f += 1
	var bell_pos: Vector3 = bell.global_position + Vector3(0, 1.1, 0)
	var bl = get_nodes_in_group("tennis_ball")
	if f > 30 and f < 100 and bl.size() > 0 and f % 4 == 0:
		print(f, " ball=", bl[0].global_position.snapped(Vector3(0.01,0.01,0.01)), " d=%.2f" % bl[0].global_position.distance_to(bell_pos))
	if f == 29:
		print("cam=", p.camera.cam.global_position, " bellpos=", bell_pos, " spawn=", p.visual.get_ball_spawn())
	match f:
		5:
			gate_y0 = gate.position.y
			p.global_position = Vector3(26, 0.1, 9)
			p.velocity = Vector3.ZERO
		10, 15, 20, 25:
			aim_at(bell_pos + Vector3(0, 0.6, 0))
		30:
			Input.action_press("tennis")
		31:
			Input.action_release("tennis")
		33:
			r["swing_state"] = String(p.state_machine.current_name())
		45:
			var balls = get_nodes_in_group("tennis_ball")
			r["ball_spawned"] = balls.size()
			if balls.size() > 0:
				r["ball_speed"] = "%.1f" % balls[0].linear_velocity.length()
		60:
			r["after_swing_state"] = String(p.state_machine.current_name())
		110:
			r["bell_rung"] = bell.rung
			r["gate_moving"] = "%.2f" % (gate.position.y - gate_y0)
		200:
			r["gate_open_y"] = "%.2f" % (gate.position.y - gate_y0)
			# wall test: shoot at house from close range, ball must not pass through
			p.global_position = Vector3(0, 0.1, -5.5)
			p.velocity = Vector3.ZERO
		205, 210:
			aim_at(Vector3(0, 1.5, -9))
		215:
			Input.action_press("tennis")
		216:
			Input.action_release("tennis")
		260:
			var balls2 = get_nodes_in_group("tennis_ball")
			var behind := 0
			for b in balls2:
				if b.global_position.z < -8.2 and absf(b.global_position.x) < 5.0: behind += 1
			r["balls_through_wall"] = behind
			for k in r: print(k, ": ", r[k])
			quit()
	return false
