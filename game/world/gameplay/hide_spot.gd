## Úkryt (sud / keř): Bruno do něj vleze (E), strážní ho nevidí. Ven: E, skok nebo pohyb.
## Když se schová během poplachu, strážný ho ztratí z očí a začne hledat.
## Zpoza úkrytu koukají jen uši (aby hráč věděl, že je uvnitř).
@tool
class_name HideSpot
extends Node3D

enum Kind { BARREL, BUSH }

@export var kind: Kind = Kind.BARREL:
	set(v):
		kind = v
		if is_inside_tree():
			_build()

var occupant: Player
var _cooldown: float = 0.0
var _ears: Node3D
var _body: Node3D


func _ready() -> void:
	_build()
	if Engine.is_editor_hint():
		return
	add_to_group(&"interactable")
	add_to_group(&"hide_spot")


func can_interact(p: Player) -> bool:
	return occupant == null and p.hidden_in == null and p.is_on_floor()


func get_prompt() -> String:
	return "HUD_HIDE"


func interact(p: Player) -> void:
	if occupant != null:
		return
	occupant = p
	p.hidden_in = self
	p.global_position = global_position + Vector3(0, 0.05, 0)
	p.velocity = Vector3.ZERO
	p.reset_physics_interpolation()
	p.state_machine.transition_to(&"Locked", {"force": true})
	p.visual.visible = false
	_ears.visible = true
	_cooldown = 0.35
	_wobble(0.18)
	AudioManager.play_at(&"land", global_position, -4.0, 1.4)
	var hud: Node = get_tree().get_first_node_in_group(&"hud")
	if hud != null:
		hud.call("show_toast", tr("HUD_HIDDEN"))


## Vylézt ven (vstup hráče, smrt, respawn).
func force_exit(hop: bool = true) -> void:
	if occupant == null:
		return
	var p: Player = occupant
	occupant = null
	_ears.visible = false
	if not is_instance_valid(p):
		return
	p.hidden_in = null
	p.visual.visible = true
	if hop and p.is_inside_tree():
		p.state_machine.transition_to(&"Air", {"force": true})
		var out: Vector3 = p.visual.get_forward()
		p.velocity = Vector3(out.x, 0.0, out.z) * 3.0 + Vector3.UP * 6.0
	_wobble(0.12)
	AudioManager.play_at(&"jump", global_position, -6.0, 1.2)


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or occupant == null:
		return
	_cooldown = maxf(_cooldown - delta, 0.0)
	# Uši se lehce pohupují – Bruno se rozhlíží.
	_ears.rotation.y = sin(Time.get_ticks_msec() * 0.002) * 0.6
	if _cooldown > 0.0:
		return
	var moving: bool = Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back").length() > 0.5
	if Input.is_action_just_pressed(&"action") or Input.is_action_just_pressed(&"jump") or moving:
		force_exit()


func _wobble(amount: float) -> void:
	var tw: Tween = create_tween()
	tw.tween_property(_body, "scale", Vector3(1.0 + amount, 1.0 - amount, 1.0 + amount), 0.08)
	tw.tween_property(_body, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _build() -> void:
	for c: Node in get_children():
		if c.has_meta(&"generated"):
			c.free()
	_body = Node3D.new()
	_body.set_meta(&"generated", true)
	add_child(_body)
	if kind == Kind.BARREL:
		var wood := StandardMaterial3D.new()
		wood.albedo_color = Color(0.55, 0.32, 0.17)
		wood.roughness = 0.85
		var band := StandardMaterial3D.new()
		band.albedo_color = Color(0.22, 0.2, 0.2)
		band.metallic = 0.6
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.5
		cyl.bottom_radius = 0.5
		cyl.height = 1.2
		_part(cyl, Vector3(0, 0.6, 0), Vector3.ONE, wood)
		for y: float in [0.22, 0.98]:
			var ring := CylinderMesh.new()
			ring.top_radius = 0.52
			ring.bottom_radius = 0.52
			ring.height = 0.07
			_part(ring, Vector3(0, y, 0), Vector3.ONE, band)
		var lid := CylinderMesh.new()
		lid.top_radius = 0.44
		lid.bottom_radius = 0.44
		lid.height = 0.04
		var dark := StandardMaterial3D.new()
		dark.albedo_color = Color(0.32, 0.18, 0.1)
		_part(lid, Vector3(0, 1.21, 0), Vector3.ONE, dark)
	else:
		var leaf := StandardMaterial3D.new()
		leaf.albedo_color = Color(0.42, 0.52, 0.28)
		leaf.roughness = 0.9
		var leaf2 := StandardMaterial3D.new()
		leaf2.albedo_color = Color(0.5, 0.6, 0.32)
		var sph := SphereMesh.new()
		sph.radial_segments = 10
		sph.rings = 6
		for b: Array in [[Vector3(0, 0.55, 0), 1.3], [Vector3(0.45, 0.4, 0.2), 0.9], [Vector3(-0.4, 0.42, -0.25), 1.0], [Vector3(0.1, 0.45, -0.5), 0.8], [Vector3(-0.2, 0.9, 0.2), 0.8]]:
			_part(sph, b[0], Vector3.ONE * float(b[1]), leaf if randf() < 0.5 else leaf2)
	# Uši (vidět jen když je Bruno uvnitř).
	_ears = Node3D.new()
	_ears.set_meta(&"generated", true)
	_ears.position.y = 1.25 if kind == Kind.BARREL else 1.25
	_ears.visible = false
	add_child(_ears)
	var fur := StandardMaterial3D.new()
	fur.albedo_color = Color(0.13, 0.08, 0.06)
	var ear := BoxMesh.new()
	ear.size = Vector3(0.1, 0.28, 0.16)
	for s: float in [-1.0, 1.0]:
		var e := MeshInstance3D.new()
		e.mesh = ear
		e.material_override = fur
		e.position = Vector3(0.13 * s, 0.1, 0)
		e.rotation_degrees.z = -18.0 * s
		_ears.add_child(e)


func _part(mesh: Mesh, pos: Vector3, scl: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.scale = scl
	_body.add_child(mi)
