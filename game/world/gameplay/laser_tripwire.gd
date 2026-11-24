## Laserový paprsek (poplach). Dotyk = poplach: strážní v okolí přiběhnou na místo.
## Vysoký paprsek (`block_standing`) má pod sebou neviditelnou zábranu – vestoje se do něj
## Bruno vždy zapíchne, projde jen plazením (plížení u překážky). Nízký se dá přeskočit.
## `blink_period` > 0 = paprsek bliká (zapnuto/vypnuto), dá se proběhnout ve správnou chvíli.
@tool
class_name LaserTripwire
extends Area3D

@export var length: float = 8.0:
	set(v):
		length = v
		if is_inside_tree():
			_build()
@export var beam_height: float = 0.95:
	set(v):
		beam_height = v
		if is_inside_tree():
			_build()
@export var block_standing: bool = true:
	set(v):
		block_standing = v
		if is_inside_tree():
			_build()
@export var blink_period: float = 0.0
@export var alarm_radius: float = 30.0

var active: bool = true
var _beam: MeshInstance3D
var _block: CollisionShape3D
var _cooldown: float = 0.0
var _t: float = 0.0


func _ready() -> void:
	collision_layer = 64
	collision_mask = 2
	monitorable = false
	_build()
	if Engine.is_editor_hint():
		return
	add_to_group(&"laser")
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_cooldown = maxf(_cooldown - delta, 0.0)
	if blink_period > 0.0:
		_t += delta
		var on: bool = fmod(_t, blink_period) < blink_period * 0.55
		if on != active:
			active = on
			_beam.visible = on
			if on:
				for b: Node3D in get_overlapping_bodies():
					_on_body_entered(b)


func _on_body_entered(body: Node) -> void:
	var p: Player = body as Player
	if p == null or not active or _cooldown > 0.0:
		return
	trigger_alarm(p.global_position)


func trigger_alarm(at: Vector3) -> void:
	_cooldown = 2.0
	AudioManager.play_at(&"alert", global_position, 3.0, 0.8)
	for n: Node in get_tree().get_nodes_in_group(&"guard"):
		var g: Guard = n as Guard
		if g != null and g.global_position.distance_to(at) <= alarm_radius:
			g.investigate(at)
	Events.laser_alarm.emit(at)
	if _beam != null:
		var tw: Tween = create_tween()
		tw.tween_property(_beam, "scale", Vector3(3, 1, 3), 0.08)
		tw.tween_property(_beam, "scale", Vector3.ONE, 0.3)


func _build() -> void:
	for c: Node in get_children():
		if c.has_meta(&"generated"):
			c.free()
	# Spouštěcí oblast kolem paprsku (osa X lokálně).
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(length, 0.22, 0.95)
	shape.shape = box
	shape.position = Vector3(length * 0.5, beam_height, 0)
	shape.set_meta(&"generated", true)
	add_child(shape)
	_beam = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.025
	cyl.bottom_radius = 0.025
	cyl.height = length
	_beam.mesh = cyl
	_beam.rotation.z = PI * 0.5
	_beam.position = Vector3(length * 0.5, beam_height, 0)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1, 0.1, 0.15)
	_beam.material_override = mat
	_beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_beam.set_meta(&"generated", true)
	add_child(_beam)
	var post_mat := StandardMaterial3D.new()
	post_mat.albedo_color = Color(0.2, 0.2, 0.25)
	for x: float in [0.0, length]:
		var post := MeshInstance3D.new()
		var pm := BoxMesh.new()
		pm.size = Vector3(0.15, beam_height + 0.3, 0.15)
		post.mesh = pm
		post.material_override = post_mat
		post.position = Vector3(x, (beam_height + 0.3) * 0.5, 0)
		post.set_meta(&"generated", true)
		add_child(post)
	# Neviditelná zábrana pod vysokým paprskem: vestoje se nedá projít (nutí plazení).
	if block_standing:
		var sb := StaticBody3D.new()
		sb.collision_layer = 1
		sb.collision_mask = 0
		sb.set_meta(&"generated", true)
		add_child(sb)
		_block = CollisionShape3D.new()
		var bb := BoxShape3D.new()
		bb.size = Vector3(length, 0.15, 0.7)
		_block.shape = bb
		_block.position = Vector3(length * 0.5, beam_height, 0)
		sb.add_child(_block)
