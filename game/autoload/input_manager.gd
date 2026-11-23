## Jediná vrstva nad vstupy, která řeší věci, jež InputMap neumí:
## rozhlížení (myš + páčka + dotyk), detekci posledního zařízení a přepínání dotykového HUD.
## Stavy hráče NIKDY nečtou last_device – ten slouží jen UI (ikonky tlačítek).
extends Node

enum Device { KEYBOARD_MOUSE, GAMEPAD, TOUCH }

signal device_changed(device: Device)
signal touch_controls_toggled(visible: bool)

const JOY_MOTION_THRESHOLD: float = 0.3

var last_device: Device = Device.KEYBOARD_MOUSE
var touch_controls_visible: bool = false
var mouse_sensitivity: float = 0.003
var stick_sensitivity: float = 3.0

var _mouse_look: Vector2 = Vector2.ZERO
var _touch_look: Vector2 = Vector2.ZERO


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_touch_controls(OS.has_feature("mobile"))


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
		if not touch_controls_visible and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
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
	return out


func get_look_stick() -> Vector2:
	return Input.get_vector(&"look_left", &"look_right", &"look_up", &"look_down")


func get_move_vector() -> Vector2:
	return Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")


func set_touch_controls(on: bool) -> void:
	touch_controls_visible = on
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
	elif event is InputEventJoypadMotion:
		if absf((event as InputEventJoypadMotion).axis_value) > JOY_MOTION_THRESHOLD:
			detected = Device.GAMEPAD
	elif event is InputEventKey or event is InputEventMouseButton:
		detected = Device.KEYBOARD_MOUSE
	elif event is InputEventMouseMotion and not Input.emulate_touch_from_mouse:
		detected = Device.KEYBOARD_MOUSE

	if detected != last_device:
		last_device = detected
		device_changed.emit(detected)
