## Skákací houba (Rayman 2D Platform Kit): dopadneš na klobouk → vymrští tě vysoko.
## Po odrazu máš k dispozici ještě dvojskok i ušní vrtulník.
class_name BouncyMushroom
extends Node3D

@export var bounce_velocity: float = 17.0

@onready var _area: Area3D = $BounceArea
@onready var _cap: Node3D = $Cap


func _ready() -> void:
	_area.collision_layer = 0
	_area.collision_mask = 2 # player
	_area.monitoring = true
	_area.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	var p: Player = body as Player
	if p == null or p.velocity.y > 0.5:
		return
	p.bounce(bounce_velocity)
	var tw: Tween = create_tween()
	tw.tween_property(_cap, "scale", Vector3(1.35, 0.55, 1.35), 0.06)
	tw.tween_property(_cap, "scale", Vector3(0.9, 1.2, 0.9), 0.1).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_cap, "scale", Vector3.ONE, 0.18).set_trans(Tween.TRANS_BACK)
