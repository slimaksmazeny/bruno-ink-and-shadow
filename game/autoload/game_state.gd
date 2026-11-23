## Běhová data hry (postup, sbírky, schopnosti, oblečky).
## Hra čte a mění data jen přes tyto funkce – nikdy přímo JSON slovník.
## SaveManager tato data jen serializuje do souboru a zpět.
extends Node

const SAVE_VERSION: int = 1

var data: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	reset()


func reset() -> void:
	data = default_data()


static func default_data() -> Dictionary:
	return {
		"save_version": SAVE_VERSION,
		"game_version": str(ProjectSettings.get_setting("application/config/version", "0.0.0")),
		"saved_at_unix": 0,
		"playtime_s": 0.0,
		"player": {
			"outfit_equipped": "OUTFIT_DEFAULT",
			"outfits_unlocked": ["OUTFIT_DEFAULT"],
			"abilities": ["double_jump", "ear_glide", "spire_magnet", "tennis_bat"],
		},
		"progress": {
			"current_chapter": "ch1",
			"chapters": {
				"ch1": default_chapter(true),
			},
		},
	}


static func default_chapter(unlocked: bool) -> Dictionary:
	return {
		"unlocked": unlocked,
		"completed": false,
		"missions_done": [],
		"bottles": [],
		"vault_opened": false,
		"golden_tennis_balls": [],
		"cages": [],
		"sidequests": {},
	}


func _process(delta: float) -> void:
	data["playtime_s"] = float(data.get("playtime_s", 0.0)) + delta


# --- Sběratelské předměty: ukládáme ID, počty se dopočítají ---

## category: "bottles" | "golden_tennis_balls" | "cages"
func is_collected(chapter_id: String, category: String, collectible_id: String) -> bool:
	var list: Array = _chapter(chapter_id).get(category, [])
	return list.has(collectible_id)


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
		chapters[chapter_id] = default_chapter(false)
	return chapters[chapter_id]
