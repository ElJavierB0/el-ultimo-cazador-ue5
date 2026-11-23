class_name FoeCombatant
extends Combatant
## FoeCombatant: enemigo dentro de la batalla. Elige sus ataques al azar según su peso.

var data: Dictionary
var boss := false
var _hp := 1
var _max_hp := 1
var _atk := 1
var _def := 0
var _level := 1


func _init(enemy: Enemy, level_index: int) -> void:
	body = enemy
	actor = enemy.actor
	data = enemy.data
	boss = enemy.is_boss()
	display_name = data.name
	type = data.type
	_max_hp = roundi(data.hp * (1.0 + 0.25 * level_index))
	_hp = _max_hp
	_atk = data.atk + level_index * 2
	_def = data.def + level_index
	_level = (5 if boss else 2) + level_index * 4


func hp() -> int:
	return _hp


func max_hp() -> int:
	return _max_hp


func attack() -> int:
	return maxi(1, _atk + atk_mod)


func defense() -> int:
	return maxi(0, _def + def_mod)


func level() -> int:
	return _level


func take_damage(amount: int) -> int:
	var real := clampi(amount, 0, _hp)
	_hp -= real
	return real


func heal(amount: int) -> int:
	var before := _hp
	_hp = mini(_max_hp, _hp + amount)
	return _hp - before


func choose_move() -> Dictionary:
	return BattleRules.pick_move(data.moves)
