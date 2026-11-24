## Otočný reflektor: světelný kužel krouží po zemi (sem a tam). Když Bruna zachytí
## (je v kuželu a nic mezi nimi), spustí poplach – strážní v okolí přiběhnou.
## Plížení nepomůže: načasuj průchod nebo se schovej za něco.
@tool
class_name Searchlight
extends Node3D

@export var height: float = 6.0:
	set(v):
		height = v
		if is_inside_tree():
			_build()
## Polovina rozsahu otáčení (stupně) a rychlost (rad/s).
@export var sweep_deg: float = 60.0
@export var sweep_speed: float = 0.7
@export var beam_angle_deg: float = 12.0
@export var reach: float = 16.0
@export var alarm_radius: float = 28.0

var _head: Node3D
var _tilt: Node3D
var _beam: MeshInstance3D
var _beam_mat: StandardMaterial3D
var _light: SpotLight3D
var _t: float = 0.0
var _cooldown: float = 0.0


func _ready() -> void:
	_build()
	if Engine.is_editor_hint():
		return
	add_to_group(&"searchlight")


func _physics_process(delta: float) -> void:
	_t += delta
	if _head != null:
		_head.rotation.y = sin(_t * sweep_speed) * deg_to_rad(sweep_deg)
	if Engine.is_editor_hint():
		return
	_cooldown = maxf(_cooldown - delta, 0.0)
	var p: Player = get_tree().get_first_node_in_group(&"player") as Player
	var caught: bool = p != null and sees(p.global_position + Vector3.UP * 0.6)
	_beam_mat.albedo_color = Color(1, 0.3, 0.2, 0.22) if caught else Color(1, 0.95, 0.7, 0.14)
	if caught and _cooldown <= 0.0:
		_cooldown = 2.5
		AudioManager.play_at(&"alert", global_position, 3.0, 0.9)
		for n: Node in get_tree().get_nodes_in_group(&"guard"):
			var g: Guard = n as Guard
			if g != null and g.global_position.distance_to(p.global_position) <= alarm_radius:
				g.investigate(p.global_position)
		Events.laser_alarm.emit(p.global_position)


## Je bod v kuželu reflektoru a bez překážky?
func sees(point: Vector3) -> bool:
	var origin: Vector3 = _tilt.global_position
	var dir: Vector3 = -_tilt.global_transform.basis.z
	var to: Vector3 = point - origin
	if to.length() > reach or dir.angle_to(to) > deg_to_rad(beam_angle_deg):
		return false
	var q := PhysicsRayQueryParameters3D.create(origin, point, 1)
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()


func _build() -> void:
	for c: Node in get_children():
		if c.has_meta(&"generated"):
			c.free()
	var steel := StandardMaterial3D.new()
	steel.albedo_color = Color(0.3, 0.3, 0.35)
	var mast := MeshInstance3D.new()
	var mm := CylinderMesh.new()
	mm.top_radius = 0.12
	mm.bottom_radius = 0.18
	mm.height = height
	mast.mesh = mm
	mast.material_override = steel
	mast.position.y = height * 0.5
	mast.set_meta(&"generated", true)
	add_child(mast)
	_head = Node3D.new()
	_head.position.y = height
	_head.set_meta(&"generated", true)
	add_child(_head)
	# Hlava míří dolů pod úhlem ~35° (na zem před stožárem).
	var tilt := Node3D.new()
	tilt.rotation.x = deg_to_rad(-35.0)
	_head.add_child(tilt)
	_tilt = tilt
	var lamp := MeshInstance3D.new()
	var lm := CylinderMesh.new()
	lm.top_radius = 0.35
	lm.bottom_radius = 0.25
	lm.height = 0.6
	lamp.mesh = lm
	lamp.rotation.x = PI * 0.5
	lamp.material_override = steel
	tilt.add_child(lamp)
	_beam = MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.3
	cone.bottom_radius = tan(deg_to_rad(beam_angle_deg)) * reach
	cone.height = reach
	cone.cap_top = false
	cone.cap_bottom = false
	_beam.mesh = cone
	_beam.rotation.x = -PI * 0.5
	_beam.position = Vector3(0, 0, -reach * 0.5)
	_beam_mat = StandardMaterial3D.new()
	_beam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_beam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_beam_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_beam_mat.albedo_color = Color(1, 0.95, 0.7, 0.14)
	_beam.material_override = _beam_mat
	_beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	tilt.add_child(_beam)
	_light = SpotLight3D.new()
	_light.spot_range = reach + 4.0
	_light.spot_angle = beam_angle_deg + 4.0
	_light.light_energy = 6.0
	_light.light_color = Color(1, 0.95, 0.75)
	tilt.add_child(_light)
