class_name Combatant
extends RefCounted
## Combatant: participante de una batalla (clase base del cazador y de los enemigos).

var display_name := ""
var type := "humano"
var actor: Actor
var body: Entity
var home := Vector3.ZERO
var atk_mod := 0
var def_mod := 0
var burn := 0


func hp() -> int:
	return 0


func max_hp() -> int:
	return 1


func attack() -> int:
	return 0


func defense() -> int:
	return 0


func level() -> int:
	return 1


func is_alive() -> bool:
	return hp() > 0


## Aplica el daño y devuelve cuánto recibió realmente.
func take_damage(_amount: int) -> int:
	return 0


func heal(_amount: int) -> int:
	return 0


func chest() -> Vector3:
	return body.global_position + Vector3(0, actor.height * 0.6, 0)


func head() -> Vector3:
	return body.global_position + Vector3(0, actor.height, 0)
