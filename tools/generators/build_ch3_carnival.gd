## Kapitola 3 „Pouť“ – první hratelná verze (greybox). Noční pouť: kolotoč, ruské kolo,
## lano přes oblast s reflektory, strážní, lasery, trezor ve stánku s cenami.
## godot --headless --path game --script ../tools/generators/build_ch3_carnival.gd
extends SceneTree

const OUT: String = "res://levels/ch3_carnival/carnival.tscn"

var lvl: Node3D
var _drop_i: int = 0
var _sand: StandardMaterial3D
var _rock: StandardMaterial3D
var _wood: StandardMaterial3D
var _canvas: StandardMaterial3D
var _bulb: StandardMaterial3D


func _initialize() -> void:
	lvl = Node3D.new()
	lvl.name = "CarnivalLevel"
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
	print("build_ch3_carnival: saved ", OUT, " -> ", err, " (drops: ", _drop_i, ")")
	lvl.free()
	quit()


func _materials() -> void:
	_sand = StandardMaterial3D.new()
	_sand.albedo_color = Color(0.24, 0.3, 0.22)
	_rock = StandardMaterial3D.new()
	_rock.albedo_color = Color(0.3, 0.22, 0.35)
	_wood = StandardMaterial3D.new()
	_wood.albedo_color = Color(0.5, 0.32, 0.2)
	_canvas = StandardMaterial3D.new()
	_canvas.albedo_color = Color(0.85, 0.25, 0.3)
	_bulb = StandardMaterial3D.new()
	_bulb.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_bulb.albedo_color = Color(1, 0.85, 0.45)


func _environment() -> void:
	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	var env := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.05, 0.04, 0.14)
	sm.sky_horizon_color = Color(0.25, 0.15, 0.35)
	sm.ground_horizon_color = Color(0.2, 0.12, 0.25)
	sm.ground_bottom_color = Color(0.04, 0.03, 0.06)
	sky.sky_material = sm
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 1.2
	env.glow_enabled = true
	env.glow_intensity = 0.6
	we.environment = env
	_add(lvl, we)
	var moon := DirectionalLight3D.new()
	moon.name = "MoonLight"
	moon.rotation_degrees = Vector3(-45, 30, 0)
	moon.light_color = Color(0.6, 0.65, 1.0)
	moon.light_energy = 0.5
	moon.shadow_enabled = true
	_add(lvl, moon)
	for spec: Array in [[Vector3(14, 4, -10), Color(1, 0.6, 0.4)], [Vector3(14, 4, 10), Color(1, 0.6, 0.4)], [Vector3(22, 5, 0), Color(1, 0.8, 0.5)], [Vector3(38, 4, -4), Color(0.6, 0.7, 1)], [Vector3(84, 4, 0), Color(1, 0.7, 0.4)]]:
		var l := OmniLight3D.new()
		l.name = "Lamp"
		l.position = spec[0]
		l.light_color = spec[1]
		l.light_energy = 2.0
		l.omni_range = 14.0
		_add(lvl, l)


func _geometry() -> void:
	var g: Node3D = _group("Geometry")
	_box(g, "Ground", Vector3(45, -0.5, 0), Vector3(100, 1, 34), _sand)
	_box(g, "FenceNorth", Vector3(45, 1, -16.5), Vector3(100, 2, 0.4), _wood)
	_box(g, "FenceSouth", Vector3(45, 1, 16.5), Vector3(100, 2, 0.4), _wood)
	_box(g, "FenceWest", Vector3(-5, 1, 0), Vector3(0.4, 2, 34), _wood)
	_box(g, "FenceEast", Vector3(95, 1, 0), Vector3(0.4, 2, 34), _wood)
	# Žárovky podél plotů.
	for x: int in range(-2, 94, 4):
		for z: float in [-16.2, 16.2]:
			_bulb_at(g, Vector3(x, 2.1, z))
	_tent(g, "TentA", Vector3(14, 0, -10), 4.0)
	_tent(g, "TentB", Vector3(14, 0, 10), 4.0)
	_tent(g, "TentC", Vector3(60, 0, 12), 3.0)
	# Vysoké pódium u ruského kola, rozhledna, stánek s cenami.
	_box(g, "HighStage", Vector3(47.5, 3.7, -9), Vector3(4, 7.4, 4), _rock)
	_box(g, "Lookout", Vector3(66, 3.7, -9), Vector3(3, 7.4, 3), _rock)
	_box(g, "BoothBack", Vector3(88, 1.75, 0), Vector3(0.4, 3.5, 8), _wood)
	_box(g, "BoothSideN", Vector3(84, 1.75, -4), Vector3(8, 3.5, 0.4), _wood)
	_box(g, "BoothSideS", Vector3(84, 1.75, 4), Vector3(8, 3.5, 0.4), _wood)
	_box(g, "BoothRoof", Vector3(84, 3.6, 0), Vector3(8.4, 0.3, 8.4), _canvas)
	# Pult stánku s párky – nízká překážka (plazení).
	_box(g, "HotdogCounter", Vector3(58, 1.05, 6), Vector3(4, 0.5, 2.4), _wood)
	_box(g, "CounterLegA", Vector3(56.1, 0.4, 5.0), Vector3(0.2, 0.8, 0.2), _wood)
	_box(g, "CounterLegB", Vector3(59.9, 0.4, 7.0), Vector3(0.2, 0.8, 0.2), _wood)
	# Bedny jako úkryt před reflektory.
	for p: Vector3 in [Vector3(52, 0.6, 2), Vector3(57, 0.6, -3), Vector3(63, 0.6, 2)]:
		_box(g, "CoverCrate", p, Vector3(1.2, 1.2, 1.2), _wood)


