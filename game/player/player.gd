## Bruno. Jediný CharacterBody3D pro 3D i 2D (2D = pohyb uzamčený do roviny, od Kroku F).
## Jediné místo ve hře, které volá move_and_slide(). Stavy jen nastavují velocity.
class_name Player
extends CharacterBody3D

enum Mode { MODE_3D, MODE_2D }

@export var profile_3d: MovementProfile
@export var profile_2d: MovementProfile
## Kamera v levelu (HybridCamera). Z ní se bere směr „dopředu“ pro ovládání ve 3D.
@export var camera: HybridCamera
## Pod touto výškou se Bruno vrátí na start (pád do propasti).
@export var kill_y: float = -25.0
## Počet životů (Sly-style: málo, ale rychlý návrat na checkpoint).
@export var max_health: int = 3
## Jak dlouho po zásahu nejde Bruno znovu zranit (bliká).
@export var invulnerable_time: float = 1.2

var mode: Mode = Mode.MODE_3D
var profile: MovementProfile
var plane_origin: Vector3 = Vector3.ZERO
var plane_normal: Vector3 = Vector3.BACK

var jumps_used: int = 0
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var is_sneaking: bool = false
## Plížení přepnuté tlačítkem L3 (na ovladači). Zruší ho sprint nebo další stisk L3.
var sneak_toggled: bool = false
## Útok ve vzduchu jde jednou za skok (obnoví se po dopadu).
var air_attack_used: bool = false

var health: int = 3
var _invulnerable: float = 0.0
var _was_on_floor: bool = true
var _dying: bool = false
## Nastavuje WindColumn každý fyzikální snímek, kdy je Bruno uvnitř; Player ho po snímku vynuluje.
var wind_lift: float = 0.0

var _spawn_transform: Transform3D

@onready var state_machine: PlayerStateMachine = $StateMachine
@onready var visual: PlayerVisual = $Visual
@onready var anchor_detector: AnchorDetector = $AnchorDetector
@onready var cane_hitbox: CaneHitbox = $CaneHitbox

var _hit_stop_running: bool = false


func _ready() -> void:
	profile = profile_3d
	add_to_group(&"player")
	health = max_health
	_spawn_transform = global_transform
	anchor_detector.player = self
	cane_hitbox.hit_landed.connect(_on_cane_hit_landed)
	state_machine.setup(self)


func _physics_process(delta: float) -> void:
	_update_timers(delta)
	anchor_detector.refresh(PlayerState.ANCHOR_STATES.keys())
	state_machine.physics_update(delta)
	var fall_speed: float = -velocity.y
	if wind_lift > 0.0 and not is_on_floor() and velocity.y < -2.0:
		# Bez plachtění vítr jen zbrzdí pád.
		velocity.y = move_toward(velocity.y, -2.0, 20.0 * delta)
	wind_lift = 0.0

	if mode == Mode.MODE_2D:
		velocity -= plane_normal * velocity.dot(plane_normal)
	move_and_slide()
	if mode == Mode.MODE_2D:
		var offset: float = (global_position - plane_origin).dot(plane_normal)
		global_position -= plane_normal * offset

	var on_floor: bool = is_on_floor()
	if on_floor and not _was_on_floor and fall_speed > 4.0:
		AudioManager.play(&"land", linear_to_db(clampf(fall_speed / 14.0, 0.3, 1.0)))
	_was_on_floor = on_floor

	if _invulnerable > 0.0:
		_invulnerable -= delta
		visual.visible = _invulnerable <= 0.0 or fmod(_invulnerable, 0.16) > 0.07

	if global_position.y < kill_y and not _dying:
		# Pád do propasti stojí jeden život (Rayman), pak návrat na checkpoint.
		health -= 1
		Events.player_health_changed.emit(health, max_health)
		if health <= 0:
			die()
		else:
			AudioManager.play(&"hurt")
			respawn(false)

	visual.update_visual(delta, self)
	# Hitbox není pod Visual (ten se při dopadu škáluje – Jolt nepodporuje nerovnoměrné škálování tvarů).
	cane_hitbox.rotation.y = visual.rotation.y
	_debug_watch()


func _update_timers(delta: float) -> void:
	if is_on_floor():
		coyote_timer = profile.coyote_time
	else:
		coyote_timer = maxf(coyote_timer - delta, 0.0)

	if Input.is_action_just_pressed(&"sneak_toggle"):
		sneak_toggled = not sneak_toggled
	if Input.is_action_pressed(&"sprint"):
		sneak_toggled = false

	if Input.is_action_just_pressed(&"jump"):
		jump_buffer_timer = profile.jump_buffer_time
	else:
		jump_buffer_timer = maxf(jump_buffer_timer - delta, 0.0)


## Směr pohybu ze vstupu. Stavy neví nic o zařízení ani o 3D/2D režimu.
func get_move_dir() -> Vector3:
	var raw: Vector2 = InputManager.get_move_vector()
	if mode == Mode.MODE_2D:
		var plane_right: Vector3 = Vector3.UP.cross(plane_normal).normalized()
		return plane_right * raw.x
	var yaw: float = camera.get_control_yaw() if camera != null else 0.0
	return Basis(Vector3.UP, yaw) * Vector3(raw.x, 0.0, raw.y)


## Síla vychýlení páčky / kláves (0–1) – podle ní chůze vs. plížení.
func get_move_strength() -> float:
	return minf(InputManager.get_move_vector().length(), 1.0)


