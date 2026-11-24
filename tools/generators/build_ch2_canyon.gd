## Kapitola 2 „Kaňon“ – první hratelná verze (greybox). Postaví celou scénu od nuly.
## Loupež: klíč od důlního trezoru nosí strážný u řeky → přes řeku (lano / kruh) →
## tábor (strážní, plazení, lasery) → trezor v boudě → zpět k dodávce.
## godot --headless --path game --script ../tools/generators/build_ch2_canyon.gd
extends SceneTree

const OUT: String = "res://levels/ch2_canyon/canyon.tscn"

var lvl: Node3D
var _drop_i: int = 0
var _sand: StandardMaterial3D
var _rock: StandardMaterial3D
var _wood: StandardMaterial3D


func _initialize() -> void:
	lvl = Node3D.new()
	lvl.name = "CanyonLevel"
	_materials()
	_environment()
	_geometry()
	_actors()
	_content()
	_painting()
	var packed := PackedScene.new()
	var err: Error = packed.pack(lvl)
	if err == OK:
		err = ResourceSaver.save(packed, OUT)
	print("build_ch2_canyon: saved ", OUT, " -> ", err, " (drops: ", _drop_i, ")")
	lvl.free()
	quit()


func _materials() -> void:
	_sand = StandardMaterial3D.new()
	_sand.albedo_color = Color(0.82, 0.55, 0.36)
	_sand.roughness = 0.95
	_rock = StandardMaterial3D.new()
	_rock.albedo_color = Color(0.62, 0.34, 0.24)
	_rock.roughness = 0.9
	_wood = StandardMaterial3D.new()
	_wood.albedo_color = Color(0.45, 0.3, 0.18)


func _environment() -> void:
	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	var env := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.32, 0.36, 0.62)
	sm.sky_horizon_color = Color(0.98, 0.62, 0.4)
	sm.ground_horizon_color = Color(0.85, 0.55, 0.4)
	sm.ground_bottom_color = Color(0.3, 0.2, 0.18)
	sm.sun_angle_max = 20.0
	sky.sky_material = sm
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.95, 0.65, 0.45)
	env.fog_density = 0.006
	we.environment = env
	_add(lvl, we)
	var sun := DirectionalLight3D.new()
	sun.name = "DuskSun"
	sun.rotation_degrees = Vector3(-24, -35, 0)
	sun.light_color = Color(1.0, 0.78, 0.55)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	_add(lvl, sun)


func _geometry() -> void:
	var g: Node3D = _group("Geometry")
	# Dno kaňonu se řekou (propast) mezi x 32 a 40.
	_box(g, "FloorWest", Vector3(13.5, -0.5, 0), Vector3(37, 1, 26), _sand)
	_box(g, "FloorEast", Vector3(67.5, -0.5, 0), Vector3(55, 1, 26), _sand)
	_box(g, "RiverBed", Vector3(36, -14, 0), Vector3(8, 1, 26), _rock)
	# Stěny kaňonu a konce.
	_box(g, "WallNorth", Vector3(45, 7, -13.5), Vector3(100, 16, 1), _rock)
	_box(g, "WallSouth", Vector3(45, 7, 13.5), Vector3(100, 16, 1), _rock)
	_box(g, "WallWest", Vector3(-5.5, 7, 0), Vector3(1, 16, 28), _rock)
	_box(g, "WallEast", Vector3(95.5, 7, 0), Vector3(1, 16, 28), _rock)
	# Stolové hory (mesy).
	_box(g, "MesaA", Vector3(16, 2, -6), Vector3(6, 4, 6), _rock)      # vrch 4
	_box(g, "MesaB", Vector3(24, 3, 5), Vector3(5, 6, 5), _rock)       # vrch 6
	_box(g, "MesaC", Vector3(55, 2.5, -7.5), Vector3(8, 5, 6), _rock)  # vrch 5, přední stěna z = -4.5
	_box(g, "StepCrate", Vector3(55, 0.75, -3.3), Vector3(1.5, 1.5, 1.5), _wood)
	# Bouda s trezorem (otevřená k západu).
	_box(g, "ShackBack", Vector3(80, 1.75, 0), Vector3(0.4, 3.5, 8), _wood)
	_box(g, "ShackSideN", Vector3(76, 1.75, -4), Vector3(8, 3.5, 0.4), _wood)
	_box(g, "ShackSideS", Vector3(76, 1.75, 4), Vector3(8, 3.5, 0.4), _wood)
	_box(g, "ShackRoof", Vector3(76, 3.6, 0), Vector3(8.4, 0.3, 8.4), _wood)
	# Důlní vozík jako nízká překážka (plazení) v táboře.
	_box(g, "CartTop", Vector3(50, 1.05, 6), Vector3(4, 0.5, 2.4), _wood)
	_box(g, "CartLegA", Vector3(48.1, 0.4, 5.0), Vector3(0.2, 0.8, 0.2), _wood)
	_box(g, "CartLegB", Vector3(51.9, 0.4, 7.0), Vector3(0.2, 0.8, 0.2), _wood)


