## Vrstva pozadí pro 2D (obraz): plochá silueta kopců / stromů / střech v dané hloubce.
## Kamera ve 2D má perspektivu, takže vzdálenější vrstvy se samy hýbou pomaleji (parallax).
## Tvar se generuje z `shape_seed` – vlastní procedurální kresba, žádné převzaté obrázky.
@tool
class_name BackdropLayer
extends MeshInstance3D

enum Style { HILLS, TREES, ROOFS }

const BACKDROP_LAYER: int = 2

@export var style: Style = Style.HILLS:
	set(v):
		style = v
		_rebuild()
@export var width: float = 140.0:
	set(v):
		width = v
		_rebuild()
@export var height: float = 6.0:
	set(v):
		height = v
		_rebuild()
## Jak hluboko pod horizont silueta sahá (zakryje spodní okraj).
@export var depth_below: float = 30.0
@export var color: Color = Color(0.18, 0.14, 0.32):
	set(v):
		color = v
		_rebuild()
@export var shape_seed: int = 1:
	set(v):
		shape_seed = v
		_rebuild()


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = shape_seed
	var top: PackedVector2Array = _outline(rng)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in top.size() - 1:
		var a: Vector2 = top[i]
		var b: Vector2 = top[i + 1]
		var a0 := Vector3(a.x, -depth_below, 0)
		var b0 := Vector3(b.x, -depth_below, 0)
		var a1 := Vector3(a.x, a.y, 0)
		var b1 := Vector3(b.x, b.y, 0)
		st.add_vertex(a0)
		st.add_vertex(a1)
		st.add_vertex(b1)
		st.add_vertex(a0)
		st.add_vertex(b1)
		st.add_vertex(b0)
	mesh = st.commit()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_override = mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Vrstva 2 = jen 2D pozadí; HybridCamera ji ukazuje jen ve 2D.
	layers = BACKDROP_LAYER


func _outline(rng: RandomNumberGenerator) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var x: float = -width * 0.5
	var end_x: float = width * 0.5
	match style:
		Style.HILLS:
			var phase: float = rng.randf() * TAU
			while x <= end_x:
				var y: float = height * (0.55 + 0.3 * sin(x * 0.07 + phase) + 0.15 * sin(x * 0.19 + phase * 2.0))
				pts.append(Vector2(x, y))
				x += 1.5
		Style.TREES:
			pts.append(Vector2(x, 0.0))
			while x < end_x:
				var gap: float = rng.randf_range(1.0, 4.0)
				x += gap
				pts.append(Vector2(x, 0.0))
				# Strom: kmen + kulatá koruna (mnohoúhelník).
				var trunk: float = rng.randf_range(0.3, 0.6)
				var crown: float = rng.randf_range(1.2, 2.6) * height / 6.0
				var h: float = rng.randf_range(0.5, 1.0) * height
				pts.append(Vector2(x, h - crown))
				for k: int in 9:
					var a: float = PI - float(k) / 8.0 * PI
					pts.append(Vector2(x + trunk * 0.5 + cos(a) * crown, h - crown * 0.4 + sin(a) * crown))
				pts.append(Vector2(x + trunk, h - crown))
				pts.append(Vector2(x + trunk, 0.0))
				x += trunk
		Style.ROOFS:
			pts.append(Vector2(x, 0.0))
			while x < end_x:
				var w: float = rng.randf_range(2.5, 6.0)
				var h: float = rng.randf_range(0.4, 1.0) * height
				pts.append(Vector2(x, h))
				if rng.randf() < 0.5:
					pts.append(Vector2(x + w * 0.5, h + rng.randf_range(0.8, 2.0)))
				elif rng.randf() < 0.5:
					# Komín.
					pts.append(Vector2(x + w * 0.3, h))
					pts.append(Vector2(x + w * 0.3, h + 1.2))
					pts.append(Vector2(x + w * 0.45, h + 1.2))
					pts.append(Vector2(x + w * 0.45, h))
				pts.append(Vector2(x + w, h))
				x += w
				pts.append(Vector2(x, rng.randf_range(0.2, 0.5) * height))
			pts.append(Vector2(x, 0.0))
	return pts
