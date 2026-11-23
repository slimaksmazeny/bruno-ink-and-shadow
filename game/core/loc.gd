## Pomocné funkce pro lokalizaci.
## Čeština má 3 tvary množného čísla (1 lahvička, 2–4 lahvičky, 5+ lahviček),
## proto mají počitatelné texty klíče s příponou _ONE / _FEW / _MANY.
class_name Loc
extends RefCounted


static func plural(base_key: String, n: int) -> String:
	var suffix: String = "_MANY"
	if TranslationServer.get_locale().begins_with("cs"):
		if n == 1:
			suffix = "_ONE"
		elif n >= 2 and n <= 4:
			suffix = "_FEW"
	else:
		suffix = "_ONE" if n == 1 else "_MANY"
	return TranslationServer.translate(base_key + suffix).format({"n": n})


## Přeloží klíč a dosadí pojmenované hodnoty: Loc.fmt("HUD_BOTTLES", {"n": 5}).
static func fmt(key: String, values: Dictionary) -> String:
	return TranslationServer.translate(key).format(values)