func _actors() -> void:
	var player: Node3D = (load("res://player/player.tscn") as PackedScene).instantiate() as Node3D
	player.name = "Player"
	player.position = Vector3(2, 0.05, 0)
	player.rotation.y = -PI * 0.5
	_add(lvl, player)
	var cam: Node3D = (load("res://camera/hybrid_camera.tscn") as PackedScene).instantiate() as Node3D
	cam.name = "HybridCamera"
	_add(lvl, cam)
	# Exportované uzly se nastavují objektem – PackedScene je uloží jako cestu.
	cam.set("target", player)
	player.set("camera", cam)
	var hud := CanvasLayer.new()
	hud.name = "Hud"
	hud.set_script(load("res://ui/hud/hud.gd"))
	_add(lvl, hud)
	var m := Node.new()
	m.name = "Mission"
	m.set_script(load("res://levels/mission.gd"))
	m.set("chapter_id", "canyon")
	m.set("key_id", "mine_key")
	_add(lvl, m)


func _content() -> void:
	var c: Node3D = _group("Content")
	# Parkour: tyč na mesu A, lano z mesy A na mesu B, špička na mese B, lano přes řeku, kruh nad řekou.
	_line(c, "PoleMesaA", 1, Vector3(12.85, 0, -6), Vector3.UP, 4.0, Vector3.LEFT)
	var a := Vector3(18.6, 4.02, -3.4)
	var b := Vector3(22.0, 6.02, 3.0)
	_line(c, "RopeAB", 3, a, (b - a).normalized(), a.distance_to(b), Vector3.BACK)
	var spire: Node3D = (load("res://world/anchors/spire_anchor.tscn") as PackedScene).instantiate() as Node3D
	spire.name = "SpireMesaB"
	spire.position = Vector3(24, 6.4, 5)
	_add(c, spire)
	_line(c, "RopeRiver", 3, Vector3(31.6, 0.02, 7), Vector3.RIGHT, 8.8, Vector3.BACK)
	var ring := Area3D.new()
	ring.name = "RingRiver"
	ring.set_script(load("res://world/anchors/ring_anchor.gd"))
	ring.position = Vector3(36, 5.3, -3)
	_add(c, ring)
	# Římsa na mese C (z bedny).
	_line(c, "LedgeMesaC", 2, Vector3(51.3, 5.0, -4.48), Vector3.RIGHT, 7.4, Vector3.BACK)

	# Strážní.
	_guard(c, "GuardRiver", Vector3(20, 0.05, 0), PackedVector3Array([Vector3(-6, 0, 0), Vector3(8, 0, 0)]), "mine_key", 20)
	_guard(c, "GuardCamp", Vector3(58, 0.05, 3), PackedVector3Array([Vector3(-8, 0, 0), Vector3(5, 0, 0)]), "", 30)
	_guard(c, "GuardMesaC", Vector3(55, 5.05, -8), PackedVector3Array([Vector3(-3, 0, 0), Vector3(3, 0, 0)]), "", 45)

	# Lasery před boudou (vysoký = plazení, nízký bliká).
	_laser(c, "LaserHigh", Vector3(68.5, 0, -13), 26.0, 0.95, true, 0.0)
	_laser(c, "LaserBlink", Vector3(69.3, 0, -13), 26.0, 0.35, false, 1.5)

	# Trezor v boudě, dodávka u startu.
	var v := Node3D.new()
	v.name = "Vault"
	v.set_script(load("res://world/gameplay/vault.gd"))
	v.set("key_id", "mine_key")
	v.position = Vector3(78.6, 0, 0)
	v.rotation.y = PI * 1.5
	_add(c, v)
	var van := Node3D.new()
	van.name = "GetawayVan"
	van.set_script(load("res://world/gameplay/getaway.gd"))
	van.position = Vector3(4, 0, 8)
	_add(c, van)

	# Checkpointy, nebezpečí, piškoty, světlušky.
	_area(c, "CpRiverEast", "res://world/gameplay/checkpoint.gd", Vector3(42, 0, 8), {"checkpoint_id": "cp_canyon_river"})
	_area(c, "CpCamp", "res://world/gameplay/checkpoint.gd", Vector3(64, 0, 9), {"checkpoint_id": "cp_canyon_camp"})
	_area(c, "Quicksand", "res://world/gameplay/hazard.gd", Vector3(60, 0, 5.5), {"size": Vector3(3, 0.3, 3)})
	_area(c, "TreatRiver", "res://world/gameplay/treat.gd", Vector3(44, 0, -8), {})
	_area(c, "TreatMesaB", "res://world/gameplay/treat.gd", Vector3(24.5, 6.0, 6.2), {})
	var jar := StaticBody3D.new()
	jar.name = "JarMesaC"
	jar.set_script(load("res://world/gameplay/firefly_jar.gd"))
	jar.set("jar_id", "jar_canyon_mesac")
	jar.position = Vector3(58, 5.0, -9.5)
	_add(c, jar)

	# Kapky inkoustu po trase (+ zlaté na mesách).
	for x: float in [5.0, 7.0, 9.0, 11.0]:
		_drop(c, Vector3(x, 0.8, 0))
	for t: float in [0.25, 0.5, 0.75]:
		_drop(c, a.lerp(b, t) + Vector3.UP * 0.7)
	_drop(c, Vector3(15, 4.8, -6))
	_drop(c, Vector3(24, 7.6, 5), true)
	for x: float in [33.5, 36.0, 38.5]:
		_drop(c, Vector3(x, 0.8, 7))
	_drop(c, Vector3(36, 3.2, -3))
	for x: float in [44.0, 47.0]:
		_drop(c, Vector3(x, 0.8, 0))
	_drop(c, Vector3(49.3, 0.4, 6))
	_drop(c, Vector3(50.7, 0.4, 6))
	for x: float in [53.0, 55.0, 57.0]:
		_drop(c, Vector3(x, 4.0, -4.0))
	_drop(c, Vector3(55, 5.8, -6), true)
	for x: float in [62.0, 65.0]:
		_drop(c, Vector3(x, 0.8, -6))
	_drop(c, Vector3(74, 0.8, 0))
	_drop(c, Vector3(28, 0.8, -10))
	_drop(c, Vector3(86, 0.8, 9))

	_sign(c, "SignStart", "CH2_SIGN_START", Vector3(6, 2.6, -3))


