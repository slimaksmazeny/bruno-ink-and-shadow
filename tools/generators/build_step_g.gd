## v0.2.2 „Kostra hry“: přidá do testovací ulice HUD, checkpointy, kapky inkoustu,
## nebezpečné oblasti a strážného. Spouštět opakovaně je bezpečné (staré uzly smaže).
## godot --headless --path game --script ../tools/generators/build_step_g.gd
extends SceneTree

const LEVEL: String = "res://levels/greybox/greybox_street.tscn"
const GROUP_NAMES: Array[String] = ["Platforms2D", "Hud", "Checkpoints", "InkDrops", "Hazards", "Guards", "SignGuard", "SignHazard"]

var lvl: Node


func _initialize() -> void:
	lvl = (load(LEVEL) as PackedScene).instantiate()
	for n: String in GROUP_NAMES:
		var old: Node = lvl.get_node_or_null(n)
		if old != null:
			lvl.remove_child(old)
			old.free()

	var hud := CanvasLayer.new()
	hud.name = "Hud"
	hud.set_script(load("res://ui/hud/hud.gd"))
	_add(lvl, hud)

	var cps: Node3D = _group("Checkpoints")
	_checkpoint(cps, "cp_street_b", Vector3(19.5, 0, 9))
	_checkpoint(cps, "cp_painting_floor3", Vector3(229.5, 0, 0), true)

	var drops: Node3D = _group("InkDrops")
	var pts: Array[Vector3] = [
		# Ulice od startu k rampě
		Vector3(-2, 0.8, 11), Vector3(-4, 0.8, 11), Vector3(-6, 0.8, 11), Vector3(-8, 0.8, 11),
		# Skokové bedny + rampa
		Vector3(-14, 1.8, 10), Vector3(-18, 2.3, 10), Vector3(-22, 3.0, 10), Vector3(-4, 2.8, 4),
		# Oblouk přes propast
		Vector3(14.6, 2.0, 0), Vector3(15.75, 2.7, 0), Vector3(16.9, 2.0, 0),
		# Střechy
		Vector3(11, 5.3, -3.5), Vector3(14, 6.8, -10), Vector3(2, 12.4, -9),
		# Ulice B kolem strážného
		Vector3(22, 0.8, 6), Vector3(26, 0.8, 6), Vector3(30, 0.8, 6), Vector3(36, 0.8, -2),
		# Obraz (2D)
		Vector3(202.8, 2.0, 0), Vector3(203.5, 2.4, 0), Vector3(204.2, 2.0, 0),
		Vector3(211, 4.5, 0), Vector3(211, 6.5, 0),
		Vector3(216, 5.3, 0), Vector3(218.5, 5.3, 0), Vector3(224.5, 5.2, 0),
		Vector3(231, 0.8, 0), Vector3(233, 0.8, 0),
		Vector3(238, 5.0, 0), Vector3(238, 7.0, 0), Vector3(243.5, 5.8, 0),
		# 2D kit: průchozí plošina, pohyblivá plošina
		Vector3(200.5, 3.1, 0), Vector3(233.5, 6.2, 0),
	]
	for i: int in pts.size():
		var d := Area3D.new()
		d.name = "Ink%02d" % i
		d.set_script(load("res://world/gameplay/ink_drop.gd"))
		d.set("collectible_id", "gb_ink_%02d" % i)
		d.position = pts[i]
		_add(drops, d)

	var hz: Node3D = _group("Hazards")
	_hazard(hz, "InkPuddle", Vector3(34, 0, 3), Vector3(3.2, 0.3, 3.2), 0)
	_hazard(hz, "Spikes2D", Vector3(203.5, 0, 0), Vector3(1.5, 0.6, 1.5), 1)

	# 2D Rayman kit (v0.2.1 – W2-10, první díly).
	var plats: Node3D = _group("Platforms2D")
	_platform(plats, "OneWay1", "one_way_platform", Vector3(200.5, 2.2, 0), Vector3(3, 0.3, 4))
	_platform(plats, "Crumble1", "crumbling_platform", Vector3(223.3, 3.2, 0), Vector3(1.4, 0.35, 4))
	_platform(plats, "Crumble2", "crumbling_platform", Vector3(225.7, 2.2, 0), Vector3(1.4, 0.35, 4))
	var mp: Node3D = _platform(plats, "Lift1", "moving_platform", Vector3(233.5, 0.2, 0), Vector3(2.5, 0.4, 4))
	mp.set("travel", Vector3(0, 4.6, 0))

	var guards: Node3D = _group("Guards")
	var g := CharacterBody3D.new()
	g.name = "GuardStreetB"
	g.set_script(load("res://world/enemies/guard.gd"))
	g.position = Vector3(29, 0.05, 1.5)
	g.set("patrol_points", PackedVector3Array([Vector3(-6, 0, 0), Vector3(7, 0, 0)]))
	_add(guards, g)

	_sign("SignGuard", "GB_SIGN_GUARD", Vector3(24, 2.6, 9.5), Color(1, 0.75, 0.5))
	_sign("SignHazard", "GB_SIGN_HAZARD", Vector3(34, 1.4, 5.2), Color(0.85, 0.6, 1))

	var packed := PackedScene.new()
	var err: Error = packed.pack(lvl)
	if err == OK:
		err = ResourceSaver.save(packed, LEVEL)
	print("build_step_g: saved ", LEVEL, " -> ", err, " (ink drops: ", pts.size(), ")")
	lvl.free()
	quit()


func _group(n: String) -> Node3D:
	var g := Node3D.new()
	g.name = n
	_add(lvl, g)
	return g


func _checkpoint(parent: Node, id: String, pos: Vector3, in_2d: bool = false) -> void:
	var c := Area3D.new()
	c.name = id.to_pascal_case()
	c.set_script(load("res://world/gameplay/checkpoint.gd"))
	c.set("checkpoint_id", id)
	c.set("plane_2d", in_2d)
	c.position = pos
	_add(parent, c)


func _platform(parent: Node, n: String, script_name: String, pos: Vector3, size: Vector3) -> Node3D:
	var b := AnimatableBody3D.new()
	b.name = n
	b.set_script(load("res://world/platforms_2d/%s.gd" % script_name))
	b.set("size", size)
	b.position = pos
	_add(parent, b)
	return b


func _hazard(parent: Node, n: String, pos: Vector3, size: Vector3, look: int) -> void:
	var h := Area3D.new()
	h.name = n
	h.set_script(load("res://world/gameplay/hazard.gd"))
	h.set("size", size)
	h.set("look", look)
	h.position = pos
	_add(parent, h)


func _sign(n: String, key: String, pos: Vector3, color: Color) -> void:
	var l := Label3D.new()
	l.name = n
	l.text = key
	l.position = pos
	l.pixel_size = 0.008
	l.font_size = 64
	l.outline_size = 16
	l.modulate = color
	l.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_add(lvl, l)


func _add(parent: Node, n: Node) -> void:
	parent.add_child(n)
	n.owner = lvl
