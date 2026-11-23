# Bruno: Ink & Shadow — Technická architektura (`ARCHITECTURE.md`)

> **Zdroj pravdy pro kód v `game/`.** `DESIGN.md` říká *co* hra dělá, tento dokument říká *jak* je to postavené.
> Verze dokumentu: `v0.2.0-arch.1` (doplněno při Kroku A: autoload DebugOverlay, akce `debug_toggle_language`, `*.translation` se negenerují do gitu) · Autor: Claude (architekt) · Schvaluje: Tomáš · Implementuje: Claude (záloha: Antigravity)
> Při rozporu mezi tímto dokumentem a roadmapou v `index.html` platí tento dokument (cesty k souborům jsou zde aktualizované).

---

## 0. TL;DR — 10 rozhodnutí, která platí od 1. dne

1. **Engine:** Godot **4.7.x stable, standardní build (ne .NET)**. Verzi zapsat do `README.md`. Na 4.8 přejít až po vydání 4.8.1, jen mezi milníky a po commitu.
2. **Jeden hráč pro 3D i 2D:** jediný `CharacterBody3D`. 2D pasáže jsou **2.5D v 3D prostoru** (pohyb uzamčený do roviny). Žádná `CharacterBody2D` verze Bruna.
3. **Stavy nevědí, jestli je hra ve 3D nebo 2D.** Režim řeší hráč (`player.gd`) a jeho pohybový profil (`MovementProfile` `.tres`).
4. **Pouze `player.gd` volá `move_and_slide()`** — jednou za fyzikální snímek. Stavy jen nastavují `velocity`.
5. **Parkour = systém kotev (Anchor).** Modré jiskry jsou `Anchor` uzly s typem. `v0.2.0` má jediný typ `SPIRE`; `v0.2.1` jen přidá typy + stavy, jádro se nemění.
6. **Kamera = jedna `Camera3D` míchající dva „rigy“** (3D third-person a 2D side-scroll), které běží pořád. Přechod = tween jednoho čísla `blend` 0 → 1.
7. **Směr pohybu ve 3D se počítá z yaw 3D rigu, ne ze skutečné kamery** → během přechodu se ovládání nikdy „nepřetočí“.
8. **Vstupy jen přes `InputMap` akce.** Dotykový HUD akce *mačká* (`Input.action_press`, `TouchScreenButton.action`), takže stavy nepoznají rozdíl mezi klávesnicí, ovladačem a prstem.
9. **Texty jen přes klíče** v `localization/translations.csv` (UTF-8). Uložené hry = JSON s `save_version`, sbírané předměty se ukládají **jako ID, ne jako počty**.
10. **Mobil od začátku:** renderer *Forward+* na PC, *Mobile* na Androidu (override). Obrysy cel-shadingu později **inverted hull** (ne post-process). Světla oken = emise, ne skutečná světla.

---

## 1. Volba enginu — sanity check

**Verdikt: Godot 4 je pro tenhle projekt a AI-driven workflow správná volba.** Hlavní důvody:

- Scény (`.tscn`), zdroje (`.tres`) i `project.godot` jsou **čitelný text** → Antigravity je umí vytvářet, číst a opravovat. Unity scény/prefaby jsou YAML s GUID odkazy, které AI agent snadno rozbije.
- GDScript je malý jazyk s malým API povrchem; AI v něm chybuje méně než v Unity C# + balíčcích.
- Jolt je od Godotu 4.6 výchozí 3D fyzika nových projektů → žádné experimentální nastavení.
- Bez licenčních poplatků, malé stažení, rychlé spuštění — ideální pro iterace „vygeneruj → F5 → zkontroluj“.

**Skryté limity, na které musíme myslet hned (a jak je obejdeme):**

| Riziko | Proč | Opatření od 1. dne |
| :--- | :--- | :--- |
| **AI míchá Godot 3 a Godot 4 syntaxi** | Nejčastější zdroj chyb | Pravidla v sekci 10 (tabulka zakázané syntaxe) + typovaný GDScript |
| **Cel-shading obrysy na Androidu** | Renderer *Mobile* nemá screen-space normal buffer → post-process obrysy jsou drahé/nefunkční | Obrysy metodou **inverted hull** (`next_pass` materiál, `cull_front`, roztažení po normálách). Funguje všude, je levná |
| **Hodně světel v noční scéně** | Mobile renderer má limit světel na objekt; každé světlo stojí | Okna, lucerny = **emisivní textury**. Kužely baterek hlídek = **průhledný mesh kužele** (+ max. 1 skutečné SpotLight u nejbližší hlídky) |
| **Velké průhledné 2D vrstvy (UbiArt parallax)** | Overdraw je na mobilu nejdražší věc | Vrstvy ořezávat na tvar (ne celé obdélníky), max ~4–5 překrývajících se průhledných vrstev |
| **Kompilace shaderů na Androidu (záseky)** | První zobrazení materiálu | Málo unikátních materiálů (sdílený cel shader s parametry), warm-up při načítání levelu |
| **Konzole (PS/Switch/Xbox)** | Godot je neexportuje nativně (jen přes třetí strany) | Teď neřešíme; jen vědět, že cíl je PC + Android |
| **iOS** | Export vyžaduje Mac | Mimo rozsah |

---

## 2. Hráč: jeden `CharacterBody3D` pro 3D i 2D

