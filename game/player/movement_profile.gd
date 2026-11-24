## Laditelné hodnoty pohybu. Hráč má dva profily: profile_3d.tres (stealth hry) a profile_2d.tres (2D plošinovky).
## Ladí se v Inspectoru bez kódu: dvojklik na .tres v panelu Souborový systém.
class_name MovementProfile
extends Resource

@export_group("Ground")
@export var walk_speed: float = 4.5
@export var sneak_speed: float = 2.0
@export var sprint_speed: float = 9.0
@export var ground_accel: float = 35.0
@export var ground_decel: float = 45.0
## Pod touto výchylkou páčky se Bruno plíží (0–1).
@export_range(0.0, 1.0) var sneak_stick_threshold: float = 0.45

@export_group("Air")
@export var jump_height: float = 1.6
@export var double_jump_height: float = 1.2
@export var gravity: float = 28.0
@export var fall_gravity_mult: float = 1.6
## Přídavná gravitace, když hráč pustí skok během výstupu (kratší skok).
@export var jump_cut_gravity_mult: float = 2.5
@export var air_accel: float = 18.0
@export var max_fall_speed: float = 30.0

@export_group("Glide (Ušní vrtulník)")
@export var glide_fall_speed: float = 2.5
@export var glide_air_speed: float = 6.0

@export_group("Forgiveness")
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.12

@export_group("Visual")
## Jak rychle se Bruno otáčí do směru pohybu.
@export var turn_speed: float = 12.0
