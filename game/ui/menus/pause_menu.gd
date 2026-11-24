## Pauza (autoload). Esc / Start / dotykové ⏸ během hry.
## Pokračovat · Zpět na checkpoint · Nastavení · Hlavní menu · Ukončit.
extends CanvasLayer

const MAIN_MENU: String = "res://ui/menus/main_menu.tscn"

var is_open: bool = false
var _root: Control
var _menu: PanelContainer
var _settings: SettingsPanel
var _first: Button


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = UiStyle.make_theme()
	_root.visible = false
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.01, 0.06, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)
	_menu = PanelContainer.new()
	center.add_child(_menu)
	var box := VBoxContainer.new()
	_menu.add_child(box)
	var title := Label.new()
	title.text = "UI_PAUSE_TITLE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", UiStyle.GOLD)
	box.add_child(title)
	_first = _add(box, "UI_MENU_CONTINUE", close)
	_add(box, "UI_PAUSE_CHECKPOINT", _on_checkpoint)
	_add(box, "UI_MENU_SETTINGS", _on_settings)
	_add(box, "UI_PAUSE_MAIN_MENU", _on_main_menu)
	if OS.get_name() not in ["Web", "iOS"]:
		_add(box, "UI_MENU_QUIT", func() -> void: get_tree().quit())
	_settings = SettingsPanel.new()
	_settings.visible = false
	_settings.closed.connect(_on_settings_closed)
	center.add_child(_settings)


func _input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"pause") or event.is_echo():
		return
	if is_open:
		if _settings.visible:
			return # nastavení zavře ui_cancel / Zpět
		close()
	elif _in_gameplay():
		open()
	get_viewport().set_input_as_handled()


func open() -> void:
	is_open = true
	_root.visible = true
	_menu.visible = true
	_settings.visible = false
	get_tree().paused = true
	InputManager.release_mouse()
	AudioManager.play(&"ui_accept", 0.0, 0.8, 0.0)
	_first.grab_focus.call_deferred()


func close() -> void:
	if not is_open:
		return
	is_open = false
	_root.visible = false
	get_tree().paused = false
	if not InputManager.touch_controls_visible and OS.get_name() not in ["Android", "iOS"]:
		InputManager.capture_mouse()


func _in_gameplay() -> bool:
	return get_tree().get_first_node_in_group(&"player") != null and not InkWipe.is_covered()


func _on_checkpoint() -> void:
	close()
	var p: Player = get_tree().get_first_node_in_group(&"player") as Player
	if p != null:
		p.respawn(false)


func _on_settings() -> void:
	_menu.visible = false
	_settings.open()


func _on_settings_closed() -> void:
	_menu.visible = true
	_first.grab_focus.call_deferred()


func _on_main_menu() -> void:
	close()
	InputManager.release_mouse()
	await InkWipe.cover(0.3)
	get_tree().change_scene_to_file(MAIN_MENU)
	await InkWipe.reveal(0.35)


func _add(parent: Control, key: String, cb: Callable) -> Button:
	var b := UiStyle.make_button(key)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b
