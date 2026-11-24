## Kroky: sprint za zády strážného = hluk → jde se podívat; plížení = ticho.
## godot --headless --path game --script ../tools/tests/test_step_p.gd
extends SceneTree

var p
var g
var f: int = 0
var fails: int = 0
var started: bool = false


func _initialize() -> void:
	change_scene_to_file("res://levels/greybox/greybox_street.tscn")


func check(name: String, ok: bool, info: String = "") -> void:
	print(("PASS " if ok else "FAIL ") + name + ("  " + info if info != "" else ""))
	if not ok:
		fails += 1


func setup(sneak: bool) -> void:
	g.set("patrol_points", PackedVector3Array())
	g.global_position = Vector3(29, 0.05, 1.5)
	g.rotation.y = 0.0
	g.state = 0
	g.suspicion = 0.0
	p.global_position = Vector3(26.5, 0.05, 5.0)
	p.velocity = Vector3.ZERO
	p.sneak_toggled = sneak
	p.camera.rig_3d.snap_behind(Vector3.RIGHT)


func _physics_process(_d: float) -> bool:
	if not started:
		if current_scene == null or current_scene.get_node_or_null("Player") == null:
			return false
		p = current_scene.get_node("Player")
		g = current_scene.get_node("Guards/GuardStreetB")
		started = true
	f += 1
	match f:
		5:
			setup(true)
			Input.action_press(&"move_forward")
		50:
			Input.action_release(&"move_forward")
			check("sneak_steps_silent", g.state == 0, "state=%d" % g.state)
			setup(false)
		55:
			Input.action_press(&"move_forward")
			Input.action_press(&"sprint")
		95:
			Input.action_release(&"move_forward")
			Input.action_release(&"sprint")
			check("sprint_steps_heard", g.state == 3, "state=%d posture=%d" % [g.state, p.visual.posture])
			print("RESULT: %d fails" % fails)
			quit(1 if fails > 0 else 0)
	return false
