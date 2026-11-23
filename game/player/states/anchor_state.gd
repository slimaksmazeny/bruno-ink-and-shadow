## Společný základ stavů připnutých ke kotvě (Perch; v0.2.1 Climb, LedgeHang, WallSneak, PathFollow, HookSwing).
class_name AnchorState
extends PlayerState

var anchor: Anchor


func enter(_previous: StringName, msg: Dictionary = {}) -> void:
	anchor = msg.get("anchor", null) as Anchor
	player.jumps_used = 0


func exit() -> void:
	anchor = null


## Skok z kotvy = plnohodnotný skok ze země (dvojskok zůstává k dispozici).
func jump_off() -> void:
	machine.transition_to(&"Air", {"jump": true})


## Pustit se kotvy bez skoku.
func drop_off() -> void:
	player.jumps_used = 1
	machine.transition_to(&"Air", {})
