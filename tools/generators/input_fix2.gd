extends SceneTree
func _jb(b: JoyButton) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new(); e.button_index = b; e.device = -1; return e
func _ja(a: JoyAxis, v: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new(); e.axis = a; e.axis_value = v; e.device = -1; return e
func _k(k: Key) -> InputEventKey:
	var e := InputEventKey.new(); e.physical_keycode = k; e.device = -1; return e
func _m(b: MouseButton) -> InputEventMouseButton:
	var e := InputEventMouseButton.new(); e.button_index = b; e.device = -1; return e
func _act(name: String, dz: float, ev: Array) -> void:
	ProjectSettings.set_setting("input/" + name, {"deadzone": dz, "events": ev})
func _initialize() -> void:
	# Přichycení ke kotvě / kontext: ○ (B), E, prostřední tlačítko myši
	_act("action", 0.5, [_k(KEY_E), _m(MOUSE_BUTTON_MIDDLE), _jb(JOY_BUTTON_B)])
	# Hlavní útok holí (když nemíříš): □ (X), levé tlačítko myši, F
	_act("attack", 0.5, [_k(KEY_F), _m(MOUSE_BUTTON_LEFT), _jb(JOY_BUTTON_X)])
	# Míření tenisákem (držet): L2 (LT), pravé tlačítko myši
	_act("aim", 0.3, [_m(MOUSE_BUTTON_RIGHT), _ja(JOY_AXIS_TRIGGER_LEFT, 1.0)])
	# Výstřel tenisáku při míření: R2 (RT), levé tlačítko myši
	_act("fire", 0.3, [_m(MOUSE_BUTTON_LEFT), _ja(JOY_AXIS_TRIGGER_RIGHT, 1.0)])
	# Sprint: Shift, R2 (RT) a navíc R1 (RB) jako ve Slyovi
	_act("sprint", 0.3, [_k(KEY_SHIFT), _ja(JOY_AXIS_TRIGGER_RIGHT, 1.0), _jb(JOY_BUTTON_RIGHT_SHOULDER)])
	# Rychlý odpal bez míření (klávesnice a dotykové tlačítko): Q
	_act("tennis", 0.5, [_k(KEY_Q)])
	print(ProjectSettings.save())
	quit()
