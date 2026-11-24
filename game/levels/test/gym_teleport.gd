## Tréninkové hřiště: rychlý přesun mezi stanovišti. Klávesy 1–9, ovladač D-pad ←/→.
## Stanoviště = děti tohoto uzlu (Marker3D) v pořadí; jméno se ukáže jako hláška.
extends Node3D

var _index: int = 0


func _unhandled_input(event: InputEvent) -> void:
	var target: int = -1
	if event is InputEventKey and event.pressed and not event.echo:
		var ke := event as InputEventKey
		# Fyzická klávesa (nezávislá na rozložení), jinak záložně logická (i numpad).
		var k: int = ke.physical_keycode if ke.physical_keycode != KEY_NONE else ke.keycode
		if k >= KEY_KP_0 and k <= KEY_KP_9:
			k = KEY_0 + (k - KEY_KP_0)
		if k >= KEY_1 and k <= KEY_9:
			target = k - KEY_1
		elif k == KEY_0:
			target = 9
	elif event is InputEventJoypadButton and event.pressed:
		var b: int = (event as InputEventJoypadButton).button_index
		if b == JOY_BUTTON_DPAD_RIGHT:
			target = (_index + 1) % get_child_count()
		elif b == JOY_BUTTON_DPAD_LEFT:
			target = (_index - 1 + get_child_count()) % get_child_count()
	if target >= 0 and target < get_child_count():
		go_to(target)
		get_viewport().set_input_as_handled()


func go_to(i: int) -> void:
	var m: Node3D = get_child(i) as Node3D
	var p: Player = get_tree().get_first_node_in_group(&"player") as Player
	if m == null or p == null:
		return
	_index = i
	p.global_position = m.global_position
	p.velocity = Vector3.ZERO
	p.reset_physics_interpolation()
	p.state_machine.transition_to(&"Idle", {"force": true})
	p.set_checkpoint(m.global_transform)
	if p.camera != null:
		p.camera.rig_3d.snap_behind(-m.global_transform.basis.z)
	var hud: Hud = get_tree().get_first_node_in_group(&"hud") as Hud
	if hud != null:
		hud.show_toast("%d · %s" % [i + 1, String(m.name).replace("_", " ")])
	AudioManager.play(&"portal", -6.0, 1.4)
