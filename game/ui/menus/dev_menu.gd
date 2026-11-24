## Vývojářské menu (autoload) – F1 nebo ovladač Select/Back. Jen pro testování.
## Levely, teleport (checkpointy, stanoviště hřiště, start), cheaty (nesmrtelnost, létání,
## zpomalení), věci (klíč, mince, životy), mise a uložená hra.
extends CanvasLayer

const LEVELS: Array[Array] = [
	["Ulice (kap. 1)", "res://levels/greybox/greybox_street.tscn"],
	["Kaňon (kap. 2)", "res://levels/ch2_canyon/canyon.tscn"],
	["Tréninkové hřiště", "res://levels/test/gym.tscn"],
	["Hlavní menu", "res://ui/menus/main_menu.tscn"],
]

var is_open: bool = false
var god_mode: bool = false
var _root: Control
var _list: VBoxContainer
var _info: Label
var _slow: bool = false


func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = UiStyle.make_theme()
	_root.visible = false
	add_child(_root)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	panel.custom_minimum_size = Vector2(430, 0)
	panel.offset_right = 430
	_root.add_child(panel)
	var col := VBoxContainer.new()
	panel.add_child(col)
	var title := Label.new()
	title.text = "DEV MENU  (F1 / Select)"
	title.add_theme_color_override("font_color", UiStyle.GOLD)
	title.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	col.add_child(title)
	_info = Label.new()
	_info.add_theme_font_size_override("font_size", 18)
	_info.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	col.add_child(_info)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_list)


