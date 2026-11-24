## v0.2.5: vrstvené pozadí za 2D dráhou v obraze (kopce, střechy, stromy, měsíc).
## Opakované spuštění je bezpečné. godot --headless --path game --script ../tools/generators/build_step_k.gd
extends SceneTree

const LEVEL: String = "res://levels/greybox/greybox_street.tscn"
const LAYER: String = "res://world/platforms_2d/backdrop_layer.gd"

var lvl: Node


func _initialize() -> void:
	lvl = (load(LEVEL) as PackedScene).instantiate()
	var old: Node = lvl.get_node_or_null("Backdrop2D")
	if old != null:
		lvl.remove_child(old)
		old.free()
	# Staré úzké pozadí obrazu (BgFar, BgHills*, BgBush*) nahrazuje tato vrstvená verze.
	var pw: Node = lvl.get_node("PaintingWorld")
	for c: Node in pw.get_children():
		if String(c.name).begins_with("Bg"):
			pw.remove_child(c)
			c.free()
	var g := Node3D.new()
	g.name = "Backdrop2D"
	_add(lvl, g)
	var sky := MeshInstance3D.new()
	sky.name = "PaperSky"
	var qm := QuadMesh.new()
	qm.size = Vector2(700, 260)
	sky.mesh = qm
	var skm := StandardMaterial3D.new()
	skm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	skm.albedo_color = Color(0.95, 0.9, 0.78)
	sky.material_override = skm
	sky.position = Vector3(245, 40, -120)
	_add(g, sky)
	# x střed dráhy ~245; čím dál (záporné z), tím širší a světlejší (atmosféra).
	_layer(g, "FarHills", 0, Vector3(245, 2, -60), 360.0, 22.0, Color(0.72, 0.66, 0.78), 7)
	_layer(g, "MidRoofs", 2, Vector3(245, -1, -32), 220.0, 9.0, Color(0.42, 0.35, 0.55), 3)
	_layer(g, "NearTrees", 1, Vector3(245, -2, -14), 140.0, 6.5, Color(0.14, 0.11, 0.26), 11)
	var moon := MeshInstance3D.new()
	moon.name = "InkSun"
	var sm := SphereMesh.new()
	sm.radius = 5.0
	sm.height = 10.0
	moon.mesh = sm
	var mm := StandardMaterial3D.new()
	mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mm.albedo_color = Color(0.88, 0.38, 0.28)
	moon.material_override = mm
	moon.position = Vector3(265, 30, -90)
	_add(g, moon)
	var packed := PackedScene.new()
	var err: Error = packed.pack(lvl)
	if err == OK:
		err = ResourceSaver.save(packed, LEVEL)
	print("build_step_k: saved -> ", err)
	lvl.free()
	quit()


func _layer(parent: Node, n: String, style: int, pos: Vector3, w: float, h: float, c: Color, s: int) -> void:
	var m := MeshInstance3D.new()
	m.name = n
	m.set_script(load(LAYER))
	m.set("style", style)
	m.set("width", w)
	m.set("height", h)
	m.set("color", c)
	m.set("seed", s)
	m.position = pos
	_add(parent, m)


func _add(parent: Node, n: Node) -> void:
	parent.add_child(n)
	n.owner = lvl
