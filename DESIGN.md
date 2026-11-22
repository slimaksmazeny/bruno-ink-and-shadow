# Bruno: Ink & Shadow — Game Design Bible (`DESIGN.md`)

> **Hlavní zdroj pravdy pro vývoj (Godot 4 · Claude · Antigravity)**  
> Verze dokumentu: `v0.1.4` | Engine: **Godot 4** (GDScript + Jolt 3D + nativní 2D) | Jazyky: **Čeština (CS) + Angličtina (EN)** | Složka hry: `game/` | Vizuály: `vis/` (23 podkladů)

---

## 1. Základní koncept, Engine, Platformy & Lokalizace

**Bruno: Ink & Shadow** spojuje dva výrazné herní režimy v jednom plynulém dobrodružství:
- **3D Stealth & Parkour (styl Sly Cooper 2):** Noční Open-Hub lokace s cel-shadingem, výraznými černými obrysy a ručně malovanými texturami. Plížení po střechách, magnetické přistávání na modrých bodech, kradení klíčů, odlákávání hlídek a průzkum misijních interiérů.
- **2D Dynamická plošinovka (styl Rayman Origins / UbiArt):** Vrstvené malované 2D prostředí s parallaxem, rytmický sprint po čtyřech, plachtění na uších, houpání na kruzích a adrenalinové úniky před rozpadajícím se inkoustem.
- **Mosquito pasáže (mosty mezi kapitolami):** Boční akční střílečka na mechanickém komáru **„Šídlo“**, který spojuje jednotlivé světy bez nudné statické mapy.

### Technické pilíře (od 1. dne)
- **Engine:** **Godot 4** (GDScript), **Jolt Physics** pro 3D fyziku, nativní 2D engine pro Rayman/Mosquito pasáže.
- **Architektura pohybu:** Čistý, modulární **State Machine** (žádný špagetový monolitický skript pro pohyb).
- **Multiplatformní ovládání (jednotná `InputMap`):**
  - **PC:** klávesnice + myš
  - **Gamepad:** PS / Xbox ovladač (nativní podpora analogů i haptiky)
  - **Mobil:** poloprůhledný dotykový HUD (virtuální joystick + kontextová tlačítka)
  - *Pravidlo:* V kódu nikdy nekontrolujeme konkrétní klávesy, vždy pouze pojmenované akce z `InputMap`.
- **Bilingvní vývoj od 1. dne (CS + EN):**
  - Veškeré texty (UI, dialogy, cutscény, titulky, názvy úkolů) procházejí nativní překladovou tabulkou Godotu 4 (`res://localization/translations.csv`) přes `tr("KEY")`.
  - **Zákaz hardcoded textů v GDScriptu a scénách.**
- **Zlaté pravidlo prototypování:** Nejdřív vyladit zábavný a přesný pohyb na šedých kostkách (*Greybox*), až potom přidávat cel-shading shadery, animace a finální art.

---

## 2. Příběh, Cutscény, Postavy & Animace

### Příběh & Struktura vyprávění
Aristokratický havran **Baron Kaňka** ukradl **Prastarý štětec**, pomocí kterého uvězňuje celé čtvrti, poklady i duchy legendárních mistrů do živých obrazů. Ve 3D se Bruno plíží nočními huby a proniká do misijních interiérů; ve 2D uniká z oživlých obrazů nebo překonává inkoustové trhliny. Tón hry přirozeně graduje od hravého, komického začátku až po vážný deštivý noir.

### Cutscény ve stylu *Sly 2* „Živý komiks“
- Stylizované **2D komiksové panely** s jemným parallaxem vrstev, zvukovými efekty (šustění štětce, cinkání, noční déšť) a textovými bublinami napojenými na `.csv` lokalizaci (`CS` / `EN`).
- Reference: `vis/cutscene_intro_v01.png`.

### Hlavní postavy
- **🐾 Bruno (hráč):** Antropomorfní černý jezevčík s pálením, černo-červený obojek se zlatou šestiúhelníkovou známkou (současně design HUD životů). Dlouhé uši slouží jako vrtulník pro plachtění. Běhá a bojuje na 2 nohách; při sprintu (hlavně ve 2D) dává hůl na záda a běží rychle po 4.
- **🐿️ Kiki (parťačka):** Drzá, energická veverka-vynálezkyně s leteckými brýlemi, francouzským klíčem a vysílačkou. Naviguje Bruna v uchu, zadává střešní časovky a pilotuje mechanického komára **„Šídlo“**.
- **🎩 Baron Kaňka (hlavní záporák):** Havran v roztrhaném fialovém kabátu s monoklem a obřím Prastarým štětcem se svítícím fialovým inkoustem.
- **👻 Duchové legendárních mistrů:** Uvěznění mistři z minulosti (`vis/char_masters_v01.png`), kteří Brunovi postupně předávají nové techniky (Rail Grinding, Jiskrový výstřel, Dračí skok, Stínový průnik).