## Malovaný 2D svět „Pouštní obraz“: vstup přes rám na severní stěně kaňonu (x 46).
## 2D dráha leží daleko (x 296–366, z = 0): vítr nad propastí, kaňky, průchozí plošina,
## kruh, písty, rozpadající se most a výstupní portál.
func _painting() -> void:
	var g: Node3D = _group("Painting")
	# Rám a plátno na stěně kaňonu.
	_box(g, "PaintingFrame", Vector3(46, 3, -12.8), Vector3(6, 4, 0.6), _wood)
	var canvas := MeshInstance3D.new()
	canvas.name = "PaintingCanvas"
	var qm := QuadMesh.new()
	qm.size = Vector2(5.2, 3.2)
	canvas.mesh = qm
	var cm := StandardMaterial3D.new()
	cm.albedo_color = Color(0.98, 0.78, 0.5)
	cm.emission_enabled = true
	cm.emission = Color(0.9, 0.55, 0.3)
	cm.emission_energy_multiplier = 0.4
	canvas.material_override = cm
	canvas.position = Vector3(46, 3, -12.48)
	_add(g, canvas)
	var lane := Marker3D.new()
	lane.name = "LaneStart"
	lane.position = Vector3(299, 0.05, 0)
	_add(g, lane)
	var portal: Node3D = (load("res://world/portals/painting_portal.tscn") as PackedScene).instantiate() as Node3D
	portal.name = "PaintingPortal"
	portal.position = Vector3(46, 0, -11.6)
	_add(g, portal)
	portal.set("lane_start", lane)
	_sign(g, "SignPainting", "CH2_SIGN_PAINTING", Vector3(46, 5.6, -11.8))

	var sand2 := StandardMaterial3D.new()
	sand2.albedo_color = Color(0.9, 0.6, 0.35)
	var w: Node3D = _group("PaintingWorld")
	_box(w, "P_FloorA", Vector3(304, -5, 0), Vector3(16, 10, 4), sand2)        # 296–312, vrch 0
	_box(w, "P_FloorB", Vector3(324, -5, 0), Vector3(12, 10, 4), sand2)        # 318–330
	_box(w, "P_FloorC", Vector3(343.5, -5, 0), Vector3(13, 10, 4), sand2)      # 337–350
	_box(w, "P_EndDeck", Vector3(361, -5, 0), Vector3(10, 10, 4), sand2)       # 356–366
	_box(w, "P_WallStart", Vector3(295.5, 3, 0), Vector3(1, 6, 4), sand2)
	_area(w, "P_Spikes", "res://world/gameplay/hazard.gd", Vector3(307, 0, 0), {"size": Vector3(1.5, 0.6, 1.5), "look": 1})
	_area(w, "P_Wind", "res://world/platforms_2d/wind_column.gd", Vector3(315, -10, 0), {"size": Vector3(2.5, 22, 4)})
	var blob := CharacterBody3D.new()
	blob.name = "P_Blob"
	blob.set_script(load("res://world/enemies/ink_blob.gd"))
	blob.set("patrol_half_width", 3.5)
	blob.position = Vector3(324, 0.05, 0)
	_add(w, blob)
	var ow := AnimatableBody3D.new()
	ow.name = "P_OneWay"
	ow.set_script(load("res://world/platforms_2d/one_way_platform.gd"))
	ow.set("size", Vector3(3, 0.3, 4))
	ow.position = Vector3(327, 2.6, 0)
	_add(w, ow)
	var jar := StaticBody3D.new()
	jar.name = "P_Jar"
	jar.set_script(load("res://world/gameplay/firefly_jar.gd"))
	jar.set("jar_id", "jar_canyon_painting")
	jar.position = Vector3(328, 2.75, 0)
	_add(w, jar)
	var ring := Area3D.new()
	ring.name = "P_Ring"
	ring.set_script(load("res://world/anchors/ring_anchor.gd"))
	ring.position = Vector3(333.5, 4.4, 0)
	_add(w, ring)
	for i: int in 2:
		var pis := AnimatableBody3D.new()
		pis.name = "P_Piston%d" % i
		pis.set_script(load("res://world/platforms_2d/piston.gd"))
		pis.set("size", Vector3(2, 0.6, 4))
		pis.set("travel", Vector3(0, 3.5, 0))
		pis.set("phase", 0.5 * float(i))
		pis.position = Vector3(341.5 + i * 4.0, -0.3, 0)
		_add(w, pis)
	for i: int in 3:
		var cr := AnimatableBody3D.new()
		cr.name = "P_Crumble%d" % i
		cr.set_script(load("res://world/platforms_2d/crumbling_platform.gd"))
		cr.set("size", Vector3(1.4, 0.35, 4))
		cr.position = Vector3(351.3 + i * 2.0, -0.1, 0)
		_add(w, cr)
	var exitp: Node3D = (load("res://world/portals/exit_portal.tscn") as PackedScene).instantiate() as Node3D
	exitp.name = "ExitPortal"
	exitp.position = Vector3(363.5, 0, 0)
	_add(w, exitp)
	exitp.set("entry_portal", portal)
	for x: float in [301.0, 303.0, 307.0, 320.0, 322.0, 339.0, 348.0, 352.3, 354.3]:
		_drop(w, Vector3(x, 0.8 if x != 307.0 else 2.2, 0))
	for y: float in [4.0, 7.0, 10.0]:
		_drop(w, Vector3(315, y, 0))
	_drop(w, Vector3(315, 12.5, 0), true)
	_drop(w, Vector3(333.5, 2.0, 0))
	# Pozadí obrazu (vrstva 2 – jen ve 2D).
	var bd: Node3D = _group("Backdrop2D")
	var sky := MeshInstance3D.new()
	sky.name = "PaperSky"
	var sq := QuadMesh.new()
	sq.size = Vector2(600, 240)
	sky.mesh = sq
	var skm := StandardMaterial3D.new()
	skm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	skm.albedo_color = Color(0.98, 0.86, 0.68)
	sky.material_override = skm
	sky.position = Vector3(330, 35, -120)
	sky.layers = 2
	_add(bd, sky)
	for spec: Array in [["FarMesas", 2, Vector3(330, 0, -60), 340.0, 20.0, Color(0.86, 0.6, 0.5), 21], ["MidRidge", 0, Vector3(330, -1, -30), 220.0, 10.0, Color(0.7, 0.4, 0.32), 5], ["NearCacti", 1, Vector3(330, -2, -14), 140.0, 6.0, Color(0.32, 0.18, 0.2), 17]]:
		var m := MeshInstance3D.new()
		m.name = spec[0]
		m.set_script(load("res://world/platforms_2d/backdrop_layer.gd"))
		m.set("style", spec[1])
		m.set("width", spec[3])
		m.set("height", spec[4])
		m.set("color", spec[5])
		m.set("shape_seed", spec[6])
		m.position = spec[2]
		_add(bd, m)


