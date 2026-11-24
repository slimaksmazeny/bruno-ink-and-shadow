## Zvuky a hudba. Jednoduché volání odkudkoli: AudioManager.play(&"jump").
## Zvuky jsou v res://audio/sfx/<jméno>.wav (zatím generované zástupné – tools/generators/gen_sfx.py).
## Sběrnice: Master → Music, SFX. Hlasitosti nastavuje Settings.
extends Node

const SFX_DIR: String = "res://audio/sfx/"
const POOL_SIZE: int = 12
const POOL_SIZE_3D: int = 8

var _streams: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []
var _pool_3d: Array[AudioStreamPlayer3D] = []
var _next: int = 0
var _next_3d: int = 0
## Ochrana proti „kulometu“ stejného zvuku ve stejném snímku.
var _last_played: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus(&"Music")
	_ensure_bus(&"SFX")
	for i: int in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = &"SFX"
		add_child(p)
		_pool.append(p)
	for i: int in POOL_SIZE_3D:
		var p3 := AudioStreamPlayer3D.new()
		p3.bus = &"SFX"
		p3.unit_size = 6.0
		p3.max_distance = 45.0
		add_child(p3)
		_pool_3d.append(p3)
	apply_volumes()


## Přehraje zvuk bez polohy (UI, Brunovy vlastní zvuky).
## pitch_jitter = náhodná odchylka výšky, aby se opakované zvuky neomrzely.
func play(sfx: StringName, volume_db: float = 0.0, pitch: float = 1.0, pitch_jitter: float = 0.06) -> void:
	var stream: AudioStream = _get_stream(sfx)
	if stream == null or _throttled(sfx):
		return
	var p: AudioStreamPlayer = _pool[_next]
	_next = (_next + 1) % POOL_SIZE
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = pitch * randf_range(1.0 - pitch_jitter, 1.0 + pitch_jitter)
	p.play()


## Přehraje zvuk v prostoru (strážný, zvon, bedna…).
func play_at(sfx: StringName, pos: Vector3, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	var stream: AudioStream = _get_stream(sfx)
	if stream == null or _throttled(sfx):
		return
	var p: AudioStreamPlayer3D = _pool_3d[_next_3d]
	_next_3d = (_next_3d + 1) % POOL_SIZE_3D
	p.global_position = pos
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = pitch * randf_range(0.95, 1.05)
	p.play()


func apply_volumes() -> void:
	_set_bus_linear(&"Master", Settings.master_volume)
	_set_bus_linear(&"Music", Settings.music_volume)
	_set_bus_linear(&"SFX", Settings.sfx_volume)


func _get_stream(sfx: StringName) -> AudioStream:
	if _streams.has(sfx):
		return _streams[sfx]
	var path: String = SFX_DIR + String(sfx) + ".wav"
	var stream: AudioStream = null
	if ResourceLoader.exists(path):
		stream = load(path) as AudioStream
	else:
		push_warning("AudioManager: chybí zvuk %s" % path)
	_streams[sfx] = stream
	return stream


func _throttled(sfx: StringName) -> bool:
	var now: int = Engine.get_process_frames()
	if int(_last_played.get(sfx, -10)) >= now - 1:
		return true
	_last_played[sfx] = now
	return false


func _ensure_bus(bus_name: StringName) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var idx: int = AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, &"Master")


func _set_bus_linear(bus_name: StringName, value: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(value, 0.0001)))
	AudioServer.set_bus_mute(idx, value <= 0.001)
