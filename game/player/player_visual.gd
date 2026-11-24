## Greybox vzhled Bruna: postoj na 2 nohách vs. sprint na 4 nohách, plížení, natočení do směru pohybu.
## Později se sem napojí skutečný model a AnimationTree – stavy hráče se kvůli tomu měnit nebudou.
class_name PlayerVisual
extends Node3D

enum Posture { STAND, SPRINT }

@onready var _stand: Node3D = $Stand
@onready var _sprint: Node3D = $Sprint
@onready var _ears: Node3D = $Stand/EarsPivot

var posture: Posture = Posture.STAND
var gliding: bool = false
var perched: bool = false
## Při míření se Bruno neotáčí do směru pohybu (úkroky do stran), ale drží směr kamery.
var facing_locked: bool = false
var _yaw: float = 0.0
var _squash: float = 1.0
var _ear_spin: float = 0.0

# Procedurální „živost“ (v0.2.6): krok, dech, ocas, plandání uší, cval nohou.
var _phase: float = 0.0
var _wag: float = 0.0
var _excited: float = 0.0
var _stand_base: Vector3
var _sprint_base: Vector3
var _legs: Array[Node3D] = []
var _leg_base: Array[Vector3] = []
var _tails: Array[Node3D] = []


func _ready() -> void:
	_stand_base = _stand.position
	_sprint_base = _sprint.position
	for n: String in ["LegFL", "LegFR", "LegBL", "LegBR"]:
		var leg: Node3D = _sprint.get_node_or_null(n) as Node3D
		if leg != null:
			_legs.append(leg)
			_leg_base.append(leg.rotation)
	# Ocas (tenký, nahoru zahnutý) pro oba postoje.
	var black: Material = ($Stand/Body as MeshInstance3D).material_override
	_tails.append(_make_tail(_stand, Vector3(0, 0.55, 0.26), black))
	_tails.append(_make_tail(_sprint, Vector3(0, 0.45, 0.62), black))
	if not Engine.is_editor_hint():
		Events.collectible_collected.connect(func(_id: String) -> void: _excited = 1.2)
		Events.coins_changed.connect(func(_t: int) -> void: _excited = 1.5)


func _make_tail(parent: Node3D, pos: Vector3, mat: Material) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = "TailPivot"
	pivot.position = pos
	parent.add_child(pivot)
	var m := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.015
	cyl.bottom_radius = 0.045
	cyl.height = 0.38
	m.mesh = cyl
	m.material_override = mat
	m.position = Vector3(0, 0.15, 0.08)
	m.rotation.x = deg_to_rad(35.0)
	pivot.add_child(m)
	return pivot


func set_posture(new_posture: Posture) -> void:
	posture = new_posture
	_stand.visible = posture == Posture.STAND
	_sprint.visible = posture == Posture.SPRINT


## Ušní vrtulník: uši se zvednou do vodorovné polohy a točí se nad hlavou jako vrtule.
func set_gliding(on: bool) -> void:
	gliding = on
	if on:
		set_posture(Posture.STAND)
	else:
		_ears.rotation = Vector3.ZERO


func set_perched(on: bool) -> void:
	perched = on


## Okamžitě natočí Bruna do daného směru (míření tenisákem).
func face_direction(dir: Vector3) -> void:
	if dir.length() > 0.01:
		_yaw = atan2(-dir.x, -dir.z)
		rotation.y = _yaw


## Švih holí jako pálkou.
func play_swing(duration: float) -> void:
	var cane: Node3D = $Stand/Cane
	var tw: Tween = create_tween()
	tw.tween_property(cane, "rotation_degrees", Vector3(-70, 0, -60), duration * 0.35).set_trans(Tween.TRANS_BACK)
	tw.tween_property(cane, "rotation_degrees", Vector3(0, 0, -8), duration * 0.65).set_trans(Tween.TRANS_SINE)


## Útok holí: 1. švih zprava doleva, 2. zleva doprava, 3. otočka o 360° (finále komba).
func play_attack(combo: int, duration: float) -> void:
	var cane: Node3D = $Stand/Cane
	var tw: Tween = create_tween()
	match combo:
		1:
			cane.rotation_degrees = Vector3(-80, 70, -20)
			tw.tween_property(cane, "rotation_degrees", Vector3(-85, -80, -20), duration * 0.45).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		2:
			cane.rotation_degrees = Vector3(-85, -80, -20)
			tw.tween_property(cane, "rotation_degrees", Vector3(-80, 70, -20), duration * 0.45).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		_:
			cane.rotation_degrees = Vector3(-90, 0, -20)
			var spin: Node3D = $Stand
			spin.rotation.y = 0.0
			tw.parallel().tween_property(spin, "rotation:y", -TAU, duration * 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tw.tween_callback(func() -> void: spin.rotation.y = 0.0)
	tw.tween_property(cane, "rotation_degrees", Vector3(0, 0, -8), duration * 0.4).set_trans(Tween.TRANS_SINE)


## Útok ve vzduchu: rychlá otočka celého Bruna s napřaženou holí.
func play_air_attack(duration: float) -> void:
	var cane: Node3D = $Stand/Cane
	var spin: Node3D = $Stand
	set_posture(Posture.STAND)
	cane.rotation_degrees = Vector3(-90, 0, -20)
	spin.rotation.y = 0.0
	var tw: Tween = create_tween()
	tw.tween_property(spin, "rotation:y", -TAU, duration * 0.8).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func() -> void: spin.rotation.y = 0.0)
	tw.tween_property(cane, "rotation_degrees", Vector3(0, 0, -8), duration * 0.2)


