class_name FleeAction
extends BattleAction
## FleeAction: intento de huida. No funciona contra guardianes y resta puntos.

func _init() -> void:
	super("huir", "Huir", "70 % de probabilidad · −25 puntos")


func blocked_reason(_battle: Battle) -> String:
	return ""


func execute(battle: Battle) -> Result:
	if battle.foe.boss:
		await battle.say("¡No puedes huir de un guardián!")
		return Result.NO_TURN
	if randf() > BattleRules.FLEE_CHANCE:
		await battle.say("¡No pudiste escapar!")
		return Result.TURN_USED
	Game.add_score("FLEE")
	Audio.sfx("back")
	battle.fled = true
	battle.hero.body.facing *= -1
	battle.hero.actor.face(battle.hero.body.facing)
	battle.hero.actor.play("run")
	await battle.say("%s escapa entre las sombras." % battle.hero.display_name)
	return Result.BATTLE_OVER
