## Kapsářství: zezadu u nic netušícího strážného ukrást mince; zepředu ani po poplachu ne.
## godot --headless --path game --script ../tools/tests/test_step_k.gd
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


func _physics_process(_d: float) -> bool:
	if not started:
		if current_scene == null or current_scene.get_node_or_null("Player") == null:
			return false
		p = current_scene.get_node("Player")
		g = current_scene.get_node("Guards/GuardStreetB")
		started = true
	f += 1
	var gs = get_root().get_node("GameState")
	match f:
		5:
			g.set("patrol_points", PackedVector3Array())
			g.global_position = Vector3(29, 0.05, 1.5)
			g.rotation.y = 0.0
			p.sneak_toggled = true
			p.global_position = Vector3(29, 0.05, -0.2) # před ním
		10:
			check("no_pickpocket_from_front", not g.can_be_pickpocketed_by(p))
			p.global_position = Vector3(29, 0.05, 2.7) # za zády
		15:
			check("pickpocket_possible_behind", g.can_be_pickpocketed_by(p) and g._hint.visible)
			var before: int = gs.get_coins()
			p.state_machine.current._try_pickpocket()
			check("coins_added", gs.get_coins() == before + 25, "coins=%d" % gs.get_coins())
			check("loot_gone", g.loot == 0 and not g.can_be_pickpocketed_by(p))
			var hud = current_scene.get_node("Hud")
			check("hud_coins_visible", hud._coin_label.visible and hud._coin_label.text.ends_with("25"), hud._coin_label.text)
			print("RESULT: %d fails" % fails)
			quit(1 if fails > 0 else 0)
	return false
