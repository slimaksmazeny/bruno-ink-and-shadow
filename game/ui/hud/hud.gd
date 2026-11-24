## Testovací HUD (CanvasLayer v levelu): životy vlevo nahoře, kapky inkoustu vpravo nahoře,
## krátké hlášky uprostřed (checkpoint, poplach). Po chvíli klidu se kapky ztlumí (2D plošinovky styl).
class_name Hud
extends CanvasLayer

const FADE_AFTER: float = 3.0

var _health: HealthPips
var _ink_label: Label
var _ink_box: Control
var _coin_label: Label
var _objective: Label
var _prompt: Label
var _player: Player
var _toast: Label
var _alert: Label
var _idle: float = 0.0
var _alerted_guards: int = 0


func _ready() -> void:
	layer = 20
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_health = HealthPips.new()
	_health.position = Vector2(28, 24)
	root.add_child(_health)

	_ink_box = HBoxContainer.new()
	_ink_box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_ink_box.position = Vector2(-230, 22)
	_ink_box.custom_minimum_size = Vector2(200, 48)
	root.add_child(_ink_box)
	var icon := InkIcon.new()
	icon.custom_minimum_size = Vector2(36, 46)
	_ink_box.add_child(icon)
	_ink_label = _make_label(34)
	_ink_box.add_child(_ink_label)

	_coin_label = _make_label(28)
	_coin_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_coin_label.position = Vector2(-200, 74)
	_coin_label.add_theme_color_override("font_color", Color(1, 0.82, 0.3))
	root.add_child(_coin_label)
	_set_coins(GameState.get_coins(), false)
	Events.coins_changed.connect(func(total: int) -> void: _set_coins(total, true))

	var radar := Radar.new()
	radar.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	radar.position = Vector2(-215, -330)
	root.add_child(radar)

	_objective = _make_label(24)
	_objective.position = Vector2(28, 74)
	_objective.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
	root.add_child(_objective)
	_prompt = _make_label(30)
	_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.position = Vector2(-300, -190)
	_prompt.custom_minimum_size.x = 600
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_color_override("font_color", UiStyle.GOLD)
	_prompt.visible = false
	root.add_child(_prompt)
	Events.mission_step_changed.connect(func(_s: int) -> void:
		_refresh_objective()
		show_toast(tr(_objective_key())))
	Events.key_obtained.connect(func(_k: String) -> void: show_toast(tr("HUD_KEY")))
	_refresh_objective.call_deferred()

	_toast = _make_label(40)
	_toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast.position = Vector2(-300, 110)
	_toast.custom_minimum_size.x = 600
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.modulate.a = 0.0
	root.add_child(_toast)

	_alert = _make_label(30)
	_alert.text = "HUD_ALERT"
	_alert.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_alert.position = Vector2(-300, 24)
	_alert.custom_minimum_size.x = 600
	_alert.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_alert.add_theme_color_override("font_color", Color(1, 0.3, 0.25))
	_alert.visible = false
	root.add_child(_alert)

	Events.player_health_changed.connect(_on_health)
	Events.collectible_collected.connect(func(_id: String) -> void: _refresh_ink(true))
	Events.checkpoint_reached.connect(func(_id: String) -> void: show_toast(tr("HUD_CHECKPOINT")))
	Events.player_died.connect(func() -> void: show_toast(tr("HUD_OUCH")))
	Events.guard_alert_changed.connect(_on_guard_alert)
	AudioManager.play_music(&"sneak_loop")
	_refresh_ink.call_deferred(false)
	_init_health.call_deferred()


func _process(delta: float) -> void:
	_idle += delta
	var target_a: float = 0.45 if _idle > FADE_AFTER else 1.0
	_ink_box.modulate.a = move_toward(_ink_box.modulate.a, target_a, delta * 2.0)
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(&"player") as Player
	var it: Node = Interact.nearest(_player) if _player != null else null
	_prompt.visible = it != null
	if it != null:
		_prompt.text = "E / ○  " + tr(String(it.call("get_prompt")))
	if _alert.visible:
		_alert.modulate.a = 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.012)