### 2.1 Proč ne dvě postavy (3D + 2D)
- Přechod 3D ↔ 2D je **plynulý tween**, ne střih. Výměna dvou různých těles uprostřed tweenu = teleport, ztráta rychlosti, dvojí kód pro dvojskok/plachtění/sprint.
- Schopnosti (`Air`, `Glide`, `Sprint`) jsou ve 3D i 2D **stejná logika s jinými čísly**. Jedna implementace = jedno místo pro opravy.
- 2D vrstvy jako `Sprite3D`/quady v různé hloubce dávají **parallax zdarma** (skutečná perspektiva).
- Jedna fyzika (Jolt), jedny kolizní vrstvy, jeden debug overlay.

### 2.2 Jak funguje 2D režim
- Portál nastaví hráči **2D rovinu**: `plane_origin: Vector3` a `plane_normal: Vector3` (vodorovný vektor kolmý na rovinu, kterou vidí kamera). V greyboxu prostě `plane_normal = Vector3.BACK`.
- Po každém `move_and_slide()` hráč odstraní složku rychlosti podél normály a vrátí pozici do roviny (chrání před driftem fyziky).
- Vstup se v 2D promítne jen na osu „vpravo v rovině“ (`plane_right = Vector3.UP.cross(plane_normal)`), svislá osa páčky slouží pro „dolů“ (propadnutí one-way plošinou, později).
- Hráč má aktivní **`MovementProfile`** — `profile_3d.tres` (Sly: měkčí zrychlení, nižší gravitace) a `profile_2d.tres` (Rayman: ostré zrychlení, vyšší gravitace, kratší skoky). **Tomáš ladí feel v Inspectoru bez kódu.**

```gdscript
# player/movement_profile.gd
class_name MovementProfile
extends Resource

@export_group("Ground")
@export var walk_speed: float = 4.0
@export var sneak_speed: float = 2.0
@export var sprint_speed: float = 9.0
@export var ground_accel: float = 30.0
@export var ground_decel: float = 40.0
@export_group("Air")
@export var jump_height: float = 2.2
@export var double_jump_height: float = 1.6
@export var gravity: float = 28.0
@export var fall_gravity_mult: float = 1.6
@export var air_accel: float = 14.0
@export var max_fall_speed: float = 30.0
@export_group("Glide (Ušní vrtulník)")
@export var glide_fall_speed: float = 2.5
@export var glide_air_speed: float = 6.0
@export_group("Forgiveness")
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.12
```

### 2.3 Hlavní smyčka hráče (jediné místo s `move_and_slide`)

```gdscript
# player/player.gd  (zkrácené jádro)
class_name Player
extends CharacterBody3D

enum Mode { MODE_3D, MODE_2D }

@export var profile_3d: MovementProfile
@export var profile_2d: MovementProfile
@export var camera_rig_path: NodePath   # ThirdPersonRig v levelu

var mode: Mode = Mode.MODE_3D
var profile: MovementProfile
var plane_origin := Vector3.ZERO
var plane_normal := Vector3.BACK
var jumps_used: int = 0
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0

@onready var state_machine: PlayerStateMachine = $StateMachine
@onready var anchor_detector: AnchorDetector = $AnchorDetector
@onready var visual: PlayerVisual = $Visual
var camera_rig: ThirdPersonRig

func _ready() -> void:
	profile = profile_3d
	camera_rig = get_node(camera_rig_path) as ThirdPersonRig
	state_machine.setup(self)

func _physics_process(delta: float) -> void:
	_update_timers(delta)
	state_machine.physics_update(delta)
	if mode == Mode.MODE_2D:
		velocity -= plane_normal * velocity.dot(plane_normal)
	move_and_slide()
	if mode == Mode.MODE_2D:
		var offset := (global_position - plane_origin).dot(plane_normal)
		global_position -= plane_normal * offset

func _update_timers(delta: float) -> void:
	coyote_timer = profile.coyote_time if is_on_floor() else maxf(coyote_timer - delta, 0.0)
	if Input.is_action_just_pressed(&"jump"):
		jump_buffer_timer = profile.jump_buffer_time
	else:
		jump_buffer_timer = maxf(jump_buffer_timer - delta, 0.0)

## Jediná funkce, kterou stavy používají pro směr pohybu. Neví nic o zařízení.
func get_move_dir() -> Vector3:
	var raw := Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	if mode == Mode.MODE_2D:
		var plane_right := Vector3.UP.cross(plane_normal).normalized()
		return plane_right * raw.x
	var yaw_basis := Basis(Vector3.UP, camera_rig.get_yaw())   # yaw 3D rigu, NE kamery
	return yaw_basis * Vector3(raw.x, 0.0, raw.y)

func consume_jump_buffer() -> bool:
	if jump_buffer_timer > 0.0:
		jump_buffer_timer = 0.0
		return true
	return false

func enter_2d(origin: Vector3, normal: Vector3) -> void:
	mode = Mode.MODE_2D
	plane_origin = origin
	plane_normal = normal.normalized()
	profile = profile_2d
	Events.player_mode_changed.emit(mode)

func enter_3d() -> void:
	mode = Mode.MODE_3D
	profile = profile_3d
	Events.player_mode_changed.emit(mode)
```

### 2.4 State Machine — hierarchie, která se nerozsype

**Princip:** plochý FSM (žádné hluboké vnořování), stavy jako uzly-děti `StateMachine`, sdílené chování ve **třech základních třídách**:

```
PlayerState (state.gd)                 ← společné API
├── GroundedState  → Idle, Move, Sprint            (na zemi: skok, pád z hrany, kotvy)
├── AirborneState  → Air, Glide                    (ve vzduchu: dvojskok, plachtění, kotvy)
├── AnchorState    → Perch            [v0.2.0]     (připnutý ke kotvě)
│                  → Climb, LedgeHang, WallSneak,
│                    PathFollow, HookSwing [v0.2.1] ← jen se „docvaknou“
├── Swing                                          (odpal tenisáku holí)
└── Locked                                         (cutscéna / přechod 3D↔2D, ignoruje vstup)
```

