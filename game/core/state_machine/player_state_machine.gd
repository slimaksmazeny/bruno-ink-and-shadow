## Plochý stavový automat hráče. Stavy jsou uzly-děti; jméno uzlu = jméno stavu.
## Nový stav = nový uzel-dítě se skriptem dědícím z GroundedState / AirborneState / AnchorState.
class_name PlayerStateMachine
extends Node

signal state_changed(from: StringName, to: StringName)

@export var initial_state: PlayerState

var current: PlayerState
var _states: Dictionary[StringName, PlayerState] = {}


func setup(p: Player) -> void:
	for child: Node in get_children():
		if child is PlayerState:
			var state := child as PlayerState
			state.player = p
			state.machine = self
			_states[StringName(state.name)] = state
	if initial_state == null:
		push_error("PlayerStateMachine: chybí initial_state")
		return
	current = initial_state
	current.enter(&"", {})


func physics_update(delta: float) -> void:
	if current != null:
		current.physics_update(delta)


func transition_to(target: StringName, msg: Dictionary = {}) -> void:
	if not _states.has(target):
		push_error("PlayerStateMachine: neznámý stav '%s'" % target)
		return
	var next: PlayerState = _states[target]
	if next == current and not msg.get("force", false):
		return
	var previous := StringName(current.name)
	current.exit()
	current = next
	current.enter(previous, msg)
	state_changed.emit(previous, target)


func has_state(state_name: StringName) -> bool:
	return _states.has(state_name)


func current_name() -> StringName:
	return StringName(current.name) if current != null else &""