func _input(event: InputEvent) -> void:
	var toggle: bool = false
	if event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).physical_keycode == KEY_F1:
		toggle = true
	elif event is InputEventJoypadButton and event.pressed and (event as InputEventJoypadButton).button_index == JOY_BUTTON_BACK:
		toggle = true
	if toggle:
		if is_open:
			close()
		else:
			open()
		get_viewport().set_input_as_handled()
	elif is_open and event.is_action_pressed(&"ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if not is_open:
		return
	var p: Player = _player()
	var pos: String = "%.1f, %.1f, %.1f" % [p.global_position.x, p.global_position.y, p.global_position.z] if p != null else "–"
	var scene: String = get_tree().current_scene.scene_file_path.get_file() if get_tree().current_scene != null else "–"
	_info.text = "%s · %s\nstav: %s · FPS %d" % [scene, pos, String(p.state_machine.current.name) if p != null else "–", Engine.get_frames_per_second()]


func open() -> void:
	is_open = true
	_root.visible = true
	_rebuild()
	get_tree().paused = true
	InputManager.release_mouse()


func close() -> void:
	is_open = false
	_root.visible = false
	if not PauseMenu.is_open:
		get_tree().paused = false
	if _player() != null and not InputManager.touch_controls_visible and OS.get_name() not in ["Android", "iOS"]:
		InputManager.capture_mouse()


func _player() -> Player:
	return get_tree().get_first_node_in_group(&"player") as Player


func _rebuild() -> void:
	for c: Node in _list.get_children():
		c.queue_free()
	_header("Levely")
	for lv: Array in LEVELS:
		var path: String = String(lv[1])
		_btn(String(lv[0]), func() -> void: _load_level(path))
	var p: Player = _player()
	if p != null:
		_header("Teleport")
		_btn("Start levelu", func() -> void: _teleport(p.level_start, true))
		for n: Node in get_tree().get_nodes_in_group(&"checkpoint"):
			var cp: Checkpoint = n as Checkpoint
			_btn("Checkpoint: " + cp.checkpoint_id, func() -> void:
				if cp.plane_2d:
					cp.call("_restore")
				else:
					_teleport(cp.global_position + Vector3.UP * 0.1, false))
		var st: Node = get_tree().current_scene.get_node_or_null("Stations")
		if st != null:
			for i: int in st.get_child_count():
				var idx: int = i
				_btn("%d · %s" % [i + 1, String(st.get_child(i).name).replace("_", " ")], func() -> void:
					close()
					st.call("go_to", idx))
		var vault: Node3D = get_tree().get_first_node_in_group(&"vault") as Node3D
		if vault != null:
			_btn("K trezoru", func() -> void: _teleport(vault.global_position - vault.global_transform.basis.z * 1.3, false))
		_header("Cheaty")
		_toggle("Nesmrtelnost", god_mode, func(on: bool) -> void: god_mode = on)
		_toggle("Létání (WASD, skok = nahoru, Ctrl = dolů)", p.fly_mode, func(on: bool) -> void: p.set_fly_mode(on))
		_toggle("Zpomalení 0,25×", _slow, func(on: bool) -> void:
			_slow = on
			Engine.time_scale = 0.25 if on else 1.0)
		_header("Věci")
		_btn("Doplnit životy", func() -> void: p.heal(p.max_health))
		_btn("Ubrat život", func() -> void:
			p.set("_invulnerable", 0.0)
			p.take_damage(1, p.global_position + Vector3.FORWARD))
		_btn("+100 mincí", func() -> void: GameState.add_coins(100))
		var m: Mission = get_tree().get_first_node_in_group(&"mission") as Mission
		if m != null:
			_btn("Dát klíč od trezoru", func() -> void: GameState.add_key(m.key_id))
			_btn("Mise: další krok", func() -> void: _advance_mission(m))
		_btn("Sebrat všechny kapky", func() -> void:
			for d: Node in get_tree().get_nodes_in_group(&"ink_drop"):
				var drop: InkDrop = d as InkDrop
				if not drop.collected:
					drop.call("_on_body_entered", p))
		_header("Strážní")
		_btn("Spustit poplach (všichni)", func() -> void:
			for g: Node in get_tree().get_nodes_in_group(&"guard"):
				(g as Guard).investigate(p.global_position))
		_btn("Uspat všechny strážné", func() -> void:
			for g: Node in get_tree().get_nodes_in_group(&"guard"):
				(g as Guard).on_cane_hit({"damage": 99}))
	_header("Hra")
	_btn("Komiksový vzhled zap/vyp", func() -> void: Settings.set_comic_shading(not Settings.comic_shading))
	_btn("Smazat uloženou hru", func() -> void:
		GameState.reset()
		SaveManager.save_game())
	_btn("Zavřít", close)
	if _list.get_child_count() > 1:
		(_list.get_child(1) as Control).grab_focus.call_deferred()


func _teleport(pos: Vector3, _is_start: bool) -> void:
	var p: Player = _player()
	if p == null:
		return
	close()
	if p.mode == Player.Mode.MODE_2D:
		p.enter_3d()
		if p.camera != null:
			p.camera.blend = 0.0
	p.global_position = pos
	p.velocity = Vector3.ZERO
	p.reset_physics_interpolation()
	p.state_machine.transition_to(&"Idle", {"force": true})
	if p.camera != null:
		p.camera.snap_to_target()


func _advance_mission(m: Mission) -> void:
	match m.step:
		Mission.Step.STEAL_KEY:
			GameState.add_key(m.key_id)
		Mission.Step.OPEN_VAULT:
			m.notify(&"vault_opened")
		Mission.Step.TAKE_TREASURE:
			m.notify(&"treasure_taken")
		Mission.Step.ESCAPE:
			close()
			m.notify(&"escaped")


func _load_level(path: String) -> void:
	close()
	Engine.time_scale = 1.0
	_slow = false
	get_tree().change_scene_to_file(path)


func _header(text: String) -> void:
	var l := Label.new()
	l.text = "— " + text + " —"
	l.add_theme_color_override("font_color", UiStyle.GOLD)
	l.add_theme_font_size_override("font_size", 20)
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_list.add_child(l)


func _btn(text: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	b.custom_minimum_size = Vector2(380, 40)
	b.add_theme_font_size_override("font_size", 19)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.pressed.connect(cb)
	_list.add_child(b)


func _toggle(text: String, on: bool, cb: Callable) -> void:
	var c := CheckButton.new()
	c.text = text
	c.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	c.button_pressed = on
	c.add_theme_font_size_override("font_size", 19)
	c.toggled.connect(cb)
	_list.add_child(c)
