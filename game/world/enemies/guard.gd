## Strážný s baterkou (inspirace klasické 3D stealth plošinovky). Kostra stealth nepřítele.
##
## Vnímání: kužel baterky (úhel + dosah) a přímá viditelnost (paprsek na zdi).
## Detekce je „rozmazaná“: ukazatel podezření se plní tím rychleji, čím blíž Bruno je.
## Plížení zmenší dosah. Zblízka (close_radius) strážný Bruna ucítí i zezadu – jako ve stealth hryovi.
##
## Stavy: PATROL → SUSPICIOUS („?“, otočí se za Brunem) → ALERT („!“, honí a útočí)
##        → SEARCH (ztratil ho, chvíli hledá) → zpět PATROL.  Zásah holí → STUNNED.
## Nepozorovaný zásah zezadu = okamžité knockout (odměna za stealth), jinak 3 zásahy.
@tool
class_name Guard
extends CharacterBody3D

enum State { PATROL, SUSPICIOUS, ALERT, SEARCH, STUNNED, KNOCKED_OUT }

@export_group("Hlídka")
## Body hlídky relativně k výchozí pozici strážného (aspoň 2 body).
@export var patrol_points: PackedVector3Array = PackedVector3Array([Vector3(-4, 0, 0), Vector3(4, 0, 0)])
@export var patrol_speed: float = 1.8
@export var chase_speed: float = 4.6
## Jak dlouho stojí a rozhlíží se na konci trasy.
@export var wait_time: float = 1.4

@export_group("Vnímání")
@export var view_angle_deg: float = 32.0:
	set(v):
		view_angle_deg = v
		if is_inside_tree():
			_build()
@export var view_range: float = 9.0:
	set(v):
		view_range = v
		if is_inside_tree():
			_build()
## Násobek dosahu, když se Bruno plíží.
@export var sneak_range_mult: float = 0.55
## Na tuto vzdálenost strážný Bruna vždy ucítí (i zezadu), pokud se neplíží.
@export var close_radius: float = 1.6
## Sekundy plného podezření potřebné k poplachu (zblízka rychleji).
@export var detect_time: float = 0.9
@export var lose_time: float = 3.0
## Na jakou vzdálenost slyší volání kolegy o pomoc.
@export var help_radius: float = 18.0

@export_group("Boj")
@export var max_health: int = 3
@export var attack_range: float = 1.3
@export var attack_cooldown: float = 1.1
## Nápřah před úderem (s): strážný se zakloní a zabliká „!“ – dá se uhnout (C / L1).
@export var windup_time: float = 0.45
@export var stun_time: float = 1.6

@export_group("Kapsářství")
## Kolik mincí má strážný u pasu (0 = nic).
@export var loot: int = 25
## Klíč, který strážný nosí u pasu (prázdné = žádný). Ukradne se spolu s mincemi.
@export var carries_key: String = ""
## Jak blízko za zády musí Bruno být.
@export var pickpocket_range: float = 1.7

var state: State = State.PATROL
var suspicion: float = 0.0
var health: int = 3

var _origin: Vector3
var _patrol_idx: int = 0
var _wait: float = 0.0
var _timer: float = 0.0
var _attack_cd: float = 0.0
var _last_seen: Vector3
var _player: Player
## Při hledání jít na místo (false = místo je jinde výš/níž – jen se otočit a dívat).
var _search_walk: bool = true
var _windup: float = -1.0
var _start_transform: Transform3D
var _ko_tween: Tween