**Stavy pro `v0.2.0` (8):** `Idle`, `Move` (chůze/plížení podle síly páčky), `Sprint` (4 nohy), `Air` (skok + dvojskok + pád, počítadlo `jumps_used`), `Glide`, `Perch`, `Swing`, `Locked`.
Záměrně **ne** zvlášť `Jump` / `DoubleJump` / `Fall` — jeden `Air` stav s počítadlem znamená méně přechodů a méně bugů.

**`Crawl` v `v0.2.1`** nebude kotva, ale `GroundedState` s nízkou kolizí — proto hráč už v `v0.2.0` dostane dvě kolize (`CollisionStand` aktivní, `CollisionLow` vypnutá) a funkci `set_posture()`.

```gdscript
# core/state_machine/player_state.gd
class_name PlayerState
extends Node

var player: Player
var machine: PlayerStateMachine

func enter(_previous: StringName, _msg: Dictionary = {}) -> void:
	pass
func exit() -> void:
	pass
func physics_update(_delta: float) -> void:
	pass
```

```gdscript
# core/state_machine/player_state_machine.gd
class_name PlayerStateMachine
extends Node

signal state_changed(from: StringName, to: StringName)

@export var initial_state: PlayerState
var current: PlayerState
var _states: Dictionary[StringName, PlayerState] = {}

func setup(p: Player) -> void:
	for child in get_children():
		if child is PlayerState:
			var s := child as PlayerState
			s.player = p
			s.machine = self
			_states[StringName(s.name)] = s
	current = initial_state
	current.enter(&"", {})

func physics_update(delta: float) -> void:
	current.physics_update(delta)

func transition_to(target: StringName, msg: Dictionary = {}) -> void:
	if not _states.has(target):
		push_error("StateMachine: unknown state '%s'" % target)
		return
	var next: PlayerState = _states[target]
	if next == current and not msg.get("force", false):
		return
	var prev: StringName = StringName(current.name)
	current.exit()
	current = next
	current.enter(prev, msg)
	state_changed.emit(prev, target)
```

**Pravidla pro stavy (závazná):**
- Stav **nikdy** nevolá `move_and_slide()`, `Input.is_key_pressed()` ani nečte konkrétní zařízení.
- Přechod vždy `machine.transition_to(&"Name", {...})`, jména stavů = jména uzlů (`StringName`).
- Společná logika (gravitace, horizontální zrychlení, kontrola kotvy) žije v `GroundedState` / `AirborneState`, ne kopírovaná v každém stavu.
- Každý stav ≤ ~80 řádků. Delší = rozdělit nebo přesunout logiku do základní třídy.

### 2.5 Systém kotev (modré jiskry) — klíč k čistému `v0.2.1`

```gdscript
# world/anchors/anchor.gd
class_name Anchor
extends Area3D

enum Type { SPIRE, PIPE, LEDGE, ROPE, WALL, RING }   # v0.2.0 používá jen SPIRE
@export var type: Type = Type.SPIRE
@export var snap_point: Marker3D        # kam se Bruno přitáhne
@export var only_in_3d: bool = true

func get_snap_position(_from: Vector3) -> Vector3:
	return snap_point.global_position   # LEDGE/ROPE v0.2.1 přepíšou na nejbližší bod úsečky
```

- `AnchorDetector` (Area3D koule ~4 m na hráči) drží seznam kotev v dosahu a vybírá **nejlepší** (vzdálenost + směr pohledu + kotva nad/před hráčem). Nejlepší kotvě zapne modré jiskry (zvýraznění).
- `GroundedState` i `AirborneState` při `action` zavolají jednu sdílenou funkci:

```gdscript
const ANCHOR_STATES := {
	Anchor.Type.SPIRE: &"Perch",
	# v0.2.1 – jen přidat řádky:
	# Anchor.Type.PIPE: &"Climb", Anchor.Type.LEDGE: &"LedgeHang",
	# Anchor.Type.WALL: &"WallSneak", Anchor.Type.ROPE: &"PathFollow", Anchor.Type.RING: &"HookSwing",
}

func try_enter_anchor() -> bool:
	var a := player.anchor_detector.best_anchor()
	if a == null or not ANCHOR_STATES.has(a.type):
		return false
	machine.transition_to(ANCHOR_STATES[a.type], {"anchor": a})
	return true
```

**`v0.2.1` tedy = nové typy kotev + nové stavy + nové řádky v tabulce.** `Player`, `StateMachine`, kamera ani vstupy se nemění.

---

## 3. Kamera a přechod 3D ↔ 2D (`camera/hybrid_camera.gd`)

### 3.1 Struktura
```
HybridCamera (Node3D, hybrid_camera.gd)        ← v levelu, NE jako dítě hráče
├── ThirdPersonRig (Node3D, third_person_rig.gd)
│   └── YawPivot → PitchPivot → SpringArm3D → CameraPoint (Marker3D)
├── SideScrollRig (Node3D, side_scroll_rig.gd)
│   └── CameraPoint (Marker3D)
└── Camera3D                                   ← jediná skutečná kamera
```
- **Oba rigy se aktualizují každý snímek**, i když je jejich váha 0. 3D rig čte vstup myši/páčky jen když je hráč v 3D.
- Kamera v `_process` čte `player.get_global_transform_interpolated()` a je zapnutá **physics interpolation** (projektové nastavení) → žádné cukání při 60 Hz fyzice a 120 Hz monitoru.

