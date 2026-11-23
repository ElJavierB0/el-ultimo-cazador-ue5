class_name SwordAction
extends BattleAction
## SwordAction: ataque con la espada de acero o de plata.

const POWER := 6

var _sound: String


func _init(p_id: String, p_label: String, p_hint: String, p_sound: String) -> void:
	super(p_id, p_label, p_hint)
	_sound = p_sound


func execute(battle: Battle) -> Result:
	battle.announce("%s usa %s." % [battle.hero.display_name, label])
	Audio.sfx(_sound)
	await battle.lunge(battle.hero, battle.foe)
	if randf() < BattleRules.MISS_CHANCE:
		Audio.sfx("miss")
		Fx.popup(battle.level, battle.foe.head(), "Falló", Color("#cfcfcf"))
		await battle.say("¡El ataque falló!")
		return Result.TURN_USED
	var mult := BattleRules.effectiveness(id, battle.foe.type)
	var crit := randf() < BattleRules.CRIT_CHANCE
	var amount := BattleRules.damage(POWER, battle.hero.attack(), battle.foe.defense(), mult * (1.5 if crit else 1.0))
	await battle.hit_foe(amount, mult, crit, Color("#e8f4ff"))
	return Result.TURN_USED if battle.foe.is_alive() else Result.BATTLE_OVER
