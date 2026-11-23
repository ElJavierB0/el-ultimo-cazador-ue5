class_name HeroCombatant
extends Combatant
## HeroCombatant: el cazador dentro de la batalla. Usa las estadísticas persistentes de Hunter.

var hunter: Hunter
var vigor := BattleRules.MAX_VIGOR
var shield := false
var damage_taken := 0


func _init(p_hunter: Hunter, p_body: Entity) -> void:
	hunter = p_hunter
	body = p_body
	actor = p_body.actor
	display_name = hunter.display_name


func hp() -> int:
	return hunter.hp


func max_hp() -> int:
	return hunter.max_hp


func attack() -> int:
	return maxi(1, hunter.attack + atk_mod)


func defense() -> int:
	return maxi(0, hunter.defense + def_mod)


func level() -> int:
	return hunter.level


func take_damage(amount: int) -> int:
	var real := hunter.take_damage(BattleRules.shielded(amount) if shield else amount)
	damage_taken += real
	return real


func heal(amount: int) -> int:
	return hunter.heal(amount)


func spend_vigor(cost: int) -> void:
	vigor = maxi(0, vigor - cost)


func recover_vigor() -> void:
	vigor = mini(BattleRules.MAX_VIGOR, vigor + 1)