### Seznam hlavních animací Bruna
| Animace | Kontext / Režim | Popis |
| :--- | :--- | :--- |
| **Idle + Tenisák** | 3D / 2D | Klidový postoj na 2 nohách; po **5 s** nečinnosti vytáhne tenisák a začne si s ním pinkat na čumáku. |
| **Chůze / Plížení** | 3D | Pružná chůze na 2 nohách, při plížení přikrčená silueta a tichý došlap. |
| **Sprint (4 nohy)** | 3D / 2D | Hůl se přichytí na záda, Bruno přejde do rychlého běhu na všech čtyřech. |
| **Dvojskok + Ušní vrtulník** | 3D / 2D | Výskok s otočkou, při podržení skoku roztočení dlouhých uší a zpomalené plachtění. |
| **Magnet na špičky** | 3D | Přesný skok s přitažením na modrou jiskru a balancování na špičce / laně. |
| **Odpal tenisáku holí** | 3D | Nápřah a švih holí jako pálkou (míření na zvon, spínač nebo odlákání stráže). |
| **Skok do obrazu** | 3D → 2D | Stylizovaný skok do portálu s inkoustovým rozstřikem a plynulým nájezdem kamery do 2D. |
| **Sly Parkour set** | 3D (`v0.2.1`) | Šplh po okapech (`CLIMB`), plazení (`CRAWL`), ručkování po římsách (`LEDGE_HANG`), přitisknutí ke zdi (`WALL_SNEAK`), jízda po lanech (`PATH_FOLLOW`). |

---

## 3. Struktura hry — 6 Kapitol (Sly 2 Open-Hub ve 2 fázích)

Hra je rozdělena do **6 plnohodnotných kapitol** (otevřený noční 3D hub + misijní interiéry + 2D úniky + boss + Mosquito průlet) naplánovaných ve **2 vývojových fázích**:

### Fáze 1 — Kapitoly 1–3 (První plnohodnotné vydání)
| # | Kapitola | Atmosféra & Prostředí | Boss | Klíčové schopnosti |
| :-: | :--- | :--- | :--- | :--- |
| **1** | **Zátoka Bublin** | Goofy & hravý noční přístav, maják, barevné 2D úniky | **Šéfkuchař Ropuch** *(Žabí hlídači)* | Ušní vrtulník (plachtění), Běh po zdech ve 2D |
| **2** | **Měděný kaňon** | Dobrodružný steampunk western, parní vlaky, měděné rokle | **Šerif Píst** *(Steampunk stráže)* | Rail Grinding, Jiskrový výstřel (odrážení tenisáku ve zpomaleném čase) |
| **3** | **Zrcadlový karneval** | Noční Benátky, kanály, masky, zrcadlové iluze a lustry | **Hraběnka Škraboška** *(Maskované hlídky)* | Zrcadlový úhyb / přitisknutí ke stínům, pokročilé houpání na kruzích |

### Fáze 2 — Kapitoly 4–6 (Rozšíření & Finále)
| # | Kapitola | Atmosféra & Prostředí | Boss | Klíčové schopnosti |
| :-: | :--- | :--- | :--- | :--- |
| **4** | **Zamrzlá knihovna** | Zasněžené věže, zamrzlé střechy, kluzké inkoustové regály | **Archivistka Můra** *(Tiché hlídky)* | Ledové skluzavky, tichý dopad z výšky |
| **5** | **Továrna na barvy** | Průmyslový komplex, barevná potrubí, lasery a písty | **Inženýr Štětka** *(Průmyslové stráže)* | Stínový průnik přes lasery, magnet na pohyblivá potrubí |
| **6** | **Inkoustová citadela** | Deštivý temný noir, gotická katedrála z tekutého inkoustu | **Baron Kaňka** *(dvoufázový 3D + 2D souboj)* | Dračí skok ze špičky na špičku, kombinace všech schopností |

---

## 4. Úkryt (Safe House), Interiéry & Sidequesty

