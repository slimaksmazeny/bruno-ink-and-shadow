## Finále loupeže (kaňon): po krystalu odpočet útěku, poplach strážných, vypršení = chycen.
## godot --headless --path game --script ../tools/tests/test_escape.gd
extends SceneTree

var p
var m
var f: int = 0
var fails: int = 0
var started: bool = false
var caught: int = 0


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
		m = current_scene.get_node("Mission")
		get_root().get_node("Events").mission_caught.connect(func() -> void: caught += 1)
		started = true
	f += 1
	match f:
		20:
			p.global_position = Vector3(60, 0.05, 9)
			m.notify(&"key")
			m.notify(&"vault_opened")
			m.notify(&"treasure_taken")
			check("escape_timer_starts", m.step == 3 and absf(m.escape_left - 120.0) < 0.1, "left=%.1f" % m.escape_left)
		30:
			var hud = current_scene.get_node("Hud")
			check("hud_countdown", hud._escape.visible and hud._escape.text.begins_with("⏱"), hud._escape.text)
			var hunting: int = 0
			for g in get_nodes_in_group(&"guard"):
				if g.state == 3 or g.state == 2:
					hunting += 1
			check("guards_hunt", hunting >= 2, "hunting=%d" % hunting)
			m.escape_left = 0.2
		60:
			check("caught_when_time_out", caught == 1 and m.step == 3 and m.escape_left > 100.0, "caught=%d step=%d left=%.1f" % [caught, m.step, m.escape_left])
		140:
			check("respawned_alive", p.health == p.max_health)
			print("RESULT: %d fails" % fails)
			quit(1 if fails > 0 else 0)
	return false