var _body: Node3D
var _cone: MeshInstance3D
var _cone_mat: StandardMaterial3D
var _label: Label3D
var _meter: MeshInstance3D
var _bag: MeshInstance3D
var _hint: Label3D
var _key_mesh: MeshInstance3D


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	_build()
	if Engine.is_editor_hint():
		return
	add_to_group(&"hittable")
	add_to_group(&"guard")
	health = max_health
	_origin = global_position
	_last_seen = global_position
	Events.noise_made.connect(_on_noise)
	Events.guard_called_help.connect(_on_help)
	Events.player_died.connect(_on_player_died)
	_start_transform = global_transform


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(&"player") as Player
	_attack_cd = maxf(_attack_cd - delta, 0.0)

	var sees: bool = _can_see_player()
	match state:
		State.PATROL:
			_patrol(delta)
			_update_suspicion(delta, sees)
		State.SUSPICIOUS:
			_stop(delta)
			_face(_last_seen, delta, 5.0)
			_update_suspicion(delta, sees)
		State.ALERT:
			_alert(delta, sees)
		State.SEARCH:
			_timer -= delta
			if _search_walk:
				_move_towards(_last_seen, patrol_speed * 1.3, delta)
			else:
				_stop(delta)
				_face(_last_seen, delta, 4.0)
			if sees:
				_set_state(State.ALERT)
			elif _timer <= 0.0:
				_set_state(State.PATROL)
		State.STUNNED:
			_stop(delta)
			_timer -= delta
			_body.rotation.z = sin(_timer * 30.0) * 0.12
			if _timer <= 0.0:
				_body.rotation.z = 0.0
				_set_state(State.ALERT)
		State.KNOCKED_OUT:
			_stop(delta)

	if not is_on_floor():
		velocity.y -= 24.0 * delta
	else:
		velocity.y = -0.5
	move_and_slide()
	_update_visuals()
	_update_pickpocket_hint()


## Bruno je zezadu blízko, strážný nic netuší a má co ukrást?
func can_be_pickpocketed_by(p: Player) -> bool:
	if (loot <= 0 and carries_key.is_empty()) or not (state == State.PATROL or state == State.SUSPICIOUS) or p == null:
		return false
	var to: Vector3 = p.global_position - global_position
	to.y = 0.0
	if to.length() > pickpocket_range:
		return false
	# Za zády = Bruno je v opačném směru, než se strážný dívá.
	return to.normalized().dot(_forward()) < -0.2


func pickpocket(p: Player) -> void:
	var amount: int = loot
	loot = 0
	_bag.visible = false
	_hint.visible = false
	if amount > 0:
		GameState.add_coins(amount)
	if not carries_key.is_empty():
		GameState.add_key(carries_key)
		carries_key = ""
		if _key_mesh != null:
			_key_mesh.visible = false
	AudioManager.play(&"pickup", 0.0, 0.75, 0.0)
	AudioManager.play(&"pickup", -4.0, 1.25, 0.0)
	p.visual.play_swing(0.2)


func _update_pickpocket_hint() -> void:
	if _hint == null:
		return
	_hint.visible = _player != null and can_be_pickpocketed_by(_player)


# --- Vnímání ---------------------------------------------------------------

func _can_see_player() -> bool:
	if _player == null or _player.health <= 0 or _player.hidden_in != null:
		return false
	var eye: Vector3 = global_position + Vector3.UP * 1.5
	var target: Vector3 = _player.global_position + Vector3.UP * 0.5
	var to: Vector3 = target - eye
	var dist: float = to.length()
	var sneaking: bool = _player.is_sneaking
	var in_close: bool = dist < close_radius and not sneaking
	var range_now: float = view_range * (sneak_range_mult if sneaking else 1.0)
	if not in_close:
		if dist > range_now:
			return false
		var fwd: Vector3 = _forward()
		var flat: Vector3 = Vector3(to.x, 0.0, to.z).normalized()
		if fwd.angle_to(flat) > deg_to_rad(view_angle_deg):
			return false
	# Přímá viditelnost (zdi, bedny – vrstva world).
	var q := PhysicsRayQueryParameters3D.create(eye, target, 1)
	q.exclude = [get_rid()]
	if not get_world_3d().direct_space_state.intersect_ray(q).is_empty():
		return false
	_last_seen = _player.global_position
	return true


