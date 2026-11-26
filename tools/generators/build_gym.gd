## Tréninkové hřiště (testovací level): stanoviště pro všechny mechaniky, měřítka, teleport 1–9.
## godot --headless --path game --script ../tools/generators/build_gym.gd
extends SceneTree

const OUT: String = "res://levels/test/gym.tscn"

var lvl: Node3D
var _grid: ShaderMaterial
var _accent: StandardMaterial3D
var _drop_i: int = 0
var _stations: Node3D


func _initialize() -> void:
	lvl = Node3D.new()
	lvl.name = "Gym"
	_grid = ShaderMaterial.new()
	_grid.shader = load("res://shaders/grid_floor.gdshader")
	_accent = StandardMaterial3D.new()
	_accent.albedo_color = Color(0.95, 0.7, 0.25)
	_env()
	_box(lvl, "Floor", Vector3(60, -0.5, 0), Vector3(150, 1, 70), _grid)
	_stations = Node3D.new()
	_stations.name = "Stations"
	_stations.set_script(load("res://levels/test/gym_teleport.gd"))
	_add(lvl, _stations)
	_actors()
	_jumps(Vector3(0, 0, -20))
	_gaps(Vector3(20, 0, -20))
	_glide(Vector3(50, 0, -20))
	_anchors(Vector3(0, 0, 10))
	_crawl_lasers(Vector3(30, 0, 10))
	_combat(Vector3(50, 0, 10))
	_guard_pen(Vector3(75, 0, 10))
	_platforms(Vector3(75, 0, -20))
	_heist(Vector3(105, 0, 0))
	_boss(Vector3(60, 0, 45))
	var packed := PackedScene.new()
	var err: Error = packed.pack(lvl)
	if err == OK:
		err = ResourceSaver.save(packed, OUT)
	print("build_gym: saved ", OUT, " -> ", err)
	lvl.free()
	quit()


func _env() -> void:
	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	var env := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.45, 0.6, 0.85)
	sm.sky_horizon_color = Color(0.85, 0.88, 0.95)
	sky.sky_material = sm
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.8
	we.environment = env
	_add(lvl, we)
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-50, -30, 0)
	sun.shadow_enabled = true
	_add(lvl, sun)


func _actors() -> void:
	var player: Node3D = (load("res://player/player.tscn") as PackedScene).instantiate() as Node3D
	player.name = "Player"
	player.position = Vector3(-8, 0.05, 0)
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
	m.set("chapter_id", "gym")
	m.set("key_id", "gym_key")
	_add(lvl, m)
	_sign(Vector3(-8, 3.2, -3), "TRÉNINKOVÉ HŘIŠTĚ · 1–9 / D-pad = teleport na stanoviště · mřížka = 1 m", 72)


func _station(n: String, pos: Vector3, look: Vector3) -> void:
	var mk := Marker3D.new()
	mk.name = n
	mk.position = pos + Vector3(0, 0.05, 0)
	mk.basis = Basis.looking_at(look, Vector3.UP)
	_add(_stations, mk)


func _jumps(o: Vector3) -> void:
	_station("Skoky", o + Vector3(-4, 0, 4), Vector3.RIGHT)
	_sign(o + Vector3(6, 5.5, -2), "1 · VÝŠKA SKOKU (skok / dvojskok)")
	var h: float = 0.5
	var x: float = 0.0
	while h <= 4.01:
		_box(lvl, "Jump%.1f" % h, o + Vector3(x, h * 0.5, 0), Vector3(1.8, h, 1.8), _grid)
		_sign(o + Vector3(x, h + 0.6, 1.2), "%.1f m" % h, 48)
		x += 2.6
		h += 0.5


func _gaps(o: Vector3) -> void:
	_station("Mezery", o + Vector3(-1, 1.05, 0), Vector3.RIGHT)
	_sign(o + Vector3(12, 4.5, -2), "2 · DÉLKA SKOKU (rozběh / sprint / dvojskok / plachtění)")
	var x: float = 0.0
	_box(lvl, "GapStart", o + Vector3(x, 0.5, 0), Vector3(3, 1, 3), _grid)
	x += 1.5
	for gap: float in [2.0, 3.0, 4.0, 5.0, 6.0, 8.0]:
		x += gap
		_box(lvl, "GapLand%d" % int(gap), o + Vector3(x + 1.5, 0.5, 0), Vector3(3, 1, 3), _grid)
		_sign(o + Vector3(x - gap * 0.5, 1.6, 1.8), "%d m" % int(gap), 48)
		x += 3.0


