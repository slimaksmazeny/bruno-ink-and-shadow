## Hlavní menu (hlavní scéna hry). Pokračovat / Nová hra · Nastavení · Ukončit.
extends Control

const FIRST_LEVEL: String = "res://levels/greybox/greybox_street.tscn"

var _menu: VBoxContainer
var _settings: SettingsPanel
var _first: Button
var _t: float = 0.0
var _title: Label


func _ready() -> void:
	theme = UiStyle.make_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	InputManager.release_mouse()
	AudioManager.play_music(&"sneak_loop", 1.5, 0.9)
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.05, 0.13)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var blots := InkBlots.new()
	blots.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(blots)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 28)
	center.add_child(col)
	_title = Label.new()
	_title.text = "Bruno: Ink & Shadow"
	_title.add_theme_font_size_override("font_size", 76)
	_title.add_theme_color_override("font_color", UiStyle.GOLD)
	_title.add_theme_color_override("font_outline_color", Color(0.02, 0.01, 0.05))
	_title.add_theme_constant_override("outline_size", 16)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_title)
	var sub := Label.new()
	sub.text = "UI_MENU_SUBTITLE"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.modulate = Color(1, 1, 1, 0.7)
	col.add_child(sub)

	_menu = VBoxContainer.new()
	_menu.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(_menu)
	if SaveManager.has_save(1):
		_first = _add("UI_MENU_CONTINUE", _on_continue)
		_add("UI_MENU_NEW_GAME", _on_new_game)
	else:
		_first = _add("UI_MENU_PLAY", _on_new_game)
	_add("UI_MENU_SETTINGS", _on_settings)
	if OS.get_name() not in ["Web", "iOS"]:
		_add("UI_MENU_QUIT", func() -> void: get_tree().quit())

	_settings = SettingsPanel.new()
	_settings.visible = false
	_settings.closed.connect(func() -> void:
		_menu.visible = true
		_first.grab_focus.call_deferred())
	col.add_child(_settings)

	var ver := Label.new()
	ver.text = "v%s · %s" % [str(ProjectSettings.get_setting("application/config/version", "0.0.0")), tr("UI_MENU_HINT")]
	ver.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	ver.position = Vector2(20, -44)
	ver.modulate = Color(1, 1, 1, 0.45)
	ver.add_theme_font_size_override("font_size", 18)
	add_child(ver)
	_first.grab_focus.call_deferred()


func _process(delta: float) -> void:
	_t += delta
	_title.pivot_offset = _title.size * 0.5
	_title.rotation = sin(_t * 0.9) * 0.015
	_title.scale = Vector2.ONE * (1.0 + sin(_t * 1.7) * 0.012)


func start_game() -> void:
	await InkWipe.cover(0.35)
	get_tree().change_scene_to_file(FIRST_LEVEL)
	await InkWipe.reveal(0.4)


func _on_new_game() -> void:
	GameState.reset()
	start_game()


func _on_continue() -> void:
	if SaveManager.load_game(1):
		GameState.resume_checkpoint = str(GameState.data.get("progress", {}).get("last_checkpoint", ""))
	else:
		GameState.reset()
	start_game()


func _on_settings() -> void:
	_menu.visible = false
	_settings.open()


func _add(key: String, cb: Callable) -> Button:
	var b := UiStyle.make_button(key)
	b.pressed.connect(cb)
	_menu.add_child(b)
	return b


## Pomalu se vlnící inkoustové skvrny v pozadí.
class InkBlots extends Control:
	var _t: float = 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var s: Vector2 = size
		for i: int in 7:
			var fi: float = float(i)
			var p := Vector2(s.x * fmod(0.13 + fi * 0.17, 1.0), s.y * fmod(0.2 + fi * 0.31, 1.0))
			p += Vector2(sin(_t * 0.3 + fi), cos(_t * 0.25 + fi * 1.3)) * 30.0
			var r: float = 90.0 + 50.0 * sin(_t * 0.4 + fi * 2.0)
			draw_circle(p, r, Color(0.12, 0.08, 0.3, 0.35))
			draw_circle(p + Vector2(r * 0.5, -r * 0.3), r * 0.35, Color(0.18, 0.1, 0.4, 0.3))
