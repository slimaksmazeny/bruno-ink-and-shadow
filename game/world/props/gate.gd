## Brána, která se otevře (zajede do země), když zazvoní zvon se stejným bell_id.
class_name Gate
extends AnimatableBody3D

@export var bell_id: StringName = &"bell_main"
@export var open_depth: float = 4.6
@export var open_time: float = 1.2

var is_open: bool = false


func _ready() -> void:
	Events.bell_hit.connect(_on_bell_hit)


func _on_bell_hit(id: StringName) -> void:
	if id != bell_id or is_open:
		return
	is_open = true
	AudioManager.play_at(&"gate", global_position)
	var tw: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "position:y", position.y - open_depth, open_time)
