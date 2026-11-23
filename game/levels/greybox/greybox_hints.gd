## Nápověda testovací ulice: v dotykovém režimu schová řádky s klávesami (kryly by tlačítka).
extends CanvasLayer


func _ready() -> void:
	InputManager.touch_controls_toggled.connect(_on_touch_toggled)
	_on_touch_toggled(InputManager.touch_controls_visible)


func _on_touch_toggled(on: bool) -> void:
	for label_name: String in ["Controls", "Keys"]:
		var l: Control = get_node_or_null("HintBox/" + label_name) as Control
		if l != null:
			l.visible = not on