func _guard(parent: Node, n: String, pos: Vector3, pts: PackedVector3Array, key: String, loot: int) -> void:
	var g := CharacterBody3D.new()
	g.name = n
	g.set_script(load("res://world/enemies/guard.gd"))
	g.position = pos
	g.set("patrol_points", pts)
	g.set("carries_key", key)
	g.set("loot", loot)
	_add(parent, g)


func _laser(parent: Node, n: String, pos: Vector3, length: float, h: float, block: bool, blink: float) -> void:
	var l := Area3D.new()
	l.name = n
	l.set_script(load("res://world/gameplay/laser_tripwire.gd"))
	l.set("length", length)
	l.set("beam_height", h)
	l.set("block_standing", block)
	l.set("blink_period", blink)
	l.position = pos
	l.rotation.y = -PI * 0.5
	_add(parent, l)


func _line(parent: Node, n: String, type: int, pos: Vector3, axis: Vector3, length: float, outward: Vector3) -> void:
	var l := Area3D.new()
	l.name = n
	l.set_script(load("res://world/anchors/line_anchor.gd"))
	l.set("type", type)
	l.set("axis", axis)
	l.set("length", length)
	l.set("outward", outward)
	l.position = pos
	_add(parent, l)


func _area(parent: Node, n: String, script_path: String, pos: Vector3, props: Dictionary) -> void:
	var a := Area3D.new()
	a.name = n
	a.set_script(load(script_path))
	for k: String in props:
		a.set(k, props[k])
	a.position = pos
	_add(parent, a)


