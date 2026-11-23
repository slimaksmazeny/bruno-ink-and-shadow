## Generátor Kroku A: nastaví ProjectSettings (InputMap, renderer, fyzika, lokalizace…)
## a vytvoří scény přes Godot API, aby byl formát souborů 100% platný pro Godot 4.7.
## Spuštění: godot --headless --path game --script /home/claude/tools/build_step_a.gd
extends SceneTree


func _initialize() -> void:
	_setup_project_settings()
	_setup_input_map()
	var err: Error = ProjectSettings.save()
	print("ProjectSettings.save -> ", err)
	_build_debug_overlay()
	_build_greybox_street()
	quit()


# ------------------------------------------------------------------ settings
func _setup_project_settings() -> void:
	var s: Dictionary = {
		"display/window/size/viewport_width": 1920,
		"display/window/size/viewport_height": 1080,
		"display/window/size/window_width_override": 1600,
		"display/window/size/window_height_override": 900,
		"display/window/stretch/mode": "canvas_items",
		"display/window/stretch/aspect": "expand",
		"display/window/handheld/orientation": 4, # sensor landscape
		"physics/3d/physics_engine": "Jolt Physics",
		"physics/common/physics_ticks_per_second": 60,
		"physics/common/physics_interpolation": true,
		"rendering/renderer/rendering_method": "forward_plus",
		"rendering/renderer/rendering_method.mobile": "mobile",
		"rendering/textures/canvas_textures/default_texture_filter": 1,
		"internationalization/locale/translations": PackedStringArray([
			"res://localization/translations.cs.translation",
			"res://localization/translations.en.translation",
		]),
		"internationalization/locale/fallback": "en",
		"debug/gdscript/warnings/untyped_declaration": 1,
		"input_devices/pointing/emulate_touch_from_mouse": false,
		"layer_names/3d_physics/layer_1": "world",
		"layer_names/3d_physics/layer_2": "player",
		"layer_names/3d_physics/layer_3": "enemies",
		"layer_names/3d_physics/layer_4": "anchors",
		"layer_names/3d_physics/layer_5": "props",
		"layer_names/3d_physics/layer_6": "projectiles",
		"layer_names/3d_physics/layer_7": "triggers",
		"layer_names/3d_physics/layer_8": "one_way_2d",
	}
	for key: String in s:
		ProjectSettings.set_setting(key, s[key])


