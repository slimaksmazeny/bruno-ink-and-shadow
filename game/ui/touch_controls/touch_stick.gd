## Plovoucí virtuální joystick: střed vznikne tam, kam hráč položí prst.
## Výchylku převádí na akce move_* přes Input.action_press – stavy hráče nepoznají rozdíl od páčky.
class_name TouchStick
extends RefCounted

const ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"move_forward", &"move_back"]

var radius: float = 110.0
var finger: int = -1
var origin: Vector2 = Vector2.ZERO
var current: Vector2 = Vector2.ZERO


func is_active() -> bool:
	return finger != -1


func start(index: int, pos: Vector2) -> void:
	finger = index
	origin = pos
	current = pos
	_apply()


func drag(pos: Vector2) -> void:
	current = pos
	# Když prst ujede daleko, střed se „táhne“ za ním (pohodlnější na malém displeji).
	var off: Vector2 = current - origin
	if off.length() > radius * 1.4:
		origin = current - off.normalized() * radius * 1.4
	_apply()


func stop() -> void:
	finger = -1
	current = origin
	for a: StringName in ACTIONS:
		Input.action_release(a)


## Výchylka -1..1 (y dolů = dozadu, stejně jako Input.get_vector).
func value() -> Vector2:
	if finger == -1:
		return Vector2.ZERO
	var v: Vector2 = (current - origin) / radius
	return v.limit_length(1.0)


func _apply() -> void:
	var v: Vector2 = value()
	_press(&"move_left", maxf(-v.x, 0.0))
	_press(&"move_right", maxf(v.x, 0.0))
	_press(&"move_forward", maxf(-v.y, 0.0))
	_press(&"move_back", maxf(v.y, 0.0))


func _press(action: StringName, strength: float) -> void:
	if strength > 0.05:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)
