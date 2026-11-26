## Strážní se po Brunově smrti vrátí (kaňon) + Bruno se nikdy neotáčí (orientace vizuálu).
## godot --headless --path game --script ../tools/tests/test_guard_respawn.gd
extends SceneTree

var p
var g
var f: int = 0
var fails: int = 0
var started: bool = false
var start_pos: Vector3
var guards0: int


func _initialize() -> void:
	change_scene_to_file("res://levels/ch2_canyon/canyon.tscn")


func check(name: String, ok: bool, info: String = "") -> void:
	print(("PASS " if ok else "FAIL ") + name + ("  " + info if info != "" else ""))
	if not ok:
		fails += 1


func _keypickups() -> int:
	var n: int = 0
	for c in current_scene.find_children("*", "", true, false):
		if c.get_script() != null and String(c.get_script().resource_path).ends_with("key_pickup.gd"):
			n += 1
	return n


func _physics_process(_d: float) -> bool:
	if not started:
		if current_scene == null or current_scene.get_node_or_null("Player") == null:
			return false
		p = current_scene.get_node("Player")
		started = true
	f += 1
	match f:
		10:
			check("player_body_not_rotated", p.global_transform.basis.is_equal_approx(Basis()), str(p.global_transform.basis))
			guards0 = get_nodes_in_group(&"guard").size()
			for x in get_nodes_in_group(&"guard"):
				if x.carries_key != "":
					g = x
			check("has_key_guard", g != null)
			start_pos = g._start_transform.origin
			# Vyřadit strážného s klíčem holí (3 zásahy).
			for i in 3:
				g.on_cane_hit({"damage": 1, "dir": Vector3.FORWARD})
			check("guard_ko", g.state == 5)
		200:
			check("guard_hidden_after_ko", not g.visible and get_nodes_in_group(&"guard").size() == guards0 - 1)
			check("key_dropped_once", _keypickups() == 1, str(_keypickups()))
			p.die()
		224:
			check("guard_back_after_death", g.visible and g.state == 0 and g.health == g.max_health and g.global_position.distance_to(start_pos) < 0.5, "vis=%s st=%d pos=%s" % [g.visible, g.state, g.global_position])
			check("guard_in_groups", get_nodes_in_group(&"guard").size() == guards0 and g.is_in_group(&"hittable"))
			check("no_duplicate_key", g.carries_key == "" and _keypickups() == 1, "carries=%s picks=%d" % [g.carries_key, _keypickups()])
			check("player_still_unrotated", p.global_transform.basis.is_equal_approx(Basis()))
			print("RESULT: %d fails" % fails)
			quit(1 if fails > 0 else 0)
	return false