### 3.2 Míchání (blend) a tween

```gdscript
# camera/hybrid_camera.gd  (jádro)
class_name HybridCamera
extends Node3D

@export var fov_3d: float = 70.0
@export var fov_2d: float = 32.0          # úzké FOV + větší vzdálenost = „zploštění do obrazu“
@export_range(0.0, 1.0) var blend: float = 0.0

@onready var rig_3d: ThirdPersonRig = $ThirdPersonRig
@onready var rig_2d: SideScrollRig = $SideScrollRig
@onready var cam: Camera3D = $Camera3D

func _process(_delta: float) -> void:
	var a: Transform3D = rig_3d.camera_point.global_transform
	var b: Transform3D = rig_2d.camera_point.global_transform
	var w := blend
	var rot := Quaternion(a.basis.orthonormalized()).slerp(Quaternion(b.basis.orthonormalized()), w)
	cam.global_transform = Transform3D(Basis(rot), a.origin.lerp(b.origin, w))
	cam.fov = lerpf(fov_3d, fov_2d, w)

func blend_to(target: float, duration: float = 0.9) -> void:
	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "blend", target, duration)
	await tw.finished
```

- **Dolly-zoom efekt:** 2D rig stojí daleko (≈ 18–22 m) s úzkým FOV, 3D rig blízko se širokým FOV. Při tweenu se FOV zužuje, zatímco kamera couvá — svět se „zploští do malby“. Perspektivu **nepřepínáme na ortogonální** (to nejde plynule tweenovat) — úzké FOV vypadá skoro ploše a zachová parallax.
- **SpringArm** kolize 3D rigu se během přechodu nemusí vypínat — blend jen bere jeho výsledek.

### 3.3 Sekvence portálu (bez rozbití vstupů)

`world/portals/painting_portal.gd` (vstup) a `exit_portal.gd` (výstup) dělají přesně toto:

1. Hráč vstoupí do `Area3D` před rámem → `player.state_machine.transition_to(&"Locked")` (vstupy ignorovány, rychlost tlumená).
2. Tween hráče na startovní `Marker3D` 2D dráhy (0.3 s) + `InkSplash` částice.
3. `await hybrid_camera.blend_to(1.0, 0.9)`.
4. `player.enter_2d(plane_origin, plane_normal)` → `transition_to(&"Air")` nebo `&"Idle"`.
5. Výstup zpět: zrcadlově, `blend_to(0.0)`, `enter_3d()`, 3D rig se před tweenem natočí **za záda hráče** (`rig_3d.snap_behind(player)`).

**Proč se ovládání nerozbije:** po celou dobu přechodu je hráč v `Locked` a režim se přepíná **až po doběhnutí tweenu**. Ve 3D se směr počítá z yaw 3D rigu, který se během blendu neotáčí → nic se „neotočí pod rukama“.

**Volitelný inkoustový přechod (`ui/transitions/ink_wipe.tscn`):** `CanvasLayer` + `ColorRect` se shaderem (šumová maska, uniform `progress` 0–1). Levné i na mobilu. Pro budoucí velké 2D levely můžeme na vrcholu inkoustu **teleportovat** do samostatné 2D sub-scény — API portálu zůstane stejné. V `v0.2.0` je 2D dráha fyzicky hned za rámem ve stejné scéně.

---

## 4. Vstupy: PC + gamepad + dotyk (jedna vrstva)

### 4.1 Akce v `InputMap`

| Akce | Klávesnice + myš | Xbox | PlayStation | Dotyk |
| :--- | :--- | :--- | :--- | :--- |
| `move_left/right/forward/back` | A / D / W / S | levá páčka | levá páčka | virtuální joystick |
| `look_left/right/up/down` | myš (delta) | pravá páčka | pravá páčka | tah prstem v pravé polovině |
| `jump` | Mezerník | A | ✕ | tlačítko šipka ↑ |
| `sprint` (držet) | Shift | LB / L3 | L1 / L3 | tlačítko běžícího Bruna |
| `action` (hůl: kotva / kontext) | E / levé tlačítko myši | B | ○ | tlačítko hole |
| `tennis` (odpal tenisáku) | Q / pravé tlačítko myši | Y | △ | tlačítko tenisáku |
| `sneak` (držet, plížení) | Ctrl | LT | L2 | (automaticky podle vychýlení joysticku) |
| `pause` | Esc | Menu | Options | ikona pauzy |
| `debug_toggle_touch` | M | — | — | — |
| `debug_overlay` | F3 | — | — | — |
| `debug_toggle_language` | L | — | — | — |

- Deadzone pohybových akcí **0.2**. Pohyb vždy přes `Input.get_vector()` (kruhová deadzone, analogová síla).
- `M` je schválně debug akce — až bude `M` = mapa, jen se přemapuje.
- 4 dotyková tlačítka odpovídají mockupu `vis/ui_hud_mockup_v01.png` (hůl, skok, sprint, tenisák).

### 4.2 `InputManager` (autoload) — jen pro věci, které `InputMap` neumí

