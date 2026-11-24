## v0.2.6 Loupež: mise, trezor na konci ulice B, únikové auto u startu, klíč u strážného.
## Opakované spuštění je bezpečné. godot --headless --path game --script ../tools/generators/build_step_l.gd
extends SceneTree

const LEVEL: String = "res://levels/greybox/greybox_street.tscn"

var lvl: Node


func _initialize() -> void:
	lvl = (load(LEVEL) as PackedScene).instantiate()
	for n: String in ["Mission", "Heist"]:
		var old: Node = lvl.get_node_or_null(n)
		if old != null:
			lvl.remove_child(old)
			old.free()
	var m := Node.new()
	m.name = "Mission"
	m.set_script(load("res://levels/mission.gd"))
	_add(lvl, m)
	var h := Node3D.new()
	h.name = "Heist"
	_add(lvl, h)
	var v := Node3D.new()
	v.name = "Vault"
	v.set_script(load("res://world/gameplay/vault.gd"))
	v.position = Vector3(38.5, 0, 7)
	v.rotation.y = PI * 0.5 + PI # dvířka k ulici (−X)
	_add(h, v)
	var van := Node3D.new()
	van.name = "GetawayVan"
	van.set_script(load("res://world/gameplay/getaway.gd"))
	van.position = Vector3(11.5, 0, 9.5)
	_add(h, van)
	# Klíč nosí strážný v ulici B.
	var g: Node = lvl.get_node("Guards/GuardStreetB")
	g.set("carries_key", "vault_key")
	var packed := PackedScene.new()
	var err: Error = packed.pack(lvl)
	if err == OK:
		err = ResourceSaver.save(packed, LEVEL)
	print("build_step_l: saved -> ", err)
	lvl.free()
	quit()


func _add(parent: Node, n: Node) -> void:
	parent.add_child(n)
	n.owner = lvl
