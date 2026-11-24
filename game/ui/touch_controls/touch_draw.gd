## Kreslení dotykového ovládání (bez textur – greybox styl, barvy podle HUD mockupu).
extends Control

const GOLD := Color(0.95, 0.71, 0.2)
const FILL := Color(0.12, 0.09, 0.25, 0.55)
const FILL_PRESSED := Color(0.35, 0.25, 0.6, 0.75)

@onready var ctl: CanvasLayer = get_parent() as CanvasLayer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _draw() -> void:
	if ctl == null:
		return
	var joy: TouchStick = ctl.get("joystick")
	var vs: Vector2 = get_viewport_rect().size
	# Joystick: když není prst dole, ukáže se „klidová“ pozice vlevo dole.
	var rest := Vector2(vs.x * 0.14, vs.y * 0.74)
	var origin: Vector2 = joy.origin if joy.is_active() else rest
	var knob: Vector2 = origin + joy.value() * joy.radius
	draw_circle(origin, joy.radius, FILL)
	draw_arc(origin, joy.radius, 0.0, TAU, 48, Color(0.75, 0.7, 0.95, 0.6), 3.0)
	draw_circle(knob, joy.radius * 0.42, Color(0.2, 0.17, 0.35, 0.9))
	draw_arc(knob, joy.radius * 0.42, 0.0, TAU, 40, GOLD, 4.0)

	for b: Variant in ctl.get("buttons"):
		_draw_button(b)
	_draw_button(ctl.get("pause_button"))


func _draw_button(b: Variant) -> void:
	var c: Vector2 = b.center
	var r: float = b.radius
	var pressed: bool = b.finger != -1
	if String(b.icon) == "sneak":
		var pl: Player = get_tree().get_first_node_in_group(&"player") as Player
		pressed = pressed or (pl != null and pl.sneak_toggled)
	draw_circle(c, r, FILL_PRESSED if pressed else FILL)
	draw_arc(c, r, 0.0, TAU, 48, GOLD, 4.0)
	var s: float = r * 0.45
	match String(b.icon):
		"cane":
			draw_line(c + Vector2(-s * 0.2, s), c + Vector2(-s * 0.2, -s * 0.3), GOLD, 6.0)
			draw_arc(c + Vector2(s * 0.15, -s * 0.3), s * 0.35, PI, TAU, 16, GOLD, 6.0)
		"jump":
			draw_line(c + Vector2(0, s), c + Vector2(0, -s), GOLD, 6.0)
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s * 1.2), c + Vector2(-s * 0.6, -s * 0.3), c + Vector2(s * 0.6, -s * 0.3)]), GOLD)
		"sprint":
			for k: int in 2:
				var o := Vector2(-s * 0.45 + k * s * 0.7, 0)
				draw_polyline(PackedVector2Array([c + o + Vector2(-s * 0.3, -s * 0.6), c + o + Vector2(s * 0.3, 0), c + o + Vector2(-s * 0.3, s * 0.6)]), GOLD, 6.0)
		"tennis":
			draw_circle(c, s * 0.8, Color(0.75, 0.95, 0.25))
			draw_arc(c + Vector2(-s * 0.8, 0), s * 0.6, -0.9, 0.9, 12, Color(1, 1, 1), 3.0)
			draw_arc(c + Vector2(s * 0.8, 0), s * 0.6, PI - 0.9, PI + 0.9, 12, Color(1, 1, 1), 3.0)
		"sneak":
			# Plížení: dvě šipky dolů nad „zemí“.
			for k: int in 2:
				var o := Vector2(0, -s * 0.55 + k * s * 0.5)
				draw_polyline(PackedVector2Array([c + o + Vector2(-s * 0.6, -s * 0.2), c + o + Vector2(0, s * 0.2), c + o + Vector2(s * 0.6, -s * 0.2)]), GOLD, 5.0)
			draw_line(c + Vector2(-s * 0.8, s * 0.7), c + Vector2(s * 0.8, s * 0.7), GOLD, 5.0)
		"pause":
			draw_rect(Rect2(c + Vector2(-s * 0.55, -s * 0.7), Vector2(s * 0.35, s * 1.4)), GOLD)
			draw_rect(Rect2(c + Vector2(s * 0.2, -s * 0.7), Vector2(s * 0.35, s * 1.4)), GOLD)