func _update_suspicion(delta: float, sees: bool) -> void:
	if sees:
		var dist: float = global_position.distance_to(_player.global_position)
		var closeness: float = clampf(1.0 - dist / view_range, 0.15, 1.0)
		suspicion += delta / detect_time * (0.5 + closeness * 1.5)
		if state == State.PATROL and suspicion > 0.2:
			_set_state(State.SUSPICIOUS)
		if suspicion >= 1.0:
			_set_state(State.ALERT)
	else:
		suspicion -= delta * 0.4
		if suspicion <= 0.0 and state == State.SUSPICIOUS:
			_set_state(State.PATROL)
	suspicion = clampf(suspicion, 0.0, 1.0)


# --- Chování ---------------------------------------------------------------

func _patrol(delta: float) -> void:
	if patrol_points.size() < 2:
		_stop(delta)
		return
	if _wait > 0.0:
		_wait -= delta
		_stop(delta)
		# Rozhlížení na místě.
		rotation.y += sin(_wait * 2.5) * delta * 0.9
		return
	var target: Vector3 = _origin + patrol_points[_patrol_idx]
	if _move_towards(target, patrol_speed, delta):
		_patrol_idx = (_patrol_idx + 1) % patrol_points.size()
		_wait = wait_time


func _alert(delta: float, sees: bool) -> void:
	if sees:
		_timer = lose_time
	else:
		_timer -= delta
		if _timer <= 0.0:
			_set_state(State.SEARCH)
			return
	var dist: float = global_position.distance_to(_player.global_position)
	if dist > attack_range * 0.8:
		_move_towards(_last_seen, chase_speed, delta)
	else:
		_stop(delta)
		_face(_player.global_position, delta, 10.0)
	if _windup >= 0.0:
		_windup += delta
		_body.rotation.x = lerpf(0.0, -0.35, minf(_windup / windup_time, 1.0))
		if _windup >= windup_time:
			_windup = -1.0
			_attack_cd = attack_cooldown
			_swing()
			# Úder trefí jen to, co je pořád před strážným a na dosah.
			var to: Vector3 = _player.global_position - global_position
			to.y = 0.0
			if to.length() <= attack_range + 0.3 and _forward().dot(to.normalized()) > 0.35:
				_player.take_damage(1, global_position)
		return
	if dist <= attack_range and _attack_cd <= 0.0 and sees:
		_windup = 0.0
		AudioManager.play_at(&"suspicious", global_position, -2.0, 1.6)


## Vrací true, když dorazil.
func _move_towards(target: Vector3, speed: float, delta: float) -> bool:
	var to: Vector3 = target - global_position
	to.y = 0.0
	if to.length() < 0.35:
		_stop(delta)
		return true
	var dir: Vector3 = to.normalized()
	velocity.x = move_toward(velocity.x, dir.x * speed, 20.0 * delta)
	velocity.z = move_toward(velocity.z, dir.z * speed, 20.0 * delta)
	_face(global_position + dir, delta, 6.0)
	return false


func _stop(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 25.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 25.0 * delta)


func _face(point: Vector3, delta: float, speed: float) -> void:
	var to: Vector3 = point - global_position
	if Vector2(to.x, to.z).length() < 0.05:
		return
	var want: float = atan2(-to.x, -to.z)
	rotation.y = lerp_angle(rotation.y, want, 1.0 - exp(-speed * delta))


func _forward() -> Vector3:
	return -global_transform.basis.z


func _set_state(s: State) -> void:
	if s == state:
		return
	var was_alert: bool = state == State.ALERT
	state = s
	match s:
		State.SUSPICIOUS:
			AudioManager.play_at(&"suspicious", global_position)
		State.ALERT:
			suspicion = 1.0
			_timer = lose_time
			AudioManager.play_at(&"alert", global_position)
			Events.guard_alert_changed.emit(true)
			Events.guard_called_help.emit(self, _last_seen)
		State.SEARCH:
			_timer = 4.0
			suspicion = 0.5
			_search_walk = absf(_last_seen.y - global_position.y) < 2.0
		State.PATROL:
			suspicion = 0.0
	if was_alert and s != State.ALERT:
		Events.guard_alert_changed.emit(false)


