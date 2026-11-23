## 3D kamera za zády Bruna (Sly styl). Nedrží skutečnou kameru – jen počítá, kde má být (CameraPoint).
## Skutečnou Camera3D posouvá HybridCamera, která mezi tímto rigem a 2D rigem plynule míchá (Krok F).
class_name ThirdPersonRig
extends Node3D

@export var height_offset: float = 1.2
@export var distance: float = 5.5
@export var follow_sharpness: float = 14.0
@export_range(-89.0, 0.0) var min_pitch_deg: float = -65.0
@export_range(0.0, 89.0) var max_pitch_deg: float = 30.0
@export var default_pitch_deg: float = -18.0

var target: Node3D
var input_enabled: bool = true
var yaw: float = 0.0
var pitch: float = 0.0

@onready var yaw_pivot: Node3D = $YawPivot
@onready var pitch_pivot: Node3D = $YawPivot/PitchPivot
@onready var spring_arm: SpringArm3D = $YawPivot/PitchPivot/SpringArm3D
@onready var camera_point: Marker3D = $YawPivot/PitchPivot/SpringArm3D/CameraPoint


func _ready() -> void:
	pitch = deg_to_rad(default_pitch_deg)
	spring_arm.spring_length = distance
	if target != null:
		yaw = target.global_rotation.y
		snap_to_target()


func _process(delta: float) -> void:
	if target == null:
		return
	if input_enabled:
		var look: Vector2 = InputManager.consume_look(delta)
		yaw -= look.x
		pitch = clampf(pitch - look.y, deg_to_rad(min_pitch_deg), deg_to_rad(max_pitch_deg))

	var goal: Vector3 = _target_point()
	global_position = global_position.lerp(goal, 1.0 - exp(-follow_sharpness * delta))
	yaw_pivot.rotation.y = yaw
	pitch_pivot.rotation.x = pitch


## Okamžitě skočí na cíl (po respawnu, po načtení levelu).
func snap_to_target() -> void:
	if target == null:
		return
	global_position = _target_point()


## Natočí kameru za záda daného směru pohledu (použije se při návratu z 2D, Krok F).
func snap_behind(forward: Vector3) -> void:
	if forward.length() > 0.01:
		yaw = atan2(-forward.x, -forward.z)


func get_yaw() -> float:
	return yaw


func _target_point() -> Vector3:
	var t: Transform3D = target.get_global_transform_interpolated()
	return t.origin + Vector3.UP * height_offset
