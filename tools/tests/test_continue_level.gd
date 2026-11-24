## „Pokračovat“ otevře naposledy hranou kapitolu (ne vždy kapitolu 1).
## godot --headless --path game --script ../tools/tests/test_continue_level.gd
extends SceneTree

var f: int = 0
var fails: int = 0
var stage: int = 0


func _initialize() -> void:
	change_scene_to_file("res://levels/ch2_canyon/canyon.tscn")


func check(name: String, ok: bool, info: String = "") -> void:
	print(("PASS " if ok else "FAIL ") + name + ("  " + info if info != "" else ""))
	if not ok:
		fails += 1


func _physics_process(_d: float) -> bool:
	if current_scene == null:
		return false
	f += 1
	var gs = get_root().get_node("GameState")
	var sm = get_root().get_node("SaveManager")
	if stage == 0 and f == 20:
		check("last_level_recorded", str(gs.data["progress"].get("last_level", "")) == "res://levels/ch2_canyon/canyon.tscn")
		sm.save_game()
		stage = 1
		f = 0
		change_scene_to_file("res://ui/menus/main_menu.tscn")
	elif stage == 1 and f == 10:
		current_scene._on_continue()
	elif stage == 1 and f == 90:
		check("continue_opens_canyon", current_scene != null and current_scene.name == "CanyonLevel", str(current_scene.name if current_scene else "null"))
		print("RESULT: %d fails" % fails)
		quit(1 if fails > 0 else 0)
	return false
