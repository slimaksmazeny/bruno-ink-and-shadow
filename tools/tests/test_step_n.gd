## v0.2.6 Loupež: klíč kapsářstvím → trezor → krystal → dodávka → výsledky.
## godot --headless --path game --script ../tools/tests/test_step_n.gd
extends SceneTree

var p
var g
var m
var hud
var f: int = 0
var fails: int = 0
var started: bool = false


func _initialize() -> void:
	change_scene_to_file("res://levels/greybox/greybox_street.tscn")


func check(name: String, ok: bool, info: String = "") -> void:
	print(("PASS " if ok else "FAIL ") + name + ("  " + info if info != "" else ""))
	if not ok:
		fails += 1


func put(pos: Vector3) -> void:
	p.global_position = pos
	p.velocity = Vector3.ZERO
	p.reset_physics_interpolation()


func _physics_process(_d: float) -> bool:
	if not started:
		if current_scene == null or current_scene.get_node_or_null("Player") == null:
			return false
		p = current_scene.get_node("Player")
		g = current_scene.get_node("Guards/GuardStreetB")
		m = current_scene.get_node("Mission")
		hud = current_scene.get_node("Hud")
		started = true
	f += 1
	var gs = get_root().get_node("GameState")
	match f:
		5:
			check("mission_start", m.step == 0 and hud._objective.visible, hud._objective.text)
			g.set("patrol_points", PackedVector3Array())
			g.global_position = Vector3(29, 0.05, 1.5)
			g.rotation.y = 0.0
			p.sneak_toggled = true
			put(Vector3(29, 0.05, 2.7))
		10:
			p.state_machine.current._try_pickpocket()
			check("key_stolen", gs.has_key("vault_key") and m.step == 1, "step=%d" % m.step)
			p.sneak_toggled = false
			put(Vector3(37.75, 0.05, 7))
		20:
			check("vault_prompt", hud._prompt.visible, hud._prompt.text)
			p.state_machine.current._try_interact()
		30:
			var v = current_scene.get_node("Heist/Vault")
			check("vault_opened", v.is_open and m.step == 2, "step=%d" % m.step)
			p.state_machine.current._try_interact()
		40:
			check("treasure_taken", m.step == 3, "step=%d" % m.step)
			put(Vector3(11.5, 0.05, 11.8))
		50:
			check("van_prompt", hud._prompt.visible, hud._prompt.text)
			p.state_machine.current._try_interact()
		55:
			check("heist_done_results", m.step == 4 and paused and get_root().find_child("*", false, false) != null)
			var rs = null
			for c in get_root().get_children():
				if c is CanvasLayer and c.get("mission") != null:
					rs = c
			check("results_screen_shown", rs != null)
			if rs != null:
				rs._close()
			print("RESULT: %d fails" % fails)
			quit(1 if fails > 0 else 0)
	return false
