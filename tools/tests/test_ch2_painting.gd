## Kaňon: vstup do pouštního obrazu (2D), vítr, výstup zpět do 3D.
## godot --headless --path game --script ../tools/tests/test_ch2_painting.gd
extends SceneTree

var p
var f: int = 0
var fails: int = 0
var started: bool = false
var max_y: float = -99.0


func _initialize() -> void:
	change_scene_to_file("res://levels/ch2_canyon/canyon.tscn")


func check(name: String, ok: bool, info: String = "") -> void:
	print(("PASS " if ok else "FAIL ") + name + ("  " + info if info != "" else ""))
	if not ok:
		fails += 1


func _physics_process(_d: float) -> bool:
	if not started:
		if current_scene == null or current_scene.get_node_or_null("Player") == null:
			return false
		p = current_scene.get_node("Player")
		started = true
	f += 1
	match f:
		20:
			p.global_position = Vector3(46, 0.05, -9.5)
			p.camera.rig_3d.snap_behind(Vector3.FORWARD)
			Input.action_press(&"move_forward")
		60:
			Input.action_release(&"move_forward")
		200:
			check("entered_painting_2d", p.mode == 1 and absf(p.global_position.x - 299) < 3.0, "mode=%d pos=%s" % [p.mode, p.global_position])
			# Vítr nad propastí: plachtění vynese nahoru.
			p.global_position = Vector3(315, 2.0, 0)
			p.velocity = Vector3(0, 5, 0)
			p.jumps_used = 2
			p.state_machine.transition_to(&"Air", {"force": true})
			Input.action_press(&"jump")
		320:
			Input.action_release(&"jump")
			check("painting_wind_lifts", max_y > 9.0, "max_y=%.1f" % max_y)
			p.global_position = Vector3(360.5, 0.05, 0)
			p.velocity = Vector3.ZERO
			p.state_machine.transition_to(&"Idle", {"force": true})
			Input.action_press(&"move_right")
		345:
			Input.action_release(&"move_right")
		520:
			check("back_to_3d_canyon", p.mode == 0 and p.global_position.distance_to(Vector3(46, 0, -8.3)) < 3.0, "mode=%d pos=%s" % [p.mode, p.global_position])
			print("RESULT: %d fails" % fails)
			quit(1 if fails > 0 else 0)
	if f > 200 and f < 320:
		max_y = maxf(max_y, p.global_position.y)
	return false
