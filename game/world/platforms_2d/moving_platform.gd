## Pohyblivá plošina: jezdí tam a zpět mezi výchozí pozicí a `travel`.
## Bruno se veze automaticky (AnimatableBody3D + sync_to_physics).
@tool
class_name MovingPlatform
extends Platform2DBase

@export var travel: Vector3 = Vector3(0, 4, 0)
@export var duration: float = 2.5
@export var pause_time: float = 0.6

var _home: Vector3
var _t: float = 0.0


func _ready() -> void:
	if color == Color(0.55, 0.42, 0.3):
		color = Color(0.4, 0.6, 0.5)
	super._ready()
	if Engine.is_editor_hint():
		return
	sync_to_physics = true
	_home = position


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	var cycle: float = (duration + pause_time) * 2.0
	var c: float = fmod(_t, cycle)
	var k: float
	if c < pause_time:
		k = 0.0
	elif c < pause_time + duration:
		k = (c - pause_time) / duration
	elif c < pause_time * 2.0 + duration:
		k = 1.0
	else:
		k = 1.0 - (c - pause_time * 2.0 - duration) / duration
	position = _home + travel * (0.5 - 0.5 * cos(k * PI))