func _glide(o: Vector3) -> void:
	_station("Plachteni", o + Vector3(0, 8.05, 0), Vector3.RIGHT)
	_sign(o + Vector3(0, 10, -2), "3 · PLACHTĚNÍ Z VĚŽE 8 m (drž skok)")
	_box(lvl, "GlideTower", o + Vector3(0, 4, 0), Vector3(3, 8, 3), _grid)
	for i: int in range(1, 13):
		_box(lvl, "GlideMark%d" % i, o + Vector3(1.5 + i * 2.0, 0.02, 0), Vector3(0.1, 0.04, 2), _accent)
		_sign(o + Vector3(1.5 + i * 2.0, 0.5, 1.4), "%d m" % (i * 2), 40)


func _anchors(o: Vector3) -> void:
	_station("Kotvy", o + Vector3(-3, 0, 0), Vector3.RIGHT)
	_sign(o + Vector3(8, 6, -4), "4 · KOTVY (E / ○): špička · trubka · římsa · lano · úzká římsa · kruh")
	var spire: Node3D = (load("res://world/anchors/spire_anchor.tscn") as PackedScene).instantiate() as Node3D
	spire.name = "Spire"
	spire.position = o + Vector3(1, 2.5, 0)
	_add(lvl, spire)
	_box(lvl, "SpirePost", o + Vector3(1, 1.2, 0), Vector3(0.3, 2.4, 0.3), _accent)
	# Zeď s trubkou, římsou a úzkou římsou.
	_box(lvl, "AnchorWall", o + Vector3(8, 3, -2), Vector3(8, 6, 1), _grid)
	_line("Pipe", 1, o + Vector3(5, 0, -1.4), Vector3.UP, 6.0, Vector3.BACK)
	_line("Ledge", 2, o + Vector3(6.5, 6.0, -1.48), Vector3.RIGHT, 5.0, Vector3.BACK)
	_box(lvl, "LedgeStep", o + Vector3(9, 1.25, 0.2), Vector3(1.5, 2.5, 1.5), _grid)
	_line("WallLedge", 4, o + Vector3(6.5, 2.0, -1.48), Vector3.RIGHT, 5.0, Vector3.BACK)
	# Lano mezi dvěma sloupy a kruh nad jámou (podlaha níž není – jen měkký dopad).
	_box(lvl, "RopePostA", o + Vector3(14, 2, 0), Vector3(1.2, 4, 1.2), _grid)
	_box(lvl, "RopePostB", o + Vector3(24, 2, 0), Vector3(1.2, 4, 1.2), _grid)
	_line("Rope", 3, o + Vector3(14.6, 4.02, 0), Vector3.RIGHT, 8.8, Vector3.BACK)
	var ring := Area3D.new()
	ring.name = "Ring"
	ring.set_script(load("res://world/anchors/ring_anchor.gd"))
	ring.position = o + Vector3(19, 5.5, 4)
	_add(lvl, ring)


func _crawl_lasers(o: Vector3) -> void:
	_station("Plazeni_a_lasery", o + Vector3(-3, 0, 0), Vector3.RIGHT)
	_sign(o + Vector3(4, 4, -3), "5 · PLAZENÍ (drž Ctrl / L3) · LASERY")
	_box(lvl, "CrawlTable", o + Vector3(2, 1.05, 0), Vector3(3, 0.5, 2.4), _grid)
	var l := Area3D.new()
	l.name = "LaserHigh"
	l.set_script(load("res://world/gameplay/laser_tripwire.gd"))
	l.set("length", 5.0)
	l.position = o + Vector3(6, 0, -2.5)
	l.rotation.y = -PI * 0.5
	_add(lvl, l)
	var l2 := Area3D.new()
	l2.name = "LaserBlink"
	l2.set_script(load("res://world/gameplay/laser_tripwire.gd"))
	l2.set("length", 5.0)
	l2.set("beam_height", 0.35)
	l2.set("block_standing", false)
	l2.set("blink_period", 1.6)
	l2.position = o + Vector3(8, 0, -2.5)
	l2.rotation.y = -PI * 0.5
	_add(lvl, l2)


