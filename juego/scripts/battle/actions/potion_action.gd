class_name PotionAction
extends BattleAction
## PotionAction: beber una poción del inventario.

func _init() -> void:
	super("pocion", "Poción", "Cura la mitad de la vida")


func blocked_reason(battle: Battle) -> String:
	return "No te quedan pociones." if battle.hero.hunter.potions <= 0 else ""


func execute(battle: Battle) -> Result:
	battle.announce("%s bebe una poción." % battle.hero.display_name)
	var healed := battle.hero.hunter.drink_potion()
	Audio.sfx("heal")
	Fx.burst(battle.level, battle.hero.chest(), Color("#7dffb0"), 26)
	Fx.popup(battle.level, battle.hero.head(), "+%d" % healed, Color("#7dffb0"), true)
	battle.refresh()
	await battle.hero.actor.once("item", "combat")
	await battle.say("Recupera %d PV." % healed)
	return Result.TURN_USED
