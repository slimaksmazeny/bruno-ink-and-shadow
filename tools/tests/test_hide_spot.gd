## Úkryty (kaňon): schovaný Bruno je pro strážného neviditelný, poplach se změní v hledání,
## vylezení vrátí viditelnost, smrt/respawn úkryt uvolní.
## godot --headless --path game --script ../tools/tests/test_hide_spot.gd
extends SceneTree

var p
var g
var h
var f: int = 0
var fails: int = 0
var started: bool = false


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
		started = true
	f += 1
	match f:
		10:
			var spots = get_nodes_in_group(&"hide_spot")
			check("six_hide_spots", spots.size() == 6, str(spots.size()))
			for s in spots:
				if s.global_position.distance_to(Vector3(17, 0, 4.2)) < 0.5:
					h = s
			g = current_scene.get_node("Content/GuardRiver")
			# Bruno přímo před strážným, ve výhledu.
			g.global_position = Vector3(17, 0.05, 1.0)
			g.rotation.y = 0.0
			g.look_at(Vector3(17, 0.05, 4.2), Vector3.UP)
			p.global_position = Vector3(17, 0.05, 4.2)
			g.set_physics_process(false)
		14:
			check("guard_sees_open", g._can_see_player())
			check("can_hide", h.can_interact(p))
			h.interact(p)
			check("hidden_state", p.hidden_in == h and not p.visual.visible and h._ears.visible)
			check("guard_blind_when_hidden", not g._can_see_player())
			check("spot_busy", not h.can_interact(p))
		20:
			h.force_exit()
			check("out_visible", p.hidden_in == null and p.visual.visible and p.velocity.y > 1.0)
		60:
			h.interact(p)
			p.die()
		140:
			check("death_frees_spot", h.occupant == null and p.hidden_in == null and p.visual.visible)
			print("RESULT: %d fails" % fails)
			quit(1 if fails > 0 else 0)
	return false
