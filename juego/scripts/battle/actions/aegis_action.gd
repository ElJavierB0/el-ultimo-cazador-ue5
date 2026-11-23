class_name AegisAction
extends BattleAction
## AegisAction: señal Égida. Escudo que reduce a la mitad el siguiente golpe.

func _init() -> void:
	super("egida", "Señal Égida", "Reduce a la mitad el siguiente golpe", 1)


func execute(battle: Battle) -> Result:
	battle.announce("%s traza la señal Égida." % battle.hero.display_name)
	battle.hero.spend_vigor(cost)
	battle.hero.shield = true
	Audio.sfx("shield")
	battle.show_shield(true)
	battle.refresh()
	await battle.hero.actor.once("block", "combat")
	await battle.say("Un escudo mágico lo rodea.")
	return Result.TURN_USED
