## Sklenice se světluškami – schovaný sběratelský předmět (hlavně v obrazech).
## Rozbije se holí nebo tenisákem; světlušky vyletí a započítají se (ukládá se).
@tool
class_name FireflyJar
extends StaticBody3D

const CATEGORY: String = "firefly"

@export var jar_id: String = ""

var broken: bool = false
var _glass: MeshInstance3D
var _flies: Array[MeshInstance3D] = []
var _t: float = 0.0


func _ready() -> void:
	collision_layer = 16
	collision_mask = 0
	_build()
	if Engine.is_editor_hint():
		return
	add_to_group(&"firefly_jar")
	if not jar_id.is_empty() and GameState.is_collected(InkDrop.CHAPTER_ID, CATEGORY, jar_id):
		broken = true
		visible = false
		collision_layer = 0
		return
	add_to_group(&"hittable")


func _process(delta: float) -> void:
	if broken:
		return
	_t += delta
	for i: int in _flies.size():
		var a: float = _t * (1.5 + float(i) * 0.4) + float(i) * 2.1
		_flies[i].position = Vector3(cos(a) * 0.12, 0.35 + sin(a * 1.3) * 0.12, sin(a) * 0.12)


func on_cane_hit(_info: Dictionary) -> void:
	if broken:
		return
	broken = true
	collision_layer = 0
	remove_from_group(&"hittable")
	AudioManager.play_at(&"crate_break", global_position, -4.0, 1.8)
	AudioManager.play(&"checkpoint", -2.0, 1.4, 0.0)
	if not jar_id.is_empty():
		GameState.mark_collected(InkDrop.CHAPTER_ID, CATEGORY, jar_id)
	_glass.visible = false
	for i: int in _flies.size():
		var f: MeshInstance3D = _flies[i]
		var tw: Tween = create_tween()
		var to: Vector3 = f.position + Vector3(cos(float(i) * 1.7), 2.5 + float(i) * 0.3, sin(float(i) * 1.7))
		tw.tween_property(f, "position", to, 1.2).set_trans(Tween.TRANS_SINE)
		tw.parallel().tween_property(f, "scale", Vector3.ZERO, 1.2)
	var done: Tween = create_tween()
	done.tween_interval(1.3)
	done.tween_callback(func() -> void: visible = false)


func _build() -> void:
	for c: Node in get_children():
		if c.has_meta(&"generated"):
			c.free()
	_flies.clear()
	var shape := CollisionShape3D.new()
	var cyl_shape := CylinderShape3D.new()
	cyl_shape.radius = 0.25
	cyl_shape.height = 0.6
	shape.shape = cyl_shape
	shape.position.y = 0.3
	shape.set_meta(&"generated", true)
	add_child(shape)
	_glass = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.2
	cyl.bottom_radius = 0.25
	cyl.height = 0.6
	_glass.mesh = cyl
	_glass.position.y = 0.3
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.7, 0.9, 1.0, 0.35)
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gm.roughness = 0.05
	_glass.material_override = gm
	_glass.set_meta(&"generated", true)
	add_child(_glass)
	var lid := MeshInstance3D.new()
	var lm := CylinderMesh.new()
	lm.top_radius = 0.22
	lm.bottom_radius = 0.22
	lm.height = 0.08
	lid.mesh = lm
	lid.position.y = 0.63
	var lmat := StandardMaterial3D.new()
	lmat.albedo_color = Color(0.6, 0.4, 0.2)
	lid.material_override = lmat
	lid.set_meta(&"generated", true)
	_glass.add_child(lid)
	lid.position.y = 0.33
	var fm := StandardMaterial3D.new()
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fm.albedo_color = Color(1, 0.95, 0.4)
	for i: int in 4:
		var f := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.04
		sm.height = 0.08
		f.mesh = sm
		f.material_override = fm
		f.set_meta(&"generated", true)
		add_child(f)
		_flies.append(f)
	var light := OmniLight3D.new()
	light.light_color = Color(1, 0.9, 0.4)
	light.light_energy = 0.8
	light.omni_range = 2.5
	light.position.y = 0.35
	light.set_meta(&"generated", true)
	add_child(light)
