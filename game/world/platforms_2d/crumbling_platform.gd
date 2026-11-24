## Rozpadající se inkoustová plošina: po došlápnutí se chvíli třese, pak spadne
## a po chvíli se znovu objeví.
@tool
class_name CrumblingPlatform
extends Platform2DBase

@export var shake_time: float = 0.6
@export var respawn_time: float = 3.0

var _state: int = 0 # 0 = celá, 1 = třese se, 2 = spadlá
var _t: float = 0.0
var _home: Vector3


func _ready() -> void:
	if color == Color(0.55, 0.42, 0.3):
		color = Color(0.25, 0.2, 0.45)
	super._ready()
	_home = position


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or shape == null:
		return
	match _state:
		0:
			if player_on_top(get_tree().get_first_node_in_group(&"player") as Player):
				_state = 1
				_t = shake_time
				AudioManager.play_at(&"land", global_position, -4.0, 0.6)
		1:
			_t -= delta
			mesh.position = Vector3(randf_range(-0.05, 0.05), randf_range(-0.03, 0.03), 0)
			if _t <= 0.0:
				_state = 2
				_t = respawn_time
				shape.disabled = true
				mesh.position = Vector3.ZERO
				AudioManager.play_at(&"crate_break", global_position, -6.0, 1.3)
				var tw: Tween = create_tween().set_parallel(true)
				tw.tween_property(mesh, "position:y", -3.0, 0.5).set_ease(Tween.EASE_IN)
				tw.tween_property(mesh, "scale", Vector3(0.6, 0.6, 0.6), 0.5)
		2:
			_t -= delta
			if _t <= 0.0:
				_state = 0
				shape.disabled = false
				mesh.position = Vector3.ZERO
				mesh.scale = Vector3.ZERO
				create_tween().tween_property(mesh, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK)