```gdscript
# autoload/input_manager.gd
extends Node

enum Device { KEYBOARD_MOUSE, GAMEPAD, TOUCH }
signal device_changed(device: Device)   # jen pro UI ikonky tlačítek, NIKDY pro stavy
signal touch_controls_toggled(visible: bool)

var last_device: Device = Device.KEYBOARD_MOUSE
var touch_controls_visible: bool = false
var mouse_sensitivity: float = 0.003
var stick_sensitivity: float = 3.0
var _mouse_look := Vector2.ZERO
var _touch_look := Vector2.ZERO

func _ready() -> void:
	set_touch_controls(OS.has_feature("mobile"))

func _input(event: InputEvent) -> void:
	_track_device(event)
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_mouse_look += (event as InputEventMouseMotion).relative
	if event.is_action_pressed(&"debug_toggle_touch") and OS.is_debug_build():
		set_touch_controls(not touch_controls_visible)

func add_touch_look(relative: Vector2) -> void:
	_touch_look += relative

## Jediný zdroj rozhlížení pro ThirdPersonRig (myš + páčka + dotyk sloučené).
func consume_look(delta: float) -> Vector2:
	var stick := Input.get_vector(&"look_left", &"look_right", &"look_up", &"look_down")
	var out := (_mouse_look + _touch_look) * mouse_sensitivity + stick * stick_sensitivity * delta
	_mouse_look = Vector2.ZERO
	_touch_look = Vector2.ZERO
	return out

func set_touch_controls(on: bool) -> void:
	touch_controls_visible = on
	if not OS.has_feature("mobile"):
		Input.emulate_touch_from_mouse = on            # myš se chová jako prst
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if on else Input.MOUSE_MODE_CAPTURED
	touch_controls_toggled.emit(on)

func _track_device(event: InputEvent) -> void:
	var d := last_device
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		d = Device.TOUCH
	elif event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf((event as InputEventJoypadMotion).axis_value) > 0.3):
		d = Device.GAMEPAD
	elif event is InputEventKey or event is InputEventMouseButton:
		d = Device.KEYBOARD_MOUSE
	if d != last_device:
		last_device = d
		device_changed.emit(d)
```

### 4.3 Dotykový HUD (`ui/touch_controls/`)
- **Tlačítka:** `TouchScreenButton` s vyplněnou vlastností `action` (`jump`, `sprint`, `action`, `tennis`) → Godot akci mačká nativně, multi-touch funguje. `passby_press = true` pro skok.
- **Virtuální joystick** (`virtual_joystick.gd`, `Control`): sleduje index prstu z `InputEventScreenTouch/Drag` a převádí výchylku na akce:
  ```gdscript
  func _apply(v: Vector2) -> void:   # v v rozsahu -1..1
  	_press(&"move_left",  maxf(-v.x, 0.0)); _press(&"move_right", maxf(v.x, 0.0))
  	_press(&"move_forward", maxf(-v.y, 0.0)); _press(&"move_back", maxf(v.y, 0.0))
  func _press(action: StringName, strength: float) -> void:  # NE _set (koliduje s Object._set)
  	if strength > 0.05: Input.action_press(action, strength)
  	else: Input.action_release(action)
  ```
- **Rozhlížení:** tah prstem v pravé polovině obrazovky, který nezačal na tlačítku → `InputManager.add_touch_look(relative)`.
- Celý HUD je `CanvasLayer` skrývaný signálem `touch_controls_toggled`.
- ⚠️ Na PC emulace dotyku = **jen jeden prst** (joystick + tlačítko současně nejdou). Skutečný multi-touch otestovat na telefonu (viz krok D).

---

## 5. Lokalizace CS/EN a ukládání

### 5.1 `localization/translations.csv`

```csv
keys,cs,en
UI_MENU_PLAY,Hrát,Play
UI_SETTINGS_LANGUAGE,Jazyk,Language
UI_LANG_CS,Čeština,Czech
UI_LANG_EN,Angličtina,English
HUD_BOTTLES,Lahvičky: {n},Bottles: {n}
HUD_BOTTLES_ONE,{n} lahvička,{n} bottle
HUD_BOTTLES_FEW,{n} lahvičky,{n} bottles
HUD_BOTTLES_MANY,{n} lahviček,{n} bottles
GB_SIGN_PAINTING,"Skoč do obrazu!","Jump into the painting!"
DLG_CH1_KIKI_0001,"Bruno, slyšíš mě? Zvon na věži!","Bruno, can you hear me? The bell on the tower!"
```

- **Kódování UTF-8, oddělovač čárka**, buňky s čárkou v uvozovkách. **Needitovat v Excelu** (rozbije diakritiku/ů, ě) — VS Code nebo LibreOffice (UTF-8).
- **Prefixy klíčů:** `UI_` menu, `HUD_`, `GB_` greybox/testovací, `DLG_CHx_POSTAVA_0001` dialogy, `ITEM_`, `QUEST_`, `OUTFIT_`, `CS_CHx_` cutscény. Jen VELKÁ písmena + podtržítka.
- Godot CSV importuje na `translations.cs.translation` a `translations.en.translation`; obě cesty musí být v `project.godot` → `internationalization/locale/translations`.
- **Čeština má 3 tvary množného čísla** → klíče `_ONE / _FEW / _MANY` a helper:
  ```gdscript
  # core/loc.gd
  class_name Loc
  static func plural(base: String, n: int) -> String:
  	var suffix := "_MANY"
  	if TranslationServer.get_locale().begins_with("cs"):
  		if n == 1: suffix = "_ONE"
  		elif n >= 2 and n <= 4: suffix = "_FEW"
  	else:
  		suffix = "_ONE" if n == 1 else "_FEW"
  	return TranslationServer.translate(base + suffix).format({"n": n})
  ```
- **UI uzly:** `Label.text = "UI_MENU_PLAY"` → Godot přeloží automaticky a **přepne živě** při `TranslationServer.set_locale()`. Text skládaný v kódu: `tr("KEY")` + obnovit v `_notification(NOTIFICATION_TRANSLATION_CHANGED)`.
- Výchozí jazyk: uložený v nastavení; při prvním spuštění `OS.get_locale_language() == "cs"` → `cs`, jinak `en`.
- ⚠️ **Fonty:** každé komiksové písmo předem otestovat na `ěščřžýáíéůú ĚŠČŘŽÝÁÍÉŮÚ`. Spousta „cartoon“ fontů nemá `ů` a `ě`.

