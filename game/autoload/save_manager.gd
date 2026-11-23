## Ukládání a načítání herního postupu do JSON (user://save_<slot>.json).
## V0.2.0 je připravená jen kostra – plně se zapojí ve v0.4.0 (Úkryt, Kapitola 1).
## Zápis je atomický: .tmp → záloha .bak → přejmenování, aby Android při zabití hry nerozbil save.
extends Node

const SAVE_PATH_TEMPLATE: String = "user://save_%d.json"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _notification(what: int) -> void:
	# Android: systém může hru kdykoliv uspat a zabít → uložit při pauze aplikace.
	if what == NOTIFICATION_APPLICATION_PAUSED and GameState.data.has("progress"):
		save_game(1)


func save_path(slot: int) -> String:
	return SAVE_PATH_TEMPLATE % slot


func has_save(slot: int) -> bool:
	return FileAccess.file_exists(save_path(slot))


func save_game(slot: int = 1) -> bool:
	GameState.data["saved_at_unix"] = int(Time.get_unix_time_from_system())
	GameState.data["game_version"] = str(ProjectSettings.get_setting("application/config/version", "0.0.0"))
	return _write_json_atomic(save_path(slot), GameState.data)


func load_game(slot: int = 1) -> bool:
	var path: String = save_path(slot)
	if not FileAccess.file_exists(path):
		return false
	var text: String = FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("SaveManager: poškozený save %s" % path)
		return false
	GameState.data = _migrate(parsed as Dictionary)
	return true


## Aktualizuje starší savy na aktuální SAVE_VERSION. Nové pole = nový krok migrace.
func _migrate(loaded: Dictionary) -> Dictionary:
	var version: int = int(loaded.get("save_version", 0))
	var result: Dictionary = GameState.default_data()
	result.merge(loaded, true)
	if version < 1:
		pass # zatím žádná starší verze neexistuje
	result["save_version"] = GameState.SAVE_VERSION
	return result


func _write_json_atomic(path: String, payload: Dictionary) -> bool:
	var tmp_path: String = path + ".tmp"
	var file: FileAccess = FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: nelze zapsat %s (chyba %d)" % [tmp_path, FileAccess.get_open_error()])
		return false
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()

	if FileAccess.file_exists(path):
		DirAccess.copy_absolute(path, path + ".bak")
	var err: Error = DirAccess.rename_absolute(tmp_path, path)
	if err != OK:
		push_error("SaveManager: přejmenování %s selhalo (chyba %d)" % [tmp_path, err])
		return false
	return true
