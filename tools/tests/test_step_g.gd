## v0.2.2 Kostra hry: zdraví, louže, smrt+respawn, kapky, checkpoint, strážný, pauza, menu, zvuky.
## Pozn.: bez typů Player/Guard – v režimu --script ještě nejsou známé autoloady.
## godot --headless --path game --script ../tools/tests/test_step_g.gd
extends SceneTree

var p
var f: int = 0
var r: Array[String] = []
var fails: int = 0
var g
var hp_before: int


func _initialize() -> void:
	change_scene_to_file("res://levels/greybox/greybox_street.tscn")


func al(n: String) -> Node:
	return get_root().get_node(n)


func check(name: String, ok: bool, info: String = "") -> void:
	print(("PASS " if ok else "FAIL ") + name, " @", f)
	r.append(("PASS " if ok else "FAIL ") + name + ("  " + info if info != "" else ""))
	if not ok:
		fails += 1


func put(pos: Vector3) -> void:
	p.global_position = pos
	p.velocity = Vector3.ZERO
	p.reset_physics_interpolation()


func _physics_process(_d: float) -> bool:
	if f == 0 and p == null:
		if current_scene != null:
			p = current_scene.get_node_or_null("Player")
			g = current_scene.get_node_or_null("Guards/GuardStreetB")
		if p == null:
			return false
	f += 1
	match f:
		5:
			check("hud_exists", current_scene.get_node_or_null("Hud") != null)
			check("ink_drops_55", get_nodes_in_group(&"ink_drop").size() == 55, str(get_nodes_in_group(&"ink_drop").size()))
			check("guard_exists", g != null)
			check("audio_buses", AudioServer.get_bus_index(&"SFX") != -1 and AudioServer.get_bus_index(&"Music") != -1)
			check("full_health", p.health == 3)
			# Kapka: postavit Bruna na první kapku.
			put(Vector3(-2, 0.05, 11))
		15:
			check("ink_collected", al("GameState").is_collected("greybox", "ink", "gb_ink_00"), str(al("GameState").count_collected("greybox", "ink")))
			# Louže inkoustu.
			put(Vector3(34, 0.05, 3))
		20:
			check("hazard_damage", p.health == 2, "hp=%d" % p.health)
			check("invulnerable_after_hit", p.is_invulnerable())
		30:
			check("no_double_damage", p.health == 2, "hp=%d" % p.health)
		120:
			check("hazard_again_after_iframes_or_knocked_out", p.health <= 2, "hp=%d" % p.health)
			# Checkpoint na ulici B.
			put(Vector3(19.5, 0.05, 9))
		130:
			var cp = current_scene.get_node("Checkpoints/CpStreetB")
			check("checkpoint_active", cp.active)
			check("checkpoint_heals", p.health == 3, "hp=%d" % p.health)
			check("checkpoint_saved", al("SaveManager").has_save(1))
			# Smrt: 3 zásahy.
			for i: int in 3:
				p.set("_invulnerable", 0.0)
				p.take_damage(1, p.global_position + Vector3.RIGHT)
			put(Vector3(-20, 0.05, -5))
		200:
			check("death_respawn_at_checkpoint", p.global_position.distance_to(Vector3(19.5, 0.15, 9)) < 1.0, str(p.global_position))
			check("death_full_heal", p.health == 3, "hp=%d" % p.health)
			# Strážný: postavit Bruna před něj (v kuželu).
			g.global_position = Vector3(29, 0.05, 1.5)
			g.rotation.y = 0.0 # dívá se k -Z
			g.set("patrol_points", PackedVector3Array())
			put(Vector3(29, 0.05, -3.5))
		260:
			check("guard_alerted_front", g.state == 2, "state=%d susp=%.2f" % [g.state, g.suspicion])
			# Reset: plížení za zády – nemá vidět.
			g.state = 0
			g.suspicion = 0.0
			g.rotation.y = 0.0
			p.sneak_toggled = true
			put(Vector3(29, 0.05, 4.5))
		300:
			check("guard_blind_behind_sneaking", g.state == 0, "state=%d susp=%.2f" % [g.state, g.suspicion])
			# Knockout zezadu jednou ranou.
			g.on_cane_hit({"damage": 1, "dir": Vector3.FORWARD})
			check("guard_knockout_from_behind", g.state == 5)
			p.sneak_toggled = false
		310:
			# Pauza.
			var ev := InputEventAction.new()
			ev.action = &"pause"
			ev.pressed = true
			Input.parse_input_event(ev)
		315:
			check("pause_opens", paused and al("PauseMenu").is_open)
			al("PauseMenu").close()
		318:
			check("pause_closes", not paused)
			change_scene_to_file("res://ui/menus/main_menu.tscn")
		330:
			check("main_menu_loads", current_scene != null and current_scene.name == "MainMenu")
			for line: String in r:
				print(line)
			print("RESULT: %d fails" % fails)
			quit(1 if fails > 0 else 0)
	return false