### 🏠 Úkryt (Safe House) & Misijní interiéry
- **Úkryt v každé kapitole:** Bezpečná základna v rámci 3D hubu. Slouží k převlékání odemčených oblečků (`vis/char_bruno_outfits_v01.png`), prohlížení vitríny s trofejemi Zlatých tenisáků a plánovací tabuli hlavní loupeže.
- **Samostatné 3D misijní interiéry:** Uzavřené tematické lokace (např. *Ropuchova kuchyně*, *vnitřek majáku*, *vagóny parního vlaku*, *zrcadlový sál*) oddělené **inkoustovým střihem** (rychlý přechod scény pro vysoký výkon i na mobilu).
- **Tajný trezor:** V každé kapitole je zamčený trezor, jehož kód odemkne sesbírání všech modrých lahviček s inkoustem v hubu.

### 🎯 4 typy Sidequestů v každém Open-Hubu
1. **Kikiiny časovky po střechách:** Rychlostní parkour tratě přes modré jiskry a římsy na čas.
2. **Tenisáková střelnice:** Najdi a odpalem tenisáku rozezvuč **5 skrytých zvonů / terčů** rozmístěných po hubu.
3. **Zlodějské zakázky:** Tiché plížení a krádež speciálního klíče od pasu elitní hlídky bez spuštění alarmu.
4. **Tajné 2D trhliny:** Skryté inkoustové portály vedoucí do náročných Rayman 2D výzev — odměnou jsou tajné klece s oblečky a Zlaté tenisáky.

---

## 5. Zbraň & Kompletní 3D Movement Kit (Sly Cooper styl)

### 🖋️ Originální hůl & 🎾 Neonový tenisák
- **Hůl:** Zahnutý hák ve tvaru **hrotu plnicího pera** se svítícím inkoustem, černo-červená omotávka obojku a kovová kůstka na konci (`vis/props_cane_tennisball_v01.png`). Funkce: boj, kradení klíčů, páčení, magnet na modré jiskry, houpání na kruzích ve 2D.
- **Neonový tenisák:** Bruno ho odpaluje holí jako pálkou (`vis/action_bruno_tennisball_v01.png`). Ve 3D láká hlídky a spouští zvony/tlačítka; ve Světě 2 (*Jiskrový výstřel*) se ve zpomaleném čase odráží mezi více cíli.

### ⚙️ Architektura 3D pohybu — State Machine
Kontextové tlačítko **Hák / Akrobacie** (např. `E` / `B` / `○` / dotykové tlačítko) aktivuje parkour stav u nejbližší **modré jiskry**:

| Stav State Machine | Spouštěč / Kontext | Chování | Milník |
| :--- | :--- | :--- | :---: |
| `IDLE` / `MOVE` | Běžný pohyb na zemi | 2 nohy, plížení, po 5 s idle pinkání tenisákem | `v0.2.0` |
| `SPRINT_4LEGS` | Podržení sprintu | Hůl na záda, rychlý běh na 4 nohách | `v0.2.0` |
| `JUMP` / `GLIDE` | Skok / podržení ve vzduchu | Dvojskok + Ušní vrtulník (zpomalený pád) | `v0.2.0` |
| `SPIRE_PERCH` | Hák u modré špičky | Magnetické přitažení a balancování na špičce/komínu | `v0.2.0` |
| `TENNIS_SWING` | Akce tenisáku | Zamíření a odpal neonového tenisáku holí | `v0.2.0` |
| `CLIMB` | Hák u okapu / trubky | Vertikální šplhání po okapech a potrubí | `v0.2.1` |
| `CRAWL` | Plazení pod stolem / laserem | Nízký profil (jezevčík se protáhne úzkými otvory) | `v0.2.1` |
| `LEDGE_HANG` | Hák / zachycení u římsy | Ručkování do stran po římsách a vyšvihnutí nahoru | `v0.2.1` |
| `WALL_SNEAK` | Hák u zdi | Přitisknutí ke zdi, vyklonění za roh a nenápadný přesun | `v0.2.1` |
| `PATH_FOLLOW` | Hák u lana / kolejnice | Balancování po lanech (Svět 1) a Rail Grinding (Svět 2) | `v0.2.1` |
| `HOOK_SWING` | Hák u závěsného kruhu | Kyvadlové zhoupnutí a katapult přes propast | `v0.2.1` |

