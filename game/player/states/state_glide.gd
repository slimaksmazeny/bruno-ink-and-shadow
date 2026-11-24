## Ušní vrtulník: držení skoku při pádu zpomalí pád a umožní dlouhý let.
extends AirborneState


func enter(_previous: StringName, _msg: Dictionary = {}) -> void:
	carried_speed = maxf(horizontal_speed(), player.profile.glide_air_speed)
	player.visual.set_gliding(true)
	AudioManager.play(&"glide", -6.0)


func exit() -> void:
	player.visual.set_gliding(false)


func physics_update(delta: float) -> void:
	if Input.is_action_just_pressed(&"action") and try_enter_anchor():
		return
	if not Input.is_action_pressed(&"jump"):
		machine.transition_to(&"Air", {"keep_jumps": true})
		return
	var p: MovementProfile = player.profile
	if player.wind_lift > 0.0:
		# Stoupavý vítr (WindColumn) – uši fungují jako plachta a Bruno stoupá.
		player.velocity.y = move_toward(player.velocity.y, player.wind_lift, p.gravity * 1.2 * delta)
	else:
		# Plynule zbrzdit pád na rychlost plachtění.
		player.velocity.y = move_toward(player.velocity.y, -_fall_speed(), p.gravity * 2.0 * delta)
	if player.velocity.y > -_fall_speed() and player.wind_lift <= 0.0:
		player.velocity.y = maxf(player.velocity.y - p.gravity * 0.25 * delta, -_fall_speed())
	air_control(delta, carried_speed)
	carried_speed = move_toward(carried_speed, p.glide_air_speed, 2.0 * delta)
	check_landing()


## Vylepšení „Dlouhé plachtění“ zpomalí pád o 35 %.
func _fall_speed() -> float:
	return player.profile.glide_fall_speed * (0.65 if Upgrades.has(Upgrades.LONG_GLIDE) else 1.0)
