## v0.2.7: laserové paprsky před trezorem (vysoký = plazení, nízký blikající = skok / načasování).
## Opakované spuštění je bezpečné. godot --headless --path game --script ../tools/generators/build_step_m.gd
extends SceneTree

const LEVEL: String = "res://levels/greybox/greybox_street.tscn"

var lvl: Node


func _initialize() -> void:
	lvl = (load(LEVEL) as PackedScene).instantiate()
	var old: Node = lvl.get_node_or_null("Lasers")
	if old != null:
		lvl.remove_child(old)
		old.free()
	var g := Node3D.new()
	g.name = "Lasers"
	_add(lvl, g)
	# Paprsky napříč ulicí B (osa X lokálně → otočit o 90°, aby vedly podél Z).
	_laser(g, "LaserHigh", Vector3(36.7, 0, -12.0), 24.0, 0.95, true, 0.0)
	_laser(g, "LaserBlink", Vector3(37.3, 0, -12.0), 24.0, 0.35, false, 1.6)
	var sign := Label3D.new()
	sign.name = "SignLaser"
	sign.text = "GB_SIGN_LASER"
	sign.position = Vector3(34.5, 2.2, 10.5)
	sign.pixel_size = 0.008
	sign.font_size = 56
	sign.outline_size = 14
	sign.modulate = Color(1, 0.6, 0.6)
	sign.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_add(g, sign)
	var packed := PackedScene.new()
	var err: Error = packed.pack(lvl)
	if err == OK:
		err = ResourceSaver.save(packed, LEVEL)
	print("build_step_m: saved -> ", err)
	lvl.free()
	quit()


func _laser(parent: Node, n: String, pos: Vector3, length: float, h: float, block: bool, blink: float) -> void:
	var l := Area3D.new()
	l.name = n
	l.set_script(load("res://world/gameplay/laser_tripwire.gd"))
	l.set("length", length)
	l.set("beam_height", h)
	l.set("block_standing", block)
	l.set("blink_period", blink)
	l.position = pos
	l.rotation.y = -PI * 0.5 # lokální +X → světové +Z
	_add(parent, l)


func _add(parent: Node, n: Node) -> void:
	parent.add_child(n)
	n.owner = lvl
