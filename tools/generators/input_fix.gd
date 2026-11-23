extends SceneTree
func _joy_btn(b: JoyButton) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new(); e.button_index = b; e.device = -1; return e
func _joy_axis(a: JoyAxis, v: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new(); e.axis = a; e.axis_value = v; e.device = -1; return e
func _key(k: Key) -> InputEventKey:
	var e := InputEventKey.new(); e.physical_keycode = k; e.device = -1; return e
func _initialize() -> void:
	# Sprint: Shift / R2 (RT) – pravá strana
	ProjectSettings.set_setting("input/sprint", {"deadzone": 0.3, "events": [_key(KEY_SHIFT), _joy_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)]})
	# Plížení držením: Ctrl (klávesnice)
	ProjectSettings.set_setting("input/sneak", {"deadzone": 0.3, "events": [_key(KEY_CTRL)]})
	# Plížení přepínačem: L3 (stisk levé páčky)
	ProjectSettings.set_setting("input/sneak_toggle", {"deadzone": 0.5, "events": [_joy_btn(JOY_BUTTON_LEFT_STICK)]})
	print(ProjectSettings.save())
	quit()
