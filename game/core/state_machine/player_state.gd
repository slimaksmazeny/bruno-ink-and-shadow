## Základní třída všech stavů hráče.
## Stav NIKDY nevolá move_and_slide() a nečte konkrétní zařízení – jen nastavuje player.velocity
## a přes machine.transition_to() přepíná na jiný stav. move_and_slide() volá jen Player.
class_name PlayerState
extends Node

## Typ kotvy → stav, který ji obslouží. v0.2.1 sem jen přidá řádky (PIPE → Climb, LEDGE → LedgeHang…).
const ANCHOR_STATES: Dictionary = {
	Anchor.Type.SPIRE: &"Perch",
}

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
func apply_gravity(delta: float, multiplier: float = 1.0, allow_jump_cut: bool = true) -> void:
	var p: MovementProfile = player.profile
	var g: float = p.gravity * multiplier
	if player.velocity.y < 0.0:
		g *= p.fall_gravity_mult
	elif allow_jump_cut and not Input.is_action_pressed(&"jump"):
		g *= p.jump_cut_gravity_mult
	player.velocity.y = maxf(player.velocity.y - g * delta, -p.max_fall_speed)


## Rychlost potřebná k dosažení dané výšky skoku při základní gravitaci profilu.
func jump_velocity(height: float) -> float:
	return sqrt(2.0 * player.profile.gravity * height)


func horizontal_speed() -> float:
	return Vector2(player.velocity.x, player.velocity.z).length()


## Pokusí se přicvaknout na nejlepší kotvu v dosahu. Vrací true, pokud stav přepnul.
func try_enter_anchor() -> bool:
	var a: Anchor = player.anchor_detector.best_anchor()
	if a == null or not ANCHOR_STATES.has(a.type):
		return false
	var target: StringName = ANCHOR_STATES[a.type]
	if not machine.has_state(target):
		return false
	machine.transition_to(target, {"anchor": a})
	return true
