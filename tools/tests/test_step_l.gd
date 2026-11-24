## v0.2.5: plazení pod nízkými překážkami (3D i 2D), druhý strážný.
## godot --headless --path game --script ../tools/tests/test_step_l.gd
extends SceneTree

var p
var f: int = 0
var fails: int = 0
var started: bool = false
var saw_crawl: bool = false


func _initialize() -> void:
	change_scene_to_file("res://levels/greybox/greybox_street.tscn")


func check(name: String, ok: bool, info: String = "") -> void:
	print(("PASS " if ok else "FAIL ") + name + ("  " + info if info != "" else ""))
	if not ok:
		fails += 1


func st() -> String:
	return String(p.state_machine.current.name)


func _physics_process(_d: float) -> bool:
	if not started:
		if current_scene == null or current_scene.get_node_or_null("Player") == null:
			return false
		p = current_scene.get_node("Player")
		started = true
	f += 1
	if st() == "Crawl":
		saw_crawl = true
	match f:
		5:
			check("roof_guard_exists", current_scene.get_node_or_null("Guards2/GuardRoof") != null)
			p.global_position = Vector3(1.5, 0.05, 11)
			p.camera.rig_3d.snap_behind(Vector3.RIGHT)
			Input.action_press(&"move_forward")
		30:
			check("no_auto_crawl_without_sneak", not saw_crawl and p.global_position.x < 3.3, "%s x=%.2f" % [st(), p.global_position.x])
			p.sneak_toggled = true
		100:
			check("crawl_3d_entered", saw_crawl, st())
			check("crawl_low_collision", st() != "Crawl" or p.get_node("CollisionStand").disabled)
		200:
			Input.action_release(&"move_forward")
			p.sneak_toggled = false
			check("crawl_3d_through", p.global_position.x > 7.2 and st() != "Crawl", "%s %s" % [st(), p.global_position])
			check("stand_collision_back", not p.get_node("CollisionStand").disabled)
			saw_crawl = false
			p.enter_2d(Vector3(204, 0, 0), Vector3.BACK)
			p.camera.side_rig.target = p
			p.camera.side_rig.snap()
			p.global_position = Vector3(205.0, 0.05, 0)
			p.velocity = Vector3.ZERO
			p.sneak_toggled = true
			Input.action_press(&"move_right")
		320:
			Input.action_release(&"move_right")
			check("crawl_2d_through", saw_crawl and p.global_position.x > 208.6, "%s %s" % [st(), p.global_position])
			print("RESULT: %d fails" % fails)
			quit(1 if fails > 0 else 0)
	return false