### 5.2 Nastavení vs. postup — dva soubory

| Soubor | Formát | Obsah | Kdy |
| :--- | :--- | :--- | :--- |
| `user://settings.cfg` | `ConfigFile` | jazyk, hlasitosti, citlivost, vynucený dotykový HUD | `v0.2.0` (jen jazyk) |
| `user://save_1.json` | JSON | herní postup | struktura teď, plné použití `v0.4.0` (W4-01) |

### 5.3 Schéma uložené hry

```json
{
  "save_version": 1,
  "game_version": "0.2.0",
  "saved_at_unix": 0,
  "playtime_s": 0,
  "player": {
    "outfit_equipped": "OUTFIT_DEFAULT",
    "outfits_unlocked": ["OUTFIT_DEFAULT"],
    "abilities": ["double_jump", "ear_glide", "spire_magnet", "tennis_bat"]
  },
  "progress": {
    "current_chapter": "ch1",
    "chapters": {
      "ch1": {
        "unlocked": true,
        "completed": false,
        "missions_done": [],
        "bottles": ["ch1_bottle_001", "ch1_bottle_014"],
        "vault_opened": false,
        "golden_tennis_balls": ["ch1_gtb_hub"],
        "cages": [],
        "sidequests": { "kiki_race_01": {"done": false, "best_time": 0.0} }
      }
    }
  }
}
```

**Pravidla:**
- **Ukládáme ID, ne počty.** Každý sběratelský předmět má `@export var collectible_id: String` (unikátní, např. `ch1_bottle_007`). Při načtení levelu: `if SaveManager.is_collected(id): queue_free()`. Počty se dopočítají (`bottles.size()`).
- `save_version` + funkce `_migrate(data)` → staré savy se dají aktualizovat, když přidáme pole.
- **Atomický zápis:** zapsat do `save_1.json.tmp`, předchozí zkopírovat na `.bak`, pak přejmenovat `.tmp` → `.json`. Na Androidu může systém hru kdykoliv zabít.
- Autosave na `NOTIFICATION_APPLICATION_PAUSED` (Android) a při vstupu do Úkrytu.
- JSON vrací čísla jako `float` → při načtení `int()`.
- `GameState` (autoload) drží data za běhu; `SaveManager` je jen serializuje. Hra nikdy nesahá přímo do JSON slovníku.

---

## 6. Struktura projektu `game/`

**Organizace podle funkcí (feature-based):** scéna a její skript leží vedle sebe. AI agent tak vždy najde všechno k jedné věci v jedné složce. Názvy souborů a složek **snake_case**, třídy `PascalCase`.

```
game/                                  ← res://
├── project.godot
├── icon.svg
├── autoload/
│   ├── events.gd                      ← globální signály (signal bus)
│   ├── input_manager.gd
│   ├── game_state.gd                  ← běhová data (sbírky, schopnosti, kapitola)
│   ├── save_manager.gd                ← JSON save + settings.cfg
│   └── settings.gd                    ← jazyk, hlasitost, citlivost (aplikuje a ukládá)
│   (+ DebugOverlay = ui/debug/debug_overlay.tscn jako 6. autoload, jen debug)
├── core/
│   ├── state_machine/
│   │   ├── player_state.gd
│   │   └── player_state_machine.gd
│   └── loc.gd                         ← plural helper
├── player/
│   ├── player.tscn
│   ├── player.gd
│   ├── player_visual.gd               ← greybox: postoj 2 nohy / 4 nohy, uši, hůl
│   ├── movement_profile.gd
│   ├── profiles/
│   │   ├── profile_3d.tres
│   │   └── profile_2d.tres
│   ├── anchor_detector.gd
│   └── states/
│       ├── grounded_state.gd          ← základní třída
│       ├── airborne_state.gd          ← základní třída
│       ├── anchor_state.gd            ← základní třída
│       ├── state_idle.gd
│       ├── state_move.gd
│       ├── state_sprint.gd
│       ├── state_air.gd
│       ├── state_glide.gd
│       ├── state_perch.gd
│       ├── state_swing.gd
│       └── state_locked.gd
│           # v0.2.1: state_climb.gd, state_crawl.gd, state_ledge_hang.gd,
│           #         state_wall_sneak.gd, state_path_follow.gd, state_hook_swing.gd
├── camera/
│   ├── hybrid_camera.tscn
│   ├── hybrid_camera.gd
│   ├── third_person_rig.gd
│   └── side_scroll_rig.gd
├── world/
│   ├── anchors/      anchor.gd, spire_anchor.tscn, blue_sparkle.tscn
│   ├── portals/      painting_portal.tscn/.gd, exit_portal.tscn/.gd
│   ├── props/        tennis_ball.tscn/.gd, target_bell.tscn/.gd, gate.tscn/.gd
│   ├── platforms_2d/ bouncy_mushroom.tscn/.gd   (v0.2.1: zbylých 6 bloků)
│   └── collectibles/ (v0.3+)
├── levels/
│   └── greybox/
│       └── greybox_street.tscn        ← hlavní scéna v0.2.0
├── ui/
│   ├── debug/        debug_overlay.tscn/.gd
│   ├── touch_controls/ touch_controls.tscn, virtual_joystick.gd
│   ├── hud/          (v0.3.1)
│   ├── menus/        (v0.3.1)
│   └── transitions/  ink_wipe.tscn
├── shaders/
│   ├── ink_wipe.gdshader              ← v0.2.0
│   └── (v0.3.0) cel_toon.gdshader, outline_hull.gdshader
├── localization/
│   └── translations.csv
└── assets/                            ← jen schválené herní assety (ne concept arty z vis/)
    ├── fonts/ models/ textures/ audio/
```