## Odkud tenisák vyletí (hrot hole ve výšce hrudníku).
func get_ball_spawn() -> Vector3:
	return global_position + get_forward() * 0.7 + Vector3.UP * 0.9


## Směr, kterým se Bruno dívá (vodorovně).
func get_forward() -> Vector3:
	return Vector3(-sin(_yaw), 0.0, -cos(_yaw))


## Krátké „zmáčknutí“ při dopadu (squash & stretch).
func land_squash(amount: float = 0.75) -> void:
	_squash = amount


func update_visual(delta: float, player: Player) -> void:
	var horizontal := Vector3(player.velocity.x, 0.0, player.velocity.z)
	if horizontal.length() > 0.3 and not facing_locked:
		var target_yaw: float = atan2(-horizontal.x, -horizontal.z)
		_yaw = lerp_angle(_yaw, target_yaw, 1.0 - exp(-player.profile.turn_speed * delta))
	rotation.y = _yaw

	var hinge_l: Node3D = _ears.get_node("EarHingeL") as Node3D
	var hinge_r: Node3D = _ears.get_node("EarHingeR") as Node3D
	if gliding:
		_ear_spin += delta * 22.0
		_ears.rotation.y = _ear_spin
		hinge_l.rotation_degrees.z = lerpf(hinge_l.rotation_degrees.z, -95.0, 1.0 - exp(-25.0 * delta))
		hinge_r.rotation_degrees.z = lerpf(hinge_r.rotation_degrees.z, 95.0, 1.0 - exp(-25.0 * delta))
	else:
		hinge_l.rotation_degrees.z = lerpf(hinge_l.rotation_degrees.z, -20.0, 1.0 - exp(-15.0 * delta))
		hinge_r.rotation_degrees.z = lerpf(hinge_r.rotation_degrees.z, 20.0, 1.0 - exp(-15.0 * delta))

	if perched:
		# Jemné balancování na špičce.
		rotation.z = sin(Time.get_ticks_msec() * 0.004) * 0.06
	else:
		rotation.z = 0.0

	_animate_life(delta, player, horizontal.length())

	_squash = lerpf(_squash, 1.0, 1.0 - exp(-10.0 * delta))
	var crouch: float = 1.0
	if player.is_sneaking:
		crouch = 0.78 if posture == Posture.STAND else 0.72
	var sy: float = _squash * crouch
	scale = Vector3(1.0 / sqrt(_squash), sy, 1.0 / sqrt(_squash))


func _animate_life(delta: float, player: Player, speed: float) -> void:
	var grounded: bool = player.is_on_floor()
	_phase += delta * (2.0 + speed * 2.6) if grounded else delta * 2.0
	var moving: float = clampf(speed / 4.0, 0.0, 1.0) if grounded else 0.0
	# Krok / cval: pohupování těla.
	var bob: float = absf(sin(_phase)) * 0.06 * moving
	var breathe: float = sin(Time.get_ticks_msec() * 0.003) * 0.008 * (1.0 - moving)
	_stand.position = _stand_base + Vector3(0, bob + breathe, 0)
	_stand.rotation.z = sin(_phase) * 0.05 * moving if not gliding else 0.0
	_sprint.position = _sprint_base + Vector3(0, absf(sin(_phase)) * 0.08 * moving, 0)
	_sprint.rotation.x = sin(_phase * 2.0) * 0.06 * moving
	for i: int in _legs.size():
		var off: float = 0.0 if i < 2 else PI
		var side: float = 0.0 if i % 2 == 0 else 0.35
		_legs[i].rotation = _leg_base[i] + Vector3(sin(_phase + off + side) * 0.7 * moving, 0, 0)
	# Ocas: klidné vrtění, rychlé při radosti (sebraná kapka, mince).
	_excited = maxf(_excited - delta, 0.0)
	var wag_speed: float = 6.0 + 14.0 * minf(_excited, 1.0) + 4.0 * moving
	_wag += delta * wag_speed
	var amp: float = 0.35 + 0.35 * minf(_excited, 1.0)
	for t: Node3D in _tails:
		t.rotation.y = sin(_wag) * amp
		t.rotation.x = -0.25 * moving
	# Uši plandají s krokem a ve vzduchu (kromě vrtulníku).
	if not gliding:
		var flop: float = sin(_phase * 2.0) * 10.0 * moving
		var air: float = clampf(-player.velocity.y * 2.5, -30.0, 30.0) if not grounded else 0.0
		var hinge_l: Node3D = _ears.get_node("EarHingeL") as Node3D
		var hinge_r: Node3D = _ears.get_node("EarHingeR") as Node3D
		hinge_l.rotation_degrees.x = lerpf(hinge_l.rotation_degrees.x, flop - air, 1.0 - exp(-12.0 * delta))
		hinge_r.rotation_degrees.x = lerpf(hinge_r.rotation_degrees.x, -flop - air, 1.0 - exp(-12.0 * delta))
