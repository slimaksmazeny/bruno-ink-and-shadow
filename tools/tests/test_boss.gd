## Boss Velký hlídač (hřiště, stanoviště 0): aktivace, blok, dupnutí, únava, fáze, porážka.
## godot --headless --path game --script ../tools/tests/test_boss.gd
extends SceneTree

var p
var b
var f: int = 0
var fails: int = 0
var started: bool = false
var defeated: int = 0
var hp0: int


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
		b = current_scene.get_node("BossWarden")
		get_root().get_node("Events").boss_defeated.connect(func(_x) -> void: defeated += 1)
		started = true
	f += 1
	match f:
		20:
			check("boss_idle_far", b.phase == 0 and b.health == 6, "phase=%d hp=%d" % [b.phase, b.health])
			current_scene.get_node("Stations").go_to(9)
		60:
			check("boss_starts_fight", b.phase >= 1, "phase=%d" % b.phase)
			var hud = current_scene.get_node("Hud")
			check("hud_boss_bar", hud._boss_bar.visible and hud._boss_bar.text.contains("■"), hud._boss_bar.text)
			# Blok mimo únavu.
			b.phase = 1
			b.on_cane_hit({"damage": 1})
			check("blocked_when_not_tired", b.health == 6, "hp=%d" % b.health)
			# Dupnutí zasáhne Bruna na zemi blízko.
			p.global_position = b.global_position + Vector3(-2.5, 0.1, 0)
			p.velocity = Vector3.ZERO
			p._invulnerable = 0.0
			hp0 = p.health
		75:
			b._begin_windup()
			b._p_timer = 0.02
		80:
			check("slam_hurts_grounded", p.health == hp0 - 1, "hp %d->%d" % [hp0, p.health])
			check("tired_after_slam", b.phase == 3, "phase=%d" % b.phase)
			b.on_cane_hit({"damage": 1})
			check("hit_when_tired", b.health == 5)
		90:
			b.phase = 3
			b.on_cane_hit({"damage": 1})
			check("phase_2_after_two_hits", b.stage == 2 and b.phase == 1, "stage=%d phase=%d" % [b.stage, b.phase])
			# Tenisák během nápřahu → únava.
			b._begin_windup()
			b.on_cane_hit({"damage": 0, "ball": true})
			check("ball_interrupts_windup", b.phase == 3, "phase=%d" % b.phase)
			# Bruno ve vzduchu vlnu přeskočí.
			p.global_position = b.global_position + Vector3(-2.5, 2.5, 0)
			p._invulnerable = 0.0
			hp0 = p.health
			b._slam()
			check("jump_avoids_wave", p.health == hp0, "hp %d->%d" % [hp0, p.health])
		100:
			for i in 4:
				b.phase = 3
				b.on_cane_hit({"damage": 1})
			check("boss_defeated", defeated == 1 and b.phase == 4 and b.health <= 0, "def=%d phase=%d hp=%d" % [defeated, b.phase, b.health])
		130:
			var drops: int = 0
			for n in current_scene.get_children():
				if n.get_script() != null and String(n.get_script().resource_path).ends_with("key_pickup.gd"):
					drops += 1
			check("boss_drops_loot", drops >= 1)
			check("hud_bar_hidden", not current_scene.get_node("Hud")._boss_bar.visible)
			print("RESULT: %d fails" % fails)
			quit(1 if fails > 0 else 0)
	return false
