extends SceneTree
var p: Node
var tc: Node
var f: int = 0
var r: Dictionary = {}
var yaw0: float = 0.0
func _initialize() -> void:
	change_scene_to_file("res://levels/greybox/greybox_street.tscn")
func w(pos: Vector2) -> Vector2:
	var vs: Vector2 = tc.get_viewport().get_visible_rect().size
	var ws: Vector2 = Vector2(DisplayServer.window_get_size())
	return pos * ws / vs
func touch(i: int, pos: Vector2, pressed: bool) -> void:
	var e := InputEventScreenTouch.new(); e.index = i; e.position = pos; e.pressed = pressed
	tc._input(e)
func drag(i: int, pos: Vector2, rel: Vector2) -> void:
	var e := InputEventScreenDrag.new(); e.index = i; e.position = pos; e.relative = rel
	tc._input(e)
func _physics_process(_d: float) -> bool:
	if p == null:
		if current_scene != null:
			p = current_scene.get_node_or_null("Player"); tc = root.get_node("/root/TouchControls")
		return false
	f += 1
	var im: Node = root.get_node("/root/InputManager")
	match f:
		4:
			r["viewport"] = str(tc.get_viewport().get_visible_rect().size)
		5:
			r["hidden_by_default"] = not tc.visible
			im.set_touch_controls(true)
			r["shown"] = tc.visible
			r["mouse_action_stripped"] = InputMap.action_get_events("action").filter(func(e): return e is InputEventMouseButton).is_empty()
		10:
			var vs: Vector2 = tc.get_viewport().get_visible_rect().size
			touch(0, Vector2(vs.x * 0.15, vs.y * 0.7), true)
		12:
			var vs: Vector2 = tc.get_viewport().get_visible_rect().size
			drag(0, Vector2(vs.x * 0.15, vs.y * 0.7 - 200), Vector2(0, -200))
		40:
			r["joystick_move"] = "%s speed=%.2f move=%s" % [p.state_machine.current_name(), Vector2(p.velocity.x, p.velocity.z).length(), str(im.get_move_vector().snapped(Vector2(0.01,0.01)))]
			var sb = tc.buttons[2]
			touch(1, sb.center, true)
		70:
			r["sprint_button"] = "%s speed=%.2f" % [p.state_machine.current_name(), Vector2(p.velocity.x, p.velocity.z).length()]
			touch(1, tc.buttons[2].center, false)
			touch(0, Vector2(0, 0), false)
		90:
			r["released"] = "%s move=%s" % [p.state_machine.current_name(), str(im.get_move_vector())]
			touch(2, tc.buttons[1].center, true)
		93:
			touch(2, tc.buttons[1].center, false)
		96:
			r["jump_button"] = "%s vy=%.2f" % [p.state_machine.current_name(), p.velocity.y]
			yaw0 = p.camera.rig_3d.yaw
			var vs: Vector2 = tc.get_viewport().get_visible_rect().size
			touch(3, Vector2(vs.x * 0.6, vs.y * 0.3), true)
			drag(3, Vector2(vs.x * 0.6 + 100, vs.y * 0.3), Vector2(100, 0))
		100:
			touch(3, Vector2(0, 0), false)
			r["look_drag_yaw_change"] = "%.3f" % (p.camera.rig_3d.yaw - yaw0)
			im.set_touch_controls(false)
			r["mouse_action_restored"] = not InputMap.action_get_events("action").filter(func(e): return e is InputEventMouseButton).is_empty()
		105:
			for k in r: print(k, ": ", r[k])
			quit()
	return false