**Uzlový strom hráče (`player.tscn`):**
```
Player (CharacterBody3D, player.gd)            vrstva: player
├── CollisionStand (CollisionShape3D, Capsule)
├── CollisionLow   (CollisionShape3D, disabled) ← připraveno pro Crawl v0.2.1
├── Visual (Node3D, player_visual.gd)
│   ├── Body2Legs (MeshInstance3D)   ├── Body4Legs (MeshInstance3D, skrytý)
│   ├── EarL / EarR (MeshInstance3D) ├── Collar (MeshInstance3D)
│   └── Cane (MeshInstance3D)        └── BallSpawn (Marker3D)
├── AnchorDetector (Area3D + SphereShape3D, anchor_detector.gd)
└── StateMachine (PlayerStateMachine)
    └── Idle, Move, Sprint, Air, Glide, Perch, Swing, Locked
```

**Kolizní vrstvy (pojmenovat v Project Settings → Layer Names → 3D Physics):**
`1 world` · `2 player` · `3 enemies` · `4 anchors` · `5 props` · `6 projectiles` · `7 triggers` · `8 one_way_2d`

**Klíčová nastavení `project.godot`:**
```ini
[application]
run/main_scene="res://levels/greybox/greybox_street.tscn"
config/features=PackedStringArray("4.7")

[autoload]
Events="*res://autoload/events.gd"
InputManager="*res://autoload/input_manager.gd"
Settings="*res://autoload/settings.gd"
GameState="*res://autoload/game_state.gd"
SaveManager="*res://autoload/save_manager.gd"
DebugOverlay="*res://ui/debug/debug_overlay.tscn"   ; jen debug buildy, v exportu se sám odstraní

[display]
window/size/viewport_width=1920
window/size/viewport_height=1080
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"

[physics]
3d/physics_engine="Jolt Physics"
common/physics_ticks_per_second=60
common/physics_interpolation=true

[rendering]
renderer/rendering_method="forward_plus"
renderer/rendering_method.mobile="mobile"

[internationalization]
locale/translations=PackedStringArray("res://localization/translations.cs.translation", "res://localization/translations.en.translation")

[debug]
gdscript/warnings/untyped_declaration=1
```
(Přesné názvy klíčů ověřit v Godotu — po spuštění editoru a uložení Project Settings je Godot přepíše do správného tvaru.)

**`.gitignore` v kořeni repa musí obsahovat:** `.godot/`, `*.tmp` a `*.translation` (generuje se z CSV při importu). Soubory `*.import` a `*.uid` **commitovat**.

---

## 7. Rozsah `v0.2.0` — revize a rozdělení na kroky

**Verdikt:** rozsah je správný jako *cíl* `v0.2.0`, ale **jako jedno zadání je příliš velký**. „100 % funkční na první dobrou“ nečekej od žádné AI u 20+ souborů najednou — chyby se pak hledají v celé hromadě. Řešení: **6 malých kroků A–F, každý = jedna pracovní větev s commity od Clauda, jeden test od Tomáše, jeden merge.** Další krok začíná, až předchozí projde checklistem.

**Odloženo mimo `v0.2.0`:** haptika ovladače, idle animace s pinkáním tenisáku, Zlaté kapky v oblouku (→ `v0.2.1` s platform kitem), ukládání postupu (jen nastavení jazyka), zvuky.

| Krok | Obsah | Tomáš otestuje (checklist) |
| :-: | :--- | :--- |
| **A** | `project.godot` (Jolt, renderery, interpolace, vrstvy), 5 autoloadů (zatím kostry), celá `InputMap`, `translations.csv`, `Settings` ukládá jazyk, **debug overlay (F3)**: FPS, stav, režim, rychlost, `on_floor`, zařízení, jazyk + seznam právě držených akcí. Testovací scéna = podlaha + nápis `GB_SIGN_PAINTING`. Klávesa `L` (dočasně v debug) přepíná CS/EN. | F5 bez chyb v Output · F3 ukáže overlay · stisk kláves i tlačítek ovladače se zobrazí jako akce · `L` přepne nápis CS↔EN a po restartu jazyk zůstane |
| **B** | Hráč (kapsle + uši + hůl), `PlayerStateMachine`, `Idle/Move/Sprint/Air` (+dvojskok, coyote, buffer), `ThirdPersonRig` (myš + páčka, SpringArm), `HybridCamera` jen s 3D rigem, oba `MovementProfile`. Greybox: podlaha, schody, kostky, propast. Posture 2/4 nohy (prohození meshí). | Chůze, plížení, sprint po 4 (vizuálně jiný tvar), skok, dvojskok, coyote (skok těsně po hraně), kamera se neprotíná se zdmi · overlay ukazuje správný stav · čísla v `profile_3d.tres` mění feel |
| **C** | `Glide` (držet skok ve vzduchu), `Anchor` + `AnchorDetector` + modré jiskry, `Perch`, 3 špičky na střechách. | Plachtění zpomalí pád · u špičky se rozsvítí jiskry · `action` přitáhne Bruna na špičku, skok z ní funguje · nikdy se nezasekne |
| **D** | Dotykový HUD (joystick + 4 tlačítka + rozhlížení), přepínání `M`, auto na mobilu. **Volitelně:** první testovací Android export (debug APK). | `M` zobrazí/skryje HUD · myší „prstem“ jde chodit a skákat · stavy fungují stejně jako s klávesnicí · (APK: multi-touch na telefonu) |
| **E** | `Swing` stav, `tennis_ball.tscn` (RigidBody3D, `continuous_cd = true`, svítící stopa), `target_bell.tscn` (Area3D detekuje skupinu `tennis_ball`), `gate.tscn` se otevře přes `Events`. | Odpal míří směrem kamery · zásah zvonu spolehlivě otevře bránu (10 pokusů / 10) · míček neprolétá zdmi |
| **F** | `SideScrollRig`, `blend_to()`, `painting_portal` + `exit_portal`, `Locked` stav, 2D režim hráče, `ink_wipe`, krátká 2D dráha (2 `bouncy_mushroom`, propast, výstup). | Přechod 3D→2D→3D plynulý, bez cuknutí · během přechodu nejde ovládat · ve 2D se nedá vyběhnout z roviny · plachtění/sprint/dvojskok fungují i ve 2D s „Rayman“ feelem · po návratu do 3D míří ovládání správně |

