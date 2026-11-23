## Zásahová zóna hole před Brunem. Aktivní jen v „aktivních“ snímcích útoku.
## Každý cíl zasáhne jednou za švih. Cíl = uzel ve skupině "hittable" s metodou on_cane_hit(info).
class_name CaneHitbox
extends Area3D

signal hit_landed(target: Node, info: Dictionary)

var _active: bool = false
var _already_hit: Array[Node] = []
var _info: Dictionary = {}


func _ready() -> void:
	collision_layer = 0
	collision_mask = 4 | 16 # enemies + props
	monitoring = true
	monitorable = false


## Zapne zásahy pro jeden švih. info: {"damage": int, "knockback": float, "combo": int, "dir": Vector3}
func begin_swing(info: Dictionary) -> void:
	_active = true
	_info = info
	_already_hit.clear()


func end_swing() -> void:
	_active = false


func _physics_process(_delta: float) -> void:
	if not _active:
		return
	var targets: Array[Node] = []
	for b: Node3D in get_overlapping_bodies():
		targets.append(b)
	for a: Area3D in get_overlapping_areas():
		targets.append(a)
	for t: Node in targets:
		var target: Node = _find_hittable(t)
		if target == null or _already_hit.has(target):
			continue
		_already_hit.append(target)
		target.call("on_cane_hit", _info)
		hit_landed.emit(target, _info)


func _find_hittable(n: Node) -> Node:
	var cur: Node = n
	for _i: int in 3:
		if cur == null:
			return null
		if cur.is_in_group(&"hittable") and cur.has_method("on_cane_hit"):
			return cur
		cur = cur.get_parent()
	return null
