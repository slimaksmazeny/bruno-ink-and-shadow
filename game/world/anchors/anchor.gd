## Kotva = místo, na které se Bruno umí „přicvaknout“ tlačítkem akce (modré jiskry ve stylu Sly).
## v0.2.0 používá jen typ SPIRE (špička / komín). v0.2.1 přidá další typy – jen nové stavy, jádro se nemění.
class_name Anchor
extends Area3D

enum Type { SPIRE, PIPE, LEDGE, ROPE, WALL, RING }

@export var type: Type = Type.SPIRE
## Kam se Bruno přitáhne (chodidla). Když chybí, použije se pozice kotvy.
@export var snap_point: Marker3D
@export var only_in_3d: bool = true

var _highlighted: bool = false
var _time: float = 0.0

@onready var _sparkles: Node3D = get_node_or_null("SparklesHolder/Sparkles") as Node3D


func _ready() -> void:
	collision_layer = 8 # vrstva 4 "anchors"
	collision_mask = 0
	monitoring = false
	monitorable = true
	_time = randf() * TAU
	_apply_highlight()


func get_snap_position(_from: Vector3) -> Vector3:
	return snap_point.global_position if snap_point != null else global_position


func set_highlighted(on: bool) -> void:
	if on == _highlighted:
		return
	_highlighted = on
	_apply_highlight()


func _process(delta: float) -> void:
	if _sparkles == null:
		return
	_time += delta
	var speed: float = 3.0 if _highlighted else 1.2
	_sparkles.rotation.y += delta * speed
	_sparkles.position.y = sin(_time * 2.0) * 0.08


func _apply_highlight() -> void:
	if _sparkles == null:
		return
	var s: float = 1.6 if _highlighted else 1.0
	_sparkles.scale = Vector3(s, s, s)
	for child: Node in _sparkles.get_children():
		if child is GeometryInstance3D:
			(child as GeometryInstance3D).transparency = 0.0 if _highlighted else 0.45
