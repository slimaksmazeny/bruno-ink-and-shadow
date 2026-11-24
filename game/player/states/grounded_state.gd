## Společný základ stavů na zemi (Idle, Move, Sprint; od v0.2.1 i Crawl).
## Řeší skok (včetně jump bufferu), pád z hrany a vstup na kotvy (Krok C).
class_name GroundedState
extends PlayerState


func enter(_previous: StringName, _msg: Dictionary = {}) -> void:
	player.jumps_used = 0
	player.air_attack_used = false


## Vrací true, pokud stav přepnul – volající stav pak už nic dalšího nedělá.
func handle_common(_delta: float) -> bool:
	if Input.is_action_just_pressed(&"action"):
		if try_enter_anchor():
			return true
		if _try_pickpocket():
			return false
		# Na dotyku je hůl jedno tlačítko: kotva v dosahu = přichycení, jinak útok.
		if InputManager.touch_controls_visible:
			machine.transition_to(&"Attack", {"combo": 1})
			return true
	if Input.is_action_pressed(&"aim") and machine.has_state(&"Aim") and player.mode == Player.Mode.MODE_3D:
		machine.transition_to(&"Aim")
		return true
	if Input.is_action_just_pressed(&"attack"):
		machine.transition_to(&"Attack", {"combo": 1})
		return true
	if Input.is_action_just_pressed(&"tennis"):
		machine.transition_to(&"Swing", {"ball": true})
		return true
	if player.consume_jump_buffer():
		# Dolů + skok na průchozí plošině = seskok skrz (2D plošinovky), ne skok.
		var one_way: OneWayPlatform = player.get_floor_body() as OneWayPlatform
		if one_way != null and Input.is_action_pressed(&"move_back"):
			one_way.drop_through()
			machine.transition_to(&"Air", {})
			return true
		machine.transition_to(&"Air", {"jump": true})
		return true
	if not player.is_on_floor():
		machine.transition_to(&"Air", {})
		return true
	return false


## Na zemi držíme malou rychlost dolů, aby Bruno „lepil“ na svahy a schody.
func stick_to_floor() -> void:
	player.velocity.y = minf(player.velocity.y, 0.0)


## Vybere správný pozemní stav podle vstupu (používá se i po dopadu).
static func pick_ground_state(p: Player) -> StringName:
	if Input.is_action_pressed(&"aim") and p.mode == Player.Mode.MODE_3D:
		return &"Aim"
	var strength: float = p.get_move_strength()
	# Nízký strop nad Brunem nebo těsně před ním → plazení.
	if p.has_low_ceiling(p.global_position) or (strength > 0.05 and p.has_low_ceiling(p.global_position + p.get_move_dir().normalized() * 0.55)):
		return &"Crawl"
	if strength < 0.05:
		return &"Idle"
	if Input.is_action_pressed(&"sprint"):
		return &"Sprint"
	return &"Move"


## Kapsářství: zezadu u nic netušícího strážného akce = ukrást váček mincí.
func _try_pickpocket() -> bool:
	for n: Node in player.get_tree().get_nodes_in_group(&"guard"):
		var g: Guard = n as Guard
		if g != null and g.can_be_pickpocketed_by(player):
			g.pickpocket(player)
			return true
	return false
