## Brunova bouda: nákup vylepšení za mince a jejich účinky.
## godot --headless --path game --script ../tools/tests/test_shop.gd
extends SceneTree

var f: int = 0
var fails: int = 0
var stage: int = 0


func _initialize() -> void:
	change_scene_to_file("res://ui/menus/main_menu.tscn")


func check(name: String, ok: bool, info: String = "") -> void:
	print(("PASS " if ok else "FAIL ") + name + ("  " + info if info != "" else ""))
	if not ok:
		fails += 1


func _physics_process(_d: float) -> bool:
	if current_scene == null:
		return false
	f += 1
	var gs = get_root().get_node("GameState")
	var up = load("res://core/upgrades.gd")
	if stage == 0 and f == 10:
		gs.reset()
		gs.add_coins(100)
		check("too_expensive", not up.buy("extra_heart") and gs.get_coins() == 100)
		check("buy_glide", up.buy("long_glide") and gs.get_coins() == 20 and up.has("long_glide"))
		check("no_double_buy", not up.buy("long_glide"))
		gs.add_coins(200)
		check("buy_heart", up.buy("extra_heart"))
		check("buy_stun", up.buy("stun_ball"))
		current_scene._on_shop()
		check("shop_lists_5", current_scene._shop_box.get_child_count() == 7, str(current_scene._shop_box.get_child_count()))
		stage = 1
		f = 0
		change_scene_to_file("res://levels/test/gym.tscn")
	elif stage == 1 and f == 20:
		var p = current_scene.get_node("Player")
		check("extra_heart_effect", p.max_health == 4 and p.health == 4, "max=%d" % p.max_health)
		var glide = p.state_machine.get_node("Glide")
		check("long_glide_effect", glide._fall_speed() < p.profile.glide_fall_speed)
		var g = current_scene.get_node("Guard")
		g.on_cane_hit({"damage": 1, "ball": true})
		check("stun_ball_stuns_not_ko", g.state == 4 and g.health == g.max_health, "state=%d hp=%d" % [g.state, g.health])
		gs.reset()
		print("RESULT: %d fails" % fails)
		quit(1 if fails > 0 else 0)
	return false
