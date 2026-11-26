## Velký hlídač – první boss (kostra souboje na konci kapitoly).
##
## Vzorec (klasický „telegraf → trest → okno“):
##   HONÍ   – jde za Brunem, rána holí se od něj odrazí (blok).
##   NÁPŘAH – zvedne se (čitelný telegraf), pak DUPNE: rázová vlna kolem něj
##            zraní Bruna, když stojí na zemi v dosahu → přeskoč ji.
##            Tenisák během nápřahu ho vyvede z rovnováhy (rovnou únava).
##   ÚNAVA  – chvíli funí („z z“): jen teď ho rány holí zraňují.
## Každé 2 zásahy = další fáze: rychlejší chůze, kratší nápřah, větší vlna.
@tool
class_name BossWarden
extends Guard

enum Phase { IDLE, CHASE, WINDUP, TIRED, DEFEATED }

## Bruno blíž než tohle → souboj začne.
@export var arena_radius: float = 14.0
@export var slam_radius: float = 4.5
@export var display_name: String = "BOSS_WARDEN"

var phase: Phase = Phase.IDLE
## 1..3 – roste se ztrátou zdraví.
var stage: int = 1
var _p_timer: float = 0.0
var _touch_cd: float = 0.0
var _slam_cd: float = 1.5
var _wave: MeshInstance3D


func _ready() -> void:
	if max_health == 3:
		max_health = 6
	loot = 80
	super._ready()
	_body.scale = Vector3.ONE * _body_scale()
	# Vrstva 5 (16) = překážka kamery: kamera se o bosse zastaví a nevleze dovnitř.
	collision_layer = 4 | 16
	for c: Node in get_children():
		if c is CollisionShape3D:
			var cap := CapsuleShape3D.new()
			cap.radius = 0.65
			cap.height = 2.9
			(c as CollisionShape3D).shape = cap
			(c as CollisionShape3D).position.y = 1.45
	_wave = MeshInstance3D.new()
	_wave.set_meta(&"generated", true)
	var tm := TorusMesh.new()
	tm.inner_radius = 0.85
	tm.outer_radius = 1.0
	_wave.mesh = tm
	var wm := StandardMaterial3D.new()
	wm.albedo_color = Color(1, 0.75, 0.3, 0.8)
	wm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_wave.material_override = wm
	_wave.visible = false
	add_child(_wave)
	if Engine.is_editor_hint():
		return
	remove_from_group(&"guard")
	add_to_group(&"boss")
	_cone.visible = false
	_label.text = ""


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(&"player") as Player
	if _player == null or phase == Phase.DEFEATED:
		_gravity_move(delta)
		return
	_touch_cd = maxf(_touch_cd - delta, 0.0)
	_slam_cd = maxf(_slam_cd - delta, 0.0)
	var to: Vector3 = _player.global_position - global_position
	var dist: float = Vector2(to.x, to.z).length()
	match phase:
		Phase.IDLE:
			_stop(delta)
			if dist < arena_radius:
				_start_fight()
		Phase.CHASE:
			_last_seen = _player.global_position
			if dist > 1.1:
				_move_towards(_player.global_position, _speed(), delta)
			else:
				_stop(delta)
			if dist < 1.6 and _touch_cd <= 0.0:
				# Dotyk jen odstrčí (životy bere až vlna) – férovější souboj.
				_touch_cd = 0.6
				var away: Vector3 = Vector3(to.x, 0.0, to.z).normalized()
				_player.velocity += away * 7.0 + Vector3.UP * 3.0
			if dist < slam_radius - 0.5 and _slam_cd <= 0.0:
				_begin_windup()
		Phase.WINDUP:
			_stop(delta)
			_face(_player.global_position, delta, 4.0)
			_p_timer -= delta
			var t: float = 1.0 - _p_timer / _windup_time()
			_body.position.y = sin(clampf(t, 0.0, 1.0) * PI * 0.5) * 0.9
			if _p_timer <= 0.0:
				_slam()
		Phase.TIRED:
			_stop(delta)
			_p_timer -= delta
			_body.rotation.z = sin(_p_timer * 6.0) * 0.06
			if _p_timer <= 0.0:
				_body.rotation.z = 0.0
				_to_chase()
	_gravity_move(delta)


