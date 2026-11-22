# Bruno: Ink & Shadow — Game Design Bible (`DESIGN.md`)

> **Hlavní zdroj pravdy pro vývoj v Godot 4** | Verze dokumentu: `v0.1.3` | Engine: **Godot 4** | Projektová složka hry: `game/`

---

## 1. Základní koncept

**Bruno: Ink & Shadow** je stylizovaná akční plošinovka, která v jednom plynulém zážitku spojuje dva žánry a vizuální směry:

- **3D Stealth & Parkour (styl Sly Cooper 2):** Noční lokace s cel-shadingem, výraznými černými obrysy a ručně malovanými texturami. Plížení po střechách, magnetické přistávání na modrých bodech, kradení klíčů a chytré odlákávání hlídek.
- **2D Dynamická plošinovka (styl Rayman Origins / UbiArt):** Vrstvené malované 2D prostředí s parallaxem, rytmický běh, plachtění, houpání na kruzích a adrenalinové úniky před rozpadajícím se inkoustem.
- **Mosquito pasáže (mosty mezi světy):** Akční boční střílečka na mechanickém komáru „Šídlo“, která spojuje 3 hlavní světy bez nudné statické mapy.

**Technická zásada vývoje:** Nejdřív vyladit zábavný, přesný pohyb na šedých kostkách (*Greybox*), až potom řešit shadery, animace a finální grafiku.

---

## 2. Příběh

Aristokratický havran **Baron Kaňka** ukradl **Prastarý štětec**, pomocí kterého uvězňuje celé čtvrti, poklady i duchy tří legendárních mistrů do živých obrazů.

- Ve **3D nočních lokacích** se Bruno plíží do nepřátelských území, sbírá stopy a proniká k obrazům/kořisti.
- Ve **2D pasážích** uniká z oživlých rozpadajících se obrazů nebo dynamicky přechází mezi lokacemi.
- Tón příběhu graduje od hravého, komického startu (**Svět 1**) přes dobrodružný steampunk (**Svět 2**) až po vážný, deštivý temný noir (**Svět 3**).

---

## 3. Hlavní postavy

### 🐾 Bruno (hráč)
- **Vzhled:** Antropomorfní černý jezevčík s pálením, černo-červený obojek se zlatou šestiúhelníkovou známkou (slouží i jako designový prvek HUD životů).
- **Uši:** Dlouhé uši fungují jako vrtulník pro plachtění vzduchem.
- **Pohyb (hybridní postoj):**
  - Na **dvou nohách**: standardní chůze, plížení, skákání po špičkách, boj a míření holí.
  - Na **všech čtyřech**: při sprintu (zejména ve 2D únicích) si Bruno připne hůl na záda a běží rychle po čtyřech.
- **Idle animace:** Když hráč chvíli nic nedělá, Bruno si začne pinkat neonovým tenisákem na čumáku.

### 🐿️ Kiki (parťačka)
- **Vzhled:** Drzá, energická veverka-vynálezkyně s leteckými brýlemi, vysílačkou a francouzským klíčem.
- **Role:** Radí Brunovi přes vysílačku v uchu během 3D misí a pilotuje mechanického komára **„Šídlo“** v Mosquito pasážích mezi světy.

### 🎩 Baron Kaňka (hlavní záporák)
- **Vzhled:** Aristokratický havran v roztrhaném fialovém kabátu s monoklem a obřím Prastarým štětcem se svítícím fialovým inkoustem.

---

## 4. Zbraň a hlavní mechaniky

### 🖋️ Originální hůl
- **Design:** Zahnutý hák ve tvaru **hrotu plnicího pera** se svítícím inkoustem, černo-červená omotávka ve stylu Brunova obojku a kovová kůstka na konci.
- **Herní funkce:**
  - Boj nablízko (komba, odrážení nepřátel).
  - Kradení klíčů od pasu hlídek a páčení zámků/truhlic.
  - **Magnetické zachytávání** na modré třpytky (špičky střech, lana, komíny, háky) ve 3D.
  - Houpání na kruzích ve 2D plošinovkových pasážích.

