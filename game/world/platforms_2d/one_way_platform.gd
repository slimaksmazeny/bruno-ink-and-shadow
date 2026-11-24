## Průchozí plošina (Rayman): zespodu se dá proskočit, shora se na ní stojí.
## Seskočení dolů: držet dolů (S / páčka dolů) + skok (řeší GroundedState → drop_through()).
@tool
class_name OneWayPlatform
extends Platform2DBase

var _drop_timer: float = 0.0


func _ready() -> void:
	if color == Color(0.55, 0.42, 0.3):
		color = Color(0.85, 0.7, 0.35)
	super._ready()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or shape == null:
		return
	var p: Player = get_tree().get_first_node_in_group(&"player") as Player
	if p == null:
		return
	var feet_above: bool = p.global_position.y >= top_y() - 0.08
	if _drop_timer > 0.0:
		_drop_timer -= delta
		# Seskok trvá, dokud Bruno nepropadne pod plošinu.
		if p.global_position.y < top_y() - size.y - 0.3:
			_drop_timer = 0.0
	# Pevná jen když je Bruno nad horní hranou a nepadá skrz.
	var solid: bool = feet_above and p.velocity.y <= 0.5 and _drop_timer <= 0.0
	if shape.disabled == solid:
		shape.disabled = not solid


func drop_through() -> void:
	_drop_timer = 0.6
	shape.disabled = true