Po kroku F: tag `v0.2.0`, zápis do `DESIGN.md` a `index.html`.

---

## 8. Šablona promptu pro záložního agenta (Antigravity), kdyby Claudovi došly limity

```
Pracuješ na projektu Bruno: Ink & Shadow (Godot 4.7, GDScript, Jolt).
Před začátkem si přečti ARCHITECTURE.md (závazné) a DESIGN.md (kontext).

Úkol: KROK <X> z ARCHITECTURE.md sekce 7.
Rozsah: pouze soubory uvedené v kroku <X> a sekci 6. Nic navíc nevytvářej.
Dodrž pravidla ze sekce 10 (Godot 4 syntaxe, typovaný GDScript, žádné texty natvrdo).

Po dokončení:
1. Spusť kontrolu: godot --headless --path game --editor --quit
   a pak: godot --headless --path game --quit-after 300
   Oprav všechny chyby a varování z výstupu.
2. Vypiš seznam vytvořených/změněných souborů.
3. Vypiš checklist z kroku <X>, abych ho mohl otestovat.
Necommituj — commit udělám já po otestování.
```
(Tomáš: Antigravity potřebuje znát cestu k `godot.exe` — přidej ji do promptu nebo do PATH.)

---

## 9. Pracovní postup a git

- **Claude** pracuje ve větvi `claude/<verze>-<krok>`, commituje a otevírá Pull Request. **Tomáš** si větev v GitHub Desktopu přepne, otestuje checklist a teprve pak PR zmerguje do `main`.
- Záložní agent (Antigravity) nesmí commitovat; před jeho spuštěním udělej commit („před krokem C“), ať jde vše vrátit přes `git restore .`.
- Commit po úspěšném testu: `v0.2.0-B: hráč, state machine, 3D kamera`.
- Chyby hlásit **s debug overlay screenshotem + textem z panelu Output/Debugger** — to stačí Claudovi i Antigravity k diagnóze.
- Soubory přesouvat/přejmenovávat **jen v editoru Godotu** (FileSystem dock), jinak se rozbijí odkazy ve scénách.

---

## 10. Pravidla pro AI generování kódu (závazná pro Clauda i Antigravity)

**Godot 4 — zakázaná stará syntaxe:**

| ❌ Godot 3 | ✅ Godot 4 |
| :--- | :--- |
| `KinematicBody`, `Spatial` | `CharacterBody3D`, `Node3D` |
| `move_and_slide(velocity, up)` | nastavit `velocity`, pak `move_and_slide()` |
| `export var`, `onready var` | `@export var`, `@onready var` |
| `yield(...)` | `await ...` |
| `connect("sig", self, "_m")` | `sig.connect(_m)` |
| `.instance()` | `.instantiate()` |
| `deg2rad`, `rand_range` | `deg_to_rad`, `randf_range` |
| `PoolStringArray` | `PackedStringArray` |
| `tween = Tween.new(); add_child` | `create_tween()` |

**Další pravidla:**
- Typovaný GDScript všude (`var speed: float`, `func f(x: int) -> void`), `class_name` u znovupoužitelných tříd.
- Žádné texty natvrdo — výjimka jen `ui/debug/`.
- Vstupy pouze přes akce z `InputMap` (`&"jump"`), nikdy `KEY_SPACE` apod. (výjimka: `InputManager`).
- Konstanty a laditelné hodnoty jako `@export` nebo v `.tres`, ne „magická čísla“ v kódu.
- Signály mezi systémy přes `Events` (např. `Events.bell_hit`, `Events.player_mode_changed`), ne `get_node("../../..")`.
- Při psaní `.tscn` ručně: nevymýšlet `uid://` hodnoty (vynechat, Godot je doplní při uložení).
- Každý nový stav: dědit z `GroundedState` / `AirborneState` / `AnchorState`, registrovat jen jako dítě `StateMachine`.
- Žádná externí addons/pluginy bez schválení Claudem.

---

## 11. Otevřené body pro další konzultace

- `v0.2.1`: geometrie kotev `LEDGE`/`ROPE`/`PIPE` (úsečky a křivky `Path3D`), pravidla výstupu z kotev.
- `v0.3.0`: cel shader (`diffuse_light` v krocích + rim) a inverted-hull obrysy, rozpočet výkonu pro Android.
- `v0.3.2`: AI hlídek (kužel vidění = `ShapeCast3D`/raycasty, ne fyzický kužel), zvuková detekce.
- `v0.4.0`: načítání hubu a interiérů (`SceneRouter` + inkoustový střih, `ResourceLoader.load_threaded_request`).
