## Společný základ stavů ve vzduchu (Air; od Kroku C i Glide).
## Řeší řízení ve vzduchu a dopad na zem.
class_name AirborneState
extends PlayerState

## Rychlost, kterou si Bruno „nese“ ze země (sprint skok doletí dál).
var carried_speed: float = 0.0


func air_control(delta: float, max_speed: float) -> void:
	var dir: Vector3 = player.get_move_dir()
	accelerate_horizontal(dir * max_speed, player.profile.air_accel, delta)


## Vrací true, pokud Bruno dopadl a stav se přepnul.
func check_landing() -> bool:
	if player.is_on_floor() and player.velocity.y <= 0.0:
		player.visual.land_squash()
		machine.transition_to(GroundedState.pick_ground_state(player))
		return true
	return false
