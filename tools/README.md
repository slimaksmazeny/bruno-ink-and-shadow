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
| `test_step_f.gd` | brána → vstup do obrazu (průlet kamery, inkoust), 2D režim a kamera z boku, rovina drží, odraz z houby + dvojskok na plošinu, pád do propasti → návrat na začátek 2D, výstup zpět do 3D |
| `test_camera_2d_peek.gd` | 2D kamera: na kraji plošiny nad dírou se sníží a oddálí, uprostřed se vrátí |
| `test_step_g.gd` | v0.2.2: zdraví, louže, checkpoint, smrt, strážný, pauza, menu (21 kontrol) |
| `test_step_h.gd` | 2D kit (průchozí, rozpadající se, zvedací plošina) + Pokračovat na 2D checkpointu |
| `test_step_i.gd` | v0.2.3: trubka, lano, římsa, vítr, zlaté kapky (9 kontrol) |
| `test_step_j.gd` | v0.2.4: kruh 2D/3D, odraz od zdi, píst, úzká římsa, hudba (11 kontrol) |
| `test_attack.gd` | kombo holí 1→2→3 (výpad, auto-cíl na figurínu), rozbití bedny, útok ve vzduchu jednou za skok, obnovení času po zastavení |
| `test_step_e2_aim.gd` | míření (kamera, úkroky, výstřel, sprint potlačen), útok holí, přichycení jen ke kotvě, na kterou se díváš |

## Generátory scén
Scény v `game/` byly poprvé vytvořeny těmito skripty přes Godot API (100% platný formát `.tscn`).
**Po ručních úpravách scén v editoru je znovu nespouštěj** – přepsaly by tvoje změny.
`build_step_e.gd` obsahuje aktuální stav (hráč, kamera, špičky, tenisák, zvon, brána, ulice).

## Přísná kontrola varování
Godot v headless režimu GDScript varování nevypisuje. Pro kontrolu dočasně zkopíruj
`tools/strict_warnings.cfg` jako `game/override.cfg` (varování se změní na chyby), spusť
`--headless --path . --editor --quit` a pak `override.cfg` zase smaž. Výstup musí být prázdný.
