## v0.2.7 lasery: vestoje do vysokého paprsku = poplach a zábrana; plazením projde bez poplachu.
## godot --headless --path game --script ../tools/tests/test_step_o.gd
extends SceneTree

var p
var g
var f: int = 0
var fails: int = 0
var started: bool = false
var alarms: int = 0


func _initialize() -> void:
	change_scene_to_file("res://levels/greybox/greybox_street.tscn")


func check(name: String, ok: bool, info: String = "") -> void:
	print(("PASS " if ok else "FAIL ") + name + ("  " + info if info != "" else ""))
	if not ok:
		fails += 1


func _physics_process(_d: float) -> bool:
	if not started:
		if current_scene == null or current_scene.get_node_or_null("Player") == null:
			return false
		p = current_scene.get_node("Player")
		g = current_scene.get_node("Guards/GuardStreetB")
		get_root().get_node("Events").laser_alarm.connect(func(_pos: Vector3) -> void: alarms += 1)
		started = true
	f += 1
	match f:
		5:
			g.set("patrol_points", PackedVector3Array())
			g.global_position = Vector3(25, 0.05, -8)
			p.global_position = Vector3(35.0, 0.05, 0)
			p.camera.rig_3d.snap_behind(Vector3.RIGHT)
			Input.action_press(&"move_forward")
		90:
			check("standing_blocked_by_high_laser", p.global_position.x < 36.7, "x=%.2f" % p.global_position.x)
			check("standing_triggers_alarm", alarms >= 1, "alarms=%d" % alarms)
			check("alarm_sends_guard", g.state == 3, "state=%d" % g.state)
			Input.action_release(&"move_forward")
			alarms = 0
			p.global_position = Vector3(35.0, 0.05, -4)
			p.velocity = Vector3.ZERO
			p.sneak_toggled = true
			# Nízký blikající paprsek za vysokým tady netestujeme.
			current_scene.get_node("Lasers/LaserBlink").set_deferred("monitoring", false)
		95:
			Input.action_press(&"move_forward")
		150:
			Input.action_release(&"move_forward")
			check("crawl_under_high_laser_no_alarm", p.global_position.x > 36.8 and alarms == 0, "x=%.2f alarms=%d st=%s" % [p.global_position.x, alarms, p.state_machine.current.name])
			print("RESULT: %d fails" % fails)
			quit(1 if fails > 0 else 0)
	return false
