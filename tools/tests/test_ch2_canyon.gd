## Kapitola 2 Kaňon: načtení, kapitola „canyon“, lano přes řeku, celá loupež, rekord pod „canyon“.
## godot --headless --path game --script ../tools/tests/test_ch2_canyon.gd
extends SceneTree

var p
var m
var f: int = 0
var fails: int = 0
var started: bool = false


func _initialize() -> void:
	change_scene_to_file("res://levels/ch2_canyon/canyon.tscn")


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
		m = current_scene.get_node("Mission")
		started = true
	f += 1
	var gs = get_root().get_node("GameState")
	match f:
		60:
			check("player_on_floor", p.is_on_floor() and absf(p.global_position.y) < 0.2, str(p.global_position))
			check("camera_linked", p.camera != null and p.camera.target == p)
			check("chapter_canyon", m.chapter_id == "canyon")
			check("drops_26", get_nodes_in_group(&"ink_drop").size() == 26, str(get_nodes_in_group(&"ink_drop").size()))
			check("guards_3", get_nodes_in_group(&"guard").size() == 3)
			# Kapka se uloží pod kapitolu canyon.
			put(Vector3(5, 0.05, 0), Vector3.RIGHT)
		70:
			check("drop_saved_under_canyon", gs.is_collected("canyon", "ink", "cn_ink_00") and not gs.is_collected("greybox", "ink", "cn_ink_00"))
			# Lano přes řeku.
			put(Vector3(31.0, 0.05, 7), Vector3.RIGHT)
		75:
			tap(&"action")
		85:
			check("river_rope_grab", String(p.state_machine.current.name) == "RopeWalk", String(p.state_machine.current.name))
			Input.action_press(&"move_forward")
		250:
			Input.action_release(&"move_forward")
			check("river_crossed", p.global_position.x > 40.0 and p.global_position.y > -0.5, str(p.global_position))
			# Loupež: klíč od strážného u řeky.
			var g = current_scene.get_node("Content/GuardRiver")
			g.set("patrol_points", PackedVector3Array())
			g.global_position = Vector3(20, 0.05, 0)
			g.rotation.y = 0.0
			p.sneak_toggled = true
			p.global_position = Vector3(20, 0.05, 1.2)
		255:
			p.state_machine.current._try_pickpocket()
			check("key_from_river_guard", gs.has_key("mine_key") and m.step == 1, "step=%d" % m.step)
			p.sneak_toggled = false
			p.global_position = Vector3(77.6, 0.05, 0)
		262:
			p.state_machine.current._try_interact()
		268:
			p.state_machine.current._try_interact()
		274:
			check("vault_and_treasure", m.step == 3, "step=%d" % m.step)
			p.global_position = Vector3(4, 0.05, 10.6)
		280:
			p.state_machine.current._try_interact()
		286:
			check("heist_done", m.step == 4 and paused)
			check("record_under_canyon", gs.best_time("canyon") > 0.0)
			for c in get_root().get_children():
				if c is CanvasLayer and c.get("mission") != null:
					c._close()
			print("RESULT: %d fails" % fails)
			quit(1 if fails > 0 else 0)
	return false
