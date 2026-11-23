## Základní třída všech stavů hráče.
## Stav NIKDY nevolá move_and_slide() a nečte konkrétní zařízení – jen nastavuje player.velocity
## a přes machine.transition_to() přepíná na jiný stav. move_and_slide() volá jen Player.
class_name PlayerState
extends Node

var player: Player
var machine: PlayerStateMachine


func enter(_previous: StringName, _msg: Dictionary = {}) -> void:
	pass


func exit() -> void:
	pass


func physics_update(_delta: float) -> void:
	pass


# --- Sdílené pomocné funkce pro všechny stavy ---

## Plynule změní vodorovnou rychlost (X/Z) směrem k cílové hodnotě.
func accelerate_horizontal(target: Vector3, accel: float, delta: float) -> void:
	var horizontal := Vector3(player.velocity.x, 0.0, player.velocity.z)
	horizontal = horizontal.move_toward(Vector3(target.x, 0.0, target.z), accel * delta)
	player.velocity.x = horizontal.x
	player.velocity.z = horizontal.z


## Gravitace s rychlejším pádem a „useknutím“ skoku při puštění tlačítka (variabilní výška skoku).
func apply_gravity(delta: float, multiplier: float = 1.0) -> void:
	var p: MovementProfile = player.profile
	var g: float = p.gravity * multiplier
	if player.velocity.y < 0.0:
		g *= p.fall_gravity_mult
	elif not Input.is_action_pressed(&"jump"):
		g *= p.jump_cut_gravity_mult
	player.velocity.y = maxf(player.velocity.y - g * delta, -p.max_fall_speed)


## Rychlost potřebná k dosažení dané výšky skoku při základní gravitaci profilu.
func jump_velocity(height: float) -> float:
	return sqrt(2.0 * player.profile.gravity * height)


func horizontal_speed() -> float:
	return Vector2(player.velocity.x, player.velocity.z).length()
