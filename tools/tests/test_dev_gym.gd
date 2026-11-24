## Tréninkové hřiště + dev menu: stanoviště, nesmrtelnost, létání, mise, přepnutí levelu.
## godot --headless --path game --script ../tools/tests/test_dev_gym.gd
extends SceneTree

var p
var dm
var f: int = 0
var fails: int = 0
var started: bool = false
var y0: float


func _initialize() -> void:
	change_scene_to_file("res://levels/test/gym.tscn")


func check(name: String, ok: bool, info: String = "") -> void:
	print(("PASS " if ok else "FAIL ") + name + ("  " + info if info != "" else ""))
	if not ok:
		fails += 1


func _physics_process(_d: float) -> bool:
	if not started:
		if current_scene == null or current_scene.get_node_or_null("Player") == null:
			return false
		p = current_scene.get_node("Player")
		dm = get_root().get_node("DevMenu")
		started = true
	f += 1
	match f:
		30:
			check("gym_on_floor", p.is_on_floor(), str(p.global_position))
			var st = current_scene.get_node("Stations")
			check("gym_9_stations", st.get_child_count() == 9, str(st.get_child_count()))
			st.go_to(8)
		35:
			check("teleport_station_9", p.global_position.distance_to(current_scene.get_node("Stations").get_child(8).global_position) < 0.5)
			dm.open()
			check("devmenu_opens_pauses", dm.is_open and paused and dm._list.get_child_count() > 15, "items=%d" % dm._list.get_child_count())
			dm.close()
			dm.god_mode = true
			p.set("_invulnerable", 0.0)
			p.take_damage(1, p.global_position + Vector3.RIGHT)
			check("god_mode", p.health == 3)
			dm.god_mode = false
			p.set_fly_mode(true)
			y0 = p.global_position.y
			Input.action_press(&"jump")
		60:
			Input.action_release(&"jump")
			check("fly_up", p.global_position.y > y0 + 2.0, "dy=%.2f" % (p.global_position.y - y0))
			p.set_fly_mode(false)
			var m = current_scene.get_node("Mission")
			for i in 3:
				dm._advance_mission(m)
			check("mission_advance", m.step == 3, "step=%d" % m.step)
		90:
			check("fly_off_falls_lands", p.is_on_floor(), str(p.global_position))
			dm._load_level("res://levels/ch2_canyon/canyon.tscn")
		130:
			check("devmenu_level_switch", current_scene != null and current_scene.name == "CanyonLevel", str(current_scene.name if current_scene else "null"))
			print("RESULT: %d fails" % fails)
			quit(1 if fails > 0 else 0)
	return false
