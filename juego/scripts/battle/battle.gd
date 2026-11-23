class_name Battle
extends Node
## Battle: combate por turnos con cámara cinematográfica dentro del mismo nivel.
## Cada turno es una secuencia: acción del jugador → turno del enemigo → efectos de fin de turno.

const GAP := 1.9

var level: LevelBase
var hero: HeroCombatant
var foe: FoeCombatant
var fled := false
var actions := {}
## Las pruebas automáticas pueden decidir las acciones en lugar del menú: func(battle) -> String
var auto_choose := Callable()

var _enemy: Enemy
var _side := 1
var _ui: BattleUi
var _shield_mesh: MeshInstance3D
var _cam_target := Vector3.ZERO
var _cam_look := Vector3.ZERO
var _shake := 0.0


func _init(p_level: LevelBase, player: Player, enemy: Enemy) -> void:
	level = p_level
	_enemy = enemy
	hero = HeroCombatant.new(Game.hunter, player)
	foe = FoeCombatant.new(enemy, Game.level_index)
	for action: BattleAction in [
		SwordAction.new("acero", "Espada de acero", "Eficaz contra humanos", "slash"),
		SwordAction.new("plata", "Espada de plata", "Eficaz contra no-muertos y arcanos", "silver"),
		EmberAction.new(), AegisAction.new(), PotionAction.new(), FleeAction.new(),
	]:
		actions[action.id] = action


func _ready() -> void:
	Audio.music("boss" if foe.boss else "battle")
	_place_fighters()
	_build_shield()
	_ui = BattleUi.new(self)
	add_child(_ui)
	refresh()
	_run()


## Acomoda a los combatientes frente a frente sin salirse del tramo de suelo.
func _place_fighters() -> void:
	_side = 1 if hero.body.global_position.x <= foe.body.global_position.x else -1
	var seg := level.segment_at(foe.body.global_position.x)
	var margin := minf(GAP + 0.6, (seg.y - seg.x) / 2.0)
	var center := clampf(foe.body.global_position.x - _side * GAP, seg.x + margin, seg.y - margin)
	var y := float(level.ground_at(foe.body.global_position.x))
	hero.home = Vector3(center - _side * GAP, y, 0)
	foe.home = Vector3(center + _side * GAP, y, 0)
	for c: Combatant in [hero, foe]:
		c.body.global_position = c.home
		c.actor.visible = true
		c.actor.play("combat")
	hero.body.facing = _side
	foe.body.facing = -_side
	hero.actor.face(_side)
	foe.actor.face(-_side)
	_cam_target = Vector3(center - _side * 1.5, y + 2.0, 6.8)
	_cam_look = Vector3(center + _side * 0.2, y + 1.05, 0)


func _build_shield() -> void:
	_shield_mesh = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 1.1
	sphere.height = 2.2
	_shield_mesh.mesh = sphere
	_shield_mesh.material_override = Trigger.glow_material(Color("#7cc4ff"), 0.6, 0.22)
	_shield_mesh.visible = false
	level.add_child(_shield_mesh)


func _exit_tree() -> void:
	if is_instance_valid(_shield_mesh):
		_shield_mesh.queue_free()


func _process(delta: float) -> void:
	var cam := level.camera
	cam.position = cam.position.lerp(_cam_target, minf(1.0, delta * 2.6))
	var look := _cam_look
	if _shake > 0.0:
		_shake -= delta
		look += Vector3(randf_range(-0.06, 0.06), randf_range(-0.06, 0.06), 0)
	cam.look_at(look)
	_shield_mesh.global_position = hero.body.global_position + Vector3(0, 0.85, 0)


## ---------- Secuencia de la batalla ----------