func _tent(parent: Node, n: String, pos: Vector3, r: float) -> void:
	var base := CSGCylinder3D.new()
	base.name = n
	base.radius = r
	base.height = 3.0
	base.sides = 12
	base.position = pos + Vector3.UP * 1.5
	base.use_collision = true
	base.material = _canvas
	_add(parent, base)
	var roof := CSGCylinder3D.new()
	roof.name = n + "Roof"
	roof.radius = r + 0.3
	roof.height = 2.5
	roof.sides = 12
	roof.cone = true
	roof.position = pos + Vector3.UP * 4.25
	roof.use_collision = true
	var stripe := StandardMaterial3D.new()
	stripe.albedo_color = Color(0.95, 0.92, 0.85)
	roof.material = stripe
	_add(parent, roof)


func _bulb_at(parent: Node, pos: Vector3) -> void:
	var b := MeshInstance3D.new()
	b.name = "Bulb"
	var sm := SphereMesh.new()
	sm.radius = 0.09
	sm.height = 0.18
	sm.radial_segments = 8
	sm.rings = 4
	b.mesh = sm
	b.material_override = _bulb
	b.position = pos
	b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_add(parent, b)


func _actors() -> void:
	var player: Node3D = (load("res://player/player.tscn") as PackedScene).instantiate() as Node3D
	player.name = "Player"
	player.position = Vector3(2, 0.05, 0)
	_add(lvl, player)
	var cam: Node3D = (load("res://camera/hybrid_camera.tscn") as PackedScene).instantiate() as Node3D
	cam.name = "HybridCamera"
	_add(lvl, cam)
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
	m.set("chapter_id", "carnival")
	m.set("key_id", "booth_key")
	_add(lvl, m)


