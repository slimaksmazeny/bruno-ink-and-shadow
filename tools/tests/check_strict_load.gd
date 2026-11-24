extends SceneTree
func _initialize() -> void:
	for f: String in ["res://levels/greybox/greybox_street.tscn", "res://ui/menus/main_menu.tscn", "res://player/player.tscn", "res://levels/ch2_canyon/canyon.tscn", "res://levels/test/gym.tscn", "res://levels/ch3_carnival/carnival.tscn"]:
		var s: Resource = load(f)
		print("loaded ", f, " ", s != null)
	quit()
