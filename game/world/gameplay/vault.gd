## Trezor s pokladem (cíl loupeže). Otevře se klíčem `key_id` (E / ○), uvnitř je poklad –
## když ho Bruno vezme, mise pokračuje útěkem. Vzhled se staví z kódu (@tool).
@tool
class_name Vault
extends Node3D

@export var key_id: String = "vault_key"

var is_open: bool = false
var treasure_taken: bool = false
var _door: Node3D
var _treasure: MeshInstance3D
var _t: float = 0.0


func _ready() -> void:
	_build()
	if Engine.is_editor_hint():
		return
	add_to_group(&"interactable")
	add_to_group(&"vault")


func _process(delta: float) -> void:
	if _treasure == null or treasure_taken:
		return
	_t += delta
	_treasure.rotation.y += delta * 1.5
	_treasure.position.y = 0.8 + sin(_t * 2.0) * 0.06


func can_interact(p: Player) -> bool:
	if not is_open:
		return true # bez klíče ukáže hlášku „zamčeno“
	return not treasure_taken and p != null


func get_prompt() -> String:
	if not is_open:
		return "PROMPT_VAULT_OPEN" if GameState.has_key(key_id) else "PROMPT_VAULT_LOCKED"
	return "PROMPT_TREASURE"


func interact(p: Player) -> void:
	if not is_open:
		if not GameState.has_key(key_id):
			AudioManager.play_at(&"ui_back", global_position)
			return
		_open()
		return
	if not treasure_taken:
		_take(p)


func _open() -> void:
	is_open = true
	AudioManager.play_at(&"gate", global_position, 0.0, 1.3)
	var tw: Tween = create_tween()
	tw.tween_property(_door, "rotation:y", -1.9, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	get_tree().call_group(&"mission", &"notify", &"vault_opened")


func _take(p: Player) -> void:
	treasure_taken = true
	AudioManager.play(&"checkpoint", 0.0, 0.8, 0.0)
	AudioManager.play(&"bell", -6.0, 1.5, 0.0)
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(_treasure, "global_position", p.global_position + Vector3.UP * 1.6, 0.35)
	tw.tween_property(_treasure, "scale", Vector3.ZERO, 0.35).set_delay(0.25)
	get_tree().call_group(&"mission", &"notify", &"treasure_taken")


func _build() -> void:
	for c: Node in get_children():
		if c.has_meta(&"generated"):
			c.free()
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color(0.22, 0.24, 0.3)
	metal.metallic = 0.7
	metal.roughness = 0.35
	# Tělo (pevné).
	var body := StaticBody3D.new()
	body.set_meta(&"generated", true)
	add_child(body)
	for part: Array in [[Vector3(0, 0.8, -0.45), Vector3(1.4, 1.6, 0.1)], [Vector3(-0.65, 0.8, 0), Vector3(0.1, 1.6, 1.0)], [Vector3(0.65, 0.8, 0), Vector3(0.1, 1.6, 1.0)], [Vector3(0, 0.05, 0), Vector3(1.4, 0.1, 1.0)], [Vector3(0, 1.55, 0), Vector3(1.4, 0.1, 1.0)]]:
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = part[1]
		cs.shape = bs
		cs.position = part[0]
		body.add_child(cs)
		var m := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = part[1]
		m.mesh = bm
		m.material_override = metal
		m.position = part[0]
		body.add_child(m)
	# Dveře na pantu (levý okraj).
	_door = Node3D.new()
	_door.position = Vector3(-0.65, 0.8, 0.5)
	_door.set_meta(&"generated", true)
	add_child(_door)
	var dm := MeshInstance3D.new()
	var dbm := BoxMesh.new()
	dbm.size = Vector3(1.3, 1.45, 0.08)
	dm.mesh = dbm
	dm.position = Vector3(0.65, 0, 0)
	var dmat := StandardMaterial3D.new()
	dmat.albedo_color = Color(0.3, 0.32, 0.4)
	dmat.metallic = 0.8
	dm.material_override = dmat
	_door.add_child(dm)
	var dial := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.18
	cyl.bottom_radius = 0.18
	cyl.height = 0.06
	dial.mesh = cyl
	dial.rotation.x = PI * 0.5
	dial.position = Vector3(0.75, 0.1, 0.06)
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color(0.95, 0.75, 0.25)
	gold.metallic = 0.9
	dial.material_override = gold
	_door.add_child(dial)
	# Poklad: inkoustový krystal.
	_treasure = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.22
	sm.height = 0.5
	sm.radial_segments = 6
	sm.rings = 2
	_treasure.mesh = sm
	var tm := StandardMaterial3D.new()
	tm.albedo_color = Color(0.45, 0.2, 0.95)
	tm.emission_enabled = true
	tm.emission = Color(0.55, 0.3, 1.0)
	tm.emission_energy_multiplier = 1.5
	tm.metallic = 0.4
	tm.roughness = 0.1
	_treasure.material_override = tm
	_treasure.position = Vector3(0, 0.8, 0)
	_treasure.set_meta(&"generated", true)
	add_child(_treasure)
