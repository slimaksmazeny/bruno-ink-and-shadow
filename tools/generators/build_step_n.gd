## v0.2.8: inkoustové kaňky (2D nepřátelé), sklenice se světluškami, piškoty.
## Opakované spuštění je bezpečné. godot --headless --path game --script ../tools/generators/build_step_n.gd
extends SceneTree

const LEVEL: String = "res://levels/greybox/greybox_street.tscn"

var lvl: Node


func _initialize() -> void:
	lvl = (load(LEVEL) as PackedScene).instantiate()
	var old: Node = lvl.get_node_or_null("Critters")
	if old != null:
		lvl.remove_child(old)
		old.free()
	var g := Node3D.new()
	g.name = "Critters"
	_add(lvl, g)
	# Kaňky v obraze (plošiny: Floor3 227–241, Floor4 256–269.5, EndDeck 280.5–289.5).
	_blob(g, "BlobFloor3", Vector3(238.5, 0.05, 0), 1.0, 2.0)
	_blob(g, "BlobFloor4", Vector3(260.0, 5.05, 0), -1.0, 3.0)
	_blob(g, "BlobEndDeck", Vector3(283.0, 15.05, 0), 1.0)
	# Sklenice se světluškami (schované).
	_jar(g, "JarOneWay", "jar_oneway", Vector3(201.5, 2.35, 0))
	_jar(g, "JarHighLedge", "jar_highledge", Vector3(221.3, 4.5, 0))
	_jar(g, "JarTopDeck", "jar_topdeck", Vector3(273.4, 15.0, 0))
	# Piškoty.
	_treat(g, "TreatFloor3", Vector3(236.0, 0, 0))
	_treat(g, "TreatStreetB", Vector3(21.0, 0, 10.5))
	_treat(g, "TreatRoofLeft", Vector3(-15.0, 8.0, -11.0))
	var packed := PackedScene.new()
	var err: Error = packed.pack(lvl)
	if err == OK:
		err = ResourceSaver.save(packed, LEVEL)
	print("build_step_n: saved -> ", err)
	lvl.free()
	quit()


func _blob(parent: Node, n: String, pos: Vector3, dir: float, half_width: float = 0.0) -> void:
	var b := CharacterBody3D.new()
	b.name = n
	b.set_script(load("res://world/enemies/ink_blob.gd"))
	b.set("start_dir", dir)
	b.set("patrol_half_width", half_width)
	b.position = pos
	_add(parent, b)


func _jar(parent: Node, n: String, id: String, pos: Vector3) -> void:
	var j := StaticBody3D.new()
	j.name = n
	j.set_script(load("res://world/gameplay/firefly_jar.gd"))
	j.set("jar_id", id)
	j.position = pos
	_add(parent, j)


func _treat(parent: Node, n: String, pos: Vector3) -> void:
	var t := Area3D.new()
	t.name = n
	t.set_script(load("res://world/gameplay/treat.gd"))
	t.position = pos
	_add(parent, t)


func _add(parent: Node, n: Node) -> void:
	parent.add_child(n)
	n.owner = lvl
