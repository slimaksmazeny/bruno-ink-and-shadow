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

var _spawn_transform: Transform3D

@onready var state_machine: PlayerStateMachine = $StateMachine
@onready var visual: PlayerVisual = $Visual


func _ready() -> void:
	profile = profile_3d
	_spawn_transform = global_transform
	state_machine.setup(self)


func _physics_process(delta: float) -> void:
	_update_timers(delta)
	state_machine.physics_update(delta)

	if mode == Mode.MODE_2D:
		velocity -= plane_normal * velocity.dot(plane_normal)
	move_and_slide()
	if mode == Mode.MODE_2D:
		var offset: float = (global_position - plane_origin).dot(plane_normal)
		global_position -= plane_normal * offset

	if global_position.y < kill_y:
		respawn()

	visual.update_visual(delta, self)
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


func respawn() -> void:
	global_transform = _spawn_transform
	velocity = Vector3.ZERO
	jumps_used = 0
	reset_physics_interpolation()
	if camera != null:
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
