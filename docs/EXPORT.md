# Export hry (Windows .exe a Android .apk)

Předvolby exportu jsou připravené v `game/export_presets.cfg`. Hotové soubory se ukládají do složky `build/` vedle složky `game/`. Složka `build/` se na GitHub nenahrává.

## 1. Jednorázově: šablony exportu

1. V Godotu otevři **Editor → Spravovat šablony exportu…**
2. Klikni **Stáhnout a nainstalovat** (verze 4.7.2.stable). Stahování trvá pár minut.

## 2. Windows (.exe)

1. **Projekt → Exportovat…**
2. Vlevo vyber **Windows Desktop** a dole klikni **Exportovat projekt…**
3. Nech cestu `build/windows/BrunoInkShadow.exe` a odškrtni **Exportovat s laděním**, pokud chceš „čistou“ verzi.
4. Hotovo: `BrunoInkShadow.exe` je samostatný soubor (data jsou uvnitř) a jde poslat kamarádům.

## 3. Android (.apk)

Android potřebuje navíc tři věci (jednorázově):

1. **Android SDK**: nejsnáz přes [Android Studio](https://developer.android.com/studio) (stačí ho nainstalovat a jednou spustit).
2. **Java (OpenJDK 17)**: Android Studio ji obsahuje, nebo [Adoptium Temurin 17](https://adoptium.net/).
3. V Godotu **Editor → Nastavení editoru → Export → Android**:
   - *Android SDK Path*: složka SDK (obvykle `C:\Users\tomas\AppData\Local\Android\Sdk`),
   - *Java SDK Path*: složka JDK 17.
   - Ladicí klíč (debug keystore) si Godot vytvoří sám.

Pak:

1. **Projekt → Exportovat… → Android → Exportovat projekt…**
2. Soubor `build/android/BrunoInkShadow.apk` nahraj do telefonu a nainstaluj (povol instalaci z neznámých zdrojů).
3. Nebo připoj telefon kabelem (zapnuté *Ladění přes USB*) a v Godotu klikni na ikonu Androidu vpravo nahoře: hra se rovnou spustí v telefonu.

Na mobilu běží renderer **Mobile**. Komiksový vzhled funguje, dotykové ovládání se zapne samo.

## Poznámky

- Číslo verze se mění ve dvou místech: `project.godot` (`config/version`) a v předvolbách exportu (Windows: *File/Product Version*, Android: *Version Name / Code*).
- Pro vydání na Google Play bude potřeba vlastní **release keystore**. Ten se **nikdy** nenahrává na GitHub (`export_credentials.cfg` je v `.gitignore`).
