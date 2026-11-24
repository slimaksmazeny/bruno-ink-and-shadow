## Dotykové ovládání (mobil; na PC přepínač M). Zpracovává multi-touch na jednom místě:
## levá polovina = plovoucí joystick, tlačítka vpravo dole = akce, zbytek pravé poloviny = rozhlížení.
## Tlačítka jen mačkají akce z InputMap – stavy hráče nečtou dotyk napřímo.
extends CanvasLayer

class TouchButton:
	var action: StringName
	var icon: String
	var center: Vector2
	var radius: float
	var finger: int = -1

	func _init(a: StringName, i: String) -> void:
		action = a
		icon = i

	func hit(pos: Vector2) -> bool:
		return pos.distance_to(center) <= radius * 1.15

var joystick := TouchStick.new()
var buttons: Array[TouchButton] = []
var pause_button: TouchButton
var _look_finger: int = -1

@onready var canvas: Control = $Canvas


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Rozložení podle mockupu vis/ui_hud_mockup_v01.png: [hůl, skok] / [sprint, tenisák]
	buttons = [
		TouchButton.new(&"action", "cane"),
		TouchButton.new(&"jump", "jump"),
		TouchButton.new(&"sprint", "sprint"),
		TouchButton.new(&"tennis", "tennis"),
		TouchButton.new(&"sneak_toggle", "sneak"),
	]
	pause_button = TouchButton.new(&"pause", "pause")
	InputManager.touch_controls_toggled.connect(_on_toggled)
	get_viewport().size_changed.connect(_layout)
	_layout()
	_on_toggled(InputManager.touch_controls_visible)


func _on_toggled(on: bool) -> void:
	visible = on
	if not on:
		_release_all()
	canvas.queue_redraw()


func _layout() -> void:
	var size: Vector2 = get_viewport().get_visible_rect().size
	var r: float = clampf(size.y * 0.065, 48.0, 90.0)
	var gap: float = r * 2.35
	var base := Vector2(size.x - r * 1.6 - gap, size.y - r * 1.6 - gap)
	buttons[0].center = base                                  # hůl
	buttons[1].center = base + Vector2(gap, 0.0)              # skok
	buttons[2].center = base + Vector2(0.0, gap)              # sprint
	buttons[3].center = base + Vector2(gap, gap)              # tenisák
	buttons[4].center = base + Vector2(-gap * 0.95, gap * 0.5)  # plížení (přepínač – i plazení)
	for b: TouchButton in buttons:
		b.radius = r
	buttons[4].radius = r * 0.8
	pause_button.center = Vector2(size.x - r * 0.9, r * 0.9)
	pause_button.radius = r * 0.55
	joystick.radius = clampf(size.y * 0.11, 70.0, 150.0)
	if canvas != null:
		canvas.queue_redraw()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			_touch_down(t.index, t.position)
		else:
			_touch_up(t.index)
		canvas.queue_redraw()
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index == joystick.finger:
			joystick.drag(d.position)
			canvas.queue_redraw()
		elif d.index == _look_finger:
			InputManager.add_touch_look(d.relative)


func _touch_down(index: int, pos: Vector2) -> void:
	for b: TouchButton in buttons + [pause_button]:
		if b.finger == -1 and b.hit(pos):
			b.finger = index
			Input.action_press(b.action)
			return
	var size: Vector2 = get_viewport().get_visible_rect().size
	if pos.x < size.x * 0.45 and not joystick.is_active():
		joystick.start(index, pos)
	elif _look_finger == -1:
		_look_finger = index


func _touch_up(index: int) -> void:
	for b: TouchButton in buttons + [pause_button]:
		if b.finger == index:
			b.finger = -1
			Input.action_release(b.action)
	if index == joystick.finger:
		joystick.stop()
	if index == _look_finger:
		_look_finger = -1


func _release_all() -> void:
	for b: TouchButton in buttons + [pause_button]:
		if b.finger != -1:
			b.finger = -1
			Input.action_release(b.action)
	if joystick.is_active():
		joystick.stop()
	_look_finger = -1