# --- Hluk a posily ---------------------------------------------------------

## Jít se podívat na místo (hluk, volání kolegy). Jen když strážný ještě nehoní Bruna.
func investigate(pos: Vector3) -> void:
	if state == State.ALERT or state == State.STUNNED or state == State.KNOCKED_OUT:
		return
	_last_seen = pos
	_search_walk = absf(pos.y - global_position.y) < 2.0
	if state != State.SEARCH:
		AudioManager.play_at(&"suspicious", global_position)
	state = State.SEARCH
	_timer = 6.0
	suspicion = maxf(suspicion, 0.5)


func _on_noise(pos: Vector3, radius: float) -> void:
	if global_position.distance_to(pos) <= radius:
		investigate(pos)


func _on_help(caller: Node, pos: Vector3) -> void:
	if caller != self and global_position.distance_to((caller as Node3D).global_position) <= help_radius:
		investigate(pos)


# --- Návrat po Brunově smrti ---------------------------------------------

## Když Bruno padne, všichni strážní se (pod inkoustovou clonou) vrátí na svá
## místa v plné síle – vyřazení tedy nikdy nezablokuje level. Klíč a mince, které
## už Bruno vzal nebo které vypadly, se znovu neobjeví.
func _on_player_died() -> void:
	get_tree().create_timer(0.36).timeout.connect(reset_to_start)


func reset_to_start() -> void:
	if not is_inside_tree():
		return
	if _ko_tween != null and _ko_tween.is_valid():
		_ko_tween.kill()
	var was_alert: bool = state == State.ALERT
	state = State.PATROL
	if was_alert:
		Events.guard_alert_changed.emit(false)
	health = max_health
	suspicion = 0.0
	_windup = -1.0
	_attack_cd = 0.0
	_patrol_idx = 0
	_wait = 0.0
	velocity = Vector3.ZERO
	global_transform = _start_transform
	reset_physics_interpolation()
	_body.rotation = Vector3.ZERO
	_body.position.y = 0.0
	_body.scale = Vector3.ONE * _body_scale()
	visible = true
	collision_layer = 4
	if not is_in_group(&"hittable"):
		add_to_group(&"hittable")
	if not is_in_group(&"guard"):
		add_to_group(&"guard")
	_cone.visible = true
	_label.text = ""
	_bag.visible = loot > 0
	if _key_mesh != null:
		_key_mesh.visible = not carries_key.is_empty()


## Výchozí měřítko vizuálu (boss je větší).
func _body_scale() -> float:
	return 1.0


# --- Zásah holí ------------------------------------------------------------

func on_cane_hit(info: Dictionary) -> void:
	if state == State.KNOCKED_OUT:
		return
	_windup = -1.0
	_body.rotation.x = 0.0
	var unaware: bool = state == State.PATROL or state == State.SUSPICIOUS
	if bool(info.get("ball", false)):
		# Omračující tenisák: jen omráčí (delší dobu), nezraní.
		_timer = stun_time * 1.8
		_set_state(State.STUNNED)
		AudioManager.play_at(&"hit", global_position, 0.0, 1.5)
		return
	health -= max_health if unaware else int(info.get("damage", 1))
	var dir: Vector3 = info.get("dir", -_forward())
	velocity += Vector3(dir.x, 0.0, dir.z).normalized() * 5.0 + Vector3.UP * 2.5
	_flash()
	if health <= 0:
		_knock_out()
		return
	_timer = stun_time
	_set_state(State.STUNNED)


