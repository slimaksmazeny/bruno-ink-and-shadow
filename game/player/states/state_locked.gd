## Hráč je zamčený (průlet portálem, cutscéna). Ignoruje vstup, nepadá – pohyb řídí skript portálu.
extends PlayerState


func enter(_previous: StringName, _msg: Dictionary = {}) -> void:
	player.velocity = Vector3.ZERO
	player.is_sneaking = false


func physics_update(_delta: float) -> void:
	player.velocity = Vector3.ZERO