func _content() -> void:
	var c: Node3D = _group("Content")
	var car := AnimatableBody3D.new()
	car.name = "Carousel"
	car.set_script(load("res://world/carnival/carousel.gd"))
	car.position = Vector3(22, 0, 0)
	_add(c, car)
	var spire: Node3D = (load("res://world/anchors/spire_anchor.tscn") as PackedScene).instantiate() as Node3D
	spire.name = "SpireCarousel"
	spire.position = Vector3(22, 6.4, 0)
	_add(c, spire)
	var wheel := Node3D.new()
	wheel.name = "FerrisWheel"
	wheel.set_script(load("res://world/carnival/ferris_wheel.gd"))
	wheel.position = Vector3(38, 8, -9)
	_add(c, wheel)
	var a := Vector3(49.5, 7.42, -9)
	var b := Vector3(64.5, 7.42, -9)
	_line(c, "HighWire", 3, a, Vector3.RIGHT, a.distance_to(b), Vector3.BACK)
	var bounce: Node3D = (load("res://world/platforms_2d/bouncy_mushroom.tscn") as PackedScene).instantiate() as Node3D
	bounce.name = "BounceCushion"
	bounce.position = Vector3(44.5, 0, -4.5)
	_add(c, bounce)
	for spec: Array in [["SearchlightA", Vector3(55, 0, 9), 0.0], ["SearchlightB", Vector3(64, 0, -6), 180.0]]:
		var s := Node3D.new()
		s.name = spec[0]
		s.set_script(load("res://world/carnival/searchlight.gd"))
		s.position = spec[1]
		s.rotation.y = deg_to_rad(spec[2])
		_add(c, s)
	_guard(c, "GuardCarousel", Vector3(22, 0.05, 8), PackedVector3Array([Vector3(-6, 0, 0), Vector3(6, 0, 0)]), "booth_key", 30)
	_guard(c, "GuardMid", Vector3(57, 0.05, -1), PackedVector3Array([Vector3(-6, 0, 0), Vector3(7, 0, 0)]), "", 35)
	_guard(c, "GuardBooth", Vector3(78, 0.05, -6), PackedVector3Array([Vector3(-4, 0, 0), Vector3(3, 0, 0)]), "", 50)
	_laser(c, "LaserHigh", Vector3(75.5, 0, -16), 32.0, 0.95, true, 0.0)
	_laser(c, "LaserBlink", Vector3(76.3, 0, -16), 32.0, 0.35, false, 1.4)
	var v := Node3D.new()
	v.name = "Vault"
	v.set_script(load("res://world/gameplay/vault.gd"))
	v.set("key_id", "booth_key")
	v.position = Vector3(86.6, 0, 0)
	v.rotation.y = PI * 1.5
	_add(c, v)
	var van := Node3D.new()
	van.name = "GetawayVan"
	van.set_script(load("res://world/gameplay/getaway.gd"))
	van.position = Vector3(4, 0, 9)
	_add(c, van)
	_area(c, "CpWheel", "res://world/gameplay/checkpoint.gd", Vector3(40, 0, 6), {"checkpoint_id": "cp_carnival_wheel"})
	_area(c, "CpBooth", "res://world/gameplay/checkpoint.gd", Vector3(70, 0, 12), {"checkpoint_id": "cp_carnival_booth"})
	_area(c, "TreatTent", "res://world/gameplay/treat.gd", Vector3(18, 0, -4), {})
	_area(c, "TreatStage", "res://world/gameplay/treat.gd", Vector3(47.5, 7.4, -8), {})
	var jar := StaticBody3D.new()
	jar.name = "JarLookout"
	jar.set_script(load("res://world/gameplay/firefly_jar.gd"))
	jar.set("jar_id", "jar_carnival_lookout")
	jar.position = Vector3(66.5, 7.4, -9.6)
	_add(c, jar)
	for x: float in [5.0, 7.0, 9.0]:
		_drop(c, Vector3(x, 0.8, 0))
	for i: int in 6:
		var ang: float = float(i) / 6.0 * TAU
		_drop(c, Vector3(22, 1.3, 0) + Vector3(cos(ang), 0, sin(ang)) * 3.5)
	_drop(c, Vector3(22, 7.4, 0), true)
	for t: float in [0.2, 0.4, 0.6, 0.8]:
		_drop(c, a.lerp(b, t) + Vector3.UP * 0.7)
	_drop(c, Vector3(66, 8.4, -8.5), true)
	_drop(c, Vector3(47.5, 8.2, -10))
	for x: float in [52.0, 57.0, 63.0]:
		_drop(c, Vector3(x, 1.6, x * 0.0 + (2.0 if x != 57.0 else -3.0)))
	_drop(c, Vector3(57.3, 0.4, 6))
	_drop(c, Vector3(58.7, 0.4, 6))
	for x: float in [80.0, 83.0]:
		_drop(c, Vector3(x, 0.8, 0))
	_drop(c, Vector3(30, 0.8, 12))
	_drop(c, Vector3(44.5, 5.0, -4.5))
	_sign(c, "SignStart", "CH3_SIGN_START", Vector3(6, 2.6, -3))


