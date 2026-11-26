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
	_dressing()
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
	env.fog_sky_affect = 0.35
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_bloom = 0.08
	env.ssao_enabled = true
	env.ssao_intensity = 1.4
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.12
	env.adjustment_contrast = 1.06
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
	# Směr startu (Player ho převede na natočení vizuálu + kamery, tělo se neotáčí).
	player.rotation.y = -PI * 0.5
	player.position = Vector3(2, 0.05, 0)
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
	m.set("escape_time", 120.0)
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
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.width = 700.0
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



# --- Výzdoba (jen vizuál, bez kolizí) --------------------------------------

var _rng := RandomNumberGenerator.new()


func _mat(c: Color, rough: float = 0.92, emit: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emit
	return m


func _mesh(parent: Node, mesh: Mesh, pos: Vector3, rot_deg: Vector3, scl: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.scale = scl
	_add(parent, mi)
	return mi


func _dressing() -> void:
	_rng.seed = 2207
	var d := _group("Dressing")
	var bands: Array[StandardMaterial3D] = [
		_mat(Color(0.7, 0.38, 0.25)), _mat(Color(0.8, 0.5, 0.32)), _mat(Color(0.55, 0.28, 0.2)),
		_mat(Color(0.88, 0.68, 0.48)), _mat(Color(0.65, 0.33, 0.26))]
	var box := BoxMesh.new()
	# Vrstvy usazenin na stěnách kaňonu (pruhy, které stěnu „rozbijí“).
	for side: float in [-1.0, 1.0]:
		var z_wall: float = 13.0 * side
		var y: float = 0.4
		var layer: int = 0
		while y < 15.0:
			var h: float = _rng.randf_range(0.6, 1.8)
			var x: float = -5.0
			while x < 95.0:
				var w: float = _rng.randf_range(3.0, 9.0)
				var depth: float = _rng.randf_range(0.25, 0.9) * (1.0 - y / 22.0)
				_mesh(d, box, Vector3(x + w * 0.5, y + h * 0.5, z_wall - side * depth * 0.5),
					Vector3(0, 0, _rng.randf_range(-1.5, 1.5)), Vector3(w, h, depth + 0.1),
					bands[(layer + int(x / 13.0)) % bands.size()])
				x += w + _rng.randf_range(-0.6, 0.4)
			y += h
			layer += 1
	# Balvany podél stěn.
	var sph := SphereMesh.new()
	sph.radial_segments = 10
	sph.rings = 6
	var boulder_mats: Array[StandardMaterial3D] = [_mat(Color(0.58, 0.32, 0.22)), _mat(Color(0.5, 0.29, 0.21)), _mat(Color(0.68, 0.42, 0.3))]
	for i: int in 46:
		var side: float = -1.0 if i % 2 == 0 else 1.0
		var x: float = _rng.randf_range(-3.0, 93.0)
		if x > 31.0 and x < 41.0:
			continue # řeka
		var r: float = _rng.randf_range(0.35, 1.4)
		_mesh(d, sph, Vector3(x, r * 0.45, side * _rng.randf_range(11.4, 12.6)),
			Vector3(_rng.randf_range(0, 360), _rng.randf_range(0, 360), 0),
			Vector3(r * _rng.randf_range(1.0, 1.6), r * _rng.randf_range(0.6, 1.0), r * _rng.randf_range(0.9, 1.4)),
			boulder_mats[i % 3])
	# Kaktusy (saguaro + malé).
	var cyl := CylinderMesh.new()
	cyl.radial_segments = 10
	var green := _mat(Color(0.32, 0.5, 0.28), 0.8)
	var green2 := _mat(Color(0.4, 0.58, 0.3), 0.8)
	for spot: Vector3 in [Vector3(4, 0, -10.5), Vector3(11, 0, 10.8), Vector3(28, 0, -10.8), Vector3(45, 0, 10.5),
			Vector3(63, 0, -10.9), Vector3(86, 0, 10.6), Vector3(90, 0, -10.4), Vector3(19, 0, 11.2)]:
		var hgt: float = _rng.randf_range(2.2, 3.6)
		var c := Node3D.new()
		c.name = "Cactus"
		c.position = spot
		c.rotation_degrees.y = _rng.randf_range(0, 360)
		_add(d, c)
		_mesh(c, cyl, Vector3(0, hgt * 0.5, 0), Vector3.ZERO, Vector3(0.42, hgt, 0.42), green)
		_mesh(c, sph, Vector3(0, hgt, 0), Vector3.ZERO, Vector3(0.42, 0.42, 0.42), green)
		for arm: int in 2:
			var s2: float = -1.0 if arm == 0 else 1.0
			var ay: float = hgt * _rng.randf_range(0.45, 0.65)
			var al: float = _rng.randf_range(0.7, 1.2)
			_mesh(c, cyl, Vector3(s2 * 0.42, ay, 0), Vector3(0, 0, 90), Vector3(0.3, 0.6, 0.3), green2)
			_mesh(c, cyl, Vector3(s2 * 0.7, ay + al * 0.5, 0), Vector3.ZERO, Vector3(0.3, al, 0.3), green2)
			_mesh(c, sph, Vector3(s2 * 0.7, ay + al, 0), Vector3.ZERO, Vector3(0.3, 0.3, 0.3), green2)
	for i: int in 14:
		var side: float = -1.0 if i % 2 == 0 else 1.0
		var x: float = _rng.randf_range(0.0, 92.0)
		if x > 30.0 and x < 42.0:
			continue
		_mesh(d, sph, Vector3(x, 0.3, side * _rng.randf_range(9.8, 11.5)), Vector3.ZERO,
			Vector3(0.6, 0.75, 0.6), green2)
	# Skalní věže (hoodoo) v rozích a stolové hory nad okrajem kaňonu.
	for hp: Vector3 in [Vector3(-1.5, 0, 9.5), Vector3(93, 0, -9.5), Vector3(66, 0, 10.5)]:
		var ht: float = 0.0
		for seg: int in 4:
			var sh: float = _rng.randf_range(1.6, 2.6)
			var sw: float = 1.6 - seg * 0.25 + _rng.randf_range(-0.15, 0.15)
			_mesh(d, cyl, hp + Vector3(0, ht + sh * 0.5, 0), Vector3.ZERO, Vector3(sw, sh, sw), bands[seg % bands.size()])
			ht += sh
		_mesh(d, cyl, hp + Vector3(0, ht + 0.25, 0), Vector3.ZERO, Vector3(2.6, 0.5, 2.6), bands[3])
	var far := _mat(Color(0.78, 0.47, 0.38))
	var far2 := _mat(Color(0.7, 0.42, 0.4))
	for i: int in 12:
		var side: float = -1.0 if i % 2 == 0 else 1.0
		var x: float = -20.0 + i * 11.0 + _rng.randf_range(-4, 4)
		var mh: float = _rng.randf_range(18.0, 34.0)
		var mw: float = _rng.randf_range(10.0, 22.0)
		_mesh(d, box, Vector3(x, mh * 0.5, side * _rng.randf_range(30.0, 55.0)), Vector3(0, _rng.randf_range(-10, 10), 0),
			Vector3(mw, mh, _rng.randf_range(8.0, 14.0)), far if i % 3 else far2)
		_mesh(d, box, Vector3(x, mh + 0.6, side * _rng.randf_range(30.0, 55.0)), Vector3.ZERO,
			Vector3(mw * 0.6, 1.2, 6.0), far2)
	# Tábor: sloupy s lucernami + řetěz světýlek k boudě.
	var pole_mat := _mat(Color(0.35, 0.22, 0.13))
	var lamp_mat := _mat(Color(1.0, 0.72, 0.35), 0.4, 3.0)
	var posts: Array[Vector3] = [Vector3(58, 0, 8.5), Vector3(66, 0, -8.5), Vector3(72, 0, 7.0), Vector3(83, 0, -6.0), Vector3(47, 0, -9.0)]
	for pp: Vector3 in posts:
		_mesh(d, cyl, pp + Vector3(0, 1.6, 0), Vector3.ZERO, Vector3(0.18, 3.2, 0.18), pole_mat)
		_mesh(d, sph, pp + Vector3(0, 3.3, 0), Vector3.ZERO, Vector3(0.35, 0.45, 0.35), lamp_mat)
		var l := OmniLight3D.new()
		l.position = pp + Vector3(0, 3.1, 0)
		l.light_color = Color(1.0, 0.7, 0.4)
		l.light_energy = 1.6
		l.omni_range = 7.0
		_add(d, l)
	var bulb := _mat(Color(1.0, 0.85, 0.5), 0.4, 4.0)
	for k: int in posts.size() - 1:
		var a: Vector3 = posts[k] + Vector3(0, 3.1, 0)
		var b: Vector3 = posts[k + 1] + Vector3(0, 3.1, 0)
		var n: int = int(a.distance_to(b) / 0.9)
		for j: int in n + 1:
			var t: float = float(j) / float(n)
			var p: Vector3 = a.lerp(b, t) - Vector3(0, sin(t * PI) * 0.9, 0)
			_mesh(d, sph, p, Vector3.ZERO, Vector3(0.12, 0.12, 0.12), bulb)
	# Sudy a bedny v táboře.
	var barrel := _mat(Color(0.5, 0.28, 0.15))
	for bp: Vector3 in [Vector3(61, 0, -9.5), Vector3(61.8, 0, -10.3), Vector3(70, 0, 9.8), Vector3(84, 0, 6.5), Vector3(45.5, 0, 9.6)]:
		_mesh(d, cyl, bp + Vector3(0, 0.55, 0), Vector3.ZERO, Vector3(0.7, 1.1, 0.7), barrel)
	# Poletující prach ve světle západu.
	var dust := GPUParticles3D.new()
	dust.name = "Dust"
	dust.position = Vector3(45, 4, 0)
	dust.amount = 260
	dust.lifetime = 9.0
	dust.preprocess = 9.0
	dust.visibility_aabb = AABB(Vector3(-55, -6, -16), Vector3(110, 16, 32))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(50, 4, 12)
	pm.direction = Vector3(1, 0.2, 0)
	pm.spread = 40.0
	pm.initial_velocity_min = 0.2
	pm.initial_velocity_max = 0.7
	pm.gravity = Vector3(0, 0.02, 0)
	pm.scale_min = 0.6
	pm.scale_max = 1.4
	dust.process_material = pm
	var quad := QuadMesh.new()
	quad.size = Vector2(0.05, 0.05)
	var dm := StandardMaterial3D.new()
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	dm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	dm.albedo_color = Color(1.0, 0.85, 0.6, 0.55)
	quad.material = dm
	dust.draw_pass_1 = quad
	_add(d, dust)