**Rozfázování implementace v Godotu 4:**
- **`v0.2.0` (Greybox Základ):** Založení Godot 4 projektu v `game/`, `InputMap` (PC + Gamepad + Mobil), `.csv` lokalizace CS/EN, 3D ulice (pohyb, dvojskok, ušní vrtulník, magnet na špičky, odpal tenisáku), plynulý přechod 3D → 2D a krátký 2D únik.
- **`v0.2.1` (Sly Parkour Update):** Rozšíření State Machine o `CLIMB` (okapy/trubky), `CRAWL` (plazení pod stoly a lasery), `LEDGE_HANG` (římsy), `WALL_SNEAK` (stěny), `PATH_FOLLOW` (lana/kolejnice) a `HOOK_SWING`.

---

## 6. Kompletní 2D Platform Kit (Rayman Origins styl)

Ve 2D pasážích skládáme levely z modulárních, znovupoužitelných Godot scén (`.tscn`):
1. **`BouncyMushroom.tscn` (Skákací houby & bubny):** Elastický odraz s nastavitelným směrem a silou + squash-and-stretch animací.
2. **`OneWayPlatform.tscn` (Průchozí plošiny):** Skok zespodu nahoru bez kolize, možnost propadnout dolů.
3. **`CrumblingInkPlatform.tscn` (Rozpadající se plošiny v inkoustu):** Po došlapu se zatřesou a po krátké prodlevě roztečou do inkoustu.
4. **`WindCurrent.tscn` (Větrné / parní proudy):** Vztlakové zóny určené pro kombinaci s **Ušním vrtulníkem**.
5. **`SwingRing.tscn` (Houpací kruhy na hůl):** Zachycení zahnutým perem hole, nabrání hybnosti a vymrštění vpřed.
6. **`WallRunSlide.tscn` (Stěny na běh & skluzavky):** Dynamický běh po svislé stěně při sprintu a rychlé skluzavky.
7. **`RhythmPiston.tscn` (Rytmické / pohyblivé písty):** Časované plošiny a písty synchronizované do rytmu úniku.

---

## 7. Sběratelské předměty, Mapa světa, Minimapa & HUD

### ✨ Sběratelské předměty (`vis/props_collectibles_v01.png`)
- **Modré lahvičky s inkoustem (3D):** Jemně cinkají v prostoru; sesbírání všech v kapitole odemyká tajný trezor.
- **Zlaté kapky inkoustu s křídly (2D):** Originální sběratelské body (nahrazují cizí Lumy) — vedou trasu skoků a odměňují rytmus.
- **Tajné klece se skřítky (2D):** Skryté v odbočkách a 2D trhlinách; odemykají nové oblečky pro Bruna.
- **Tajný Zlatý tenisák (3D/2D):** Přesně **1 kus v každém levelu** jako výzva pro 100 % dohrání (vystavený v Úkrytu).

### 🗺️ Mapa světa, 3D Minimapa & HUD
- **Atlas světů (`vis/ui_worldmap_v01.png`):** Interaktivní mapa 3 (ve Fázi 2 všech 6) kapitol propojených trasou letu mechanického komára *Šídlo*.
- **3D Minimapa (vpravo nahoře):** Stylizovaný noční radar s **červenými kužely zorného pole hlídek**, **zlatým bodem aktuálního úkolu** a **modrým pingem blízkých lahviček**.
- **3D Navigační paprsek:** Volitelný svislý zlatý paprsek ve světě s ukazatelem vzdálenosti k cíli (inspirace *Sly 2* binokulárem/kompasem).
- **HUD (`vis/ui_hud_mockup_v01.png`):**
  - Vlevo nahoře: **Zlatá šestiúhelníková známka z obojku** rozdělená na **3 dílky životů** + indikátor nabití **tenisáku**.
  - Počítadlo modrých lahviček (3D) / Zlatých kapek (2D).
  - Na mobilních zařízeních automaticky zobrazené poloprůhledné dotykové ovládání.

---

## 8. Pravidla originality & Vizuální knihovna (`vis/`)

- **Čistý noční měsíc:** Měsíc na obloze je vždy čistý — bez jakýchkoli cizích log či symbolů.
- **Originální hůl:** Vždy hrot plnicího pera se svítícím inkoustem, černo-červená omotávka a kovová kůstka.
- **Vlastní sběratelské prvky:** Výhradně **Zlaté kapky inkoustu s křídly** (nikoli Lumové).
- **Vizuální reference:** Kompletní schválená sada **23 podkladů** (logo, ikona, HUD mockup, mapa světa, komiksové intro, 3D & 2D gameplay mockupy, postavy, oblečky, mistři, nepřátelé, světy, zbraně a Šídlo) je uložena ve složce `vis/` a přehledně katalogizována v [index.html](index.html#vizualy).