### 🎾 Neonový tenisák
- **Mechanika:** Bruno ho odpaluje holí jako pálkou.
- **Použití ve 3D:** Odlákání stráží zvukem, trefování zvonů, spínačů a vzdálených tlačítek.
- **Použití ve Světě 2 (Jiskrový výstřel):** Odrážení tenisáku mezi více cíli ve zpomaleném čase.
- **Bonusová vrstva:** Idle animace pinkání na čumáku + 1 skrytý **Zlatý tenisák** v každém levelu pro 100% dohrání.

### 🎥 Přechod 3D ↔ 2D
- Plynulý nájezd kamery ze 3D perspektivy do bočního 2D pohledu (bez tvrdého střihu/loading screenu tam, kde to level dovolí).
- 2D pasáže slouží podle konkrétního levelu buď jako **únik z oživlého obrazu po sebrání kořisti**, nebo jako **dynamický přechod mezi lokacemi**.

---

## 5. Struktura 3 světů & progrese schopností

| Svět | Atmosféra & Prostředí | Nepřátelé & Boss | Odemčené schopnosti |
| :--- | :--- | :--- | :--- |
| **Svět 1: Zátoka Bublin** | Goofy & hravý noční přístav + barevné 2D úniky | Žabí hlídači, Boss: **Šéfkuchař Ropuch** | **Ušní vrtulník** (plachtění), **Běh po zdech** ve 2D |
| **Svět 2: Měděný kaňon** | Dobrodružný steampunk, parní vlaky a kaňony | Steampunkové hlídky, Boss: **Šerif Píst** | **Rail Grinding**, **Jiskrový výstřel** (odrážení tenisáku ve zpomaleném čase) |
| **Svět 3: Inkoustová citadela** | Vážný temný noir, deštivá noc, katedrála z inkoustu | Elitní inkoustové stráže, Boss: **Baron Kaňka** (dvoufázový 3D + 2D souboj) | **Dračí skok** (ze špičky na špičku), **Stínový průnik** (průchod přes lasery) |

**Mezihry mezi světy:** Mosquito pasáže na mechanickém komáru **„Šídlo“** (pilotuje Kiki) — nasávání nepřátel/projektilů a jejich vystřelování zpět.

---

## 6. Sběratelské předměty

- **Modré lahvičky s inkoustem (3D):** Jsou slyšet jemným cinkáním; po sebrání všech v lokaci odemykají trezor s novým vylepšením.
- **Zlaté kapky inkoustu s křídly (2D):** Originální sběratelské body, které přirozeně vedou trasu skoků a odměňují rytmus pohybu.
- **Tajné klece se skřítky (2D):** Skryté odbočky ve 2D pasážích; odemykají alternativní oblečky pro Bruna.
- **Zlatý tenisák (3D/2D):** Přesně **1 tajný Zlatý tenisák v každém levelu** jako výzva pro 100% dohrání.

---

## 7. První milník — Vertical Slice (Vlna 2)

Cílem Vlny 2 je postavit co nejrychlejší **hratelný Greybox prototyp** v `game/` (Godot 4), bez finální grafiky:

1. **Mini 3D ulice (Greybox):**
   - Základní 3D pohyb Bruna (`CharacterBody3D`), skok, kamera.
   - Základní švih holí a **magnet na modré špičky/body** (přistání na úzký bod s indikací).
   - Jednoduché **odpalování tenisáku holí** na testovací cíl (zvon/spínač).
2. **Plynulý přechod 3D → 2D:**
   - Trigger zóna, která plynule přejede kamerou do bočního pohledu a uzamkne pohyb do 2D roviny.
3. **Krátký 2D únik (Greybox):**
   - Sprint po čtyřech, skákání přes mezery a **plachtění pomocí ušního vrtulníku** (zpomalený pád ve vzduchu).

---

## 8. Pravidla pro originalitu a vizuální čistotu

- **Čistý noční měsíc:** Měsíc na obloze je vždy čistý — bez jakýchkoli cizích log či symbolů.
- **Originální hůl:** Vždy hrot plnicího pera se svítícím inkoustem, černo-červená omotávka a kůstka na konci (nikoli cizí symboly).
- **Vlastní sběratelské prvky:** Ve 2D používáme výhradně vlastní **Zlaté kapky inkoustu s křídly** (nikoli Lumy).
- **Referenční concept art:** Kompletní schválená sada vizuálů je uložena ve složce `vis/`.
