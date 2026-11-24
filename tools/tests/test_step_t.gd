## v0.3.1 souboje: nápřah strážného, úhyb (nezranitelnost), zásah bez úhybu.
## godot --headless --path game --script ../tools/tests/test_step_t.gd
extends SceneTree

var p
var g
var f: int = 0
var fails: int = 0
var started: bool = false
var mark: Vector3


func _initialize() -> void:
	change_scene_to_file("res://levels/greybox/greybox_street.tscn")


func check(name: String, ok: bool, info: String = "") -> void:
	print(("PASS " if ok else "FAIL ") + name + ("  " + info if info != "" else ""))
	if not ok:
		fails += 1


func setup() -> void:
	g.set("patrol_points", PackedVector3Array())
	g.global_position = Vector3(29, 0.05, 1.5)
	g.rotation.y = 0.0
	g._attack_cd = 0.0
	g._windup = -1.0
	p.health = 3
	p.set("_invulnerable", 0.0)
	p.global_position = Vector3(29, 0.05, 0.4) # těsně před ním
	p.velocity = Vector3.ZERO
	p.state_machine.transition_to(&"Idle", {"force": true})
	g._set_state(2) # ALERT
	g._last_seen = p.global_position


func _physics_process(_d: float) -> bool:
	if not started:
		if current_scene == null or current_scene.get_node_or_null("Player") == null:
			return false
		p = current_scene.get_node("Player")
		g = current_scene.get_node("Guards/GuardStreetB")
		started = true
	f += 1
	match f:
		5:
			setup()
		8:
			check("guard_winds_up_first", g._windup >= 0.0 and p.health == 3, "windup=%.2f hp=%d" % [g._windup, p.health])
		45:
			check("hit_after_windup", p.health == 2, "hp=%d" % p.health)
			setup()
		52:
			p.visual.face_direction(Vector3.BACK) # čelem ke strážnému (stojí na +Z)
		66:
			# Úhyb těsně před úderem – bez směru = dozadu od strážného.
			mark = p.global_position
			p.state_machine.transition_to(&"Dodge")
		68:
			check("dodge_state", String(p.state_machine.current.name) == "Dodge" and p.dodging)
		87:
			check("dodge_moved_away", (p.global_position - mark).z < -1.5, "dz=%.2f" % (p.global_position - mark).z)
		95:
			check("dodge_avoids_hit", p.health == 3, "hp=%d dist=%.2f" % [p.health, p.global_position.distance_to(g.global_position)])
			print("RESULT: %d fails" % fails)
			quit(1 if fails > 0 else 0)
	return false
