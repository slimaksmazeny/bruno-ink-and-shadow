## Únikové auto (dodávka). Až má Bruno poklad, E / ○ u dodávky = konec loupeže.
@tool
class_name Getaway
extends Node3D

## Dodávka je velká – dá se použít z větší vzdálenosti.
var interact_range: float = 3.2


func _ready() -> void:
	_build()
	if Engine.is_editor_hint():
		return
	add_to_group(&"interactable")


func can_interact(_p: Player) -> bool:
	var m: Mission = get_tree().get_first_node_in_group(&"mission") as Mission
	return m != null and m.step == Mission.Step.ESCAPE


func get_prompt() -> String:
	return "PROMPT_GETAWAY"


func interact(_p: Player) -> void:
	var m: Mission = get_tree().get_first_node_in_group(&"mission") as Mission
	if m != null:
		AudioManager.play(&"portal", 0.0, 1.2)
		m.notify(&"escaped")


func _build() -> void:
	for c: Node in get_children():
		if c.has_meta(&"generated"):
			c.free()
	var body := StaticBody3D.new()
	body.set_meta(&"generated", true)
	add_child(body)
	var paint := StandardMaterial3D.new()
	paint.albedo_color = Color(0.25, 0.55, 0.5)
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.08, 0.08, 0.1)
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.6, 0.8, 0.95)
	glass.emission_enabled = true
	glass.emission = Color(0.4, 0.6, 0.8)
	glass.emission_energy_multiplier = 0.3
	for part: Array in [[Vector3(0, 1.05, 0), Vector3(3.6, 1.5, 1.8), paint], [Vector3(1.4, 1.45, 0), Vector3(0.9, 0.6, 1.82), glass]]:
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = part[1]
		cs.shape = bs
		cs.position = part[0]
		body.add_child(cs)
		var m := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = part[1]
		m.mesh = bm
		m.material_override = part[2]
		m.position = part[0]
		body.add_child(m)
	for wx: float in [-1.1, 1.1]:
		for wz: float in [-0.9, 0.9]:
			var w := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.35
			cyl.bottom_radius = 0.35
			cyl.height = 0.25
			w.mesh = cyl
			w.material_override = dark
			w.rotation.x = PI * 0.5
			w.position = Vector3(wx, 0.35, wz)
			body.add_child(w)