func _combat(o: Vector3) -> void:
	_station("Souboj", o + Vector3(-3, 0, 0), Vector3.RIGHT)
	_sign(o + Vector3(3, 4, -3), "6 · SOUBOJ: hůl (F / □), kombo, ve vzduchu, tenisák (Q), úhyb (C / L1)")
	for i: int in 2:
		var d: Node3D = (load("res://world/props/training_dummy.tscn") as PackedScene).instantiate() as Node3D
		d.name = "Dummy%d" % i
		d.position = o + Vector3(1 + i * 2.5, 0, -1)
		_add(lvl, d)
	for i: int in 3:
		var c: Node3D = (load("res://world/props/breakable_crate.tscn") as PackedScene).instantiate() as Node3D
		c.name = "Crate%d" % i
		c.position = o + Vector3(1 + i * 1.6, 0, 2.5)
		_add(lvl, c)
	var bell: Node3D = (load("res://world/props/target_bell.tscn") as PackedScene).instantiate() as Node3D
	bell.name = "Bell"
	bell.position = o + Vector3(10, 3, -2)
	_add(lvl, bell)
	var blob := CharacterBody3D.new()
	blob.name = "InkBlob"
	blob.set_script(load("res://world/enemies/ink_blob.gd"))
	blob.set("patrol_half_width", 3.0)
	blob.position = o + Vector3(9, 0.05, 4)
	_add(lvl, blob)


func _guard_pen(o: Vector3) -> void:
	_station("Strazny", o + Vector3(-4, 0, 6), Vector3(1, 0, -1).normalized())
	_sign(o + Vector3(4, 4, -6.5), "7 · STRÁŽNÝ: plížení, kapsářství (E zezadu), odlákání tenisákem, nápřah")
	for w: Array in [[Vector3(4, 0.5, -6), Vector3(14, 1, 0.3)], [Vector3(4, 0.5, 6), Vector3(14, 1, 0.3)], [Vector3(11, 0.5, 0), Vector3(0.3, 1, 12)]]:
		_box(lvl, "PenWall", o + w[0], w[1], _accent)
	var g := CharacterBody3D.new()
	g.name = "Guard"
	g.set_script(load("res://world/enemies/guard.gd"))
	g.position = o + Vector3(4, 0.05, 0)
	g.set("patrol_points", PackedVector3Array([Vector3(-3, 0, -3), Vector3(5, 0, -3), Vector3(5, 0, 3), Vector3(-3, 0, 3)]))
	_add(lvl, g)


func _boss(o: Vector3) -> void:
	_box(lvl, "BossFloor", o + Vector3(0, -0.5, 0), Vector3(30, 1, 22), _grid)
	_station("Boss", o + Vector3(-6, 0, 0), Vector3.RIGHT)
	_sign(o + Vector3(0, 6, -9), "0 · BOSS: přeskoč rázovou vlnu, bij ho jen když funí (z z); tenisák při nápřahu = únava")
	var b := CharacterBody3D.new()
	b.name = "BossWarden"
	b.set_script(load("res://world/enemies/boss_warden.gd"))
	b.position = o + Vector3(4, 0.05, 0)
	b.set("arena_radius", 11.0)
	_add(lvl, b)


func _platforms(o: Vector3) -> void:
	_station("Plosiny", o + Vector3(-4, 0, 0), Vector3.RIGHT)
	_sign(o + Vector3(8, 6, -3), "8 · PLOŠINY: houba · vítr (plachti) · výtah · píst · rozpadající · průchozí")
	var mush: Node3D = (load("res://world/platforms_2d/bouncy_mushroom.tscn") as PackedScene).instantiate() as Node3D
	mush.name = "Mushroom"
	mush.position = o + Vector3(0, 0, 0)
	_add(lvl, mush)
	var wind := Area3D.new()
	wind.name = "Wind"
	wind.set_script(load("res://world/platforms_2d/wind_column.gd"))
	wind.set("size", Vector3(2.5, 10, 2.5))
	wind.position = o + Vector3(4, 0, 0)
	_add(lvl, wind)
	_plat("Lift", "moving_platform", o + Vector3(8, 0.2, 0), Vector3(2.5, 0.4, 2.5), {"travel": Vector3(0, 5, 0)})
	_plat("Piston", "piston", o + Vector3(11.5, 0.3, 0), Vector3(2, 0.6, 2), {"travel": Vector3(0, 3, 0)})
	_plat("Crumble", "crumbling_platform", o + Vector3(15, 2.5, 0), Vector3(2, 0.35, 2), {})
	_plat("OneWay", "one_way_platform", o + Vector3(19, 2.2, 0), Vector3(3, 0.3, 3), {})