func show_toast(text: String) -> void:
	_toast.text = text
	var tw: Tween = create_tween()
	tw.tween_property(_toast, "modulate:a", 1.0, 0.15)
	tw.tween_interval(1.6)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.4)


func _init_health() -> void:
	var p: Player = get_tree().get_first_node_in_group(&"player") as Player
	if p != null:
		_health.set_health(p.health, p.max_health)


func _on_health(hp: int, max_hp: int) -> void:
	_health.set_health(hp, max_hp)


func _refresh_ink(pop: bool) -> void:
	var total: int = 0
	var got: int = 0
	for n: Node in get_tree().get_nodes_in_group(&"ink_drop"):
		var d: InkDrop = n as InkDrop
		total += d.value()
		if d.collected:
			got += d.value()
	_ink_label.text = "%d / %d" % [got, total]
	if pop:
		_idle = 0.0
		_ink_box.modulate.a = 1.0
		_ink_box.pivot_offset = _ink_box.size * 0.5
		var tw: Tween = create_tween()
		tw.tween_property(_ink_box, "scale", Vector2(1.18, 1.18), 0.06)
		tw.tween_property(_ink_box, "scale", Vector2.ONE, 0.14)


func _on_guard_alert(alerted: bool) -> void:
	_alerted_guards = maxi(_alerted_guards + (1 if alerted else -1), 0)
	_alert.visible = _alerted_guards > 0


func _make_label(size: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", UiStyle.PAPER)
	l.add_theme_color_override("font_outline_color", Color(0.03, 0.02, 0.08))
	l.add_theme_constant_override("outline_size", 10)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _objective_key() -> String:
	var m: Mission = get_tree().get_first_node_in_group(&"mission") as Mission
	return m.objective_key() if m != null else ""


func _refresh_objective() -> void:
	var k: String = _objective_key()
	_objective.visible = not k.is_empty()
	if not k.is_empty():
		_objective.text = tr("HUD_OBJECTIVE") + " " + tr(k)


func _set_coins(total: int, pop: bool) -> void:
	_coin_label.text = "¤ %d" % total
	_coin_label.visible = total > 0
	if pop:
		show_toast(tr("HUD_PICKPOCKET"))


## Životy jako „kosti“ (zatím kroužky). Ztracený život je prázdný obrys.
class HealthPips extends Control:
	var hp: int = 3
	var max_hp: int = 3
	var _shake: float = 0.0

	func set_health(h: int, m: int) -> void:
		if h < hp:
			_shake = 0.35
		hp = h
		max_hp = m
		queue_redraw()

	func _process(delta: float) -> void:
		if _shake > 0.0:
			_shake -= delta
			position.x = 28.0 + sin(_shake * 80.0) * 6.0 * _shake
			if _shake <= 0.0:
				position.x = 28.0

	func _draw() -> void:
		for i: int in max_hp:
			var c := Vector2(22 + i * 52, 22)
			draw_circle(c, 21, Color(0.03, 0.02, 0.08))
			if i < hp:
				draw_circle(c, 17, Color(0.85, 0.2, 0.25))
				draw_circle(c + Vector2(-5, -6), 5, Color(1, 0.6, 0.6, 0.8))
			else:
				draw_arc(c, 16, 0, TAU, 24, Color(0.5, 0.45, 0.6), 2.5)


class InkIcon extends Control:
	func _draw() -> void:
		var c := size * 0.5 + Vector2(0, 5)
		draw_circle(c, 13, Color(0.2, 0.4, 1.0))
		draw_colored_polygon(PackedVector2Array([c + Vector2(-11, -6), c + Vector2(11, -6), c + Vector2(0, -24)]), Color(0.2, 0.4, 1.0))
		draw_circle(c + Vector2(-4, -2), 4, Color(0.7, 0.85, 1.0))
