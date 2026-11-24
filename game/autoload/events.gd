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