## Chce hráč plížit? (Ctrl držením na klávesnici, nebo L3 přepínačem na ovladači)
func wants_sneak() -> bool:
	return sneak_toggled or Input.is_action_pressed(&"sneak")


func consume_jump_buffer() -> bool:
	if jump_buffer_timer > 0.0:
		jump_buffer_timer = 0.0
		return true
	return false


## Zásah holí: krátké „zastavení času“ a zatřesení kamery – zásah je cítit (Sly feel).
func _on_cane_hit_landed(_target: Node, info: Dictionary) -> void:
	var strong: bool = int(info.get("combo", 1)) >= 3
	AudioManager.play(&"hit", 0.0, 0.85 if strong else 1.0)
	hit_stop(0.09 if strong else 0.05)
	if camera != null:
		camera.shake(0.18 if strong else 0.09, 0.2)


func hit_stop(duration: float) -> void:
	if _hit_stop_running:
		return
	_hit_stop_running = true
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
	_hit_stop_running = false


## Odkud se Bruno obnoví po pádu (start úrovně, vstup do obrazu…).
func set_checkpoint(t: Transform3D) -> void:
	_spawn_transform = Transform3D(Basis(), t.origin)


## Odraz (skákací houba): vymrští nahoru, dvojskok i útok ve vzduchu zůstávají k dispozici.
func bounce(up_velocity: float) -> void:
	velocity.y = up_velocity
	jumps_used = 1
	AudioManager.play(&"bounce")
	air_attack_used = false
	visual.land_squash(0.7)
	state_machine.transition_to(&"Air", {"bounce": true, "force": true})


## Zásah (strážný, nebezpečná oblast). from = odkud rána přišla (pro odhození).
## Vrací true, pokud zásah prošel (Bruno nebyl chráněný).
func take_damage(amount: int, from: Vector3) -> bool:
	if _invulnerable > 0.0 or _dying or health <= 0:
		return false
	health = maxi(health - amount, 0)
	_invulnerable = invulnerable_time
	Events.player_health_changed.emit(health, max_health)
	if health <= 0:
		die()
		return true
	AudioManager.play(&"hurt")
	if camera != null:
		camera.shake(0.15, 0.25)
	# Odhození od zdroje zásahu.
	var away: Vector3 = global_position - from
	away.y = 0.0
	away = away.normalized() if away.length() > 0.01 else -visual.get_forward()
	if mode == Mode.MODE_2D:
		away -= plane_normal * away.dot(plane_normal)
	velocity = away * 6.0 + Vector3.UP * 5.5
	state_machine.transition_to(&"Air", {"force": true})
	return true


## Těleso, na kterém Bruno stojí (nebo null).
func get_floor_body() -> Object:
	if not is_on_floor():
		return null
	for i: int in get_slide_collision_count():
		var c: KinematicCollision3D = get_slide_collision(i)
		if c.get_normal().y > 0.6:
			return c.get_collider()
	return null


func heal(amount: int) -> void:
	health = mini(health + amount, max_health)
	Events.player_health_changed.emit(health, max_health)


func is_invulnerable() -> bool:
	return _invulnerable > 0.0


## Konec životů: inkoustová clona, návrat na checkpoint s plným zdravím.
func die() -> void:
	if _dying:
		return
	_dying = true
	AudioManager.play(&"death")
	Events.player_died.emit()
	state_machine.transition_to(&"Locked", {"force": true})
	velocity = Vector3.ZERO
	if is_inside_tree():
		await InkWipe.cover(0.35)
	respawn(true)
	if is_inside_tree():
		await InkWipe.reveal(0.4)
	_dying = false


func respawn(full_heal: bool = true) -> void:
	if full_heal:
		health = max_health
		Events.player_health_changed.emit(health, max_health)
	_invulnerable = 0.0
	visual.visible = true
	global_transform = _spawn_transform
	velocity = Vector3.ZERO
	jumps_used = 0
	reset_physics_interpolation()
	if camera != null:
		if mode == Mode.MODE_2D:
			camera.side_rig.snap()
		else:
			camera.snap_to_target()
	state_machine.transition_to(&"Idle", {"force": true})


func enter_2d(origin: Vector3, normal: Vector3) -> void:
	mode = Mode.MODE_2D
	plane_origin = origin
	plane_normal = normal.normalized()
	profile = profile_2d
	Events.player_mode_changed.emit(mode)


func enter_3d() -> void:
	mode = Mode.MODE_3D
	profile = profile_3d
	Events.player_mode_changed.emit(mode)


func _debug_watch() -> void:
	if not OS.is_debug_build() or not is_instance_valid(DebugOverlay):
		return
	var h_speed: float = Vector2(velocity.x, velocity.z).length()
	DebugOverlay.watch("Player state", state_machine.current_name())
	DebugOverlay.watch("Mode", "3D" if mode == Mode.MODE_3D else "2D")
	DebugOverlay.watch("Speed", "%.2f m/s  (vy %.2f)" % [h_speed, velocity.y])
	DebugOverlay.watch("On floor", "%s   jumps %d   coyote %.2f" % [is_on_floor(), jumps_used, coyote_timer])
	var a: Anchor = anchor_detector.best_anchor()
	DebugOverlay.watch("Anchor", String(a.name) if a != null else "-")
