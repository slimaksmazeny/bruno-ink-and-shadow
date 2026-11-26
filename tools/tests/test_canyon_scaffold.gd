## Výšková trasa v kaňonu: Bruno přeběhne lešení (přeskočí mezery), sleze na střechu boudy, a lasery nespustí.
## godot --headless --path game --script ../tools/tests/test_canyon_scaffold.gd
extends SceneTree

var p
var f: int = 0
var fails: int = 0
var started: bool = false
var lasers: int = 0
var min_y: float = 99.0
var jumped: Dictionary = {}


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
		get_root().get_node("Events").laser_alarm.connect(func(_x) -> void: lasers += 1)
		get_root().get_node("DevMenu").god_mode = true
		started = true
	f += 1
	if f == 10:
		p.global_position = Vector3(44.8, 5.4, -11.6)
		p.velocity = Vector3.ZERO
		p.reset_physics_interpolation()
		p.camera.rig_3d.snap_behind(Vector3.RIGHT)
	if f == 30:
		Input.action_press(&"move_forward")
	if f > 30 and f < 600:
		var x: float = p.global_position.x
		for edge: float in [49.4, 59.9, 69.9]:
			if x > edge and not jumped.has(edge):
				jumped[edge] = true
				p.jump_buffer_timer = 0.2
		if x < 74.0:
			min_y = minf(min_y, p.global_position.y)
		if x > 74.6 and not jumped.has(&"turn"):
			jumped[&"turn"] = true
			p.camera.rig_3d.snap_behind(Vector3.BACK)
	if f == 600:
		Input.action_release(&"move_forward")
		check("stayed_on_scaffold", min_y > 4.5, "min_y=%.2f" % min_y)
		check("reached_roof", p.global_position.x > 72.0 and p.global_position.y > 3.3 and absf(p.global_position.z) < 4.5, str(p.global_position))
		check("no_laser_alarm", lasers == 0, str(lasers))
		print("RESULT: %d fails" % fails)
		quit(1 if fails > 0 else 0)
	return false
