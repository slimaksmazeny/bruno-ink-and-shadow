extends SceneTree

var _frames: int = 0

func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 3:
		_run()
		return true
	return false

func _check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)

func _run() -> void:
	var settings: Node = root.get_node("/root/Settings")
	var im: Node = root.get_node("/root/InputManager")
	var gs: Node = root.get_node("/root/GameState")
	var sm: Node = root.get_node("/root/SaveManager")
	var dbg: Node = root.get_node_or_null("/root/DebugOverlay")
	_check("autoload DebugOverlay present", dbg != null)
	settings.set_locale("cs")
	_check("cs sign", TranslationServer.translate("GB_SIGN_PAINTING") == "Skoč do obrazu!")
	_check("cs plural 1", Loc.plural("HUD_BOTTLES", 1) == "1 lahvička")
	_check("cs plural 3", Loc.plural("HUD_BOTTLES", 3) == "3 lahvičky")
	_check("cs plural 7", Loc.plural("HUD_BOTTLES", 7) == "7 lahviček")
	settings.cycle_locale()
	_check("cycle -> en", TranslationServer.get_locale() == "en" and TranslationServer.translate("GB_SIGN_PAINTING") == "Jump into the painting!")
	_check("en plural 1/5", Loc.plural("HUD_BOTTLES", 1) == "1 bottle" and Loc.plural("HUD_BOTTLES", 5) == "5 bottles")
	var cfg := ConfigFile.new()
	_check("settings.cfg saved en", cfg.load("user://settings.cfg") == OK and cfg.get_value("general", "locale") == "en")
	settings.set_locale("cs")
	# all game actions exist
	var needed: Array[String] = ["move_left","move_right","move_forward","move_back","look_left","look_right","look_up","look_down","jump","sprint","action","tennis","sneak","pause","debug_toggle_touch","debug_overlay","debug_toggle_language"]
	var missing: Array[String] = []
	for a in needed:
		if not InputMap.has_action(a): missing.append(a)
	_check("input actions present " + str(missing), missing.is_empty())
	# simulate key press via action
	Input.action_press("move_right", 0.6)
	_check("move vector from action", is_equal_approx(im.get_move_vector().x, 0.6) or im.get_move_vector().x > 0.5)
	Input.action_release("move_right")
	im.set_touch_controls(true)
	_check("touch toggle on + emulate", im.touch_controls_visible and Input.emulate_touch_from_mouse)
	im.set_touch_controls(false)
	_check("touch toggle off", not im.touch_controls_visible and not Input.emulate_touch_from_mouse)
	gs.mark_collected("ch1", "bottles", "ch1_bottle_001")
	gs.mark_collected("ch1", "bottles", "ch1_bottle_001")
	_check("collect dedupe", gs.count_collected("ch1", "bottles") == 1)
	_check("save ok", sm.save_game(9))
	gs.reset()
	_check("load ok", sm.load_game(9) and gs.is_collected("ch1", "bottles", "ch1_bottle_001"))
	_check("save twice (bak/rename over existing)", sm.save_game(9) and FileAccess.file_exists("user://save_9.json.bak"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://save_9.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://save_9.json.bak"))
	dbg.get_node("Panel").visible = true
	dbg.watch("Test", 1)
	var txt: String = dbg._build_text()
	_check("debug text", txt.contains("Locale: cs") and txt.contains("Test: 1"))
	print(txt)
	quit()
