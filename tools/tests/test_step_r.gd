## v0.2.9: obrácená osa Y, FOV, citlivost ovladače, rekordy, výběr kapitol.
## godot --headless --path game --script ../tools/tests/test_step_r.gd
extends SceneTree

var f: int = 0
var fails: int = 0
var stage: int = 0


func _initialize() -> void:
	change_scene_to_file("res://levels/greybox/greybox_street.tscn")


func check(name: String, ok: bool, info: String = "") -> void:
	print(("PASS " if ok else "FAIL ") + name + ("  " + info if info != "" else ""))
	if not ok:
		fails += 1


func _physics_process(_d: float) -> bool:
	if current_scene == null:
		return false
	f += 1
	var st = get_root().get_node("Settings")
	var im = get_root().get_node("InputManager")
	var gs = get_root().get_node("GameState")
	if stage == 0 and f == 5:
		st.set_invert_y(true)
		im._mouse_look = Vector2(0, 100)
		var look: Vector2 = im.consume_look(0.016)
		check("invert_y", look.y < 0.0, str(look))
		st.set_invert_y(false)
		st.set_fov(82.0)
		var cam = current_scene.get_node("Player").camera
		check("fov_setting", absf(cam.fov_3d - 82.0) < 0.01, str(cam.fov_3d))
		st.set_fov(70.0)
		st.set_stick_sensitivity(5.0)
		check("pad_sensitivity", absf(im.stick_sensitivity - 5.0) < 0.01)
		st.set_stick_sensitivity(3.0)
		gs.reset()
		check("record_first", gs.record_result("greybox", 120.0))
		check("record_slower_no", not gs.record_result("greybox", 130.0))
		check("record_faster_yes", gs.record_result("greybox", 95.0) and absf(gs.best_time("greybox") - 95.0) < 0.01)
		stage = 1
		change_scene_to_file("res://ui/menus/main_menu.tscn")
		f = 0
	elif stage == 1 and f == 10:
		current_scene._on_chapters()
	elif stage == 1 and f == 14:
		var box = current_scene._chapters_box
		var n: int = box.get_child_count()
		check("chapters_listed", n == 5, "children=%d" % n)
		check("chapter1_playable", not box.get_child(0).disabled and box.get_child(0).text.contains("1:35"), box.get_child(0).text)
		check("chapter2_playable", not box.get_child(1).disabled)
		check("chapter3_playable", not box.get_child(2).disabled)
		print("RESULT: %d fails" % fails)
		quit(1 if fails > 0 else 0)
	return false
