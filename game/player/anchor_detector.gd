## Hledá nejbližší vhodnou kotvu kolem Bruna a rozsvítí jí modré jiskry.
## Stavy se jen ptají best_anchor() – nevědí nic o fyzice detekce.
class_name AnchorDetector
extends Area3D

## Jak vysoko nad / pod Brunem může kotva být.
@export var max_rise: float = 3.6
@export var max_drop: float = 2.5
@export var max_horizontal: float = 4.2
## Kotva musí být v tomto úhlu od směru kamery (kam se díváš), jinak se nenabídne.
@export var max_view_angle_deg: float = 50.0
## Kotva blíž než tohle se nabídne i mimo úhel pohledu (stojíš přímo u ní).
@export var always_ok_distance: float = 1.0

var player: Player
var _candidates: Array[Anchor] = []
var _best: Anchor = null


func _ready() -> void:
	collision_layer = 0
	collision_mask = 8 # anchors
	monitoring = true
	monitorable = false
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)


func refresh(allowed_types: Array) -> void:
	var best: Anchor = _pick(allowed_types)
	if best != _best:
		if is_instance_valid(_best):
			_best.set_highlighted(false)
		_best = best
		if _best != null:
			_best.set_highlighted(true)


func best_anchor() -> Anchor:
	return _best


func _pick(allowed_types: Array) -> Anchor:
	if player == null:
		return null
	var origin: Vector3 = player.global_position
	# Směr pohledu kamery (vodorovně) – Bruno se přichytí tam, kam se hráč dívá.
	var forward: Vector3 = player.visual.get_forward()
	if player.camera != null:
		forward = Basis(Vector3.UP, player.camera.get_control_yaw()) * Vector3.FORWARD
	var best: Anchor = null
	var best_score: float = INF
	for a: Anchor in _candidates:
		if not is_instance_valid(a) or not allowed_types.has(a.type):
			continue
		if a.only_in_3d and player.mode != Player.Mode.MODE_3D:
			continue
		var target: Vector3 = a.get_snap_position(origin)
		var to: Vector3 = target - origin
		var rise: float = to.y
		var flat := Vector3(to.x, 0.0, to.z)
		if rise > max_rise or rise < -max_drop or flat.length() > max_horizontal:
			continue
		# Kotva, na které už Bruno stojí, se nenabízí.
		if flat.length() < 0.2 and absf(rise) < 0.2:
			continue
		var angle_deg: float = 0.0
		if flat.length() > 0.1:
			angle_deg = rad_to_deg(flat.normalized().angle_to(forward))
		# Ve 2D rozhoduje jen vzdálenost (kamera je z boku).
		if player.mode == Player.Mode.MODE_3D and angle_deg > max_view_angle_deg and flat.length() > always_ok_distance:
			continue
		var score: float = to.length() + angle_deg * 0.06
		if score < best_score:
			best_score = score
			best = a
	return best


func _on_area_entered(area: Area3D) -> void:
	if area is Anchor and not _candidates.has(area):
		_candidates.append(area as Anchor)


func _on_area_exited(area: Area3D) -> void:
	if area is Anchor:
		_candidates.erase(area as Anchor)
		if area == _best:
			(area as Anchor).set_highlighted(false)
			_best = null