func _gravity_move(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 24.0 * delta
	else:
		velocity.y = -0.5
	move_and_slide()


func _speed() -> float:
	return chase_speed * (0.55 + 0.15 * float(stage))


func _windup_time() -> float:
	return [1.1, 0.85, 0.65][stage - 1]


func _slam_r() -> float:
	return slam_radius * (1.0 + 0.15 * float(stage - 1))


func _start_fight() -> void:
	state = State.ALERT
	Events.guard_alert_changed.emit(true)
	Events.boss_started.emit(self)
	AudioManager.play_at(&"alert", global_position, 3.0, 0.6)
	_to_chase()


func _to_chase() -> void:
	phase = Phase.CHASE
	_label.text = "!"
	_label.modulate = Color(1, 0.3, 0.2)
	_slam_cd = 1.2


func _begin_windup() -> void:
	phase = Phase.WINDUP
	_p_timer = _windup_time()
	_label.text = "!!"
	AudioManager.play_at(&"suspicious", global_position, 2.0, 0.6)


func _slam() -> void:
	_body.position.y = 0.0
	AudioManager.play_at(&"land", global_position, 6.0, 0.5)
	AudioManager.play_at(&"hit", global_position, 0.0, 0.6)
	var r: float = _slam_r()
	_wave.visible = true
	_wave.position.y = 0.1
	_wave.scale = Vector3.ONE * 0.3
	var tw: Tween = create_tween()
	tw.tween_property(_wave, "scale", Vector3(r, 1.0, r), 0.3)
	tw.tween_callback(func() -> void: _wave.visible = false)
	var to: Vector3 = _player.global_position - global_position
	var flat: float = Vector2(to.x, to.z).length()
	var low: bool = _player.is_on_floor() or to.y < 0.5
	if flat <= r and low:
		_player.take_damage(1, global_position)
		_player.velocity += Vector3(to.x, 0.0, to.z).normalized() * 6.0 + Vector3.UP * 4.0
	_tire(2.4 - 0.3 * float(stage - 1))


func _tire(t: float) -> void:
	phase = Phase.TIRED
	_p_timer = t
	_label.text = "z z"
	_label.modulate = Color(0.7, 0.85, 1.0)


func on_cane_hit(info: Dictionary) -> void:
	if phase == Phase.DEFEATED:
		return
	if phase == Phase.IDLE:
		_start_fight()
	if bool(info.get("ball", false)):
		if phase == Phase.WINDUP:
			_body.position.y = 0.0
			AudioManager.play_at(&"hit", global_position, 0.0, 1.3)
			_tire(1.8)
		return
	if phase != Phase.TIRED:
		# Blok: rána se odrazí, Bruno odletí kousek zpět.
		AudioManager.play_at(&"hit", global_position, -4.0, 2.2)
		_label.text = "✋"
		if _player != null:
			var away: Vector3 = _player.global_position - global_position
			away.y = 0.0
			_player.velocity += away.normalized() * 5.0 + Vector3.UP * 2.0
		return
	health -= int(info.get("damage", 1))
	_flash()
	AudioManager.play_at(&"hit", global_position, 2.0, 0.8)
	Events.boss_health_changed.emit(self, health, max_health)
	if health <= 0:
		phase = Phase.DEFEATED
		_body.position.y = 0.0
		_body.rotation.z = 0.0
		Events.boss_defeated.emit(self)
		_knock_out()
		return
	var new_stage: int = 1 + int(float(max_health - health) / 2.0)
	if new_stage > stage:
		stage = mini(new_stage, 3)
		AudioManager.play_at(&"alert", global_position, 3.0, 0.5 + 0.1 * float(stage))
		_to_chase()


## Bossovi se nedá krást ani ho nejde vyřadit jednou ranou zezadu.
func can_be_pickpocketed_by(_p: Player) -> bool:
	return false


func investigate(_pos: Vector3) -> void:
	pass


## Po Brunově smrti začne souboj znovu od začátku (boss v plném zdraví, nečeká).
func reset_to_start() -> void:
	if phase == Phase.DEFEATED:
		return
	super.reset_to_start()
	collision_layer = 4 | 16
	remove_from_group(&"guard")
	_cone.visible = false
	phase = Phase.IDLE
	stage = 1
	_wave.visible = false
	Events.boss_health_changed.emit(self, health, max_health)


func _body_scale() -> float:
	return 1.6
