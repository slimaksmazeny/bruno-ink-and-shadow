## v0.2.4: kruh (2D i 3D), klouzání a odraz od zdi (2D), píst, úzká římsa, hudba, přesunutý portál.
## godot --headless --path game --script ../tools/tests/test_step_j.gd
## Pozn.: netypované proměnné – v režimu --script ještě nejsou známé autoloady.
extends SceneTree

var p
var f: int = 0
var fails: int = 0
var started: bool = false
var mark: Vector3
var max_y: float = -99.0
var max_slide_fall: float = 0.0
## Pustit kruh při švihu dopředu (jako hráč): čeká na rychlost a polohu před kruhem.
var release_when_x: float = INF


func _initialize() -> void:
	change_scene_to_file("res://levels/greybox/greybox_street.tscn")


func check(name: String, ok: bool, info: String = "") -> void:
	print(("PASS " if ok else "FAIL ") + name + ("  " + info if info != "" else ""))
	if not ok:
		fails += 1


func st() -> String:
	return String(p.state_machine.current.name)


func put(pos: Vector3, vel: Vector3, state: StringName) -> void:
	p.global_position = pos
	p.velocity = vel
	p.reset_physics_interpolation()
	p.state_machine.transition_to(state, {"force": true})
	p.velocity = vel


func go_2d() -> void:
	p.enter_2d(Vector3(250, 0, 0), Vector3.BACK)
	p.camera.side_rig.target = p
	p.camera.side_rig.snap()


func tap(action: StringName) -> void:
	Input.action_press(action)
	await physics_frame
	await physics_frame
	Input.action_release(action)


func _physics_process(_d: float) -> bool:
	if not started:
		if current_scene == null or current_scene.get_node_or_null("Player") == null:
			return false
		p = current_scene.get_node("Player")
		started = true
	f += 1
	match f:
		5:
			var am = get_root().get_node("AudioManager")
			check("music_playing", am._music.playing and am._music_name == &"sneak_loop")
			var ep = current_scene.get_node("PaintingWorld/ExitPortal")
			check("exit_portal_moved", ep.global_position.distance_to(Vector3(287, 15, 0)) < 0.1, str(ep.global_position))
			# 2D kruh: ve vzduchu u kruhu.
			go_2d()
			put(Vector3(251.0, 6.8, 0), Vector3(4, 1, 0), &"Air")
			p.jumps_used = 2
		7:
			tap(&"action")
		12:
			check("ring2d_grab", st() == "HookSwing", st())
			Input.action_press(&"move_right")
		60:
			release_when_x = 252.8 + 0.6
		200:
			Input.action_release(&"move_right")
			check("ring2d_swing_to_floor4", p.global_position.x > 256.0 and p.global_position.y > 4.5 and p.global_position.y < 9.0, "%s %s" % [st(), p.global_position])
			# Klouzání po levé stěně šachty (pravá strana stěny x=265).
			put(Vector3(265.45, 11.0, 0), Vector3(-2, 0, 0), &"Air")
			p.jumps_used = 2
			Input.action_press(&"move_left")
		215, 230, 245:
			max_slide_fall = minf(max_slide_fall, p.velocity.y)
		250:
			check("wall_slide_slows_fall", max_slide_fall >= -3.2 and p.is_on_wall(), "vy_min=%.2f on_wall=%s" % [max_slide_fall, p.is_on_wall()])
			Input.action_release(&"move_left")
			tap(&"jump")
		255:
			check("wall_jump_pushes_away", p.velocity.x > 3.0 and p.velocity.y > 3.0, "v=%s" % p.velocity)
			# Píst: postavit na Piston1.
			var pis = current_scene.get_node("Track2D/Piston1")
			put(Vector3(276.0, pis.top_y() + 0.05, 0), Vector3.ZERO, &"Idle")
			max_y = p.global_position.y
		440:
			check("piston_lifts", max_y > 13.5, "max_y=%.2f" % max_y)
			# 3D kruh nad propastí v ulici.
			p.enter_3d()
			p.camera.rig_3d.snap_behind(Vector3.RIGHT)
			put(Vector3(14.6, 3.2, 6), Vector3(3, 0.5, 0), &"Air")
			p.jumps_used = 2
		443:
			tap(&"action")
		448:
			check("ring3d_grab", st() == "HookSwing", st())
			Input.action_press(&"move_forward")
		490:
			release_when_x = 15.75 + 0.6
		600:
			Input.action_release(&"move_forward")
			check("ring3d_cross_gap", p.global_position.x > 17.6 and p.global_position.y > -0.5, "%s %s" % [st(), p.global_position])
			# Úzká římsa na prostředním domě.
			p.camera.rig_3d.snap_behind(Vector3.FORWARD)
			put(Vector3(-2.5, 2.4, -7.3), Vector3.ZERO, &"Air")
			p.jumps_used = 2
		603:
			tap(&"action")
		608:
			check("wall_sneak_grab", st() == "WallSneak", "%s %s" % [st(), p.global_position])
			mark = p.global_position
			Input.action_press(&"move_right")
		668:
			Input.action_release(&"move_right")
			check("wall_sneak_moves", p.global_position.x > mark.x + 1.2 and st() == "WallSneak" and absf(p.global_position.y - 3.05) < 0.1, "%s %s" % [st(), p.global_position])
			print("RESULT: %d fails" % fails)
			quit(1 if fails > 0 else 0)
	if release_when_x < INF and st() == "HookSwing" and p.state_machine.current._vel.x > 2.0 and p.global_position.x > release_when_x:
		release_when_x = INF
		tap(&"jump")
	if f > 255 and f < 440:
		max_y = maxf(max_y, p.global_position.y)
	return false
