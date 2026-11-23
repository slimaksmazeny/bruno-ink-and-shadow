extends SceneTree
var f: int = 0
var p: Node
var log_lines: Array[String] = []
var max_y: float = -100.0
var phase: String = ""
var base_y: float = 0.0
var results: Dictionary = {}

func _initialize() -> void:
	change_scene_to_file("res://levels/greybox/greybox_street.tscn")

func st() -> String:
	return String(p.state_machine.current_name())

func hs() -> float:
	return Vector2(p.velocity.x, p.velocity.z).length()

func _physics_process(_d: float) -> bool:
	if p == null:
		if current_scene != null:
			p = current_scene.get_node_or_null("Player")
		return false
	f += 1
	match f:
		40:
			results["idle_on_floor"] = st() == "Idle" and p.is_on_floor()
			base_y = p.global_position.y
			Input.action_press("move_forward", 1.0)
		90:
			results["walk"] = "%s %.2f" % [st(), hs()]
			Input.action_press("sprint")
		150:
			results["sprint"] = "%s %.2f posture=%d" % [st(), hs(), p.visual.posture]
			Input.action_release("sprint")
			Input.action_release("move_forward")
		190:
			results["stop"] = "%s %.2f" % [st(), hs()]
			Input.action_press("move_forward", 0.3)
		230:
			results["sneak_analog"] = "%s %.2f sneaking=%s" % [st(), hs(), p.is_sneaking]
			Input.action_release("move_forward")
		255:
			p.global_position = Vector3(0, 0.1, 11)
			p.velocity = Vector3.ZERO
		260:
			base_y = p.global_position.y
			max_y = base_y
			phase = "jump"
			Input.action_press("jump")
		262:
			results["air_state"] = st()
		320:
			Input.action_release("jump")
		330:
			results["single_jump_h"] = "%.2f" % (max_y - base_y)
			results["landed"] = st()
		360:
			base_y = p.global_position.y
			max_y = base_y
			Input.action_press("jump")
		375:
			Input.action_release("jump")
		376:
			Input.action_press("jump")
		377:
			pass
		430:
			Input.action_release("jump")
		460:
			results["double_jump_h"] = "%.2f jumps=%d" % [max_y - base_y, p.jumps_used]
			# short hop: tap
			base_y = p.global_position.y
			max_y = base_y
			Input.action_press("jump")
		463:
			Input.action_release("jump")
		520:
			results["short_hop_h"] = "%.2f" % (max_y - base_y)
			# fall into gap test: teleport near gap edge and walk +x
			p.global_position = Vector3(12.5, 0.1, 0)
			p.velocity = Vector3.ZERO
			p.camera.rig_3d.yaw = -PI / 2.0  # facing +X
			Input.action_press("move_forward", 1.0)
		600:
			results["fell_off"] = "%s y=%.2f" % [st(), p.global_position.y]
		700:
			Input.action_release("move_forward")
			results["respawn"] = "%s pos=%s" % [st(), str(p.global_position.snapped(Vector3(0.1,0.1,0.1)))]
		720:
			for k in results:
				print(k, ": ", results[k])
			quit()
	if p != null:
		max_y = maxf(max_y, p.global_position.y)
	return false
