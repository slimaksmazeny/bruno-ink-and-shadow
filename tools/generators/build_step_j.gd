## v0.2.5: plazení (nízké překážky 3D/2D), druhý strážný na střechách.
## Opakované spuštění je bezpečné. godot --headless --path game --script ../tools/generators/build_step_j.gd
extends SceneTree

const LEVEL: String = "res://levels/greybox/greybox_street.tscn"
const DROP: String = "res://world/gameplay/ink_drop.gd"

var lvl: Node
var _drop_i: int = 0
var _mat: Material


func _initialize() -> void:
	lvl = (load(LEVEL) as PackedScene).instantiate()
	for n: String in ["Crawl", "Guards2", "SignCrawl"]:
		var old: Node = lvl.get_node_or_null(n)
		if old != null:
			lvl.remove_child(old)
			old.free()
	_mat = (lvl.get_node("PaintingWorld/GoalLedge") as CSGBox3D).material

	var cr: Node3D = _group("Crawl")
	# 3D: nízký „stůl“ / trubky na ulici vedle startu (spodek 0,8 m).
	_box(cr, "CrawlTable3D", Vector3(5, 1.05, 11), Vector3(4, 0.5, 2.4))
	_box(cr, "CrawlLegA", Vector3(3.1, 0.4, 10.0), Vector3(0.2, 0.8, 0.2))
	_box(cr, "CrawlLegB", Vector3(6.9, 0.4, 12.0), Vector3(0.2, 0.8, 0.2))
	_drop(cr, Vector3(4.2, 0.4, 11))
	_drop(cr, Vector3(5.8, 0.4, 11))
	# 2D: nízká škvíra na první podlaze obrazu (spodek 0,8 m).
	_box(cr, "CrawlGap2D", Vector3(207.25, 2.15, 0), Vector3(2.5, 2.7, 4))
	_drop(cr, Vector3(207.25, 0.4, 0))

	var gs: Node3D = _group("Guards2")
	var g := CharacterBody3D.new()
	g.name = "GuardRoof"
	g.set_script(load("res://world/enemies/guard.gd"))
	g.position = Vector3(14, 6.05, -10)
	g.set("patrol_points", PackedVector3Array([Vector3(-3.5, 0, 0), Vector3(3.5, 0, 0)]))
	g.set("view_range", 7.0)
	g.set("loot", 40)
	_add(gs, g)

	var sign := Label3D.new()
	sign.name = "SignCrawl"
	sign.text = "GB_SIGN_CRAWL"
	sign.position = Vector3(5, 2.2, 12.6)
	sign.pixel_size = 0.008
	sign.font_size = 64
	sign.outline_size = 16
	sign.modulate = Color(0.7, 1, 0.7)
	sign.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_add(lvl, sign)

	var packed := PackedScene.new()
	var err: Error = packed.pack(lvl)
	if err == OK:
		err = ResourceSaver.save(packed, LEVEL)
	print("build_step_j: saved -> ", err, " (new drops: ", _drop_i, ")")
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


func _drop(parent: Node, pos: Vector3) -> void:
	var d := Area3D.new()
	d.name = "Ink%02d" % _drop_i
	d.set_script(load(DROP))
	d.set("collectible_id", "gb_ink_c%02d" % _drop_i)
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
