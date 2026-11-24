## Obrazovka po dokončení loupeže: čas, kapky, mince, vyřazení strážní. Hrát znovu / Hlavní menu.
class_name ResultsScreen
extends CanvasLayer

var mission: Mission


func _ready() -> void:
	layer = 70
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	InputManager.release_mouse()
	AudioManager.duck_music(true)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = UiStyle.make_theme()
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.01, 0.06, 0.75)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var title := Label.new()
	title.text = "RESULTS_TITLE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", UiStyle.GOLD)
	box.add_child(title)
	var secs: float = mission.elapsed_sec() if mission != null else 0.0
	var got: int = 0
	var total: int = 0
	for n: Node in get_tree().get_nodes_in_group(&"ink_drop"):
		var d: InkDrop = n as InkDrop
		total += d.value()
		if d.collected:
			got += d.value()
	var record: bool = GameState.record_result(InkDrop.CHAPTER_ID, secs)
	_row(box, tr("RESULTS_TIME"), _fmt(secs) + ("   ★ " + tr("RESULTS_RECORD") if record else ""))
	var best: float = GameState.best_time(InkDrop.CHAPTER_ID)
	if not record and best > 0.0:
		_row(box, tr("RESULTS_BEST"), _fmt(best))
	_row(box, tr("RESULTS_INK"), "%d / %d" % [got, total])
	_row(box, tr("RESULTS_COINS"), "¤ %d" % GameState.get_coins())
	var jars: int = get_tree().get_nodes_in_group(&"firefly_jar").size()
	if jars > 0:
		_row(box, tr("RESULTS_FIREFLIES"), "✦ %d / %d" % [GameState.count_collected(InkDrop.CHAPTER_ID, FireflyJar.CATEGORY), jars])
	_row(box, tr("RESULTS_KO"), str(mission.knockouts if mission != null else 0))
	var again := UiStyle.make_button("RESULTS_AGAIN")
	again.pressed.connect(_again)
	box.add_child(again)
	var menu := UiStyle.make_button("UI_PAUSE_MAIN_MENU")
	menu.pressed.connect(_menu)
	box.add_child(menu)
	again.grab_focus.call_deferred()
	SaveManager.save_game()


func _row(parent: Control, label: String, value: String) -> void:
	var r := HBoxContainer.new()
	var l := Label.new()
	l.text = label
	l.custom_minimum_size.x = 300
	r.add_child(l)
	var v := Label.new()
	v.text = value
	v.add_theme_color_override("font_color", UiStyle.GOLD)
	r.add_child(v)
	parent.add_child(r)


func _again() -> void:
	_close()
	get_tree().reload_current_scene()


func _menu() -> void:
	_close()
	get_tree().change_scene_to_file("res://ui/menus/main_menu.tscn")


func _close() -> void:
	get_tree().paused = false
	AudioManager.duck_music(false)
	queue_free()


static func _fmt(secs: float) -> String:
	return "%d:%02d" % [int(secs / 60.0), int(secs) % 60]
