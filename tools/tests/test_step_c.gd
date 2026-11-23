extends SceneTree
var p: Node
var f: int = 0
var r: Dictionary = {}
var min_vy: float = 0.0
var spires: Node

func _initialize() -> void:
	change_scene_to_file("res://levels/greybox/greybox_street.tscn")

func st() -> String:
	return String(p.state_machine.current_name())

func face(target: Vector3) -> void:
	var d: Vector3 = target - p.global_position
	p.camera.rig_3d.yaw = atan2(-d.x, -d.z)

func tap(action: String) -> void:
	Input.action_press(action)

func _physics_process(_d: float) -> bool:
	if p == null:
		if current_scene != null:
			p = current_scene.get_node_or_null("Player")
			spires = current_scene.get_node_or_null("Spires")
		return false
	f += 1
	match f:
		# --- Glide: teleport high, hold jump while falling
		10:
			p.global_position = Vector3(-8, 14, 14)
			p.velocity = Vector3.ZERO
			p.state_machine.transition_to(&"Air", {})
			p.jumps_used = 2
		20:
			Input.action_press("jump")
		60:
			r["glide_state"] = st()
			r["glide_vy"] = "%.2f" % p.velocity.y
			Input.action_release("jump")
		70:
			r["after_release"] = st()
		# --- Practice spire from ground
		150:
			p.global_position = Vector3(4, 0.1, 10.8)
			p.velocity = Vector3.ZERO
			p.state_machine.transition_to(&"Idle", {"force": true})
		155:
			face(Vector3(4, 0, 9))
			Input.action_press("jump")
		160:
			Input.action_release("jump")
		168:
			r["practice_best"] = str(p.anchor_detector.best_anchor().name if p.anchor_detector.best_anchor() else "-")
			Input.action_press("action")
		169:
			Input.action_release("action")
		200:
			var sn: Vector3 = spires.get_node("SpirePractice").get_snap_position(Vector3.ZERO)
			r["practice_perch"] = "%s dist=%.2f" % [st(), p.global_position.distance_to(sn)]
		# --- Jump off with jump
		210:
			Input.action_press("jump")
		214:
			Input.action_release("jump")
		218:
			r["jump_off"] = "%s jumps=%d" % [st(), p.jumps_used]
		# --- Roof route: start perched on Spire1
		300:
			p.global_position = Vector3(11, 6.1, -7.5)
			p.velocity = Vector3.ZERO
			p.state_machine.transition_to(&"Idle", {"force": true})
		310:
			face(Vector3(11, 7, -9))
			Input.action_press("action")
		311:
			Input.action_release("action")
		340:
			r["spire1"] = st()
			face(Vector3(6.5, 8, -10))
			Input.action_press("jump")
			Input.action_press("move_forward")
		346:
			Input.action_release("jump")
		360:
			r["s1_to_s2_best"] = str(p.anchor_detector.best_anchor().name if p.anchor_detector.best_anchor() else "-")
			Input.action_press("action")
		361:
			Input.action_release("action")
			Input.action_release("move_forward")
		400:
			var sn2: Vector3 = spires.get_node("Spire2_Pole").get_snap_position(Vector3.ZERO)
			r["spire2"] = "%s dist=%.2f" % [st(), p.global_position.distance_to(sn2)]
			face(Vector3(2, 12, -9))
			Input.action_press("jump")
			Input.action_press("move_forward")
		412:
			Input.action_release("jump")
		416:
			Input.action_press("jump")
		420:
			Input.action_release("jump")
		430:
			r["s2_to_s3_best"] = str(p.anchor_detector.best_anchor().name if p.anchor_detector.best_anchor() else "-") + " y=%.2f" % p.global_position.y
			Input.action_press("action")
		431:
			Input.action_release("action")
			Input.action_release("move_forward")
		470:
			var sn3: Vector3 = spires.get_node("Spire3_RoofMid").get_snap_position(Vector3.ZERO)
			r["spire3"] = "%s dist=%.2f" % [st(), p.global_position.distance_to(sn3)]
		480:
			for k in r:
				print(k, ": ", r[k])
			quit()
	return false
