## Komiksový post-process (shaders/ink_comic.gdshader) jako čtverec přes celou obrazovku
## před kamerou. Zapíná/vypíná se v Nastavení (Settings.comic_shading).
class_name InkPost
extends MeshInstance3D


func _ready() -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(2, 2)
	quad.flip_faces = true
	mesh = quad
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/ink_comic.gdshader")
	material_override = mat
	extra_cull_margin = 16384.0
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_apply()
	Settings.graphics_changed.connect(_apply)


func _apply() -> void:
	# Compatibility renderer (web) nemá hloubkovou texturu → efekt vypnout.
	var supported: bool = RenderingServer.get_current_rendering_method() != "gl_compatibility"
	visible = Settings.comic_shading and supported