func _run() -> void:
	await _intro()
	while true:
		var action := await _choose()
		var reason := action.blocked_reason(self)
		if reason != "":
			Audio.sfx("locked")
			await say(reason)
			continue
		var result: BattleAction.Result = await action.execute(self)
		if result == BattleAction.Result.NO_TURN:
			continue
		if result == BattleAction.Result.BATTLE_OVER:
			break
		await _foe_turn()
		if not hero.is_alive():
			break
		await _end_of_turn()
		if not foe.is_alive():
			break
	await _finish()


func _intro() -> void:
	var tips := {
		"humano": "es humano: usa ACERO", "nomuerto": "es un no-muerto: usa PLATA", "arcano": "es una criatura arcana",
	}
	if foe.boss:
		foe.actor.once("taunt", "combat")
		await say("¡%s defiende su territorio!" % foe.display_name, 1.0)
	else:
		await say("¡%s te cierra el paso!" % foe.display_name, 1.0)
	await say("El medallón vibra… %s." % tips[foe.type], 1.0)


func _choose() -> BattleAction:
	var id := ""
	if auto_choose.is_valid():
		await wait(0.05)
		id = auto_choose.call(self)
	else:
		id = await _ui.choose()
	return actions[id]


func _foe_turn() -> void:
	var move := foe.choose_move()
	var power: int = move.power
	var effect: String = move.get("effect", "")
	announce("%s usa %s." % [foe.display_name, move.name])
	Audio.sfx("enemy_attack")
	if power > 0 and move.get("anim", "") != "cast":
		await lunge(foe, hero)
	else:
		await foe.actor.once(move.get("anim", "taunt"), "combat")
		if power > 0:
			await Fx.projectile(level, foe.chest(), hero.chest(), Color("#b07aff"))
	if power > 0:
		await _hit_hero(power, effect)
	if hero.is_alive():
		await _apply_effect(effect)
	if hero.shield and power > 0:
		hero.shield = false
		show_shield(false)
	refresh()


func _hit_hero(power: int, effect: String) -> void:
	if randf() < BattleRules.DODGE_CHANCE:
		Audio.sfx("miss")
		hero.actor.once("dodge", "combat")
		await say("¡%s esquiva el golpe!" % hero.display_name)
		return
	var amount := BattleRules.damage(power, foe.attack(), hero.defense())
	var real := hero.take_damage(amount)
	Audio.sfx("hit")
	_shake = 0.35
	Fx.popup(level, hero.head(), "-%d" % real, Color("#ff8a7a"), real >= 10)
	refresh()
	if hero.is_alive():
		await hero.actor.once("hit", "combat")
	await say("La Égida protege. Recibes %d de daño." % real if hero.shield else "%s recibe %d de daño." % [hero.display_name, real])
	if effect == "drain":
		var back := foe.heal(ceili(real / 2.0))
		Fx.popup(level, foe.head(), "+%d" % back, Color("#ff9a6a"))
		refresh()
		await say("%s absorbe tu energía." % foe.display_name)


func _apply_effect(effect: String) -> void:
	match effect:
		"raise_atk":
			foe.atk_mod = mini(6, foe.atk_mod + 2)
			await say("¡El ataque de %s aumenta!" % foe.display_name)
		"lower_atk":
			hero.atk_mod = maxi(-4, hero.atk_mod - 2)
			await say("El ataque de %s baja." % hero.display_name)
		"lower_def":
			hero.def_mod = maxi(-3, hero.def_mod - 1)
			await say("La defensa de %s baja." % hero.display_name)
		"heal":
			var healed := foe.heal(roundi(foe.max_hp() * 0.25))
			Audio.sfx("heal")
			Fx.popup(level, foe.head(), "+%d" % healed, Color("#7dffb0"), true)
			refresh()
			await say("%s recupera vida." % foe.display_name)


func _end_of_turn() -> void:
	if foe.burn > 0:
		foe.burn -= 1
		var real := foe.take_damage(BattleRules.burn_damage(foe.max_hp()))
		Audio.sfx("fire")
		Fx.burst(level, foe.chest(), Color("#ff8a2a"), 24)
		Fx.popup(level, foe.head(), "-%d" % real, Color("#ff9a3a"))
		refresh()
		await say("%s sufre por las quemaduras." % foe.display_name)
	hero.recover_vigor()
	refresh()


