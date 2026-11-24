## Strážní: odlákání tenisákem (hluk), volání posil při poplachu.
## godot --headless --path game --script ../tools/tests/test_step_m.gd
extends SceneTree

var p
var g
var g2
var f: int = 0
var fails: int = 0
var started: bool = false


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
		g2 = current_scene.get_node("Guards2/GuardRoof")
		started = true
	f += 1
	var ev = get_root().get_node("Events")
	match f:
		5:
			p.global_position = Vector3(-15, 0.05, 8) # daleko
			g.set("patrol_points", PackedVector3Array())
			g.global_position = Vector3(29, 0.05, 1.5)
			# Skutečný tenisák dopadne kousek od strážného.
			var ball = load("res://world/props/tennis_ball.tscn").instantiate()
			current_scene.add_child(ball)
			ball.global_position = Vector3(33, 1.5, 4)
			ball.launch(Vector3(0, -12, 0))
		40:
			check("ball_noise_investigate", g.state == 3, "state=%d" % g.state)
		160:
			check("guard_walks_to_noise", g.global_position.distance_to(Vector3(33, 0, 4)) < 2.5, str(g.global_position))
			# Posily: druhý strážný (střecha, ~16 m) slyší poplach prvního.
			g.global_position = Vector3(20, 0.05, -4)
			g.state = 0
			g2.state = 0
			ev.guard_called_help.emit(g, Vector3(18, 0, -4))
		165:
			check("help_call_brings_roof_guard", g2.state == 3, "state=%d dist=%.1f" % [g2.state, g2.global_position.distance_to(g.global_position)])
			print("RESULT: %d fails" % fails)
			quit(1 if fails > 0 else 0)
	return false
