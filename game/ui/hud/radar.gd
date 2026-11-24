## Radar v rohu HUD (jen ve 3D): Bruno uprostřed, nahoru = kam se dívá kamera,
## strážní jako červené tečky s kuželem pohledu, cíl mise jako zlatá hvězda (u okraje,
## když je daleko). Kresleno z kódu.
class_name Radar
extends Control

const RANGE_M: float = 32.0

var _player: Player


func _ready() -> void:
	custom_minimum_size = Vector2(190, 190)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(&"player") as Player
	visible = _player != null and _player.mode == Player.Mode.MODE_3D
	if visible:
		queue_redraw()


func _draw() -> void:
	var c: Vector2 = size * 0.5
	var r: float = minf(size.x, size.y) * 0.5 - 4.0
	draw_circle(c, r + 3.0, Color(0.95, 0.71, 0.2, 0.8))
	draw_circle(c, r, Color(0.04, 0.03, 0.1, 0.78))
	draw_arc(c, r * 0.5, 0, TAU, 32, Color(1, 1, 1, 0.08), 1.0)
	var yaw: float = _player.camera.get_control_yaw() if _player.camera != null else 0.0
	var origin: Vector3 = _player.global_position
	# Strážní.
	for n: Node in get_tree().get_nodes_in_group(&"guard"):
		var g: Guard = n as Guard
		if g == null or g.state == Guard.State.KNOCKED_OUT:
			continue
		var gp: Vector2 = _to_radar(g.global_position - origin, yaw, r)
		if gp.length() > r - 4.0:
			continue
		var fwd3: Vector3 = -g.global_transform.basis.z
		var fwd: Vector2 = _rotate(Vector2(fwd3.x, fwd3.z), yaw)
		var cone_len: float = g.view_range / RANGE_M * r
		var half: float = deg_to_rad(g.view_angle_deg)
		var a: float = fwd.angle()
		var col: Color = Color(1, 0.85, 0.3, 0.25)
		if g.state == Guard.State.ALERT:
			col = Color(1, 0.2, 0.15, 0.35)
		elif g.state == Guard.State.SUSPICIOUS or g.state == Guard.State.SEARCH:
			col = Color(1, 0.55, 0.1, 0.3)
		var pts := PackedVector2Array([c + gp])
		for i: int in 7:
			var t: float = a - half + 2.0 * half * float(i) / 6.0
			pts.append(c + gp + Vector2(cos(t), sin(t)) * cone_len)
		draw_colored_polygon(pts, col)
		draw_circle(c + gp, 4.5, Color(0.9, 0.2, 0.2))
	# Cíl mise.
	var m: Mission = get_tree().get_first_node_in_group(&"mission") as Mission
	if m != null:
		var target: Variant = m.objective_position()
		if target != null:
			var tp: Vector2 = _to_radar((target as Vector3) - origin, yaw, r)
			if tp.length() > r - 8.0:
				tp = tp.normalized() * (r - 8.0)
			_star(c + tp, 7.0, UiStyle.GOLD)
	# Bruno (šipka nahoru = směr kamery).
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, -8), c + Vector2(6, 6), c + Vector2(0, 3), c + Vector2(-6, 6)]), Color(0.55, 0.85, 1.0))


func _to_radar(d: Vector3, yaw: float, r: float) -> Vector2:
	return _rotate(Vector2(d.x, d.z), yaw) / RANGE_M * r


## Otočí rovinu tak, aby směr kamery mířil nahoru.
func _rotate(v: Vector2, yaw: float) -> Vector2:
	return v.rotated(yaw)


func _star(p: Vector2, s: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i: int in 10:
		var a: float = -PI * 0.5 + float(i) * PI / 5.0
		var rr: float = s if i % 2 == 0 else s * 0.45
		pts.append(p + Vector2(cos(a), sin(a)) * rr)
	draw_colored_polygon(pts, col)
