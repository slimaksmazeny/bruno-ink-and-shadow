extends SceneTree
var p: Node
var f: int = 0
var r: Dictionary = {}
var spires: Node
func _initialize() -> void:
	change_scene_to_file("res://levels/greybox/greybox_street.tscn")
func face(target: Vector3) -> void:
	var d: Vector3 = target - p.global_position
	p.camera.rig_3d.yaw = atan2(-d.x, -d.z)
func balls() -> int:
	return get_nodes_in_group("tennis_ball").size()
func _physics_process(_d: float) -> bool:
	if p == null:
		if current_scene != null:
			p = current_scene.get_node_or_null("Player"); spires = current_scene.get_node_or_null("Spires")
		return false
	f += 1
	match f:
		10:
			Input.action_press("aim")
		40:
			r["aim_state"] = String(p.state_machine.current_name())
			r["aim_cam"] = "blend=%.2f fov=%.1f arm=%.2f" % [p.camera.rig_3d.aim_blend, p.camera.cam.fov, p.camera.rig_3d.spring_arm.spring_length]
			Input.action_press("move_right")
		70:
			r["aim_strafe"] = "speed=%.2f facing_locked=%s" % [Vector2(p.velocity.x, p.velocity.z).length(), p.visual.facing_locked]
			Input.action_release("move_right")
			Input.action_press("fire")
		71:
			Input.action_release("fire")
		80:
			r["fire_ball"] = balls()
			Input.action_press("sprint")
		90:
			r["sprint_while_aim"] = String(p.state_machine.current_name())
			Input.action_release("sprint")
			Input.action_release("aim")
		120:
			r["after_aim"] = "%s blend=%.2f" % [p.state_machine.current_name(), p.camera.rig_3d.aim_blend]
			for b in get_nodes_in_group("tennis_ball"): b.free()
			Input.action_press("attack")
		121:
			Input.action_release("attack")
		124:
			r["attack"] = "%s balls=%d" % [p.state_machine.current_name(), balls()]
		# anchor: facing away from practice spire must NOT latch, facing it must latch
		160:
			p.global_position = Vector3(4, 0.1, 10.5)
			p.velocity = Vector3.ZERO
			p.state_machine.transition_to(&"Idle", {"force": true})
			face(Vector3(4, 0, 20))  # look away (spire is at z 9)
		165:
			Input.action_press("jump")
		168:
			Input.action_release("jump")
		176:
			r["look_away_best"] = str(p.anchor_detector.best_anchor().name if p.anchor_detector.best_anchor() else "-")
			Input.action_press("action")
		177:
			Input.action_release("action")
		200:
			r["look_away_state"] = String(p.state_machine.current_name())
		230:
			p.global_position = Vector3(4, 0.1, 10.5)
			p.velocity = Vector3.ZERO
			p.state_machine.transition_to(&"Idle", {"force": true})
			face(Vector3(4, 0, 9))
		235:
			Input.action_press("jump")
		238:
			Input.action_release("jump")
		246:
			Input.action_press("action")
		247:
			Input.action_release("action")
		275:
			r["look_at_state"] = String(p.state_machine.current_name())
			for k in r: print(k, ": ", r[k])
			quit()
	return false
