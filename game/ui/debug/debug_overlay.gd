## Ladicí panel (F3). Jen pro vývojové buildy – v exportované hře se sám odstraní.
## Jiné systémy sem mohou posílat hodnoty: DebugOverlay.watch("Stav", "Idle").
## Texty panelu jsou záměrně anglické/technické (výjimka z pravidla lokalizace, viz ARCHITECTURE.md §10).
extends CanvasLayer

const REFRESH_INTERVAL: float = 0.1

@onready var _panel: PanelContainer = $Panel
@onready var _label: Label = $Panel/Margin/Text

var _watches: Dictionary[String, String] = {}
var _refresh_timer: float = 0.0
var _game_actions: Array[StringName] = []


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_panel.visible = false
	for action: StringName in InputMap.get_actions():
		if not String(action).begins_with("ui_"):
			_game_actions.append(action)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"debug_overlay"):
		_panel.visible = not _panel.visible
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"debug_toggle_language"):
		Settings.cycle_locale()
		get_viewport().set_input_as_handled()


## Zobrazí/aktualizuje řádek v panelu (např. stav hráče od Kroku B).
func watch(key: String, value: Variant) -> void:
	_watches[key] = str(value)


func unwatch(key: String) -> void:
	_watches.erase(key)


func _process(delta: float) -> void:
	if not _panel.visible:
		return
	_refresh_timer -= delta
	if _refresh_timer > 0.0:
		return
	_refresh_timer = REFRESH_INTERVAL
	_label.text = _build_text()


func _build_text() -> String:
	var lines: PackedStringArray = []
	lines.append("BRUNO DEBUG  ·  v%s  ·  Godot %s" % [
		ProjectSettings.get_setting("application/config/version", "?"),
		Engine.get_version_info()["string"],
	])
	lines.append("FPS: %d   Physics: %d Hz" % [Engine.get_frames_per_second(), Engine.physics_ticks_per_second])
	lines.append("Device: %s" % InputManager.device_name(InputManager.last_device))
	lines.append("Locale: %s (%s)" % [TranslationServer.get_locale(), tr("UI_LANG_NAME")])
	lines.append("Touch HUD: %s   Mouse: %s" % [
		"ON" if InputManager.touch_controls_visible else "OFF",
		"captured" if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else "visible",
	])

	var pads: PackedStringArray = []
	for id: int in Input.get_connected_joypads():
		pads.append(Input.get_joy_name(id))
	lines.append("Gamepads: %s" % (", ".join(pads) if pads.size() > 0 else "-"))
	lines.append("Pad family: %s" % InputManager.pad_family_name(InputManager.pad_family))

	var move: Vector2 = InputManager.get_move_vector()
	var look: Vector2 = InputManager.get_look_stick()
	lines.append("Move: (%.2f, %.2f)   Look stick: (%.2f, %.2f)" % [move.x, move.y, look.x, look.y])

	var held: PackedStringArray = []
	for action: StringName in _game_actions:
		if Input.is_action_pressed(action):
			var strength: float = Input.get_action_strength(action)
			held.append("%s %.2f" % [action, strength] if strength < 0.99 else String(action))
	lines.append("Actions: %s" % (", ".join(held) if held.size() > 0 else "-"))

	if _watches.is_empty():
		lines.append("Player state: -")
	for key: String in _watches:
		lines.append("%s: %s" % [key, _watches[key]])
	return "\n".join(lines)
