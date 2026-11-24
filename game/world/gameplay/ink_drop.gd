## Kapka inkoustu – sběratelský předmět (jako lumy v Raymanovi / mince ve Slyovi).
## Každá kapka má unikátní collectible_id; sebrané se ukládají (GameState → SaveManager).
## Rychle po sobě sebrané kapky zvoní čím dál výš (série).
@tool
class_name InkDrop
extends Area3D

const CHAPTER_ID: String = "greybox"
const CATEGORY: String = "ink"
const STREAK_TIME: float = 0.9

static var _streak: int = 0
static var _streak_time_ms: int = 0

@export var collectible_id: String = ""
## Zlatá kapka (Rayman „zlaté lumy“): větší, zlatá, má hodnotu 5. Bývá schovaná v obloucích skoků.
@export var golden: bool = false:
	set(v):
		golden = v
		if is_inside_tree():
			_build()


## Kolik kapek tahle kapka „váží“ v počítadle.
func value() -> int:
	return 5 if golden else 1

var collected: bool = false
var _mesh: Node3D
var _t: float = 0.0


func _ready() -> void:
	collision_layer = 64
	collision_mask = 2
	monitorable = false
	_build()
	_t = fmod(global_position.x * 0.7 + global_position.z * 0.3, TAU) if is_inside_tree() else 0.0
	if Engine.is_editor_hint():
		return
	add_to_group(&"ink_drop")
	if collectible_id.is_empty():
		push_warning("InkDrop %s nemá collectible_id – nebude se ukládat." % get_path())
	elif GameState.is_collected(CHAPTER_ID, CATEGORY, collectible_id):
		collected = true
		visible = false
		set_deferred("monitoring", false)
		return
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if _mesh == null or collected:
		return
	_t += delta
	_mesh.rotation.y += delta * 2.0
	_mesh.position.y = sin(_t * 2.6) * 0.12


func _on_body_entered(body: Node) -> void:
	if collected or not (body is Player):
		return
	collected = true
	var now: int = Time.get_ticks_msec()
	_streak = _streak + 1 if now - _streak_time_ms < int(STREAK_TIME * 1000.0) else 0
	_streak_time_ms = now
	if golden:
		AudioManager.play(&"checkpoint", 0.0, 1.3, 0.0)
	AudioManager.play(&"pickup", 0.0, 1.0 + minf(float(_streak), 8.0) * 0.06, 0.0)
	if not collectible_id.is_empty():
		GameState.mark_collected(CHAPTER_ID, CATEGORY, collectible_id) # vyšle Events.collectible_collected
	else:
		Events.collectible_collected.emit(collectible_id)
	set_deferred("monitoring", false)
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(_mesh, "position:y", _mesh.position.y + 0.8, 0.25).set_trans(Tween.TRANS_BACK)
	tw.tween_property(_mesh, "scale", Vector3.ZERO, 0.25).set_delay(0.08)
	tw.chain().tween_callback(func() -> void: visible = false)


func _build() -> void:
	for c: Node in get_children():
		if c.has_meta(&"generated"):
			c.free()
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.55
	shape.shape = sphere
	shape.set_meta(&"generated", true)
	add_child(shape)
	_mesh = Node3D.new()
	_mesh.set_meta(&"generated", true)
	add_child(_mesh)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.75, 0.15) if golden else Color(0.12, 0.22, 0.75)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.7, 0.1) if golden else Color(0.2, 0.4, 1.0)
	mat.emission_energy_multiplier = 0.8
	mat.roughness = 0.15
	var body := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.17
	s.height = 0.34
	body.mesh = s
	body.material_override = mat
	_mesh.add_child(body)
	if golden:
		_mesh.scale = Vector3.ONE * 1.7
	var tip := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.0
	c.bottom_radius = 0.15
	c.height = 0.26
	tip.mesh = c
	tip.position.y = 0.2
	tip.material_override = mat
	_mesh.add_child(tip)
