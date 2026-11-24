## Globální sběrnice signálů (signal bus).
## Systémy spolu mluví přes tyto signály, ne přes get_node("../../..").
## Nové signály přidávej jen tehdy, když je opravdu poslouchá víc systémů.
extends Node

## Jazyk hry se změnil (např. "cs" nebo "en").
@warning_ignore("unused_signal")
signal locale_changed(locale: String)

## Hráč přepnul mezi 3D a 2D režimem (hodnota = Player.Mode, od Kroku F).
@warning_ignore("unused_signal")
signal player_mode_changed(mode: int)

## Hráč začal / přestal mířit tenisákem (zaměřovač, kamera).
@warning_ignore("unused_signal")
signal aim_changed(aiming: bool)

## Zvon / terč zasažený tenisákem (od Kroku E).
@warning_ignore("unused_signal")
signal bell_hit(bell_id: StringName)

## Sebrán sběratelský předmět (od v0.3+).
@warning_ignore("unused_signal")
signal collectible_collected(collectible_id: String)

## Zdraví hráče se změnilo (zásah, vyléčení, respawn).
@warning_ignore("unused_signal")
signal player_health_changed(health: int, max_health: int)

## Hráč přišel o všechny životy (před respawnem na checkpointu).
@warning_ignore("unused_signal")
signal player_died()

## Hráč dosáhl checkpointu.
@warning_ignore("unused_signal")
signal checkpoint_reached(checkpoint_id: String)

## Strážný zpozoroval hráče (alert = true) / ztratil ho (false).
@warning_ignore("unused_signal")
signal guard_alert_changed(alerted: bool)

## Počet mincí se změnil (kapsářství).
@warning_ignore("unused_signal")
signal coins_changed(total: int)

## Hluk ve světě (dopad tenisáku…). Strážní v dosahu se jdou podívat.
@warning_ignore("unused_signal")
signal noise_made(position: Vector3, radius: float)

## Strážný spustil poplach a volá posily (ostatní strážní v okolí přijdou hledat).
@warning_ignore("unused_signal")
signal guard_called_help(caller: Node, position: Vector3)

## Bruno získal klíč (kapsářstvím).
@warning_ignore("unused_signal")
signal key_obtained(key_id: String)

## Strážný byl vyřazen.
@warning_ignore("unused_signal")
signal guard_knocked_out()

## Mise levelu postoupila na další krok (Mission.Step jako int).
@warning_ignore("unused_signal")
signal mission_step_changed(step: int)

## Bruno spustil laserový poplach.
@warning_ignore("unused_signal")
signal laser_alarm(position: Vector3)

## Při útěku vypršel čas – strážní Bruna chytili.
@warning_ignore("unused_signal")
signal mission_caught()

## Boss: začátek souboje, změna zdraví, poražen.
@warning_ignore("unused_signal")
signal boss_started(boss: Node)
@warning_ignore("unused_signal")
signal boss_health_changed(boss: Node, health: int, max_health: int)
@warning_ignore("unused_signal")
signal boss_defeated(boss: Node)