func _knock_out() -> void:
	var was_alert: bool = state == State.ALERT
	state = State.KNOCKED_OUT
	if was_alert:
		Events.guard_alert_changed.emit(false)
	Events.guard_knocked_out.emit()
	_drop_loot()
	collision_layer = 0
	remove_from_group(&"hittable")
	_cone.visible = false
	_label.text = "✶"
	_label.modulate = Color(1, 0.9, 0.3)
	var tw: Tween = create_tween()
	tw.tween_property(_body, "rotation:x", -PI * 0.5, 0.35).set_trans(Tween.TRANS_BOUNCE)
	tw.tween_interval(2.0)
	# Škálovat jen vizuál – fyzikální tělo (Jolt) neumí nerovnoměrné měřítko.
	tw.tween_property(_body, "scale", Vector3(_body.scale.x, 0.01, _body.scale.z), 0.3)
	tw.tween_callback(func() -> void:
		visible = false
		remove_from_group(&"guard"))
	_ko_tween = tw


## Vyřazený strážný upustí klíč (jinak by loupež nešla dohrát) a polovinu mincí.
## Kapsářství se tak pořád vyplatí víc.
func _drop_loot() -> void:
	var half: int = int(float(loot) * 0.5)
	if carries_key.is_empty() and half <= 0:
		return
	var k := KeyPickup.new()
	k.key_id = carries_key
	k.coins = half
	get_parent().add_child(k)
	k.global_position = global_position + _forward() * -0.6
	carries_key = ""
	loot = 0
	if _key_mesh != null:
		_key_mesh.visible = false
	_bag.visible = false


func _swing() -> void:
	var tw: Tween = create_tween()
	tw.tween_property(_body, "rotation:x", 0.35, 0.08)
	tw.tween_property(_body, "rotation:x", 0.0, 0.2)


func _flash() -> void:
	var m: MeshInstance3D = _body.get_child(0) as MeshInstance3D
	if m == null:
		return
	var mat: StandardMaterial3D = m.material_override as StandardMaterial3D
	mat.emission_enabled = true
	mat.emission = Color(1, 1, 1)
	var tw: Tween = create_tween()
	tw.tween_property(mat, "emission_energy_multiplier", 0.0, 0.18).from(2.0)


# --- Vzhled ----------------------------------------------------------------

func _update_visuals() -> void:
	if state == State.KNOCKED_OUT:
		return
	var c: Color
	match state:
		State.ALERT: c = Color(1.0, 0.15, 0.1, 0.22)
		State.SUSPICIOUS, State.SEARCH: c = Color(1.0, 0.6, 0.1, 0.18)
		State.STUNNED: c = Color(0.6, 0.6, 0.6, 0.05)
		_: c = Color(1.0, 0.95, 0.55, 0.13)
	_cone_mat.albedo_color = c
	_cone.visible = state != State.STUNNED
	match state:
		State.ALERT: _label.text = "!"
		State.SUSPICIOUS, State.SEARCH: _label.text = "?"
		State.STUNNED: _label.text = "✶"
		_: _label.text = ""
	_label.modulate = Color(1, 0.2, 0.15) if state == State.ALERT else Color(1, 0.8, 0.2)
	if _windup >= 0.0 and int(_windup * 16.0) % 2 == 0:
		_label.modulate = Color(1, 1, 1) # nápřah – blikající „!“
	_meter.visible = suspicion > 0.01 and state != State.ALERT
	_meter.scale.x = maxf(suspicion, 0.01)


