## Společný základ stavů na zemi (Idle, Move, Sprint; od v0.2.1 i Crawl).
## Řeší skok (včetně jump bufferu), pád z hrany a vstup na kotvy (Krok C).
class_name GroundedState
extends PlayerState


func enter(_previous: StringName, _msg: Dictionary = {}) -> void:
	player.jumps_used = 0


## Vrací true, pokud stav přepnul – volající stav pak už nic dalšího nedělá.
func handle_common(_delta: float) -> bool:
	if player.consume_jump_buffer():
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
	var strength: float = p.get_move_strength()
	if strength < 0.05:
		return &"Idle"
	if Input.is_action_pressed(&"sprint") and not Input.is_action_pressed(&"sneak"):
		return &"Sprint"
	return &"Move"
