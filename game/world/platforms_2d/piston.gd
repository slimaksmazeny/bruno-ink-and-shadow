## Rytmický píst: rychle vyjede, chvíli drží, pomalu zajede. Rytmus = `beat` sekund,
## `phase` (0..1) posune začátek, aby šlo řadit víc pístů za sebou jako vlnu.
@tool
class_name Piston
extends Platform2DBase

@export var travel: Vector3 = Vector3(0, 5, 0)
@export var beat: float = 2.4
@export_range(0.0, 1.0) var phase: float = 0.0
## Části cyklu: vyjetí, držení, zajetí (zbytek = čekání dole).
@export var extend_time: float = 0.18
@export var hold_time: float = 0.9
@export var retract_time: float = 0.7

var _home: Vector3
var _t: float = 0.0
var _was_out: bool = false


func _ready() -> void:
	if color == Color(0.55, 0.42, 0.3):
		color = Color(0.6, 0.25, 0.2)
	super._ready()
	if Engine.is_editor_hint():
		return
	sync_to_physics = true
	_home = position
	_t = phase * beat


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	var c: float = fmod(_t, beat)
	var k: float
	if c < extend_time:
		k = ease(c / extend_time, 0.4)
	elif c < extend_time + hold_time:
		k = 1.0
	elif c < extend_time + hold_time + retract_time:
		k = 1.0 - (c - extend_time - hold_time) / retract_time
	else:
		k = 0.0
	position = _home + travel * k
	var out: bool = k > 0.95
	if out and not _was_out:
		AudioManager.play_at(&"land", global_position, -8.0, 0.7)
	_was_out = out
