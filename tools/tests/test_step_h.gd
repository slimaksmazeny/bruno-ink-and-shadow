## 2D kit (průchozí, rozpadající se, pohyblivá plošina) + „Pokračovat“ na 2D checkpointu.
## godot --headless --path game --script ../tools/tests/test_step_h.gd
## Pozn.: netypované proměnné – v režimu --script ještě nejsou známé autoloady.
extends SceneTree

var p
var f: int = 0
var fails: int = 0
var max_y: float = -99.0
var stage: int = 0


func _initialize() -> void:
	change_scene_to_file("res://levels/greybox/greybox_street.tscn")


func al(n: String) -> Node:
	return get_root().get_node(n)


func check(name: String, ok: bool, info: String = "") -> void:
	print(("PASS " if ok else "FAIL ") + name + ("  " + info if info != "" else ""))
	if not ok:
		fails += 1


func put(pos: Vector3) -> void:
	p.global_position = pos
	p.velocity = Vector3.ZERO
	p.reset_physics_interpolation()


func press(action: StringName, on: bool) -> void:
	if on:
		Input.action_press(action)
	else:
		Input.action_release(action)


func _physics_process(_d: float) -> bool:
	if stage == 0:
		if current_scene == null or current_scene.get_node_or_null("Player") == null:
			return false
		p = current_scene.get_node("Player")
		stage = 1
		f = 0
	f += 1
	if stage == 1:
		match f:
			3:
				p.enter_2d(Vector3(199, 0, 0), Vector3.BACK)
				var rig = p.camera.side_rig
				rig.target = p
				rig.snap()
				put(Vector3(200.5, 0.05, 0))
			10:
				press(&"jump", true)
			25:
				press(&"jump", false)
			26:
				press(&"jump", true)
			40:
				press(&"jump", false)
			90:
				check("oneway_jump_through_and_stand", p.is_on_floor() and p.global_position.y > 2.2, "y=%.2f" % p.global_position.y)
				press(&"move_back", true)
				press(&"jump", true)
			92:
				press(&"jump", false)
			93:
				press(&"move_back", false)
			140:
				check("oneway_drop_down", p.global_position.y < 0.5, "y=%.2f" % p.global_position.y)
				put(Vector3(223.3, 3.5, 0))
			200:
				check("crumble_fell_through", p.global_position.y < 2.5, "y=%.2f" % p.global_position.y)
				var lift = current_scene.get_node("Platforms2D/Lift1")
				put(Vector3(233.5, lift.top_y() + 0.05, 0))
				max_y = p.global_position.y
			400:
				check("lift_carries_up", p.global_position.y > 3.0 or max_y > 3.0, "y=%.2f" % p.global_position.y)
				al("GameState").set("resume_checkpoint", "cp_painting_floor3")
				stage = 2
				f = 0
				reload_current_scene()
		if f > 200:
			max_y = maxf(max_y, p.global_position.y)
	elif stage == 2:
		if f == 30:
			p = current_scene.get_node("Player")
			check("continue_restores_2d_checkpoint", p.mode == 1 and absf(p.global_position.x - 229.5) < 0.6, "mode=%d pos=%s" % [p.mode, p.global_position])
			check("continue_camera_2d", p.camera.blend > 0.99)
			print("RESULT: %d fails" % fails)
			quit(1 if fails > 0 else 0)
	return false
