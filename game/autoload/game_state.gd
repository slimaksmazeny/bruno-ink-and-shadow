## Běhová data hry (postup, sbírky, schopnosti, oblečky).
## Hra čte a mění data jen přes tyto funkce – nikdy přímo JSON slovník.
## SaveManager tato data jen serializuje do souboru a zpět.
extends Node

var data: Dictionary = {}
## Nastaví hlavní menu při „Pokračovat“; Checkpoint s tímto id po načtení levelu přesune Bruna k sobě.
var resume_checkpoint: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	reset()


func reset() -> void:
	data = SaveSchema.default_data()


func _process(delta: float) -> void:
	data["playtime_s"] = float(data.get("playtime_s", 0.0)) + delta


# --- Sběratelské předměty: ukládáme ID, počty se dopočítají ---

## category: "bottles" | "golden_tennis_balls" | "cages"
func is_collected(chapter_id: String, category: String, collectible_id: String) -> bool:
	var list: Array = _chapter(chapter_id).get(category, [])
	return list.has(collectible_id)


## Klíče (z kapsářství) – drží se jen během hraní levelu, neukládají se.
var keys: Array[String] = []


func add_key(key_id: String) -> void:
	if key_id not in keys:
		keys.append(key_id)
	Events.key_obtained.emit(key_id)


func has_key(key_id: String) -> bool:
	return key_id in keys


## Nejlepší čas dokončení kapitoly (s), nebo -1. Ukládá se do progress.best.<kapitola>.
func best_time(chapter_id: String) -> float:
	var best: Dictionary = data.get("progress", {}).get("best", {})
	return float((best.get(chapter_id, {}) as Dictionary).get("time", -1.0))


## Zapíše výsledek; vrací true, když je to nový rekord.
func record_result(chapter_id: String, seconds: float) -> bool:
	if not data.has("progress"):
		data["progress"] = {}
	if not data["progress"].has("best"):
		data["progress"]["best"] = {}
	var prev: float = best_time(chapter_id)
	var is_record: bool = prev < 0.0 or seconds < prev
	if is_record:
		data["progress"]["best"][chapter_id] = {"time": seconds}
	return is_record


## Mince (z kapsářství). Ukládají se do progress.coins.
func get_coins() -> int:
	return int(data.get("progress", {}).get("coins", 0))


func add_coins(amount: int) -> void:
	if not data.has("progress"):
		data["progress"] = {}
	data["progress"]["coins"] = get_coins() + amount
	Events.coins_changed.emit(get_coins())


func mark_collected(chapter_id: String, category: String, collectible_id: String) -> void:
	var chapter: Dictionary = _chapter(chapter_id)
	var list: Array = chapter.get(category, [])
	if not list.has(collectible_id):
		list.append(collectible_id)
		chapter[category] = list
		Events.collectible_collected.emit(collectible_id)


func count_collected(chapter_id: String, category: String) -> int:
	var list: Array = _chapter(chapter_id).get(category, [])
	return list.size()


func _chapter(chapter_id: String) -> Dictionary:
	var chapters: Dictionary = data["progress"]["chapters"]
	if not chapters.has(chapter_id):
		chapters[chapter_id] = SaveSchema.default_chapter(false)
	return chapters[chapter_id]
