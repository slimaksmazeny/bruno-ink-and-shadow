## Uživatelská nastavení (jazyk, hlasitost, citlivost). Ukládá se do user://settings.cfg.
## Herní postup NEpatří sem – ten řeší SaveManager.
extends Node

## Změna grafického nastavení (komiksový vzhled…).
signal graphics_changed

const SETTINGS_PATH: String = "user://settings.cfg"
const SUPPORTED_LOCALES: PackedStringArray = ["cs", "en"]
const FALLBACK_LOCALE: String = "en"

var locale: String = FALLBACK_LOCALE
var master_volume: float = 1.0
var music_volume: float = 0.7
var sfx_volume: float = 0.9
## Komiksový vzhled: inkoustové obrysy + světlo po stupních.
var comic_shading: bool = true
var mouse_sensitivity: float = 0.003

var _config: ConfigFile = ConfigFile.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()
	_apply_locale(locale)


func load_settings() -> void:
	var err: Error = _config.load(SETTINGS_PATH)
	if err == OK:
		locale = str(_config.get_value("general", "locale", _detect_os_locale()))
		master_volume = float(_config.get_value("audio", "master_volume", 1.0))
		music_volume = float(_config.get_value("audio", "music_volume", 0.7))
		sfx_volume = float(_config.get_value("audio", "sfx_volume", 0.9))
		comic_shading = bool(_config.get_value("graphics", "comic_shading", true))
		mouse_sensitivity = float(_config.get_value("input", "mouse_sensitivity", 0.003))
	else:
		# První spuštění: čeština, pokud je systém česky, jinak angličtina.
		locale = _detect_os_locale()
	if not SUPPORTED_LOCALES.has(locale):
		locale = FALLBACK_LOCALE
	InputManager.mouse_sensitivity = mouse_sensitivity


func save_settings() -> void:
	_config.set_value("general", "locale", locale)
	_config.set_value("audio", "master_volume", master_volume)
	_config.set_value("audio", "music_volume", music_volume)
	_config.set_value("audio", "sfx_volume", sfx_volume)
	_config.set_value("graphics", "comic_shading", comic_shading)
	_config.set_value("input", "mouse_sensitivity", mouse_sensitivity)
	var err: Error = _config.save(SETTINGS_PATH)
	if err != OK:
		push_error("Settings: nepodařilo se uložit %s (chyba %d)" % [SETTINGS_PATH, err])


func set_locale(new_locale: String) -> void:
	if not SUPPORTED_LOCALES.has(new_locale):
		push_warning("Settings: nepodporovaný jazyk '%s'" % new_locale)
		return
	locale = new_locale
	_apply_locale(locale)
	save_settings()


## Přepne na další jazyk v pořadí (cs → en → cs …).
func cycle_locale() -> void:
	var idx: int = SUPPORTED_LOCALES.find(locale)
	set_locale(SUPPORTED_LOCALES[(idx + 1) % SUPPORTED_LOCALES.size()])


func _apply_locale(new_locale: String) -> void:
	TranslationServer.set_locale(new_locale)
	Events.locale_changed.emit(new_locale)


func _detect_os_locale() -> String:
	return "cs" if OS.get_locale_language() == "cs" else FALLBACK_LOCALE


## Hlasitost 0..1 pro "master" / "music" / "sfx". Okamžitě se projeví a uloží.
func set_volume(kind: String, value: float) -> void:
	value = clampf(value, 0.0, 1.0)
	match kind:
		"master": master_volume = value
		"music": music_volume = value
		"sfx": sfx_volume = value
		_: push_warning("Settings: neznámá hlasitost '%s'" % kind)
	if is_instance_valid(AudioManager):
		AudioManager.apply_volumes()
	save_settings()


func set_mouse_sensitivity(value: float) -> void:
	mouse_sensitivity = clampf(value, 0.0005, 0.01)
	InputManager.mouse_sensitivity = mouse_sensitivity
	save_settings()


func set_comic_shading(on: bool) -> void:
	comic_shading = on
	graphics_changed.emit()
	save_settings()
