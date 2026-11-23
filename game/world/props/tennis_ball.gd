## Neonový tenisák. Odpálený holí letí skoro rovně (malá gravitace), odráží se a po chvíli zmizí.
## Zvony a spínače ho poznají podle skupiny "tennis_ball".
class_name TennisBall
extends RigidBody3D

@export var lifetime: float = 6.0

var _age: float = 0.0


func _ready() -> void:
	add_to_group(&"tennis_ball")
	collision_layer = 32 # projectiles
	collision_mask = 1 | 16 # world + props
	continuous_cd = true
	gravity_scale = 0.15
	contact_monitor = true
	max_contacts_reported = 2
	body_entered.connect(_on_body_entered)


func launch(velocity: Vector3) -> void:
	linear_velocity = velocity
	angular_velocity = Vector3(randf_range(-8, 8), randf_range(-8, 8), randf_range(-8, 8))


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()


func _on_body_entered(_body: Node) -> void:
	# Po prvním odrazu už „normální“ gravitace – míček se skutálí na zem.
	gravity_scale = 1.0
