## Inkoustová kaňka – jednoduchý nepřítel (hlavně 2D). Leze sem a tam po plošině,
## na kraji nebo u zdi se otočí. Skok na hlavu = rozplácnutí (Bruno se odrazí),
## hůl / tenisák = taky konec. Dotyk ze strany bere život.
@tool
class_name InkBlob
extends CharacterBody3D

@export var speed: float = 1.6
@export var start_dir: float = 1.0
## Osa pohybu (2D: podél X). Lokálně se nepoužívá rotace – směr je ve světě.
@export var axis: Vector3 = Vector3.RIGHT
## Jak daleko od startu smí kaňka odejít (0 = neomezeně, jen kraje a zdi).
@export var patrol_half_width: float = 0.0

var dead: bool = false
var _dir: float = 1.0
var _body: MeshInstance3D
var _eyes: Node3D
var _hurt: Area3D
var _t: float = 0.0
var _home: Vector3


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	_build()
	if Engine.is_editor_hint():
		return
	_dir = signf(start_dir) if start_dir != 0.0 else 1.0
	_home = global_position
	add_to_group(&"hittable")
	add_to_group(&"ink_blob")
	_hurt.body_entered.connect(_on_touch)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or dead:
		return
	_t += delta
	var ax: Vector3 = axis.normalized()
	# Otočit u zdi nebo na kraji (paprsek dolů kousek před kaňkou).
	var ahead: Vector3 = global_position + ax * _dir * 0.55 + Vector3.UP * 0.3
	var q := PhysicsRayQueryParameters3D.create(ahead, ahead + Vector3.DOWN * 0.9, 1)
	q.exclude = [get_rid()]
	var ground_ahead: bool = not get_world_3d().direct_space_state.intersect_ray(q).is_empty()
	var along: float = (global_position - _home).dot(ax)
	var too_far: bool = patrol_half_width > 0.0 and along * _dir > patrol_half_width
	if is_on_floor() and (not ground_ahead or is_on_wall() or too_far):
		_dir = -_dir
	if global_position.y < -40.0:
		queue_free()
		return
	velocity.x = ax.x * _dir * speed
	velocity.z = ax.z * _dir * speed
	velocity.y = -0.5 if is_on_floor() else velocity.y - 24.0 * delta
	move_and_slide()
	# Želé vlnění + oči ve směru pohybu.
	_body.scale = Vector3(1.0 + sin(_t * 8.0) * 0.08, 1.0 - sin(_t * 8.0) * 0.08, 1.0)
	_eyes.position.x = ax.x * _dir * 0.12
	_eyes.position.z = ax.z * _dir * 0.12 + 0.2
	# Skok na hlavu: Bruno padá a je nad kaňkou.
	var p: Player = get_tree().get_first_node_in_group(&"player") as Player
	if p != null and p.velocity.y < -0.5:
		var d: Vector3 = p.global_position - global_position
		if d.y > 0.35 and d.y < 1.1 and Vector2(d.x, d.z).length() < 0.75:
			p.bounce(11.0)
			squash()


func _on_touch(body: Node) -> void:
	var p: Player = body as Player
	if p == null or dead:
		return
	# Shora to je skok na hlavu (řeší _physics_process), ze strany zranění.
	if p.global_position.y > global_position.y + 0.35:
		return
	p.take_damage(1, global_position)


func on_cane_hit(_info: Dictionary) -> void:
	squash()


func squash() -> void:
	if dead:
		return
	dead = true
	collision_layer = 0
	_hurt.set_deferred("monitoring", false)
	remove_from_group(&"hittable")
	AudioManager.play_at(&"hit", global_position, 0.0, 1.4)
	AudioManager.play_at(&"bounce", global_position, -6.0, 1.6)
	var tw: Tween = create_tween()
	tw.tween_property(_body, "scale", Vector3(1.8, 0.12, 1.8), 0.1)
	tw.parallel().tween_property(_eyes, "scale", Vector3.ZERO, 0.1)
	tw.tween_interval(0.6)
	tw.tween_property(_body, "scale", Vector3.ZERO, 0.25)
	tw.tween_callback(queue_free)


func _build() -> void:
	for c: Node in get_children():
		if c.has_meta(&"generated"):
			c.free()
	var shape := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 0.38
	shape.shape = sph
	shape.position.y = 0.38
	shape.set_meta(&"generated", true)
	add_child(shape)
	_body = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.42
	sm.height = 0.62
	_body.mesh = sm
	_body.position.y = 0.31
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.06, 0.16)
	mat.roughness = 0.1
	mat.metallic = 0.2
	_body.material_override = mat
	_body.set_meta(&"generated", true)
	add_child(_body)
	_eyes = Node3D.new()
	_eyes.position = Vector3(0, 0.45, 0.2)
	_eyes.set_meta(&"generated", true)
	add_child(_eyes)
	var white := StandardMaterial3D.new()
	white.albedo_color = Color(1, 1, 0.95)
	white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for x: float in [-0.12, 0.12]:
		var e := MeshInstance3D.new()
		var em := SphereMesh.new()
		em.radius = 0.08
		em.height = 0.16
		e.mesh = em
		e.material_override = white
		e.position = Vector3(x, 0, 0.18)
		_eyes.add_child(e)
	_hurt = Area3D.new()
	_hurt.collision_layer = 0
	_hurt.collision_mask = 2
	var hs := CollisionShape3D.new()
	var hsph := SphereShape3D.new()
	hsph.radius = 0.5
	hs.shape = hsph
	hs.position.y = 0.38
	_hurt.add_child(hs)
	_hurt.set_meta(&"generated", true)
	add_child(_hurt)
