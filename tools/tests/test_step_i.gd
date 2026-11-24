## v0.2.3 Sly parkour (trubka, lano, římsa) + stoupavý vítr + zlaté kapky.
## godot --headless --path game --script ../tools/tests/test_step_i.gd
## Pozn.: netypované proměnné – v režimu --script ještě nejsou známé autoloady.
extends SceneTree

var p
var f: int = 0
var fails: int = 0
var started: bool = false
var mark: Vector3
var max_y: float = -99.0


func _initialize() -> void:
	change_scene_to_file("res://levels/greybox/greybox_street.tscn")


func check(name: String, ok: bool, info: String = "") -> void:
	print(("PASS " if ok else "FAIL ") + name + ("  " + info if info != "" else ""))
	if not ok:
		fails += 1


func put(pos: Vector3, look: Vector3) -> void:
	p.global_position = pos
	p.velocity = Vector3.ZERO
	p.reset_physics_interpolation()
	p.state_machine.transition_to(&"Idle", {"force": true})
	p.camera.rig_3d.snap_behind(look)
	p.visual.face_direction(look)


func tap(action: StringName) -> void:
	Input.action_press(action)
	await process_frame
	await physics_frame
	Input.action_release(action)


func st() -> String:
	return String(p.state_machine.current.name)


func _physics_process(_d: float) -> bool:
	if not started:
		if current_scene == null or current_scene.get_node_or_null("Player") == null:
			return false
		p = current_scene.get_node("Player")
		started = true
	f += 1
	match f:
		5:
			var total: int = 0
			for d in get_nodes_in_group(&"ink_drop"):
				total += d.value()
			check("drop_total_with_golden", get_nodes_in_group(&"ink_drop").size() == 58 and total == 70, "count=%d total=%d" % [get_nodes_in_group(&"ink_drop").size(), total])
			put(Vector3(-11, 0.05, -4.7), Vector3.FORWARD)
		20:
			tap(&"action")
		30:
			check("pipe_grab_climb", st() == "Climb", st())
			Input.action_press(&"move_forward")
		260:
			Input.action_release(&"move_forward")
			check("pipe_climb_over_onto_roof", p.global_position.y > 7.8 and p.global_position.z < -6.2, "%s %s" % [st(), p.global_position])
			var a := Vector3(-9.4, 8.02, -6.4)
			var b := Vector3(-1, 8.02, -1)
			put(Vector3(-9.9, 8.05, -6.9), (b - a).normalized())
		275:
			tap(&"action")
		285:
			check("rope_grab", st() == "RopeWalk", st())
			Input.action_press(&"move_forward")
		460:
			Input.action_release(&"move_forward")
			check("rope_walk_to_pillar", p.global_position.y > 7.8 and p.global_position.distance_to(Vector3(-1, 8, -1)) < 1.4, "%s %s" % [st(), p.global_position])
			put(Vector3(11, 4.55, -3.6), Vector3.FORWARD)
		535:
			tap(&"action")
		545:
			check("ledge_grab", st() == "LedgeHang", "%s %s" % [st(), p.global_position])
			mark = p.global_position
			Input.action_press(&"move_right")
		605:
			Input.action_release(&"move_right")
			check("ledge_shimmy_right", p.global_position.x > mark.x + 1.2 and st() == "LedgeHang", "dx=%.2f" % (p.global_position.x - mark.x))
			tap(&"jump")
		640:
			check("ledge_climb_up", p.global_position.y > 5.9 and p.global_position.z < -6.0, "%s %s" % [st(), p.global_position])
			# 2D vítr.
			p.enter_2d(Vector3(220, 0, 0), Vector3.BACK)
			p.camera.side_rig.target = p
			p.camera.side_rig.snap()
			p.global_position = Vector3(224.5, 1.5, 0)
			p.velocity = Vector3(0, 6, 0)
			p.jumps_used = 2
			p.state_machine.transition_to(&"Air", {"force": true})
			Input.action_press(&"jump")
		650:
			max_y = p.global_position.y
		760:
			Input.action_release(&"jump")
			check("wind_lifts_glide", max_y > 6.5, "max_y=%.2f state=%s" % [max_y, st()])
			print("RESULT: %d fails" % fails)
			quit(1 if fails > 0 else 0)
	if f > 650:
		max_y = maxf(max_y, p.global_position.y)
	return false
