## v0.2.8: kaňky (skok na hlavu, zranění zboku, hůl), sklenice se světluškami, piškot.
## godot --headless --path game --script ../tools/tests/test_step_q.gd
extends SceneTree

var p
var f: int = 0
var fails: int = 0
var started: bool = false
var vy_max: float = -99.0


func _initialize() -> void:
	change_scene_to_file("res://levels/greybox/greybox_street.tscn")


func check(name: String, ok: bool, info: String = "") -> void:
	print(("PASS " if ok else "FAIL ") + name + ("  " + info if info != "" else ""))
	if not ok:
		fails += 1


func node(path: String):
	return current_scene.get_node_or_null(path)


func _physics_process(_d: float) -> bool:
	if not started:
		if current_scene == null or current_scene.get_node_or_null("Player") == null:
			return false
		p = current_scene.get_node("Player")
		started = true
	f += 1
	var gs = get_root().get_node("GameState")
	match f:
		5:
			p.enter_2d(Vector3(230, 0, 0), Vector3.BACK)
			p.camera.side_rig.target = p
			p.camera.side_rig.snap()
			var b = node("Critters/BlobFloor3")
			b.set("speed", 0.0)
			b.global_position = Vector3(240.4, 0.05, 0) # kousek od houby
			p.global_position = b.global_position + Vector3(0, 1.4, 0)
			p.velocity = Vector3(0, -4, 0)
			p.state_machine.transition_to(&"Air", {"force": true})
			p.velocity = Vector3(0, -4, 0)
		6, 7, 8, 9, 10, 11, 12, 13, 14, 15:
			vy_max = maxf(vy_max, p.velocity.y)
		20:
			var b = node("Critters/BlobFloor3")
			check("stomp_kills_blob", b == null or b.dead, "")
			check("stomp_bounces_player", vy_max > 5.0, "vy_max=%.1f" % vy_max)
			var b2 = node("Critters/BlobFloor4")
			b2.set("speed", 0.0)
			p.set("_invulnerable", 0.0)
			p.health = 3
			p.global_position = b2.global_position + Vector3(-0.6, 0, 0)
			p.velocity = Vector3.ZERO
			p.state_machine.transition_to(&"Idle", {"force": true})
		26:
			check("blob_side_hurts", p.health == 2, "hp=%d" % p.health)
			var b3 = node("Critters/BlobEndDeck")
			b3.on_cane_hit({})
			check("cane_kills_blob", b3.dead)
			var jar = node("Critters/JarHighLedge")
			jar.on_cane_hit({})
			check("jar_breaks_collected", jar.broken and gs.is_collected("greybox", "firefly", "jar_highledge"))
			var hud = node("Hud")
			check("hud_fireflies", hud._fly_label.visible and hud._fly_label.text.begins_with("✦ 1 / 3"), hud._fly_label.text)
			# Piškot.
			p.enter_3d()
			p.health = 2
			p.set("_invulnerable", 0.0)
			p.global_position = Vector3(21.0, 0.05, 10.5)
			p.velocity = Vector3.ZERO
		34:
			check("treat_heals", p.health == 3, "hp=%d" % p.health)
			print("RESULT: %d fails" % fails)
			quit(1 if fails > 0 else 0)
	return false
