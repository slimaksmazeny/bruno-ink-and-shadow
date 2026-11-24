## Mise levelu (loupež): ukradni klíč → otevři trezor → vezmi poklad → uteč k dodávce.
## Uzel v levelu ve skupině "mission". Ostatní mu hlásí události přes notify(&"...").
## Na konci ukáže obrazovku s výsledky.
class_name Mission
extends Node

enum Step { STEAL_KEY, OPEN_VAULT, TAKE_TREASURE, ESCAPE, DONE }

const STEP_KEYS: Array[String] = ["MISSION_STEAL_KEY", "MISSION_OPEN_VAULT", "MISSION_TAKE_TREASURE", "MISSION_ESCAPE", "MISSION_DONE"]

@export var key_id: String = "vault_key"

var step: Step = Step.STEAL_KEY
var knockouts: int = 0
var _start_ms: int = 0


func _ready() -> void:
	add_to_group(&"mission")
	_start_ms = Time.get_ticks_msec()
	GameState.keys.clear()
	Events.key_obtained.connect(func(k: String) -> void:
		if k == key_id:
			notify(&"key"))
	Events.guard_knocked_out.connect(func() -> void: knockouts += 1)


func objective_key() -> String:
	return STEP_KEYS[step]


func elapsed_sec() -> float:
	return float(Time.get_ticks_msec() - _start_ms) / 1000.0


func notify(event: StringName) -> void:
	var next: Step = step
	match event:
		&"key":
			if step == Step.STEAL_KEY:
				next = Step.OPEN_VAULT
		&"vault_opened":
			if step <= Step.OPEN_VAULT:
				next = Step.TAKE_TREASURE
		&"treasure_taken":
			next = Step.ESCAPE
		&"escaped":
			if step == Step.ESCAPE:
				next = Step.DONE
	if next == step:
		return
	step = next
	Events.mission_step_changed.emit(int(step))
	if step == Step.DONE:
		_complete()


func _complete() -> void:
	var screen := ResultsScreen.new()
	screen.mission = self
	get_tree().root.add_child(screen)
