## Panel nastavení (hlavní menu i pauza): hlasitosti, citlivost myši, jazyk, dotykové ovládání.
## Texty jsou překladové klíče → Godot je přeloží sám a při změně jazyka je obnoví.
class_name SettingsPanel
extends PanelContainer

signal closed

var _first: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var box := VBoxContainer.new()
	add_child(box)
	var title := Label.new()
	title.text = "UI_MENU_SETTINGS"
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", UiStyle.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	_first = _slider(box, "UI_SETTINGS_MASTER", Settings.master_volume, func(v: float) -> void: Settings.set_volume("master", v))
	_slider(box, "UI_SETTINGS_MUSIC", Settings.music_volume, func(v: float) -> void: Settings.set_volume("music", v))
	_slider(box, "UI_SETTINGS_SFX", Settings.sfx_volume, func(v: float) -> void:
		Settings.set_volume("sfx", v)
		AudioManager.play(&"ui_move", 0.0, 1.0, 0.0))
	var sens: float = inverse_lerp(0.0005, 0.008, Settings.mouse_sensitivity)
	_slider(box, "UI_SETTINGS_MOUSE", sens, func(v: float) -> void: Settings.set_mouse_sensitivity(lerpf(0.0005, 0.008, v)))

	var lang := UiStyle.make_button("UI_SETTINGS_LANGUAGE_BUTTON")
	lang.pressed.connect(Settings.cycle_locale)
	box.add_child(lang)
	var comic := CheckButton.new()
	comic.text = "UI_SETTINGS_COMIC"
	comic.button_pressed = Settings.comic_shading
	comic.toggled.connect(Settings.set_comic_shading)
	box.add_child(comic)
	var touch := CheckButton.new()
	touch.text = "UI_SETTINGS_TOUCH"
	touch.button_pressed = InputManager.touch_controls_visible
	touch.toggled.connect(func(on: bool) -> void: InputManager.set_touch_controls(on))
	box.add_child(touch)
	var back := UiStyle.make_button("UI_BACK")
	back.pressed.connect(_close)
	box.add_child(back)


func open() -> void:
	visible = true
	if _first != null:
		_first.grab_focus.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()


func _close() -> void:
	AudioManager.play(&"ui_back", 0.0, 1.0, 0.0)
	visible = false
	closed.emit()


func _slider(parent: Control, key: String, value: float, on_change: Callable) -> HSlider:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var l := Label.new()
	l.text = key
	l.custom_minimum_size.x = 230
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = value
	s.custom_minimum_size = Vector2(300, 32)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.value_changed.connect(on_change)
	row.add_child(s)
	parent.add_child(row)
	return s