## 2D „Cirkusový plakát“: vstup přes plakátovou tabuli u severního plotu (x 30).
## Dráha x 396–472: řada kruhů nad propastí, kaňky, vítr na vysokou plošinu,
## žebřík průchozích plošin, rozpadající se most, výstup.
func _painting() -> void:
	var g: Node3D = _group("Painting")
	_box(g, "PosterBoard", Vector3(30, 2.6, -14.6), Vector3(7, 5.2, 0.6), _wood)
	var canvas := MeshInstance3D.new()
	canvas.name = "PosterCanvas"
	var qm := QuadMesh.new()
	qm.size = Vector2(6.2, 4.4)
	canvas.mesh = qm
	var cm := StandardMaterial3D.new()
	cm.albedo_color = Color(0.95, 0.35, 0.3)
	cm.emission_enabled = true
	cm.emission = Color(1, 0.45, 0.3)
	cm.emission_energy_multiplier = 0.5
	canvas.material_override = cm
	canvas.position = Vector3(30, 2.6, -14.28)
	_add(g, canvas)
	var lane := Marker3D.new()
	lane.name = "LaneStart"
	lane.position = Vector3(399, 0.05, 0)
	_add(g, lane)
	var portal: Node3D = (load("res://world/portals/painting_portal.tscn") as PackedScene).instantiate() as Node3D
	portal.name = "PaintingPortal"
	portal.position = Vector3(30, 0, -13.4)
	_add(g, portal)
	portal.set("lane_start", lane)
	_sign(g, "SignPoster", "CH3_SIGN_POSTER", Vector3(30, 6.0, -13.8))

	var paper := StandardMaterial3D.new()
	paper.albedo_color = Color(0.95, 0.85, 0.65)
	var w: Node3D = _group("PaintingWorld")
	_box(w, "P_FloorA", Vector3(403, -5, 0), Vector3(14, 10, 4), paper)       # 396–410
	_box(w, "P_WallStart", Vector3(395.5, 3, 0), Vector3(1, 6, 4), paper)
	for i: int in 3:
		var r := Area3D.new()
		r.name = "P_Ring%d" % i
		r.set_script(load("res://world/anchors/ring_anchor.gd"))
		r.position = Vector3(413.5 + i * 5.0, 4.6, 0)
		_add(w, r)
		_drop(w, Vector3(413.5 + i * 5.0, 2.4, 0))
	_box(w, "P_FloorB", Vector3(434, -5, 0), Vector3(12, 10, 4), paper)       # 428–440
	for x: float in [431.0, 437.0]:
		var blob := CharacterBody3D.new()
		blob.name = "P_Blob"
		blob.set_script(load("res://world/enemies/ink_blob.gd"))
		blob.set("patrol_half_width", 2.0)
		blob.position = Vector3(x, 0.05, 0)
		_add(w, blob)
	_area(w, "P_Wind", "res://world/platforms_2d/wind_column.gd", Vector3(443, -10, 0), {"size": Vector3(2.5, 20, 4)})
	_box(w, "P_HighDeck", Vector3(451, 1, 0), Vector3(10, 10, 4), paper)      # 446–456, vrch 6
	for i: int in 3:
		var ow := AnimatableBody3D.new()
		ow.name = "P_Ladder%d" % i
		ow.set_script(load("res://world/platforms_2d/one_way_platform.gd"))
		ow.set("size", Vector3(2.4, 0.3, 4))
		ow.position = Vector3(450 + (i % 2) * 2.5, 8.4 + i * 2.2, 0)
		_add(w, ow)
	var jar := StaticBody3D.new()
	jar.name = "P_Jar"
	jar.set_script(load("res://world/gameplay/firefly_jar.gd"))
	jar.set("jar_id", "jar_carnival_poster")
	jar.position = Vector3(450, 13.0, 0)
	_add(w, jar)
	for i: int in 3:
		var cr := AnimatableBody3D.new()
		cr.name = "P_Crumble%d" % i
		cr.set_script(load("res://world/platforms_2d/crumbling_platform.gd"))
		cr.set("size", Vector3(1.4, 0.35, 4))
		cr.position = Vector3(457.3 + i * 2.0, 5.9, 0)
		_add(w, cr)
	_box(w, "P_EndDeck", Vector3(467, 1, 0), Vector3(10, 10, 4), paper)       # 462–472, vrch 6
	var exitp: Node3D = (load("res://world/portals/exit_portal.tscn") as PackedScene).instantiate() as Node3D
	exitp.name = "ExitPortal"
	exitp.position = Vector3(469.5, 6, 0)
	_add(w, exitp)
	exitp.set("entry_portal", portal)
	for x: float in [400.0, 402.0, 404.0, 432.0, 434.0, 436.0, 448.0, 458.3, 460.3]:
		_drop(w, Vector3(x, 0.8 if x < 446.0 else 6.8, 0))
	for y: float in [3.0, 6.0, 9.0]:
		_drop(w, Vector3(443, y, 0))
	_drop(w, Vector3(452.5, 15.0, 0), true)
	var bd: Node3D = _group("Backdrop2D")
	var sky := MeshInstance3D.new()
	sky.name = "PaperSky"
	var sq := QuadMesh.new()
	sq.size = Vector2(600, 240)
	sky.mesh = sq
	var skm := StandardMaterial3D.new()
	skm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	skm.albedo_color = Color(0.98, 0.9, 0.75)
	sky.material_override = skm
	sky.position = Vector3(434, 35, -120)
	sky.layers = 2
	_add(bd, sky)
	for spec: Array in [["FarHills", 0, Vector3(434, 0, -60), 340.0, 18.0, Color(0.95, 0.72, 0.62), 31], ["MidTents", 2, Vector3(434, -2, -30), 220.0, 9.0, Color(0.88, 0.45, 0.4), 9], ["NearCrowd", 1, Vector3(434, -3.5, -14), 140.0, 4.0, Color(0.45, 0.22, 0.28), 13]]:
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
