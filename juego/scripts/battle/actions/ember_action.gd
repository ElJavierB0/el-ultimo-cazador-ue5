class_name EmberAction
extends BattleAction
## EmberAction: señal Ascua. Bola de fuego que ignora la defensa y quema dos turnos.

const POWER := 9


func _init() -> void:
	super("ascua", "Señal Ascua", "Fuego: ignora la defensa y quema", 2)


func execute(battle: Battle) -> Result:
	battle.announce("%s usa %s." % [battle.hero.display_name, label])
	battle.hero.spend_vigor(cost)
	battle.refresh()
	battle.hero.actor.once("cast", "combat")
	await battle.wait(0.35)
	Audio.sfx("fire")
	await Fx.projectile(battle.level, battle.hero.chest(), battle.foe.chest(), Color("#ff7a2a"))
	var mult := BattleRules.effectiveness(id, battle.foe.type)
	var amount := BattleRules.damage(POWER, battle.hero.attack(), 0, mult, true)
	await battle.hit_foe(amount, mult, false, Color("#ff8a2a"))
	if not battle.foe.is_alive():
		return Result.BATTLE_OVER
	battle.foe.burn = 2
	battle.refresh()
	await battle.say("%s arde en llamas." % battle.foe.display_name)
	return Result.TURN_USED