func _drop(parent: Node, pos: Vector3, golden: bool = false) -> void:
	var d := Area3D.new()
	d.name = ("Gold%02d" if golden else "Ink%02d") % _drop_i
	d.set_script(load("res://world/gameplay/ink_drop.gd"))
	d.set("collectible_id", "cn_ink_%02d" % _drop_i)
	d.set("golden", golden)
	d.position = pos
	_add(parent, d)
	_drop_i += 1


func _sign(parent: Node, n: String, key: String, pos: Vector3) -> void:
	var l := Label3D.new()
	l.name = n
	l.text = key
	l.position = pos
	l.pixel_size = 0.008
	l.font_size = 60
	l.outline_size = 14
	l.modulate = Color(1, 0.9, 0.7)
	l.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_add(parent, l)


func _box(parent: Node, n: String, pos: Vector3, size: Vector3, mat: Material) -> void:
	var b := CSGBox3D.new()
	b.name = n
	b.size = size
	b.position = pos
	b.use_collision = true
	b.material = mat
	_add(parent, b)


func _group(n: String) -> Node3D:
	var g := Node3D.new()
	g.name = n
	_add(lvl, g)
	return g


func _add(parent: Node, n: Node) -> void:
	parent.add_child(n)
	n.owner = lvl
	for c: Node in n.get_children():
		if c.owner == null and not c.has_meta(&"generated") and n.scene_file_path.is_empty():
			c.owner = lvl
