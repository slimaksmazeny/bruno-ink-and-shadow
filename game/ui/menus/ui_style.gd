## Společný vzhled menu (inkoustový panel, zlatý okraj při výběru).
## Zatím vše z kódu – později se nahradí opravdovým Theme .tres od grafika.
class_name UiStyle
extends RefCounted

const INK: Color = Color(0.05, 0.04, 0.12, 0.92)
const INK_LIGHT: Color = Color(0.14, 0.11, 0.26, 0.95)
const GOLD: Color = Color(0.95, 0.71, 0.2)
const PAPER: Color = Color(0.96, 0.93, 0.84)


static func make_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 26
	var normal := _box(INK, Color(0.3, 0.26, 0.45), 2)
	var hover := _box(INK_LIGHT, GOLD, 3)
	var pressed := _box(Color(0.25, 0.2, 0.4), GOLD, 3)
	for type: String in ["Button", "CheckButton"]:
		t.set_stylebox("normal", type, normal)
		t.set_stylebox("hover", type, hover)
		t.set_stylebox("focus", type, hover)
		t.set_stylebox("pressed", type, pressed)
		t.set_color("font_color", type, PAPER)
		t.set_color("font_hover_color", type, GOLD)
		t.set_color("font_focus_color", type, GOLD)
		t.set_color("font_pressed_color", type, GOLD)
	t.set_stylebox("panel", "PanelContainer", _box(INK, GOLD, 2, 14))
	t.set_color("font_color", "Label", PAPER)
	t.set_constant("separation", "VBoxContainer", 12)
	var grab := _box(GOLD, GOLD, 0, 8)
	t.set_stylebox("slider", "HSlider", _box(Color(0.2, 0.17, 0.32), Color(0, 0, 0, 0), 0, 4))
	t.set_stylebox("grabber_area", "HSlider", grab)
	t.set_stylebox("grabber_area_highlight", "HSlider", grab)
	return t


static func make_button(text_key: String, min_width: float = 360.0) -> Button:
	var b := Button.new()
	b.text = text_key
	b.custom_minimum_size = Vector2(min_width, 58)
	b.focus_entered.connect(func() -> void: AudioManager.play(&"ui_move", -4.0, 1.0, 0.0))
	b.pressed.connect(func() -> void: AudioManager.play(&"ui_accept", 0.0, 1.0, 0.0))
	return b


static func _box(bg: Color, border: Color, width: int, radius: int = 10) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 18
	s.content_margin_right = 18
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s
