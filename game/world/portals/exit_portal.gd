## Výstupní portál na konci 2D úrovně – vrátí Bruna zpět do 3D před rám obrazu.
class_name ExitPortal
extends Area3D

@export var entry_portal: PaintingPortal

var _time: float = 0.0

@onready var _ring: Node3D = get_node_or_null("Ring") as Node3D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # player
	monitoring = true
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	if _ring != null:
		_ring.rotation.z = _time * 1.5
		var s: float = 1.0 + sin(_time * 3.0) * 0.06
		_ring.scale = Vector3(s, s, s)


func _on_body_entered(body: Node) -> void:
	var p: Player = body as Player
	if p == null or p.mode != Player.Mode.MODE_2D or entry_portal == null or entry_portal.busy:
		return
	entry_portal.return_to_3d(p)
