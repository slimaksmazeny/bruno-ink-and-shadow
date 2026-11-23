## Výchozí struktura uložené hry (schéma JSON). Statické funkce – používá GameState i SaveManager.
## Nové pole = zvýšit SAVE_VERSION a doplnit migraci v SaveManager._migrate().
class_name SaveSchema
extends RefCounted

const SAVE_VERSION: int = 1


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