# ------------------------------------------------------------------ input map
func _key(physical: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = physical
	e.device = -1
	return e


func _mouse(button: MouseButton) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = button
	e.device = -1
	return e


func _joy_btn(button: JoyButton) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = button
	e.device = -1
	return e


func _joy_axis(axis: JoyAxis, dir: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = dir
	e.device = -1
	return e


func _action(name: String, deadzone: float, events: Array) -> void:
	ProjectSettings.set_setting("input/" + name, {"deadzone": deadzone, "events": events})


func _setup_input_map() -> void:
	# Pohyb (fyzické klávesy → WASD funguje i na české QWERTZ klávesnici)
	_action("move_left", 0.2, [_key(KEY_A), _key(KEY_LEFT), _joy_axis(JOY_AXIS_LEFT_X, -1.0)])
	_action("move_right", 0.2, [_key(KEY_D), _key(KEY_RIGHT), _joy_axis(JOY_AXIS_LEFT_X, 1.0)])
	_action("move_forward", 0.2, [_key(KEY_W), _key(KEY_UP), _joy_axis(JOY_AXIS_LEFT_Y, -1.0)])
	_action("move_back", 0.2, [_key(KEY_S), _key(KEY_DOWN), _joy_axis(JOY_AXIS_LEFT_Y, 1.0)])
	# Rozhlížení pravou páčkou (myš řeší InputManager)
	_action("look_left", 0.15, [_joy_axis(JOY_AXIS_RIGHT_X, -1.0)])
	_action("look_right", 0.15, [_joy_axis(JOY_AXIS_RIGHT_X, 1.0)])
	_action("look_up", 0.15, [_joy_axis(JOY_AXIS_RIGHT_Y, -1.0)])
	_action("look_down", 0.15, [_joy_axis(JOY_AXIS_RIGHT_Y, 1.0)])
	# Akce (Xbox A/B/Y/LB = PS ✕/○/△/L1)
	_action("jump", 0.5, [_key(KEY_SPACE), _joy_btn(JOY_BUTTON_A)])
	_action("sprint", 0.5, [_key(KEY_SHIFT), _joy_btn(JOY_BUTTON_LEFT_SHOULDER), _joy_btn(JOY_BUTTON_LEFT_STICK)])
	_action("action", 0.5, [_key(KEY_E), _mouse(MOUSE_BUTTON_LEFT), _joy_btn(JOY_BUTTON_B)])
	_action("tennis", 0.5, [_key(KEY_Q), _mouse(MOUSE_BUTTON_RIGHT), _joy_btn(JOY_BUTTON_Y)])
	_action("sneak", 0.3, [_key(KEY_CTRL), _joy_axis(JOY_AXIS_TRIGGER_LEFT, 1.0)])
	_action("pause", 0.5, [_key(KEY_ESCAPE), _joy_btn(JOY_BUTTON_START)])
	# Ladění (jen debug buildy)
	_action("debug_toggle_touch", 0.5, [_key(KEY_M)])
	_action("debug_overlay", 0.5, [_key(KEY_F3)])
	_action("debug_toggle_language", 0.5, [_key(KEY_L)])


# ------------------------------------------------------------------ helpers
func _own(node: Node, owner_node: Node) -> void:
	for child in node.get_children():
		child.owner = owner_node
		_own(child, owner_node)


func _save(root: Node, path: String) -> void:
	_own(root, root)
	var packed := PackedScene.new()
	var err: Error = packed.pack(root)
	if err != OK:
		push_error("pack failed for %s: %d" % [path, err])
		return
	err = ResourceSaver.save(packed, path)
	print("saved ", path, " -> ", err)
	root.free()


func _mat(color: Color, emission: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.9
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	return m


func _box(parent: Node, name: String, size: Vector3, pos: Vector3, mat: Material) -> CSGBox3D:
	var b := CSGBox3D.new()
	b.name = name
	b.size = size
	b.position = pos
	b.use_collision = true
	b.collision_layer = 1
	b.collision_mask = 0
	b.material = mat
	parent.add_child(b)
	return b


# ------------------------------------------------------------------ debug overlay
func _build_debug_overlay() -> void:
	var root := CanvasLayer.new()
	root.name = "DebugOverlay"
	root.layer = 100
	root.set_script(load("res://ui/debug/debug_overlay.gd"))

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.position = Vector2(16, 16)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.04, 0.12, 0.82)
	style.border_color = Color(0.95, 0.71, 0.2, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	root.add_child(panel)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	panel.add_child(margin)

	var label := Label.new()
	label.name = "Text"
	label.text = "BRUNO DEBUG"
	label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.93, 0.95, 1.0))
	margin.add_child(label)

	_save(root, "res://ui/debug/debug_overlay.tscn")


# ------------------------------------------------------------------ greybox street
func _build_greybox_street() -> void:
	var root := Node3D.new()
	root.name = "GreyboxStreet"

	# Noční prostředí (zatím bez cel-shadingu – ten přijde ve v0.3.0)
	var env := Environment.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.06, 0.07, 0.2)
	sky_mat.sky_horizon_color = Color(0.25, 0.22, 0.45)
	sky_mat.ground_horizon_color = Color(0.2, 0.18, 0.35)
	sky_mat.ground_bottom_color = Color(0.05, 0.05, 0.1)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 1.2
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world_env := WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	world_env.environment = env
	root.add_child(world_env)

	var moon := DirectionalLight3D.new()
	moon.name = "MoonLight"
	moon.light_color = Color(0.75, 0.8, 1.0)
	moon.light_energy = 0.9
	moon.shadow_enabled = true
	moon.rotation_degrees = Vector3(-50, -35, 0)
	root.add_child(moon)

	# Geometrie (CSG s kolizí – greybox, později nahradí modely)
	var geo := Node3D.new()
	geo.name = "Geometry"
	root.add_child(geo)
	var grey := _mat(Color(0.45, 0.45, 0.5))
	var dark := _mat(Color(0.3, 0.3, 0.36))
	var gold := _mat(Color(0.95, 0.71, 0.2), 0.6)
	_box(geo, "Street", Vector3(60, 1, 24), Vector3(0, -0.5, 0), grey)
	_box(geo, "HouseLeft", Vector3(10, 8, 8), Vector3(-14, 4, -10), dark)
	_box(geo, "HouseMid", Vector3(8, 11, 8), Vector3(0, 5.5, -12), dark)
	_box(geo, "HouseRight", Vector3(10, 6, 8), Vector3(14, 3, -10), dark)
	_box(geo, "StepLow", Vector3(4, 1, 4), Vector3(6, 0.5, 2), grey)
	_box(geo, "StepHigh", Vector3(4, 2, 4), Vector3(10, 1, 2), grey)
	_box(geo, "PaintingFrame", Vector3(6, 4, 0.6), Vector3(24, 3, -6), gold)

	# Popisky ve světě (Label3D se překládá automaticky podle klíče)
	var sign := Label3D.new()
	sign.name = "PaintingSign"
	sign.text = "GB_SIGN_PAINTING"
	sign.font_size = 96
	sign.pixel_size = 0.011
	sign.outline_size = 24
	sign.modulate = Color(1.0, 0.92, 0.6)
	sign.position = Vector3(24, 6, -5.6)
	root.add_child(sign)

	var diacritics := Label3D.new()
	diacritics.name = "DiacriticsTest"
	diacritics.text = "GB_DIACRITICS_TEST"
	diacritics.font_size = 64
	diacritics.pixel_size = 0.012
	diacritics.outline_size = 16
	diacritics.position = Vector3(0, 9.0, -7.9)
	root.add_child(diacritics)

	# Dočasná pevná kamera (v Kroku B ji nahradí HybridCamera)
	var cam := Camera3D.new()
	cam.name = "TempCamera"
	cam.position = Vector3(8, 7, 24)
	cam.rotation_degrees = Vector3(-14, 0, 0)
	cam.fov = 70
	cam.current = true
	root.add_child(cam)

	# UI vrstva s nápovědou (Label se překládá automaticky)
	var ui := CanvasLayer.new()
	ui.name = "HintLayer"
	root.add_child(ui)
	var box := VBoxContainer.new()
	box.name = "HintBox"
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	box.offset_top = -120
	box.offset_bottom = -24
	box.offset_left = -900
	box.offset_right = 900
	box.alignment = BoxContainer.ALIGNMENT_END
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(box)
	for pair: Array in [["Title", "GB_TITLE", 34], ["Keys", "GB_HINT_KEYS", 22]]:
		var l := Label.new()
		l.name = pair[0]
		l.text = pair[1]
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", pair[2])
		l.add_theme_constant_override("outline_size", 8)
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(l)

	_save(root, "res://levels/greybox/greybox_street.tscn")
