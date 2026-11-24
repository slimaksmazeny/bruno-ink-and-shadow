## Vylepšení z Brunovy boudy (obchod v hlavním menu) – kupují se za mince z kapsářství.
## Koupená se ukládají do progress.upgrades (GameState). Efekty čtou herní skripty přes has().
class_name Upgrades
extends RefCounted

const EXTRA_HEART: String = "extra_heart"
const LONG_GLIDE: String = "long_glide"
const SILENT_PAWS: String = "silent_paws"
const STUN_BALL: String = "stun_ball"
const FAST_CRAWL: String = "fast_crawl"

## id, překladový klíč názvu, klíč popisu, cena.
const ALL: Array[Array] = [
	[EXTRA_HEART, "UPG_EXTRA_HEART", "UPG_EXTRA_HEART_DESC", 120],
	[LONG_GLIDE, "UPG_LONG_GLIDE", "UPG_LONG_GLIDE_DESC", 80],
	[SILENT_PAWS, "UPG_SILENT_PAWS", "UPG_SILENT_PAWS_DESC", 60],
	[STUN_BALL, "UPG_STUN_BALL", "UPG_STUN_BALL_DESC", 100],
	[FAST_CRAWL, "UPG_FAST_CRAWL", "UPG_FAST_CRAWL_DESC", 40],
]


static func has(id: String) -> bool:
	var owned: Array = GameState.data.get("progress", {}).get("upgrades", [])
	return id in owned


static func cost(id: String) -> int:
	for u: Array in ALL:
		if u[0] == id:
			return int(u[3])
	return 0


## Koupit: vrací true při úspěchu (dost mincí a ještě nevlastněné). Hned uloží hru.
static func buy(id: String) -> bool:
	if has(id) or GameState.get_coins() < cost(id):
		return false
	if not GameState.data.has("progress"):
		GameState.data["progress"] = {}
	var owned: Array = GameState.data["progress"].get("upgrades", [])
	owned.append(id)
	GameState.data["progress"]["upgrades"] = owned
	GameState.add_coins(-cost(id))
	SaveManager.save_game()
	return true
