# tools/ — automatické testy a generátory (mimo herní projekt)

Tyto skripty **nejsou součástí hry** (leží mimo `game/`, takže je Godot editor nenačítá).
Spouští se z příkazové řádky přes Godot 4.7.x v headless režimu.

## Testy (regrese po každém kroku)
```
cd game
C:\Projekty\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script ../tools/tests/test_step_b.gd
```
| Test | Co ověřuje |
| --- | --- |
| `test_step_a.gd` | překlady CS/EN + české množné číslo, ukládání jazyka, InputMap, přepínač dotyku, save/load JSON, ladicí panel |
| `test_step_b.gd` | chůze 4,5 m/s, sprint 9 m/s, plížení, skok ~1,7 m, dvojskok ~2,7 m, krátký skok, pád do propasti → respawn |
| `test_step_c.gd` | ušní vrtulník (pád 2,5 m/s), přicvaknutí na cvičnou špičku, trasa přes 3 špičky na střechách |
| `test_step_d.gd` | dotyk: joystick, tlačítko sprintu a skoku, rozhlížení, vypnutí myších akcí v dotykovém režimu |
| `test_step_e.gd` | odpal tenisáku, zásah zvonu, otevření brány, míček neprolétá zdí |

## Generátory scén
Scény v `game/` byly poprvé vytvořeny těmito skripty přes Godot API (100% platný formát `.tscn`).
**Po ručních úpravách scén v editoru je znovu nespouštěj** – přepsaly by tvoje změny.
`build_step_e.gd` obsahuje aktuální stav (hráč, kamera, špičky, tenisák, zvon, brána, ulice).
