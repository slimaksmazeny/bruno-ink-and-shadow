## v0.2.3 Sly parkour + 2D vítr: trubka, lano, římsa, sloup, zlaté kapky, stoupavý vítr v obraze.
## Opakované spuštění je bezpečné (skupiny Parkour a Wind2D se smažou a postaví znovu).
## godot --headless --path game --script ../tools/generators/build_step_h.gd
extends SceneTree

const LEVEL: String = "res://levels/greybox/greybox_street.tscn"
const LINE: String = "res://world/anchors/line_anchor.gd"
const DROP: String = "res://world/gameplay/ink_drop.gd"

var lvl: Node
var _drop_i: int = 0


func _initialize() -> void:
	lvl = (load(LEVEL) as PackedScene).instantiate()
	for n: String in ["Parkour", "Wind2D", "SignParkour"]:
		var old: Node = lvl.get_node_or_null(n)
		if old != null:
			lvl.remove_child(old)
			old.free()

	var pk: Node3D = _group("Parkour")
	# Sloup uprostřed ulice – cíl lana.
	var pillar := StaticBody3D.new()
	pillar.name = "RopePillar"
	pillar.position = Vector3(-1, 4, -1)
	_add(pk, pillar)
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.6, 8, 1.6)
	col.shape = box
	_add(pillar, col)
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = box.size
	mesh.mesh = bm
	_add(pillar, mesh)

	# Trubka po přední zdi levého domu na střechu.
	_line(pk, "PipeHouseLeft", 1, Vector3(-11, 0, -5.85), Vector3.UP, 8.0, Vector3.BACK)
	# Lano ze střechy levého domu na sloup.
	var a := Vector3(-9.4, 8.02, -6.4)
	var b := Vector3(-1, 8.02, -1)
	_line(pk, "RopeToPillar", 3, a, (b - a).normalized(), a.distance_to(b), Vector3.BACK)
	# Římsa na hraně pravého domu (chytit z bedny na střeše).
	_line(pk, "LedgeHouseRight", 2, Vector3(9.3, 6.0, -5.98), Vector3.RIGHT, 9.4, Vector3.BACK)

	for t: float in [0.25, 0.5, 0.75]:
		_drop(pk, a.lerp(b, t) + Vector3.UP * 0.7)
	_drop(pk, Vector3(-11, 8.8, -8))
	_drop(pk, Vector3(12.5, 5.0, -5.4))
	_drop(pk, Vector3(16.5, 5.0, -5.4))
	_drop(pk, Vector3(-1, 8.9, -1), true)

	# 2D: stoupavý vítr nad propastí + zlatá kapka nahoře.
	var w: Node3D = _group("Wind2D")
	var wind := Area3D.new()
	wind.name = "WindPit"
	wind.set_script(load("res://world/platforms_2d/wind_column.gd"))
	wind.set("size", Vector3(2, 20, 4))
	wind.position = Vector3(224.5, -8, 0)
	_add(w, wind)
	_drop(w, Vector3(224.5, 7.5, 0))
	_drop(w, Vector3(224.5, 9.0, 0))
	_drop(w, Vector3(224.5, 10.8, 0), true)

	var sign := Label3D.new()
	sign.name = "SignParkour"
	sign.text = "GB_SIGN_PARKOUR"
	sign.position = Vector3(-11, 2.8, -4.4)
	sign.pixel_size = 0.008
	sign.font_size = 64
	sign.outline_size = 16
	sign.modulate = Color(0.55, 0.8, 1)
	sign.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_add(lvl, sign)

	var packed := PackedScene.new()
	var err: Error = packed.pack(lvl)
	if err == OK:
		err = ResourceSaver.save(packed, LEVEL)
	print("build_step_h: saved -> ", err, " (new drops: ", _drop_i, ")")
	lvl.free()
	quit()


func _line(parent: Node, n: String, type: int, pos: Vector3, axis: Vector3, length: float, outward: Vector3) -> void:
	var l := Area3D.new()
	l.name = n
	l.set_script(load(LINE))
	l.set("type", type)
	l.set("axis", axis)
	l.set("length", length)
	l.set("outward", outward)
	l.position = pos
	_add(parent, l)


func _drop(parent: Node, pos: Vector3, golden: bool = false) -> void:
	var d := Area3D.new()
	d.name = ("Gold%02d" if golden else "Ink%02d") % _drop_i
	d.set_script(load(DROP))
	d.set("collectible_id", "gb_ink_p%02d" % _drop_i)
	d.set("golden", golden)
	d.position = pos
	_add(parent, d)
	_drop_i += 1


func _group(n: String) -> Node3D:
	var g := Node3D.new()
	g.name = n
	_add(lvl, g)
	return g


func _add(parent: Node, n: Node) -> void:
	parent.add_child(n)
	n.owner = lvl
