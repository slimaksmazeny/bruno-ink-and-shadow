## Kapitola 3 Pouť: kolotoč veze, ruské kolo vynese, reflektor zachytí / úkryt, loupež, rekord.
## godot --headless --path game --script ../tools/tests/test_ch3_carnival.gd
extends SceneTree

var p
var m
var f: int = 0
var fails: int = 0
var started: bool = false
var mark: Vector3
var max_y: float = -99.0
var alarms: int = 0


func _initialize() -> void:
	change_scene_to_file("res://levels/ch3_carnival/carnival.tscn")


func check(name: String, ok: bool, info: String = "") -> void:
	print(("PASS " if ok else "FAIL ") + name + ("  " + info if info != "" else ""))
	if not ok:
		fails += 1


func put(pos: Vector3) -> void:
	p.global_position = pos
	p.velocity = Vector3.ZERO
	p.reset_physics_interpolation()
	p.state_machine.transition_to(&"Idle", {"force": true})


func _physics_process(_d: float) -> bool:
	if not started:
		if current_scene == null or current_scene.get_node_or_null("Player") == null:
			return false
		p = current_scene.get_node("Player")
		m = current_scene.get_node("Mission")
		get_root().get_node("Events").laser_alarm.connect(func(_x: Vector3) -> void: alarms += 1)
		started = true
	f += 1
	var gs = get_root().get_node("GameState")
	match f:
		40:
			check("on_floor", p.is_on_floor(), str(p.global_position))
			check("chapter_carnival", m.chapter_id == "carnival")
			# Uspat strážné, ať neruší testy pohybu.
			for g in get_nodes_in_group(&"guard"):
				g.set("patrol_points", PackedVector3Array())
			put(Vector3(26.0, 0.6, 0))
		45:
			mark = p.global_position
		150:
			check("carousel_carries", Vector2(p.global_position.x - mark.x, p.global_position.z - mark.z).length() > 1.0 and p.global_position.y > 0.3, "%s -> %s" % [mark, p.global_position])
			# Ruské kolo: postavit na nejnižší gondolu.
			var wheel = current_scene.get_node("Content/FerrisWheel")
			var low = null
			for c in wheel.get_children():
				if c is AnimatableBody3D and (low == null or c.global_position.y < low.global_position.y):
					low = c
			put(low.global_position + Vector3.UP * 0.3)
			max_y = p.global_position.y
		151, 200, 250, 300, 350, 400, 450, 500:
			max_y = maxf(max_y, p.global_position.y)
		520:
			check("ferris_lifts", max_y > 5.0, "max_y=%.1f" % max_y)
			# Reflektor: zastavit a postavit Bruna do kuželu.
			var s = current_scene.get_node("Content/SearchlightA")
			s.sweep_speed = 0.0
			s._t = 0.0
			alarms = 0
			var tilt = s._tilt
			var dir: Vector3 = -tilt.global_transform.basis.z
			var t: float = -tilt.global_position.y / dir.y
			put(tilt.global_position + dir * t + Vector3.UP * 0.05)
		530:
			check("searchlight_catches", alarms >= 1, "alarms=%d pos=%s" % [alarms, p.global_position])
			alarms = 0
			s_cover_test()
		545:
			check("searchlight_cover_blocks", alarms == 0, "alarms=%d" % alarms)
			# Loupež.
			var g = current_scene.get_node("Content/GuardCarousel")
			g.global_position = Vector3(22, 0.05, 8)
			g.rotation.y = 0.0
			p.sneak_toggled = true
			put(Vector3(22, 0.05, 9.2))
		550:
			p.state_machine.current._try_pickpocket()
			check("key_from_carousel_guard", gs.has_key("booth_key"), "step=%d" % m.step)
			p.sneak_toggled = false
			put(Vector3(85.6, 0.05, 0))
		556:
			p.state_machine.current._try_interact()
		562:
			p.state_machine.current._try_interact()
		568:
			check("booth_vault", m.step == 3, "step=%d" % m.step)
			put(Vector3(4, 0.05, 11.6))
		574:
			p.state_machine.current._try_interact()
		580:
			check("carnival_heist_done", m.step == 4 and gs.best_time("carnival") > 0.0)
			for c in get_root().get_children():
				if c is CanvasLayer and c.get("mission") != null:
					c._close()
			print("RESULT: %d fails" % fails)
			quit(1 if fails > 0 else 0)
	return false


## Schovat Bruna za bednu: postavit bednu (zeď) mezi reflektor a Bruna.
func s_cover_test() -> void:
	var s = current_scene.get_node("Content/SearchlightA")
	var wall := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(3, 3, 0.3)
	cs.shape = bs
	wall.add_child(cs)
	current_scene.add_child(wall)
	var tilt = s._tilt
	wall.global_position = tilt.global_position.lerp(p.global_position, 0.5)
	wall.look_at(p.global_position, Vector3.UP)
