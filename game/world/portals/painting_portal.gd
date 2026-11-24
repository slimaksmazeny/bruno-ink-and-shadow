## Živý rám obrazu: Bruno do něj vběhne → kamera „vplave“ do malby, inkoust zakryje obraz,
## Bruno se ocitne ve 2D světě obrazu (pohyb uzamčený do roviny) a inkoust se rozestoupí.
class_name PaintingPortal
extends Area3D

## Kde Bruno ve 2D začíná (chodidla). Rovina 2D = tento bod + plane_normal.
@export var lane_start: Marker3D
## Normála 2D roviny (kamera stojí na její straně a dívá se proti ní).
@export var plane_normal: Vector3 = Vector3.BACK
## Brána, která musí být otevřená (volitelné).
@export var gate: Gate

const DIVE_TIME: float = 0.85
const DIVE_FOV: float = 28.0

var busy: bool = false

@onready var camera_marker: Marker3D = $CameraMarker
@onready var return_point: Marker3D = $ReturnPoint


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # player
	monitoring = true
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	var p: Player = body as Player
	if p == null or busy or p.mode != Player.Mode.MODE_3D:
		return
	if gate != null and not gate.is_open:
		return
	enter_painting(p)


func enter_painting(p: Player) -> void:
	busy = true
	AudioManager.play(&"portal")
	p.state_machine.transition_to(&"Locked")
	var cam: HybridCamera = p.camera
	# 1) Kamera vplave do obrazu (dolly + zúžení záběru) – „zploštění do malby“.
	cam.set_blend_target(camera_marker, DIVE_FOV)
	cam.blend = 0.0
	await cam.blend_to(1.0, DIVE_TIME)
	# 2) Inkoust zakryje obrazovku.
	await InkWipe.cover(0.3)
	# 3) Bruno se objeví ve 2D světě obrazu.
	p.global_position = lane_start.global_position
	p.velocity = Vector3.ZERO
	p.reset_physics_interpolation()
	p.enter_2d(lane_start.global_position, plane_normal)
	p.set_checkpoint(lane_start.global_transform)
	p.visual.face_direction(Vector3.UP.cross(plane_normal))
	cam.side_rig.target = p
	cam.side_rig.snap()
	cam.set_blend_target(cam.side_rig, cam.fov_2d)
	cam.blend = 1.0
	p.state_machine.transition_to(&"Idle", {"force": true})
	# 4) Inkoust se rozestoupí – hraje se 2D.
	await InkWipe.reveal(0.45)
	busy = false


## Návrat zpět do 3D (volá ExitPortal na konci 2D úrovně).
func return_to_3d(p: Player) -> void:
	busy = true
	AudioManager.play(&"portal")
	p.state_machine.transition_to(&"Locked")
	var cam: HybridCamera = p.camera
	await InkWipe.cover(0.3)
	var forward: Vector3 = -return_point.global_transform.basis.z
	p.global_position = return_point.global_position
	p.velocity = Vector3.ZERO
	p.reset_physics_interpolation()
	p.enter_3d()
	p.set_checkpoint(return_point.global_transform)
	p.visual.face_direction(forward)
	cam.rig_3d.snap_behind(forward)
	cam.rig_3d.snap_to_target()
	# Kamera „vyplave“ z obrazu zpět za Bruna.
	cam.set_blend_target(camera_marker, DIVE_FOV)
	cam.blend = 1.0
	InkWipe.reveal(0.4)
	await cam.blend_to(0.0, DIVE_TIME)
	p.state_machine.transition_to(&"Idle", {"force": true})
	busy = false
