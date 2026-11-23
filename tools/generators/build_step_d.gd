extends SceneTree
func _initialize() -> void:
	var root := CanvasLayer.new()
	root.name = "TouchControls"
	root.layer = 50
	root.set_script(load("res://ui/touch_controls/touch_controls.gd"))
	var c := Control.new()
	c.name = "Canvas"
	c.set_script(load("res://ui/touch_controls/touch_draw.gd"))
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(c)
	c.owner = root
	var ps := PackedScene.new()
	ps.pack(root)
	print(ResourceSaver.save(ps, "res://ui/touch_controls/touch_controls.tscn"))
	root.free()
	quit()
