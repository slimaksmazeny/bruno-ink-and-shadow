## Vyřazený strážný upustí klíč + půlku mincí; po sebrání mise pokračuje (žádné zaseknutí).
## godot --headless --path game --script ../tools/tests/test_key_drop.gd
extends SceneTree

var p
var g
var m
var f: int = 0
var fails: int = 0
var started: bool = false
var coins0: int = 0


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
		m = current_scene.get_node("Mission")
		started = true
	f += 1
	var gs = get_root().get_node("GameState")
	match f:
		10:
			coins0 = gs.get_coins()
			g.set("patrol_points", PackedVector3Array())
			g.global_position = Vector3(29, 0.05, 1.5)
			g.on_cane_hit({"damage": 99})
		20:
			var keys = get_nodes_in_group(&"key_pickup")
			check("key_dropped", keys.size() == 1 and keys[0].key_id == "vault_key", str(keys.size()))
			check("radar_points_to_key", m.objective_position() != null and (m.objective_position() as Vector3).distance_to(keys[0].global_position) < 0.1)
			p.global_position = keys[0].global_position
			p.velocity = Vector3.ZERO
		30:
			check("key_picked", gs.has_key("vault_key") and m.step == 1, "step=%d" % m.step)
			check("half_coins", gs.get_coins() == coins0 + 12, "coins=%d" % gs.get_coins())
			print("RESULT: %d fails" % fails)
			quit(1 if fails > 0 else 0)
	return false
