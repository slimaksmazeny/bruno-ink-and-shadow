## Nápověda testovací ulice: v dotykovém režimu schová řádky s klávesami (kryly by tlačítka).
extends CanvasLayer


func _ready() -> void:
	InputManager.touch_controls_toggled.connect(_on_touch_toggled)
	_on_touch_toggled(InputManager.touch_controls_visible)
	Events.aim_changed.connect(_on_aim_changed)
	_on_aim_changed(false)


## Zaměřovač: tlumený normálně, výrazný při míření.
func _on_aim_changed(aiming: bool) -> void:
	var cross: Control = get_node_or_null("Crosshair") as Control
	if cross != null:
		cross.modulate.a = 1.0 if aiming else 0.35
		cross.scale = Vector2(1.4, 1.4) if aiming else Vector2.ONE
		cross.pivot_offset = cross.size * 0.5


func _on_touch_toggled(on: bool) -> void:
	for label_name: String in ["Controls", "Keys"]:
		var l: Control = get_node_or_null("HintBox/" + label_name) as Control
		if l != null:
			l.visible = not on