func _heist(o: Vector3) -> void:
	_station("Mini_loupez", o + Vector3(-6, 0, 0), Vector3.RIGHT)
	_sign(o + Vector3(0, 4, -5), "9 · MINI LOUPEŽ: klíč (strážný) → trezor → krystal → dodávka")
	var g := CharacterBody3D.new()
	g.name = "KeyGuard"
	g.set_script(load("res://world/enemies/guard.gd"))
	g.position = o + Vector3(0, 0.05, 0)
	g.set("patrol_points", PackedVector3Array([Vector3(-2, 0, 0), Vector3(4, 0, 0)]))
	g.set("carries_key", "gym_key")
	g.set("view_range", 6.0)
	_add(lvl, g)
	var v := Node3D.new()
	v.name = "Vault"
	v.set_script(load("res://world/gameplay/vault.gd"))
	v.set("key_id", "gym_key")
	v.position = o + Vector3(10, 0, 0)
	v.rotation.y = PI * 1.5
	_add(lvl, v)
	var van := Node3D.new()
	van.name = "Van"
	van.set_script(load("res://world/gameplay/getaway.gd"))
	van.position = o + Vector3(-4, 0, 7)
	_add(lvl, van)
	for i: int in 5:
		_drop(o + Vector3(2 + i * 1.5, 0.8, 4))
	var jar := StaticBody3D.new()
	jar.name = "Jar"
	jar.set_script(load("res://world/gameplay/firefly_jar.gd"))
	jar.set("jar_id", "gym_jar")
	jar.position = o + Vector3(12, 0, 4)
	_add(lvl, jar)
	for t: Array in [["Treat", "treat.gd", Vector3(6, 0, -4), {}], ["Puddle", "hazard.gd", Vector3(2, 0, -6), {"size": Vector3(2, 0.3, 2)}], ["Checkpoint", "checkpoint.gd", Vector3(-6, 0, -4), {"checkpoint_id": "gym_cp"}]]:
		var a := Area3D.new()
		a.name = t[0]
		a.set_script(load("res://world/gameplay/" + String(t[1])))
		for k: String in (t[3] as Dictionary):
			a.set(k, t[3][k])
		a.position = o + (t[2] as Vector3)
		_add(lvl, a)


func _plat(n: String, script_name: String, pos: Vector3, size: Vector3, props: Dictionary) -> void:
	var b := AnimatableBody3D.new()
	b.name = n
	b.set_script(load("res://world/platforms_2d/%s.gd" % script_name))
	b.set("size", size)
	for k: String in props:
		b.set(k, props[k])
	b.position = pos
	_add(lvl, b)


func _line(n: String, type: int, pos: Vector3, axis: Vector3, length: float, outward: Vector3) -> void:
	var l := Area3D.new()
	l.name = n
	l.set_script(load("res://world/anchors/line_anchor.gd"))
	l.set("type", type)
	l.set("axis", axis)
	l.set("length", length)
	l.set("outward", outward)
	l.position = pos
	_add(lvl, l)


func _drop(pos: Vector3) -> void:
	var d := Area3D.new()
	d.name = "Ink%02d" % _drop_i
	d.set_script(load("res://world/gameplay/ink_drop.gd"))
	d.set("collectible_id", "gym_ink_%02d" % _drop_i)
	d.position = pos
	_add(lvl, d)
	_drop_i += 1


func _sign(pos: Vector3, text: String, size: int = 64) -> void:
	var l := Label3D.new()
	l.name = "Sign"
	l.text = text
	l.position = pos
	l.pixel_size = 0.008
	l.font_size = size
	l.outline_size = 14
	l.modulate = Color(1, 1, 1)
	l.outline_modulate = Color(0.1, 0.1, 0.2)
	l.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_add(lvl, l)


func _box(parent: Node, n: String, pos: Vector3, size: Vector3, mat: Material) -> void:
	var b := CSGBox3D.new()
	b.name = n
	b.size = size
	b.position = pos
	b.use_collision = true
	b.material = mat
	_add(parent, b)


func _add(parent: Node, n: Node) -> void:
	parent.add_child(n, true)
	n.owner = lvl