func _build() -> void:
	for c: Node in get_children():
		if c.has_meta(&"generated"):
			c.free()
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.8
	shape.shape = cap
	shape.position.y = 0.9
	shape.set_meta(&"generated", true)
	add_child(shape)

	_body = Node3D.new()
	_body.set_meta(&"generated", true)
	add_child(_body)
	var torso := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.4
	cm.height = 1.8
	torso.mesh = cm
	torso.position.y = 0.9
	var tm := StandardMaterial3D.new()
	tm.albedo_color = Color(0.45, 0.12, 0.15)
	torso.material_override = tm
	_body.add_child(torso)
	var hat := MeshInstance3D.new()
	var hm := CylinderMesh.new()
	hm.top_radius = 0.28
	hm.bottom_radius = 0.42
	hm.height = 0.25
	hat.mesh = hm
	hat.position.y = 1.9
	var hmat := StandardMaterial3D.new()
	hmat.albedo_color = Color(0.1, 0.1, 0.18)
	hat.material_override = hmat
	_body.add_child(hat)
	var lamp := MeshInstance3D.new()
	var lm := BoxMesh.new()
	lm.size = Vector3(0.14, 0.14, 0.3)
	lamp.mesh = lm
	lamp.position = Vector3(0.32, 1.35, -0.4)
	var lmat := StandardMaterial3D.new()
	lmat.albedo_color = Color(1, 0.95, 0.6)
	lmat.emission_enabled = true
	lmat.emission = Color(1, 0.9, 0.5)
	lamp.material_override = lmat
	_body.add_child(lamp)

	# Kužel baterky – průhledný, ukazuje, kam strážný vidí.
	_cone = MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.05
	cone.bottom_radius = tan(deg_to_rad(view_angle_deg)) * view_range
	cone.height = view_range
	cone.radial_segments = 24
	cone.cap_top = false
	cone.cap_bottom = false
	_cone.mesh = cone
	_cone.rotation.x = -PI * 0.5
	_cone.position = Vector3(0, 1.0, -view_range * 0.5)
	_cone_mat = StandardMaterial3D.new()
	_cone_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_cone_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_cone_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_cone_mat.albedo_color = Color(1.0, 0.95, 0.55, 0.13)
	_cone.material_override = _cone_mat
	_cone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_cone.set_meta(&"generated", true)
	add_child(_cone)

	_label = Label3D.new()
	_label.position.y = 2.55
	_label.font_size = 96
	_label.outline_size = 18
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.set_meta(&"generated", true)
	add_child(_label)

	_bag = MeshInstance3D.new()
	var bag_mesh := SphereMesh.new()
	bag_mesh.radius = 0.16
	bag_mesh.height = 0.3
	_bag.mesh = bag_mesh
	var bag_mat := StandardMaterial3D.new()
	bag_mat.albedo_color = Color(0.85, 0.65, 0.2)
	bag_mat.emission_enabled = true
	bag_mat.emission = Color(0.6, 0.45, 0.1)
	bag_mat.emission_energy_multiplier = 0.4
	_bag.material_override = bag_mat
	_bag.position = Vector3(0.3, 0.85, 0.35)
	_bag.set_meta(&"generated", true)
	add_child(_bag)

	_key_mesh = MeshInstance3D.new()
	var km := BoxMesh.new()
	km.size = Vector3(0.08, 0.32, 0.04)
	_key_mesh.mesh = km
	var kmat := StandardMaterial3D.new()
	kmat.albedo_color = Color(1, 0.85, 0.2)
	kmat.emission_enabled = true
	kmat.emission = Color(1, 0.75, 0.1)
	_key_mesh.material_override = kmat
	_key_mesh.position = Vector3(-0.32, 0.85, 0.33)
	_key_mesh.visible = not carries_key.is_empty()
	_key_mesh.set_meta(&"generated", true)
	add_child(_key_mesh)

	_hint = Label3D.new()
	_hint.text = "E / ○  ¤"
	_hint.position = Vector3(0, 1.4, 0.7)
	_hint.font_size = 56
	_hint.outline_size = 12
	_hint.modulate = Color(1, 0.85, 0.3)
	_hint.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_hint.no_depth_test = true
	_hint.visible = false
	_hint.set_meta(&"generated", true)
	add_child(_hint)

	_meter = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.9, 0.08, 0.02)
	_meter.mesh = bm
	_meter.position.y = 2.25
	var mm := StandardMaterial3D.new()
	mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mm.albedo_color = Color(1, 0.7, 0.1)
	mm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_meter.material_override = mm
	_meter.visible = false
	_meter.set_meta(&"generated", true)
	add_child(_meter)
