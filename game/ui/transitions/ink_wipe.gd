## Globální inkoustový přechod (autoload InkWipe). Použití: await InkWipe.cover(0.35) … await InkWipe.reveal(0.4)
extends CanvasLayer

@onready var _rect: ColorRect = $Ink

var _tween: Tween


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_set_progress(0.0)


func cover(duration: float = 0.35) -> void:
	await _animate(1.0, duration)


func reveal(duration: float = 0.4) -> void:
	await _animate(0.0, duration)


func is_covered() -> bool:
	return _get_progress() >= 0.99


func _animate(to: float, duration: float) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_rect.visible = true
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_method(_set_progress, _get_progress(), to, duration)
	await _tween.finished
	_rect.visible = to > 0.0


func _set_progress(v: float) -> void:
	(_rect.material as ShaderMaterial).set_shader_parameter("progress", v)


func _get_progress() -> float:
	return float((_rect.material as ShaderMaterial).get_shader_parameter("progress"))
