## v0.2.4: 2D dráha za cílem (kruh přes propast, šachta na odrazy od zdí, rytmické písty),
## výstupní portál přesunut na konec; 3D kruh nad propastí v ulici a úzká římsa na prostředním domě.
## Opakované spuštění je bezpečné. godot --headless --path game --script ../tools/generators/build_step_i.gd
extends SceneTree

const LEVEL: String = "res://levels/greybox/greybox_street.tscn"
const DROP: String = "res://world/gameplay/ink_drop.gd"

var lvl: Node
var _drop_i: int = 0
var _mat: Material


func _initialize() -> void:
	lvl = (load(LEVEL) as PackedScene).instantiate()
	var pw: Node3D = lvl.get_node("PaintingWorld") as Node3D
	for n: String in ["Track2D", "Parkour2"]:
		var old: Node = lvl.get_node_or_null(n)
		if old != null:
			lvl.remove_child(old)
			old.free()
	_mat = (pw.get_node("GoalLedge") as CSGBox3D).material

	# --- 2D dráha (souřadnice světa, rovina z = 0) ---
	var tr: Node3D = _group("Track2D")
	_ring(tr, "Ring2D_1", Vector3(252.8, 9.2, 0))
	_box(tr, "Floor4", Vector3(262.75, 0, 0), Vector3(13.5, 10, 4))         # vrch y = 5
	_box(tr, "ShaftWallL", Vector3(264.5, 11.75, 0), Vector3(1, 8.5, 4))    # y 7.5..16 (pod ní vchod)
	_box(tr, "ShaftWallR", Vector3(269.0, 10, 0), Vector3(1, 10, 4))        # y 5..15
	_box(tr, "TopDeck", Vector3(271.75, 12.5, 0), Vector3(4.5, 5, 4))       # vrch y = 15, x 269.5..274
	var p1: Node3D = _plat(tr, "Piston1", "piston", Vector3(276.0, 9.0, 0), Vector3(2, 0.6, 4))
	p1.set("travel", Vector3(0, 5.6, 0))
	var p2: Node3D = _plat(tr, "Piston2", "piston", Vector3(278.5, 9.0, 0), Vector3(2, 0.6, 4))
	p2.set("travel", Vector3(0, 5.6, 0))
	p2.set("phase", 0.45)
	_box(tr, "EndDeck", Vector3(285.0, 12.5, 0), Vector3(9, 5, 4))          # vrch y = 15, x 280.5..289.5
	var cp := Area3D.new()
	cp.name = "CpFloor4"
	cp.set_script(load("res://world/gameplay/checkpoint.gd"))
	cp.set("checkpoint_id", "cp_painting_floor4")
	cp.set("plane_2d", true)
	cp.position = Vector3(258.0, 5.0, 0)
	_add(tr, cp)
	for x: float in [250.5, 252.8, 255.0]:
		_drop(tr, Vector3(x, 7.2 if x != 252.8 else 6.6, 0))
	for y: float in [8.0, 10.5, 13.0]:
		_drop(tr, Vector3(266.7, y, 0))
	_drop(tr, Vector3(266.7, 16.2, 0), true)
	_drop(tr, Vector3(277.25, 16.5, 0))
	# Výstupní portál na konec nové dráhy.
	var exit_portal: Node3D = pw.get_node("ExitPortal") as Node3D
	exit_portal.position = Vector3(287.0, 15.0, 0) - pw.position

	# --- 3D ---
	var pk: Node3D = _group("Parkour2")
	_ring(pk, "Ring3D_Gap", Vector3(15.75, 5.2, 6))
	_drop(pk, Vector3(15.75, 3.0, 6))
	var w := Area3D.new()
	w.name = "WallLedgeHouseMid"
	w.set_script(load("res://world/anchors/line_anchor.gd"))
	w.set("type", 4)
	w.set("axis", Vector3.RIGHT)
	w.set("length", 7.0)
	w.set("outward", Vector3.BACK)
	w.position = Vector3(-3.5, 3.0, -7.98)
	_add(pk, w)
	for x: float in [-2.0, 0.0, 2.0]:
		_drop(pk, Vector3(x, 3.8, -7.5))

	var packed := PackedScene.new()
	var err: Error = packed.pack(lvl)
	if err == OK:
		err = ResourceSaver.save(packed, LEVEL)
	print("build_step_i: saved -> ", err, " (new drops: ", _drop_i, ")")
	lvl.free()
	quit()


func _box(parent: Node, n: String, pos: Vector3, size: Vector3) -> void:
	var b := CSGBox3D.new()
	b.name = n
	b.size = size
	b.position = pos
	b.use_collision = true
	b.material = _mat
	_add(parent, b)


func _ring(parent: Node, n: String, pos: Vector3) -> void:
	var r := Area3D.new()
	r.name = n
	r.set_script(load("res://world/anchors/ring_anchor.gd"))
	r.position = pos
	_add(parent, r)


func _plat(parent: Node, n: String, script_name: String, pos: Vector3, size: Vector3) -> Node3D:
	var b := AnimatableBody3D.new()
	b.name = n
	b.set_script(load("res://world/platforms_2d/%s.gd" % script_name))
	b.set("size", size)
	b.position = pos
	_add(parent, b)
	return b


func _drop(parent: Node, pos: Vector3, golden: bool = false) -> void:
	var d := Area3D.new()
	d.name = ("Gold%02d" if golden else "Ink%02d") % _drop_i
	d.set_script(load(DROP))
	d.set("collectible_id", "gb_ink_t%02d" % _drop_i)
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
