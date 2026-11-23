extends SceneTree
var p: Node
var f: int = 0
var r: Dictionary = {}
var dummy: Node
var crate: Node
var states: Array[String] = []
var max_speed: float = 0.0
func _initialize() -> void:
	change_scene_to_file("res://levels/greybox/greybox_street.tscn")
func face(target: Vector3) -> void:
	var d: Vector3 = target - p.global_position
	p.camera.rig_3d.yaw = atan2(-d.x, -d.z)
func press(a: String) -> void:
	Input.action_press(a)
func _physics_process(_d: float) -> bool:
	if p == null:
		if current_scene != null:
			p = current_scene.get_node_or_null("Player")
			dummy = current_scene.get_node_or_null("Training/TrainingDummy")
			if p != null:
				p.state_machine.state_changed.connect(func(a, b): if f >= 15 and f < 90: print(f, " ", a, ">", b, " combo=", p.state_machine.current.get("combo"), " ts=", Engine.time_scale))
			crate = current_scene.get_node_or_null("Training/Crate1")
		return false
	f += 1
	var st: String = String(p.state_machine.current_name())
	if states.is_empty() or states[-1] != st:
		states.append(st)
	if st == "Attack":
		max_speed = maxf(max_speed, Vector2(p.velocity.x, p.velocity.z).length())
	match f:
		5:
			# stand 2 m from dummy, camera looking slightly off (auto-target should fix facing)
			p.global_position = Vector3(-7, 0.02, 11.0)
			p.velocity = Vector3.ZERO
			face(Vector3(-6.2, 0, 9))
		20:
			states.clear()
			press("attack")
		21: Input.action_release("attack")
		32: press("attack")
		33: Input.action_release("attack")
		46: press("attack")
		47: Input.action_release("attack")
		90:
			r["combo_states"] = ",".join(states)
			r["dummy_hits"] = dummy.total_hits
			r["lunge_max_speed"] = "%.1f" % max_speed
			r["time_scale_restored"] = Engine.time_scale
			states.clear()
			# crate: 2 hits breaks it
			p.global_position = Vector3(-9.0, 0.02, 9.6)
			p.velocity = Vector3.ZERO
			p.state_machine.transition_to(&"Idle", {"force": true})
			face(Vector3(-9.0, 0, 7.8))
		105: press("attack")
		106: Input.action_release("attack")
		117: press("attack")
		118: Input.action_release("attack")
		160:
			r["crate_broken"] = crate.broken
			# air attack
			p.global_position = Vector3(-3, 0.02, 10)
			p.velocity = Vector3.ZERO
			p.state_machine.transition_to(&"Idle", {"force": true})
			states.clear()
		180:
			states.clear()
			press("jump")
		184: Input.action_release("jump")
		190: press("attack")
		191: Input.action_release("attack")
		199:
			press("attack")
		200:
			Input.action_release("attack")
		260:
			r["air_states"] = ",".join(states)
			r["air_attack_used_reset"] = not p.air_attack_used
			for k in r: print(k, ": ", r[k])
			quit()
	return false
