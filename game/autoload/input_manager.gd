## Jediná vrstva nad vstupy, která řeší věci, jež InputMap neumí:
## rozhlížení (myš + páčka + dotyk), detekci posledního zařízení a přepínání dotykového HUD.
## Stavy hráče NIKDY nečtou last_device – ten slouží jen UI (ikonky tlačítek).
extends Node

enum Device { KEYBOARD_MOUSE, GAMEPAD, TOUCH }
## Rodina ovladače – jen pro ikonky tlačítek v UI (✕○△□ vs. A B X Y). Mapování tlačítek je pro všechny stejné:
## ✕ = A (skok), ○ = B (hůl), △ = Y (tenisák), R2 = RT (sprint), L3 = stisk levé páčky (plížení přepínačem), Options = Menu (pauza).
enum PadFamily { NONE, XBOX, PLAYSTATION, NINTENDO, GENERIC }

signal device_changed(device: Device)
signal pad_family_changed(family: PadFamily)
signal touch_controls_toggled(visible: bool)

const JOY_MOTION_THRESHOLD: float = 0.3

var last_device: Device = Device.KEYBOARD_MOUSE
var pad_family: PadFamily = PadFamily.NONE
var pad_name: String = ""
var touch_controls_visible: bool = false
var mouse_sensitivity: float = 0.003
var stick_sensitivity: float = 3.0
## Obrácená svislá osa kamery (nastavuje Settings).
var invert_y: bool = false

var _mouse_look: Vector2 = Vector2.ZERO
## Akce navázané na tlačítka myši, dočasně odebrané, když je zapnutý dotykový HUD.
var _stripped_mouse_events: Dictionary = {}
var _touch_look: Vector2 = Vector2.ZERO


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_touch_controls(OS.has_feature("mobile"))
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	var pads: Array[int] = Input.get_connected_joypads()
	if not pads.is_empty():
		_set_active_pad(pads[0])


func _input(event: InputEvent) -> void:
	_track_device(event)

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_mouse_look += (event as InputEventMouseMotion).relative

	if event.is_action_pressed(&"debug_toggle_touch") and OS.is_debug_build():
		set_touch_controls(not touch_controls_visible)
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed(&"pause") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		release_mouse()


func _unhandled_input(event: InputEvent) -> void:
	# Kliknutí do hry zachytí kurzor (jen na PC a jen když není zapnutý dotykový HUD).
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		var in_game: bool = not get_tree().paused and get_tree().get_first_node_in_group(&"player") != null
		if in_game and not touch_controls_visible and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			capture_mouse()


## Dotykové rozhlížení posílá ui/touch_controls (Krok D).
func add_touch_look(relative: Vector2) -> void:
	_touch_look += relative


## Jediný zdroj rozhlížení pro ThirdPersonRig (Krok B). Po přečtení se vynuluje.
func consume_look(delta: float) -> Vector2:
	var stick: Vector2 = get_look_stick()
	var out: Vector2 = (_mouse_look + _touch_look) * mouse_sensitivity + stick * stick_sensitivity * delta
	_mouse_look = Vector2.ZERO
	_touch_look = Vector2.ZERO
	if invert_y:
		out.y = -out.y
	return out


func get_look_stick() -> Vector2:
	return Input.get_vector(&"look_left", &"look_right", &"look_up", &"look_down")


func get_move_vector() -> Vector2:
	return Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")


func set_touch_controls(on: bool) -> void:
	touch_controls_visible = on
	# S dotykovým HUD nesmí klik/dotyk zároveň spouštět akce navázané na tlačítka myši.
	_set_mouse_bindings_enabled(not on)
	if not OS.has_feature("mobile"):
		# Na PC se myš začne chovat jako prst, aby šel dotykový HUD testovat.
		Input.emulate_touch_from_mouse = on
		if on:
			release_mouse()
	touch_controls_toggled.emit(on)


func capture_mouse() -> void:
	if OS.has_feature("mobile"):
		return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func release_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_mouse_look = Vector2.ZERO


func device_name(device: Device) -> String:
	match device:
		Device.GAMEPAD:
			return "Gamepad"
		Device.TOUCH:
			return "Touch"
		_:
			return "Keyboard + Mouse"


func _track_device(event: InputEvent) -> void:
	var detected: Device = last_device
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		detected = Device.TOUCH
	elif event is InputEventJoypadButton:
		detected = Device.GAMEPAD
		_set_active_pad(event.device)
	elif event is InputEventJoypadMotion:
		if absf((event as InputEventJoypadMotion).axis_value) > JOY_MOTION_THRESHOLD:
			detected = Device.GAMEPAD
			_set_active_pad(event.device)
	elif event is InputEventKey or event is InputEventMouseButton:
		detected = Device.KEYBOARD_MOUSE
	elif event is InputEventMouseMotion and not Input.emulate_touch_from_mouse:
		detected = Device.KEYBOARD_MOUSE

	if detected != last_device:
		last_device = detected
		device_changed.emit(detected)


func pad_family_name(family: PadFamily) -> String:
	match family:
		PadFamily.PLAYSTATION:
			return "PlayStation"
		PadFamily.XBOX:
			return "Xbox"
		PadFamily.NINTENDO:
			return "Nintendo"
		PadFamily.GENERIC:
			return "Generic"
		_:
			return "-"


## Rozpozná rodinu ovladače podle názvu, který hlásí systém (SDL databáze v Godotu).
static func classify_pad(joy_name: String) -> PadFamily:
	var n: String = joy_name.to_lower()
	for key: String in ["ps4", "ps5", "ps3", "dualshock", "dualsense", "playstation", "sony", "wireless controller"]:
		if n.contains(key):
			return PadFamily.PLAYSTATION
	for key: String in ["xbox", "xinput", "microsoft", "x-box"]:
		if n.contains(key):
			return PadFamily.XBOX
	for key: String in ["nintendo", "switch", "pro controller", "joy-con"]:
		if n.contains(key):
			return PadFamily.NINTENDO
	return PadFamily.GENERIC


func _set_active_pad(device_id: int) -> void:
	var joy_name: String = Input.get_joy_name(device_id)
	var family: PadFamily = classify_pad(joy_name)
	pad_name = joy_name
	if family != pad_family:
		pad_family = family
		pad_family_changed.emit(family)


func _on_joy_connection_changed(device_id: int, connected: bool) -> void:
	if connected:
		_set_active_pad(device_id)
	else:
		var pads: Array[int] = Input.get_connected_joypads()
		if pads.is_empty():
			pad_name = ""
			pad_family = PadFamily.NONE
			pad_family_changed.emit(pad_family)
		else:
			_set_active_pad(pads[0])


func _set_mouse_bindings_enabled(enabled: bool) -> void:
	if enabled:
		for action: StringName in _stripped_mouse_events:
			for e: InputEvent in _stripped_mouse_events[action]:
				if InputMap.has_action(action):
					InputMap.action_add_event(action, e)
		_stripped_mouse_events.clear()
		return
	for action: StringName in InputMap.get_actions():
		if String(action).begins_with("ui_"):
			continue
		for e: InputEvent in InputMap.action_get_events(action):
			if e is InputEventMouseButton:
				if not _stripped_mouse_events.has(action):
					_stripped_mouse_events[action] = []
				(_stripped_mouse_events[action] as Array).append(e)
				InputMap.action_erase_event(action, e)
				Input.action_release(action)
