## Mise levelu (loupež): ukradni klíč → otevři trezor → vezmi poklad → uteč k dodávce.
## Uzel v levelu ve skupině "mission". Ostatní mu hlásí události přes notify(&"...").
## Na konci ukáže obrazovku s výsledky.
class_name Mission
extends Node

enum Step { STEAL_KEY, OPEN_VAULT, TAKE_TREASURE, ESCAPE, DONE }

const STEP_KEYS: Array[String] = ["MISSION_STEAL_KEY", "MISSION_OPEN_VAULT", "MISSION_TAKE_TREASURE", "MISSION_ESCAPE", "MISSION_DONE"]

@export var key_id: String = "vault_key"
## Jméno kapitoly – pod ním se ukládají kapky, světlušky a rekordy.
@export var chapter_id: String = "greybox"
## Finále: po vzetí pokladu poplach a odpočet útěku (s). 0 = bez odpočtu.
@export var escape_time: float = 0.0

## Zbývající čas útěku (jen v kroku ESCAPE s odpočtem), jinak < 0.
var escape_left: float = -1.0
var _alarm_pulse: float = 0.0

var step: Step = Step.STEAL_KEY
var knockouts: int = 0
var _start_ms: int = 0


func _enter_tree() -> void:
	# Už při vstupu do stromu (před _ready kapek), ať si kapky zjistí kapitolu.
	add_to_group(&"mission")


## Kapitola levelu, ve kterém je `node` (bez mise = "greybox").
static func chapter_of(node: Node) -> String:
	if node == null or not node.is_inside_tree():
		return "greybox"
	var m: Mission = node.get_tree().get_first_node_in_group(&"mission") as Mission
	return m.chapter_id if m != null else "greybox"


func _ready() -> void:
	_start_ms = Time.get_ticks_msec()
	# „Pokračovat“ v menu otevře naposledy hranou kapitolu (testovací hřiště ne).
	var scene: Node = get_tree().current_scene if get_tree() != null else null
	if scene != null and not scene.scene_file_path.is_empty() and chapter_id != "gym":
		if not GameState.data.has("progress"):
			GameState.data["progress"] = {}
		if str(GameState.data["progress"].get("last_level", "")) != scene.scene_file_path:
			GameState.data["progress"]["last_level"] = scene.scene_file_path
			GameState.data["progress"]["last_checkpoint"] = ""
	GameState.keys.clear()
	Events.key_obtained.connect(func(k: String) -> void:
		if k == key_id:
			notify(&"key"))
	Events.guard_knocked_out.connect(func() -> void: knockouts += 1)


func objective_key() -> String:
	return STEP_KEYS[step]


## Kde je aktuální cíl (pro radar), nebo null.
func objective_position() -> Variant:
	match step:
		Step.STEAL_KEY:
			for n: Node in get_tree().get_nodes_in_group(&"guard"):
				var g: Guard = n as Guard
				if g != null and g.carries_key == key_id:
					return g.global_position
			for n: Node in get_tree().get_nodes_in_group(&"key_pickup"):
				var k: KeyPickup = n as KeyPickup
				if k != null and k.key_id == key_id and not k.taken:
					return k.global_position
		Step.OPEN_VAULT, Step.TAKE_TREASURE:
			var v: Node3D = get_tree().get_first_node_in_group(&"vault") as Node3D
			if v != null:
				return v.global_position
		Step.ESCAPE:
			for n: Node in get_tree().get_nodes_in_group(&"interactable"):
				if n is Getaway:
					return (n as Node3D).global_position
	return null


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
	if step == Step.ESCAPE and escape_time > 0.0:
		escape_left = escape_time
		AudioManager.play(&"alert", 4.0, 0.8)
		AudioManager.play_music(&"sneak_loop", 0.5, 1.25)
	elif step == Step.DONE:
		escape_left = -1.0
		AudioManager.play_music(&"sneak_loop", 1.0, 1.0)
	if step == Step.DONE:
		_complete()


func _process(delta: float) -> void:
	if step != Step.ESCAPE or escape_left < 0.0 or get_tree().paused:
		return
	escape_left -= delta
	# Poplach: strážní každé 2 s „vědí“, kde Bruno je, a běží za ním.
	_alarm_pulse -= delta
	var p: Player = get_tree().get_first_node_in_group(&"player") as Player
	if _alarm_pulse <= 0.0 and p != null:
		_alarm_pulse = 2.0
		for n: Node in get_tree().get_nodes_in_group(&"guard"):
			(n as Guard).investigate(p.global_position)
	if escape_left <= 0.0 and p != null:
		# Chytili ho: zpět na checkpoint, odpočet znovu.
		escape_left = escape_time
		Events.mission_caught.emit()
		p.die()


func _complete() -> void:
	var screen := ResultsScreen.new()
	screen.mission = self
	get_tree().root.add_child(screen)
