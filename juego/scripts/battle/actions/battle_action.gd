class_name BattleAction
extends RefCounted
## BattleAction: acción del jugador en la batalla (patrón Comando).
## Cada acción sabe si se puede usar y cómo se ejecuta; Battle no necesita conocer los detalles.

enum Result { TURN_USED, NO_TURN, BATTLE_OVER }

var id := ""
var label := ""
var hint := ""
var cost := 0


func _init(p_id: String, p_label: String, p_hint: String, p_cost := 0) -> void:
	id = p_id
	label = p_label
	hint = p_hint
	cost = p_cost


## Motivo por el que no se puede usar, o texto vacío si se puede.
func blocked_reason(battle: Battle) -> String:
	return "No tienes suficiente vigor." if battle.hero.vigor < cost else ""


func execute(_battle: Battle) -> Result:
	return Result.TURN_USED
