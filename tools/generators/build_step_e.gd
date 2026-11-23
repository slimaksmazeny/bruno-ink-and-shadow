## Generátor Kroku B: profily pohybu, player.tscn, hybrid_camera.tscn a rozšířená greybox ulice.
extends SceneTree


func _initialize() -> void:
	_build_profiles()
	_build_spire()
	_build_props()
	_build_hittables()
	_build_step_f_scenes()
	_build_player()
	_build_camera()
	_build_greybox_street()
	quit()


# ------------------------------------------------------------------ helpers
func _own(node: Node, owner_node: Node) -> void:
	for child: Node in node.get_children():
		child.owner = owner_node
		if child.scene_file_path == "":
			_own(child, owner_node)


func _save_scene(root: Node, path: String) -> void:
	_own(root, root)
	var packed := PackedScene.new()
	var err: Error = packed.pack(root)
	if err != OK:
		push_error("pack failed %s: %d" % [path, err])
		return
	err = ResourceSaver.save(packed, path)
	print("saved ", path, " -> ", err)
	root.free()


func _mat(color: Color, emission: float = 0.0, rough: float = 0.85) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	return m


func _mesh(parent: Node, name: String, mesh: Mesh, pos: Vector3, rot_deg: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = mesh
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(mi)
	return mi


func _capsule(r: float, h: float) -> CapsuleMesh:
	var c := CapsuleMesh.new()
	c.radius = r
	c.height = h
	return c


func _sphere(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	return s


func _boxm(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


func _cyl(r: float, h: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r
	c.bottom_radius = r
	c.height = h
	return c


# ------------------------------------------------------------------ profiles
func _build_profiles() -> void:
	var script: Script = load("res://player/movement_profile.gd")

	var p3: Resource = script.new()
	p3.resource_name = "Profile 3D (Sly)"
	ResourceSaver.save(p3, "res://player/profiles/profile_3d.tres")

	var p2: Resource = script.new()
	p2.resource_name = "Profile 2D (Rayman)"
	p2.walk_speed = 6.5
	p2.sneak_speed = 2.5
	p2.sprint_speed = 11.0
	p2.ground_accel = 70.0
	p2.ground_decel = 80.0
	p2.jump_height = 2.6
	p2.double_jump_height = 1.9
	p2.gravity = 42.0
	p2.fall_gravity_mult = 1.8
	p2.jump_cut_gravity_mult = 3.0
	p2.air_accel = 45.0
	p2.max_fall_speed = 34.0
	p2.glide_fall_speed = 3.0
	p2.glide_air_speed = 7.0
	p2.coyote_time = 0.1
	p2.jump_buffer_time = 0.12
	p2.turn_speed = 25.0
	ResourceSaver.save(p2, "res://player/profiles/profile_2d.tres")
	print("saved profiles")


# ------------------------------------------------------------------ player
func _build_player() -> void:
	var black := _mat(Color(0.09, 0.08, 0.08), 0.0, 0.6)
	var tan := _mat(Color(0.78, 0.45, 0.18))
	var red := _mat(Color(0.72, 0.08, 0.1))
	var gold := _mat(Color(0.95, 0.71, 0.2), 0.4, 0.4)
	var ink := _mat(Color(0.25, 0.55, 1.0), 1.2, 0.3)

	var root := CharacterBody3D.new()
	root.name = "Player"
	root.set_script(load("res://player/player.gd"))
	root.collision_layer = 2
	root.collision_mask = 1 | 16
	root.floor_snap_length = 0.35
	root.floor_max_angle = deg_to_rad(46.0)
	root.set("profile_3d", load("res://player/profiles/profile_3d.tres"))
	root.set("profile_2d", load("res://player/profiles/profile_2d.tres"))

	var stand_shape := CapsuleShape3D.new()
	stand_shape.radius = 0.35
	stand_shape.height = 1.25
	var col := CollisionShape3D.new()
	col.name = "CollisionStand"
	col.shape = stand_shape
	col.position = Vector3(0, 0.625, 0)
	root.add_child(col)

	var low_shape := BoxShape3D.new()
	low_shape.size = Vector3(0.6, 0.5, 1.1)
	var col_low := CollisionShape3D.new()
	col_low.name = "CollisionLow"
	col_low.shape = low_shape
	col_low.position = Vector3(0, 0.25, 0)
	col_low.disabled = true
	root.add_child(col_low)

	var visual := Node3D.new()
	visual.name = "Visual"
	visual.set_script(load("res://player/player_visual.gd"))
	root.add_child(visual)

	# --- Postoj na dvou nohách
	var stand := Node3D.new()
	stand.name = "Stand"
	visual.add_child(stand)
	_mesh(stand, "Body", _capsule(0.27, 0.95), Vector3(0, 0.55, 0), Vector3.ZERO, black)
	_mesh(stand, "Belly", _capsule(0.17, 0.6), Vector3(0, 0.5, -0.13), Vector3.ZERO, tan)
	_mesh(stand, "Head", _sphere(0.23), Vector3(0, 1.13, -0.04), Vector3.ZERO, black)
	_mesh(stand, "Snout", _capsule(0.1, 0.36), Vector3(0, 1.08, -0.3), Vector3(90, 0, 0), tan)
	_mesh(stand, "Nose", _sphere(0.05), Vector3(0, 1.1, -0.48), Vector3.ZERO, black)
	# Uši na temeni hlavy: každé visí z kloubu (EarHinge) – pro ušní vrtulník se zvednou
	# do vodorovné polohy a celý EarsPivot se točí nad hlavou jako vrtule.
	var ears := Node3D.new()
	ears.name = "EarsPivot"
	ears.position = Vector3(0, 1.33, -0.02)
	stand.add_child(ears)
	for side: Array in [["L", -1.0], ["R", 1.0]]:
		var hinge := Node3D.new()
		hinge.name = "EarHinge" + side[0]
		hinge.position = Vector3(0.16 * side[1], 0.0, 0.0)
		hinge.rotation_degrees = Vector3(0, 0, 20.0 * side[1])
		ears.add_child(hinge)
		_mesh(hinge, "Ear" + side[0], _boxm(Vector3(0.05, 0.42, 0.2)), Vector3(0, -0.2, 0.0), Vector3.ZERO, black)
	var collar := TorusMesh.new()
	collar.inner_radius = 0.17
	collar.outer_radius = 0.23
	_mesh(stand, "Collar", collar, Vector3(0, 0.9, 0), Vector3.ZERO, red)
	_mesh(stand, "Tag", _cyl(0.06, 0.02), Vector3(0, 0.82, -0.23), Vector3(90, 0, 0), gold)
	# Hůl = kloub (Cane) s tyčí a modrým hrotem plnicího pera jako dětmi, takže se hrot hýbe s holí.
	var cane := Node3D.new()
	cane.name = "Cane"
	cane.position = Vector3(0.38, 0.55, -0.05)
	cane.rotation_degrees = Vector3(0, 0, -8)
	stand.add_child(cane)
	_mesh(cane, "CaneMesh", _cyl(0.025, 1.05), Vector3.ZERO, Vector3.ZERO, gold)
	_mesh(cane, "CaneTip", _sphere(0.06), Vector3(0, 0.53, 0), Vector3.ZERO, ink)

	# --- Sprint po čtyřech (hůl na zádech)
	var sprint := Node3D.new()
	sprint.name = "Sprint"
	sprint.visible = false
	visual.add_child(sprint)
	_mesh(sprint, "Body", _capsule(0.24, 1.15), Vector3(0, 0.38, 0.05), Vector3(90, 0, 0), black)
	_mesh(sprint, "Head", _sphere(0.21), Vector3(0, 0.55, -0.62), Vector3.ZERO, black)
	_mesh(sprint, "Snout", _capsule(0.09, 0.32), Vector3(0, 0.5, -0.84), Vector3(90, 0, 0), tan)
	_mesh(sprint, "EarL", _boxm(Vector3(0.05, 0.16, 0.42)), Vector3(-0.2, 0.6, -0.42), Vector3(-15, 0, -20), black)
	_mesh(sprint, "EarR", _boxm(Vector3(0.05, 0.16, 0.42)), Vector3(0.2, 0.6, -0.42), Vector3(-15, 0, 20), black)
	_mesh(sprint, "Collar", collar, Vector3(0, 0.46, -0.42), Vector3(90, 0, 0), red)
	_mesh(sprint, "CaneOnBack", _cyl(0.025, 1.0), Vector3(0, 0.66, 0.05), Vector3(90, 0, 0), gold)
	for leg: Array in [["LegFL", -0.15, -0.35], ["LegFR", 0.15, -0.35], ["LegBL", -0.15, 0.45], ["LegBR", 0.15, 0.45]]:
		_mesh(sprint, leg[0], _cyl(0.06, 0.3), Vector3(leg[1], 0.15, leg[2]), Vector3.ZERO, black)

	# --- Zásahová zóna hole (před Brunem, otáčí se s Visual)
	var hitbox := Area3D.new()
	hitbox.name = "CaneHitbox"
	hitbox.set_script(load("res://player/cane_hitbox.gd"))
	var hb_shape := SphereShape3D.new()
	hb_shape.radius = 0.95
	var hb_col := CollisionShape3D.new()
	hb_col.name = "Shape"
	hb_col.shape = hb_shape
	hb_col.position = Vector3(0, 0.8, -0.95)
	hitbox.add_child(hb_col)
	root.add_child(hitbox)

	# --- Detektor kotev (modré jiskry)
	var det := Area3D.new()
	det.name = "AnchorDetector"
	det.set_script(load("res://player/anchor_detector.gd"))
	var det_shape := SphereShape3D.new()
	det_shape.radius = 4.5
	var det_col := CollisionShape3D.new()
	det_col.name = "Shape"
	det_col.shape = det_shape
	det_col.position = Vector3(0, 0.8, 0)
	det.add_child(det_col)
	root.add_child(det)

	# --- Stavový automat
	var sm := Node.new()
	sm.name = "StateMachine"
	sm.set_script(load("res://core/state_machine/player_state_machine.gd"))
	root.add_child(sm)
	var idle: Node = null
	for state_name: String in ["Idle", "Move", "Sprint", "Air", "Glide", "Perch", "Swing", "Aim", "Attack", "AirAttack", "Locked"]:
		var st := Node.new()
		st.name = state_name
		st.set_script(load("res://player/states/state_%s.gd" % state_name.to_snake_case()))
		sm.add_child(st)
		if state_name == "Idle":
			idle = st
	sm.set("initial_state", idle)

	_save_scene(root, "res://player/player.tscn")


# ------------------------------------------------------------------ spire
func _build_spire() -> void:
	var pole_mat := _mat(Color(0.35, 0.33, 0.42))
	var cap_mat := _mat(Color(0.55, 0.5, 0.65))
	var blue := _mat(Color(0.15, 0.55, 1.0), 0.9, 0.2)
	blue.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var root := Area3D.new()
	root.name = "SpireAnchor"
	root.set_script(load("res://world/anchors/anchor.gd"))

	# Sloup s plochou hlavičkou (výška 1,6 m nad základnou)
	var body := StaticBody3D.new()
	body.name = "Pole"
	body.collision_layer = 1
	body.collision_mask = 0
	root.add_child(body)
	var pole_shape := CylinderShape3D.new()
	pole_shape.radius = 0.12
	pole_shape.height = 1.6
	var pole_col := CollisionShape3D.new()
	pole_col.name = "PoleShape"
	pole_col.shape = pole_shape
	pole_col.position = Vector3(0, 0.8, 0)
	body.add_child(pole_col)
	_mesh(body, "PoleMesh", _cyl(0.12, 1.6), Vector3(0, 0.8, 0), Vector3.ZERO, pole_mat)
	var cap := CylinderMesh.new()
	cap.top_radius = 0.16
	cap.bottom_radius = 0.22
	cap.height = 0.12
	_mesh(body, "Cap", cap, Vector3(0, 1.56, 0), Vector3.ZERO, cap_mat)

	# Zóna kotvy kolem špičky
	var zone := SphereShape3D.new()
	zone.radius = 0.8
	var zone_col := CollisionShape3D.new()
	zone_col.name = "Zone"
	zone_col.shape = zone
	zone_col.position = Vector3(0, 1.65, 0)
	root.add_child(zone_col)

	var snap := Marker3D.new()
	snap.name = "SnapPoint"
	snap.position = Vector3(0, 1.63, 0)
	root.add_child(snap)
	root.set("snap_point", snap)

	# Modré jiskry
	var sparkles := Node3D.new()
	sparkles.name = "Sparkles"
	var holder := Node3D.new()
	holder.name = "SparklesHolder"
	holder.position = Vector3(0, 1.95, 0)
	root.add_child(holder)
	holder.add_child(sparkles)
	var diamond := _boxm(Vector3(0.09, 0.09, 0.09))
	for i: int in 5:
		var ang: float = TAU * float(i) / 5.0
		_mesh(sparkles, "Spark%d" % i, diamond, Vector3(cos(ang) * 0.32, 0.05 * float(i % 2), sin(ang) * 0.32), Vector3(45, 45, 0), blue)

	_save_scene(root, "res://world/anchors/spire_anchor.tscn")


# ------------------------------------------------------------------ props (Krok E)
func _build_props() -> void:
	# Tenisák
	var ball := RigidBody3D.new()
	ball.name = "TennisBall"
	ball.set_script(load("res://world/props/tennis_ball.gd"))
	ball.mass = 0.06
	var pm := PhysicsMaterial.new()
	pm.bounce = 0.6
	pm.friction = 0.6
	ball.physics_material_override = pm
	var bshape := SphereShape3D.new()
	bshape.radius = 0.12
	var bcol := CollisionShape3D.new()
	bcol.name = "Shape"
	bcol.shape = bshape
	ball.add_child(bcol)
	var neon := _mat(Color(0.75, 1.0, 0.2), 1.4, 0.3)
	_mesh(ball, "Mesh", _sphere(0.12), Vector3.ZERO, Vector3.ZERO, neon)
	var trail := CPUParticles3D.new()
	trail.name = "Trail"
	trail.amount = 24
	trail.lifetime = 0.35
	trail.local_coords = false
	trail.direction = Vector3.ZERO
	trail.spread = 0.0
	trail.initial_velocity_min = 0.0
	trail.initial_velocity_max = 0.0
	trail.gravity = Vector3.ZERO
	trail.scale_amount_min = 1.0
	trail.scale_amount_max = 1.0
	var curve := Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, 0))
	trail.scale_amount_curve = curve
	var tmesh := _sphere(0.07)
	var tmat := _mat(Color(0.75, 1.0, 0.25), 1.2, 0.3)
	tmesh.material = tmat
	trail.mesh = tmesh
	ball.add_child(trail)
	_save_scene(ball, "res://world/props/tennis_ball.tscn")

	# Zvon
	var bell := Node3D.new()
	bell.name = "TargetBell"
	bell.set_script(load("res://world/props/target_bell.gd"))
	var frame_mat := _mat(Color(0.3, 0.22, 0.15))
	var bell_mat := _mat(Color(0.75, 0.55, 0.2), 0.0, 0.35)
	bell_mat.metallic = 0.6
	var beam := StaticBody3D.new()
	beam.name = "Frame"
	beam.collision_layer = 16
	beam.collision_mask = 0
	bell.add_child(beam)
	_mesh(beam, "PostL", _boxm(Vector3(0.15, 1.6, 0.15)), Vector3(-0.8, 0.8, 0), Vector3.ZERO, frame_mat)
	_mesh(beam, "PostR", _boxm(Vector3(0.15, 1.6, 0.15)), Vector3(0.8, 0.8, 0), Vector3.ZERO, frame_mat)
	_mesh(beam, "Beam", _boxm(Vector3(1.8, 0.15, 0.2)), Vector3(0, 1.6, 0), Vector3.ZERO, frame_mat)
	var pivot := Node3D.new()
	pivot.name = "BellPivot"
	pivot.position = Vector3(0, 1.55, 0)
	bell.add_child(pivot)
	var bell_mesh := CylinderMesh.new()
	bell_mesh.top_radius = 0.22
	bell_mesh.bottom_radius = 0.5
	bell_mesh.height = 0.75
	var bm := _mesh(pivot, "BellMesh", bell_mesh, Vector3(0, -0.45, 0), Vector3.ZERO, bell_mat)
	bm.name = "BellMesh"
	var area := Area3D.new()
	area.name = "HitArea"
	var ashape := SphereShape3D.new()
	ashape.radius = 0.95
	var acol := CollisionShape3D.new()
	acol.name = "Shape"
	acol.shape = ashape
	acol.position = Vector3(0, 1.1, 0)
	area.add_child(acol)
	bell.add_child(area)
	_save_scene(bell, "res://world/props/target_bell.tscn")

	# Brána
	var gate := AnimatableBody3D.new()
	gate.name = "Gate"
	gate.set_script(load("res://world/props/gate.gd"))
	gate.collision_layer = 1
	gate.collision_mask = 0
	var gshape := BoxShape3D.new()
	gshape.size = Vector3(6.6, 4.5, 0.3)
	var gcol := CollisionShape3D.new()
	gcol.name = "Shape"
	gcol.shape = gshape
	gcol.position = Vector3(0, 2.25, 0)
	gate.add_child(gcol)
	var bars := _mat(Color(0.25, 0.25, 0.3), 0.0, 0.4)
	bars.metallic = 0.7
	for i: int in 9:
		_mesh(gate, "Bar%d" % i, _boxm(Vector3(0.12, 4.5, 0.12)), Vector3(-3.2 + i * 0.8, 2.25, 0), Vector3.ZERO, bars)
	_mesh(gate, "Rail", _boxm(Vector3(6.6, 0.2, 0.2)), Vector3(0, 4.3, 0), Vector3.ZERO, bars)
	_save_scene(gate, "res://world/props/gate.tscn")


# ------------------------------------------------------------------ hittables
func _build_hittables() -> void:
	var wood := _mat(Color(0.55, 0.38, 0.2))
	var sack_mat := _mat(Color(0.85, 0.75, 0.5))
	var dummy := Node3D.new()
	dummy.name = "TrainingDummy"
	dummy.set_script(load("res://world/props/training_dummy.gd"))
	var body := StaticBody3D.new()
	body.name = "Body"
	body.collision_layer = 16
	body.collision_mask = 0
	dummy.add_child(body)
	var post_shape := CylinderShape3D.new()
	post_shape.radius = 0.35
	post_shape.height = 1.8
	var pcol := CollisionShape3D.new()
	pcol.name = "Shape"
	pcol.shape = post_shape
	pcol.position = Vector3(0, 0.9, 0)
	body.add_child(pcol)
	_mesh(body, "Post", _cyl(0.07, 0.6), Vector3(0, 0.3, 0), Vector3.ZERO, wood)
	_mesh(body, "Base", _cyl(0.4, 0.08), Vector3(0, 0.04, 0), Vector3.ZERO, wood)
	var pivot := Node3D.new()
	pivot.name = "SackPivot"
	pivot.position = Vector3(0, 0.55, 0)
	dummy.add_child(pivot)
	var sack := _mesh(pivot, "Sack", _capsule(0.33, 1.1), Vector3(0, 0.6, 0), Vector3.ZERO, sack_mat)
	sack.name = "Sack"
	_mesh(pivot, "Head", _sphere(0.2), Vector3(0, 1.3, 0), Vector3.ZERO, sack_mat)
	var label := Label3D.new()
	label.name = "HitLabel"
	label.text = "×1"
	label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	label.font_size = 72
	label.outline_size = 18
	label.pixel_size = 0.008
	label.modulate = Color(1.0, 0.85, 0.3)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 2.3, 0)
	dummy.add_child(label)
	_save_scene(dummy, "res://world/props/training_dummy.tscn")

	var crate := StaticBody3D.new()
	crate.name = "BreakableCrate"
	crate.set_script(load("res://world/props/breakable_crate.gd"))
	crate.collision_layer = 16
	crate.collision_mask = 0
	var cshape := BoxShape3D.new()
	cshape.size = Vector3(0.9, 0.9, 0.9)
	var ccol := CollisionShape3D.new()
	ccol.name = "Shape"
	ccol.shape = cshape
	ccol.position = Vector3(0, 0.45, 0)
	crate.add_child(ccol)
	var cm := _mesh(crate, "Mesh", _boxm(Vector3(0.9, 0.9, 0.9)), Vector3(0, 0.45, 0), Vector3.ZERO, _mat(Color(0.62, 0.42, 0.22)))
	cm.name = "Mesh"
	_save_scene(crate, "res://world/props/breakable_crate.tscn")


# ------------------------------------------------------------------ Krok F scény
func _unshaded(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


func _build_step_f_scenes() -> void:
	# Inkoustový přechod (autoload InkWipe)
	var ink := CanvasLayer.new()
	ink.name = "InkWipe"
	ink.layer = 90
	ink.set_script(load("res://ui/transitions/ink_wipe.gd"))
	var rect := ColorRect.new()
	rect.name = "Ink"
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.visible = false
	var sm := ShaderMaterial.new()
	sm.shader = load("res://shaders/ink_wipe.gdshader")
	rect.material = sm
	ink.add_child(rect)
	_save_scene(ink, "res://ui/transitions/ink_wipe.tscn")

	# Skákací houba
	var mush := Node3D.new()
	mush.name = "BouncyMushroom"
	mush.set_script(load("res://world/platforms_2d/bouncy_mushroom.gd"))
	var stem_mat := _mat(Color(0.95, 0.9, 0.78))
	var cap_mat := _mat(Color(0.9, 0.25, 0.2), 0.25)
	var dot_mat := _mat(Color(1, 1, 0.95))
	var sb := StaticBody3D.new()
	sb.name = "Body"
	sb.collision_layer = 1
	sb.collision_mask = 0
	mush.add_child(sb)
	var stem_shape := CylinderShape3D.new()
	stem_shape.radius = 0.28
	stem_shape.height = 1.0
	var stem_col := CollisionShape3D.new()
	stem_col.name = "Stem"
	stem_col.shape = stem_shape
	stem_col.position = Vector3(0, 0.5, 0)
	sb.add_child(stem_col)
	var cap_shape := CylinderShape3D.new()
	cap_shape.radius = 0.9
	cap_shape.height = 0.3
	var cap_col := CollisionShape3D.new()
	cap_col.name = "CapShape"
	cap_col.shape = cap_shape
	cap_col.position = Vector3(0, 1.1, 0)
	sb.add_child(cap_col)
	_mesh(mush, "StemMesh", _cyl(0.28, 1.0), Vector3(0, 0.5, 0), Vector3.ZERO, stem_mat)
	var cap := Node3D.new()
	cap.name = "Cap"
	cap.position = Vector3(0, 0.95, 0)
	mush.add_child(cap)
	var dome := SphereMesh.new()
	dome.radius = 0.95
	dome.height = 0.95
	dome.is_hemisphere = true
	_mesh(cap, "Dome", dome, Vector3.ZERO, Vector3.ZERO, cap_mat)
	for i: int in 5:
		var ang: float = TAU * float(i) / 5.0
		_mesh(cap, "Dot%d" % i, _sphere(0.11), Vector3(cos(ang) * 0.55, 0.38, sin(ang) * 0.55), Vector3.ZERO, dot_mat)
	var area := Area3D.new()
	area.name = "BounceArea"
	var ashape := BoxShape3D.new()
	ashape.size = Vector3(1.7, 0.5, 1.7)
	var acol := CollisionShape3D.new()
	acol.name = "Shape"
	acol.shape = ashape
	acol.position = Vector3(0, 1.45, 0)
	area.add_child(acol)
	mush.add_child(area)
	_save_scene(mush, "res://world/platforms_2d/bouncy_mushroom.tscn")

	# Rám obrazu – vstupní portál (umisťuje se těsně před rám)
	var portal := Area3D.new()
	portal.name = "PaintingPortal"
	portal.set_script(load("res://world/portals/painting_portal.gd"))
	var pshape := BoxShape3D.new()
	pshape.size = Vector3(5.0, 3.0, 1.2)
	var pcol := CollisionShape3D.new()
	pcol.name = "Shape"
	pcol.shape = pshape
	pcol.position = Vector3(0, 1.5, 0)
	portal.add_child(pcol)
	var cm := Marker3D.new()
	cm.name = "CameraMarker"
	cm.position = Vector3(0, 3.0, 3.4)
	portal.add_child(cm)
	var rp := Marker3D.new()
	rp.name = "ReturnPoint"
	rp.position = Vector3(0, 0.05, 3.3)
	rp.rotation_degrees = Vector3(0, 180, 0)
	portal.add_child(rp)
	_save_scene(portal, "res://world/portals/painting_portal.tscn")

	# Výstupní portál (konec 2D úrovně)
	var exitp := Area3D.new()
	exitp.name = "ExitPortal"
	exitp.set_script(load("res://world/portals/exit_portal.gd"))
	var eshape := BoxShape3D.new()
	eshape.size = Vector3(1.6, 2.6, 3.0)
	var ecol := CollisionShape3D.new()
	ecol.name = "Shape"
	ecol.shape = eshape
	ecol.position = Vector3(0, 1.3, 0)
	exitp.add_child(ecol)
	var ring := Node3D.new()
	ring.name = "Ring"
	ring.position = Vector3(0, 1.4, 0)
	exitp.add_child(ring)
	var torus := TorusMesh.new()
	torus.inner_radius = 0.95
	torus.outer_radius = 1.18
	_mesh(ring, "Torus", torus, Vector3.ZERO, Vector3(90, 0, 0), _mat(Color(0.95, 0.71, 0.2), 1.2))
	var disc := CylinderMesh.new()
	disc.top_radius = 0.95
	disc.bottom_radius = 0.95
	disc.height = 0.02
	var disc_mat := _mat(Color(0.3, 0.6, 1.0), 1.0)
	disc_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	disc_mat.albedo_color.a = 0.55
	_mesh(ring, "Disc", disc, Vector3.ZERO, Vector3(90, 0, 0), disc_mat)
	_save_scene(exitp, "res://world/portals/exit_portal.tscn")


# ------------------------------------------------------------------ camera
func _build_camera() -> void:
	var root := Node3D.new()
	root.name = "HybridCamera"
	root.set_script(load("res://camera/hybrid_camera.gd"))
	root.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF

	var rig := Node3D.new()
	rig.name = "ThirdPersonRig"
	rig.set_script(load("res://camera/third_person_rig.gd"))
	root.add_child(rig)
	var yaw := Node3D.new()
	yaw.name = "YawPivot"
	rig.add_child(yaw)
	var pitch := Node3D.new()
	pitch.name = "PitchPivot"
	yaw.add_child(pitch)
	var arm := SpringArm3D.new()
	arm.name = "SpringArm3D"
	arm.collision_mask = 1
	arm.margin = 0.2
	var arm_shape := SphereShape3D.new()
	arm_shape.radius = 0.25
	arm.shape = arm_shape
	arm.spring_length = 5.5
	# Kamera lehce přes pravé rameno, aby Bruno nezakrýval zaměřovač.
	arm.position = Vector3(0.55, 0, 0)
	pitch.add_child(arm)
	var point := Marker3D.new()
	point.name = "CameraPoint"
	arm.add_child(point)

	var side := Node3D.new()
	side.name = "SideScrollRig"
	side.set_script(load("res://camera/side_scroll_rig.gd"))
	root.add_child(side)

	var cam := Camera3D.new()
	cam.name = "Camera3D"
	cam.fov = 70.0
	cam.near = 0.05
	cam.current = true
	root.add_child(cam)

	_save_scene(root, "res://camera/hybrid_camera.tscn")


# ------------------------------------------------------------------ greybox street
func _box(parent: Node, name: String, size: Vector3, pos: Vector3, mat: Material, rot_deg: Vector3 = Vector3.ZERO) -> CSGBox3D:
	var b := CSGBox3D.new()
	b.name = name
	b.size = size
	b.position = pos
	b.rotation_degrees = rot_deg
	b.use_collision = true
	b.collision_layer = 1
	b.collision_mask = 0
	b.material = mat
	parent.add_child(b)
	return b


func _sign(parent: Node, name: String, key: String, pos: Vector3, px: float, color: Color, rot_y: float = 0.0) -> void:
	var l := Label3D.new()
	l.name = name
	l.text = key
	l.font_size = 64
	l.outline_size = 16
	l.pixel_size = px
	l.modulate = color
	l.position = pos
	l.rotation_degrees = Vector3(0, rot_y, 0)
	parent.add_child(l)


func _build_greybox_street() -> void:
	var root := Node3D.new()
	root.name = "GreyboxStreet"

	var env := Environment.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.06, 0.07, 0.2)
	sky_mat.sky_horizon_color = Color(0.25, 0.22, 0.45)
	sky_mat.ground_horizon_color = Color(0.2, 0.18, 0.35)
	sky_mat.ground_bottom_color = Color(0.05, 0.05, 0.1)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 1.2
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world_env := WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	world_env.environment = env
	root.add_child(world_env)

	var moon := DirectionalLight3D.new()
	moon.name = "MoonLight"
	moon.light_color = Color(0.75, 0.8, 1.0)
	moon.light_energy = 0.9
	moon.shadow_enabled = true
	moon.rotation_degrees = Vector3(-50, -35, 0)
	root.add_child(moon)

	var geo := Node3D.new()
	geo.name = "Geometry"
	root.add_child(geo)
	var grey := _mat(Color(0.45, 0.45, 0.5))
	var light := _mat(Color(0.58, 0.58, 0.64))
	var dark := _mat(Color(0.3, 0.3, 0.36))
	var gold := _mat(Color(0.95, 0.71, 0.2), 0.6)
	var warn := _mat(Color(0.85, 0.25, 0.25))

	# Ulice ve dvou částech s propastí 3,5 m mezi nimi (x 14 → 17,5)
	_box(geo, "StreetA", Vector3(44, 1, 24), Vector3(-8, -0.5, 0), grey)
	_box(geo, "StreetB", Vector3(22.5, 1, 24), Vector3(28.75, -0.5, 0), grey)
	_box(geo, "GapEdgeA", Vector3(0.3, 0.05, 24), Vector3(13.85, 0.02, 0), warn)
	_box(geo, "GapEdgeB", Vector3(0.3, 0.05, 24), Vector3(17.65, 0.02, 0), warn)
	# Domy
	_box(geo, "HouseLeft", Vector3(10, 8, 8), Vector3(-14, 4, -10), dark)
	_box(geo, "HouseMid", Vector3(8, 11, 8), Vector3(0, 5.5, -12), dark)
	_box(geo, "HouseRight", Vector3(10, 6, 8), Vector3(14, 3, -10), dark)
	# Rampa (místo schodů – CharacterBody nešplhá po hraně schodu) a plošina nahoře
	_box(geo, "Ramp", Vector3(8, 0.4, 3), Vector3(-10, 0.95, 4), light, Vector3(0, 0, 14))
	_box(geo, "RampTop", Vector3(4, 2, 3), Vector3(-4, 1.0, 4), light)
	# Skokové kostky: 1 m, 1,5 m (skok), 2,4 m (dvojskok)
	_box(geo, "JumpBox1m", Vector3(2, 1, 2), Vector3(-14, 0.5, 10), light)
	_box(geo, "JumpBox1_5m", Vector3(2, 1.5, 2), Vector3(-18, 0.75, 10), light)
	_box(geo, "JumpBox2_4m", Vector3(2, 2.4, 2), Vector3(-22, 1.2, 10), light)
	# Původní schody z Kroku A
	_box(geo, "StepLow", Vector3(4, 1, 4), Vector3(6, 0.5, 2), grey)
	_box(geo, "StepHigh", Vector3(4, 2, 4), Vector3(10, 1, 2), grey)
	# Rám obrazu (portál bude v Kroku F)
	_box(geo, "PaintingFrame", Vector3(6, 4, 0.6), Vector3(24, 3, -6), gold)
	# Cesta na střechy: StepHigh (2 m) → bedna (4,5 m) → střecha HouseRight (6 m)
	_box(geo, "RoofCrate", Vector3(2.5, 4.5, 2.5), Vector3(11, 2.25, -3.5), light)

	# Modré špičky (kotvy typu SPIRE)
	var spires := Node3D.new()
	spires.name = "Spires"
	root.add_child(spires)
	var spire_scene: PackedScene = load("res://world/anchors/spire_anchor.tscn")
	var spire_spots: Array = [
		["SpirePractice", Vector3(4, 0, 9)],         # cvičná u startu
		["Spire1_RoofRight", Vector3(11, 6, -9)],    # na střeše HouseRight
		["Spire2_Pole", Vector3(6.5, 0, -10)],       # vysoký sloup mezi domy
		["Spire3_RoofMid", Vector3(2, 11, -9)],      # na střeše HouseMid
	]
	for spot: Array in spire_spots:
		var sp: Node3D = spire_scene.instantiate()
		sp.name = spot[0]
		sp.position = spot[1] + (Vector3(0, 7.0, 0) if spot[0] == "Spire2_Pole" else Vector3.ZERO)
		spires.add_child(sp)
	# Vysoký sloup pod Spire2 (aby špička byla v 8,6 m)
	_box(geo, "Spire2Column", Vector3(0.5, 7.0, 0.5), Vector3(6.5, 3.5, -10), dark)

	# Věž se zvonem (cíl pro tenisák) a brána před obrazem
	_box(geo, "BellTower", Vector3(2.4, 8, 2.4), Vector3(32, 4, -9), dark)
	var bell: Node3D = (load("res://world/props/target_bell.tscn") as PackedScene).instantiate()
	bell.name = "TargetBell"
	bell.position = Vector3(32, 8, -9)
	bell.rotation_degrees = Vector3(0, -90, 0)
	root.add_child(bell)
	# Tréninkový koutek útoku holí: figurína + 3 rozbitelné bedny
	var training := Node3D.new()
	training.name = "Training"
	root.add_child(training)
	var dummy_inst: Node3D = (load("res://world/props/training_dummy.tscn") as PackedScene).instantiate()
	dummy_inst.position = Vector3(-7, 0, 9)
	training.add_child(dummy_inst)
	var crate_scene: PackedScene = load("res://world/props/breakable_crate.tscn")
	for i: int in 3:
		var c: Node3D = crate_scene.instantiate()
		c.name = "Crate%d" % (i + 1)
		c.position = Vector3(-9.0 - i * 1.3, 0, 7.8)
		training.add_child(c)
	_sign(root, "SignTraining", "GB_SIGN_TRAINING", Vector3(-9, 2.4, 7.2), 0.0042, Color(1.0, 0.85, 0.4))
	var gate: Node3D = (load("res://world/props/gate.tscn") as PackedScene).instantiate()
	gate.name = "PaintingGate"
	gate.position = Vector3(24, 0, -5.2)
	root.add_child(gate)

	_sign(root, "PaintingSign", "GB_SIGN_PAINTING", Vector3(24, 6, -5.6), 0.011, Color(1.0, 0.92, 0.6))
	_sign(root, "DiacriticsTest", "GB_DIACRITICS_TEST", Vector3(0, 9.0, -7.9), 0.012, Color(1, 1, 1))
	_sign(root, "SignJumps", "GB_SIGN_JUMPS", Vector3(-18, 3.4, 8.9), 0.006, Color(0.8, 0.9, 1.0))
	_sign(root, "SignRamp", "GB_SIGN_RAMP", Vector3(-8, 3.4, 5.6), 0.008, Color(0.8, 0.9, 1.0))
	_sign(root, "SignGap", "GB_SIGN_GAP", Vector3(15.75, 2.2, 3), 0.008, Color(1.0, 0.6, 0.6))
	_sign(root, "SignSpire", "GB_SIGN_SPIRE", Vector3(4, 3.0, 9), 0.007, Color(0.6, 0.85, 1.0))
	_sign(root, "SignRoofs", "GB_SIGN_ROOFS", Vector3(11, 5.4, -2.1), 0.007, Color(0.6, 0.85, 1.0))
	# --- Krok F: obraz v rámu, vstupní portál, 2D svět uvnitř obrazu
	var canvas_quad := QuadMesh.new()
	canvas_quad.size = Vector2(5.2, 3.3)
	var canvas_mat := _unshaded(Color(0.98, 0.78, 0.45))
	_mesh(root, "PaintingCanvas", canvas_quad, Vector3(24, 3, -5.68), Vector3.ZERO, canvas_mat)
	var hill_quad := QuadMesh.new()
	hill_quad.size = Vector2(5.0, 1.3)
	_mesh(root, "PaintingCanvasHills", hill_quad, Vector3(24, 2.0, -5.67), Vector3.ZERO, _unshaded(Color(0.25, 0.55, 0.5)))

	var world2d := Node3D.new()
	world2d.name = "PaintingWorld"
	root.add_child(world2d)
	var ochre := _mat(Color(0.86, 0.6, 0.3))
	var ochre_dark := _mat(Color(0.6, 0.38, 0.2))
	_box(world2d, "Floor1", Vector3(18, 1, 4), Vector3(205, -0.5, 0), ochre)
	_box(world2d, "HighLedge", Vector3(8, 10, 4), Vector3(218, -0.5, 0), ochre_dark)
	_box(world2d, "Floor3", Vector3(14, 1, 4), Vector3(234, -0.5, 0), ochre)
	_box(world2d, "GoalLedge", Vector3(8, 11, 4), Vector3(245, -0.5, 0), ochre_dark)
	var mush_scene: PackedScene = load("res://world/platforms_2d/bouncy_mushroom.tscn")
	for spot: Array in [["Mushroom1", Vector3(211, 0, 0)], ["Mushroom2", Vector3(238, 0, 0)]]:
		var m: Node3D = mush_scene.instantiate()
		m.name = spot[0]
		m.position = spot[1]
		world2d.add_child(m)
	# Malované pozadí (UbiArt greybox): vrstvy v různé hloubce = parallax zdarma
	var far := QuadMesh.new()
	far.size = Vector2(160, 60)
	_mesh(world2d, "BgFar", far, Vector3(222, 8, -40), Vector3.ZERO, _unshaded(Color(0.98, 0.85, 0.58)))
	var hills := QuadMesh.new()
	hills.size = Vector2(26, 9)
	for i: int in 6:
		_mesh(world2d, "BgHills%d" % i, hills, Vector3(190 + i * 13, 1.5 + float(i % 2) * 1.5, -18), Vector3(0, 0, 8.0 * float(i % 3 - 1)), _unshaded(Color(0.3, 0.6, 0.55)))
	var bush := QuadMesh.new()
	bush.size = Vector2(6, 3)
	for i: int in 9:
		_mesh(world2d, "BgBush%d" % i, bush, Vector3(194 + i * 6.5, 0.6, -5), Vector3.ZERO, _unshaded(Color(0.16, 0.38, 0.33)))
	var lane_start := Marker3D.new()
	lane_start.name = "LaneStart"
	lane_start.position = Vector3(199, 0.05, 0)
	world2d.add_child(lane_start)
	_sign(world2d, "SignMushroom", "GB_SIGN_MUSHROOM", Vector3(209, 3.2, 0.5), 0.006, Color(0.3, 0.15, 0.05))
	_sign(world2d, "SignExit", "GB_SIGN_EXIT", Vector3(246, 8.6, 0.5), 0.006, Color(0.3, 0.15, 0.05))

	var portal: Area3D = (load("res://world/portals/painting_portal.tscn") as PackedScene).instantiate()
	portal.name = "PaintingPortal"
	portal.position = Vector3(24, 0, -4.4)
	root.add_child(portal)
	portal.set("lane_start", lane_start)
	portal.set("gate", gate)
	var exitp: Area3D = (load("res://world/portals/exit_portal.tscn") as PackedScene).instantiate()
	exitp.name = "ExitPortal"
	exitp.position = Vector3(246, 5.0, 0)
	world2d.add_child(exitp)
	exitp.set("entry_portal", portal)

	_sign(root, "SignBell", "GB_SIGN_BELL", Vector3(32, 11.2, -9), 0.009, Color(0.85, 1.0, 0.4), -90.0)

	# Bruno + kamera
	var spawn := Vector3(0, 0.05, 11)
	var player: Node3D = (load("res://player/player.tscn") as PackedScene).instantiate()
	player.position = spawn
	root.add_child(player)
	var cam: Node3D = (load("res://camera/hybrid_camera.tscn") as PackedScene).instantiate()
	root.add_child(cam)
	cam.set("target", player)
	player.set("camera", cam)

	# Nápověda
	var ui := CanvasLayer.new()
	ui.name = "HintLayer"
	ui.set_script(load("res://levels/greybox/greybox_hints.gd"))
	root.add_child(ui)
	var box := VBoxContainer.new()
	box.name = "HintBox"
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	box.offset_top = -130
	box.offset_bottom = -20
	box.offset_left = -940
	box.offset_right = 940
	box.alignment = BoxContainer.ALIGNMENT_END
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(box)
	for pair: Array in [["Title", "GB_TITLE", 30], ["Controls", "GB_HINT_CONTROLS", 20], ["Keys", "GB_HINT_KEYS", 18]]:
		var l := Label.new()
		l.name = pair[0]
		l.text = pair[1]
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.add_theme_font_size_override("font_size", pair[2])
		l.add_theme_constant_override("outline_size", 8)
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(l)

	var cross := Label.new()
	cross.name = "Crosshair"
	cross.text = "+"
	cross.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	cross.add_theme_font_size_override("font_size", 30)
	cross.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	cross.add_theme_constant_override("outline_size", 6)
	cross.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	cross.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	cross.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cross.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cross.grow_horizontal = Control.GROW_DIRECTION_BOTH
	cross.grow_vertical = Control.GROW_DIRECTION_BOTH
	cross.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(cross)

	_save_scene(root, "res://levels/greybox/greybox_street.tscn")