func _finish() -> void:
	var result := "win"
	if fled:
		result = "flee"
	elif not hero.is_alive():
		result = "lose"
		Audio.sfx("defeat")
		await hero.actor.once("death")
		await say("%s ha caído…" % hero.display_name, 1.2)
	else:
		await _victory()
	Audio.stop_music()
	hero.actor.play("idle")
	queue_free()
	Events.battle_finished.emit(result, _enemy)


func _victory() -> void:
	Audio.sfx("victory")
	await foe.actor.once("death")
	Fx.burst(level, foe.chest(), Color("#d8d0ff"), 40)
	hero.actor.play("cheer")
	await say("¡%s ha sido derrotado!" % foe.display_name, 0.9)
	var points := Game.add_score("ENEMY_DEFEATED", foe.data.score)
	if hero.damage_taken == 0:
		points += Game.add_score("FLAWLESS_BATTLE")
	Game.hunter.add_coins(foe.data.coins)
	Game.stats.enemies += 1
	await say("+%d puntos y +%d monedas." % [points, foe.data.coins], 0.9)
	var ups := Game.hunter.gain_xp(foe.data.xp)
	await say("%s gana %d de experiencia." % [hero.display_name, foe.data.xp], 0.7)
	if ups > 0:
		Audio.sfx("level_up")
		Fx.popup(level, hero.head(), "¡NIVEL!", Color("#9fd3ff"), true)
		refresh()
		await say("¡%s sube al nivel %d! Más PV y ataque." % [hero.display_name, hero.level()], 1.0)


## ---------- Servicios que usan las acciones ----------

## El atacante corre hacia su objetivo, golpea y regresa a su lugar.
func lunge(attacker: Combatant, target: Combatant) -> void:
	var dir := signf(target.home.x - attacker.home.x)
	attacker.actor.play("run", 0.08)
	await _move(attacker, target.home.x - dir * 1.1, 0.28)
	await attacker.actor.once("attack", "", 1.25)
	attacker.actor.play("run", 0.1)
	_return_home(attacker)


func _return_home(attacker: Combatant) -> void:
	await _move(attacker, attacker.home.x, 0.3)
	if attacker.is_alive():
		attacker.actor.play("combat")


func _move(who: Combatant, x: float, seconds: float) -> void:
	var tween := create_tween()
	tween.tween_property(who.body, "global_position:x", x, seconds).set_trans(Tween.TRANS_QUAD)
	await tween.finished


## Aplica un golpe al enemigo con sus efectos, mensajes y puntos.
func hit_foe(amount: int, mult: float, crit: bool, color: Color) -> void:
	var real := foe.take_damage(amount)
	Audio.sfx("crit" if crit else "hit")
	_shake = 0.25
	Fx.burst(level, foe.chest(), color, 22)
	Fx.popup(level, foe.head(), "¡%d!" % real if crit else "-%d" % real, Color("#ffd34a") if crit else Color.WHITE, crit or mult > 1.0)
	refresh()
	if foe.is_alive():
		await foe.actor.once("hit", "combat")
	if crit:
		Game.add_score("CRITICAL_HIT")
		await say("¡Golpe crítico!")
	if mult > 1.0:
		Game.add_score("EFFECTIVE_HIT")
		await say("¡Es un golpe certero!")
	elif mult < 1.0:
		await say("No es muy eficaz…")


func show_shield(value: bool) -> void:
	_shield_mesh.visible = value


func refresh() -> void:
	if _ui != null:
		_ui.refresh()


## Muestra un mensaje sin detener la secuencia.
func announce(text: String) -> void:
	_ui.set_message(text)


## Muestra un mensaje y espera a que se lea (o a que el jugador lo salte).
func say(text: String, hold := 0.6) -> void:
	await _ui.say(text, hold)


func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, false).timeout
