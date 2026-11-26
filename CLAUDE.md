# Bruno: Ink & Shadow – pravidla pro Clauda

Hybrid 3D stealth/parkour + 2D plošinovka, Godot 4.7.2, GDScript, Jolt. Autor: Tomáš (sólo vývojář), komunikace česky.
Podrobnosti: `ARCHITECTURE.md`, `DESIGN.md`. Godot skilly: `.claude/skills/` (godot-code-gen, godot-scene-design,
godot-shader, godot-interactive, godot-live-edit, godot-testing – MIT, viz LICENSE-*).

## Priorita: kvalita před šířkou
- Nejdřív doladit to, co existuje (pocit, kamera, čitelnost), teprve pak nové funkce.
- Malé kroky. Každý krok = funkční commit + push.
- „Hotovo“ se smí říct až po ověření ve hře (viz smyčka níže), ne jen po zelených testech.

## Povinná ověřovací smyčka
1. **Strict načtení**: `cp ../tools/strict_warnings.cfg override.cfg`, editor `--quit`, `check_strict_load.gd`, `rm override.cfg` – nula warningů.
2. **Headless testy** `tools/tests/*.gd` (regrese, počítat `SCRIPT ERROR|FAIL`). Ke každé nové mechanice test
   + aspoň 2 kontroly mimo „šťastnou cestu“ (smrt, checkpoint, respawn, vyřazení klíčové postavy…).
3. **Vizuální kontrola**: render (xvfb) nebo screenshot z běžící hry (Godot AI MCP / ovládání PC, je-li k dispozici).
   Hlídat: orientace a náklon postavy, kamera (nesmí do objektů), čitelnost HUD, překryvy UI.
4. Na Tomášově PC jen po jeho svolení. Při chybě opravit a smyčku opakovat.

## Kód a scény
- Striktně typovaný GDScript 4.x (typy proměnných i návratové typy), žádné shadowing built-inů, `int(float(x)*0.5)` místo celočíselného dělení.
- `.tscn` levelů se needitují ručně – generují je skripty v `tools/generators/` (exportované reference nastavovat jako objekty, ne NodePath).
- **Hráč (`Player`) se nikdy neotáčí** – směr drží jen `PlayerVisual` (`face_direction`). V levelech hráče neotáčet.
- Testy v `--script` režimu: netypované proměnné pro autoloady, `Input.is_action_just_pressed` nefunguje (použít jump buffer / přímé volání).
- Vstupy z klávesnice: číst `physical_keycode`, záložně `keycode`.

## Hra a design
- Žádné ochranné známky v souborech hry (Sly, Rayman, UbiArt…); zvuky i hudba vlastní (generované).
- Nesmí existovat softlock: vyřazení/ smrt / checkpoint nesmí znemožnit dohrání levelu.
- Herní doba: 6 kapitol × ~1,5 h příběh / ~2,5 h na 100 %.

## Repo
- Neukládat tajnosti (`export_credentials.cfg` je v .gitignore).
- `index.html` (studio centrum): zachovat localStorage klíče `bruno_ink_shadow_v1` a `bruno_roadmap_v015`; deník `log_NNN` nejnovější nahoře.
- Verze: `config/version` v project.godot, `(vX)` v translations.csv, export_presets.cfg (verze + code).
