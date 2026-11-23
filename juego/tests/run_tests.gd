extends Node
## Pruebas automáticas de la beta: reglas (unitarias) y nivel jugado de principio a fin (integración).
## Uso: godot --headless --path juego res://tests/tests.tscn
## Termina con código 0 si todo pasa y 1 si algo falla.

var _passed := 0
var _failed := 0
var _group := ""
var _main: Main


func _ready() -> void:
	seed(20261122)
	await get_tree().process_frame
	_test_score()
	_test_hunter()
	_test_shop()
	_test_battle_rules()
	_test_bestiary()
	_test_lives()
	Engine.time_scale = 8.0
	Engine.physics_ticks_per_second = 480
	Engine.max_physics_steps_per_frame = 64
	await _test_level()
	print("\n%d pruebas correctas, %d fallidas" % [_passed, _failed])
	get_tree().quit(0 if _failed == 0 else 1)


func _case(id: String, text: String, ok: bool, detail := "") -> void:
	if ok:
		_passed += 1
	else:
		_failed += 1
	print("%s %s %s%s" % ["OK   " if ok else "FALLA", id, text, "" if ok or detail == "" else "  → " + detail])


func _section(title: String) -> void:
	_group = title
	print("\n== %s ==" % title)


## ---------- Unitarias ----------

func _test_score() -> void:
	_section("Puntaje")
	var s := ScoreSystem.new()
	_case("P-01", "Una moneda suma 10", s.add("COIN") == 10 and s.total == 10)
	s.add("BONFIRE")
	_case("P-02", "Los eventos se acumulan", s.total == 60)
	s.add("LIFE_LOST")
	_case("P-03", "El total nunca baja de cero", s.total == 0)
	_case("P-04", "El bono de tiempo es (240 − s) × 5", s.time_bonus(100.0) == 700)
	_case("P-05", "Sin bono si se pasa del tiempo", s.time_bonus(500.0) == 0)
	s.start_level()
	s.add("COIN")
	s.add("COIN")
	_case("P-06", "El resumen agrupa por evento", s.summary() == {"COIN": 20})


func _test_hunter() -> void:
	_section("Cazador")
	var h := Hunter.new()
	_case("C-01", "Empieza con 40 PV y 2 pociones", h.hp == 40 and h.potions == 2)
	_case("C-02", "El daño no deja la vida en negativo", h.take_damage(999) == 40 and h.hp == 0 and not h.is_alive())
	_case("C-03", "La poción cura 20 y se gasta", h.drink_potion() == 20 and h.potions == 1)
	h.potions = 0
	_case("C-04", "Sin pociones no se puede beber", h.drink_potion() == -1)
	h.full_heal()
	_case("C-05", "La curación no pasa del máximo", h.heal(50) == 0 and h.hp == 40)
	_case("C-06", "100 de experiencia suben un nivel", h.gain_xp(100) == 1 and h.level == 2 and h.max_hp == 48 and h.attack == 8)
	_case("C-07", "La vestimenta mejora la defensa", h.unlock_armor(1) and h.defense == 4)
	_case("C-08", "No se puede volver a una vestimenta anterior", not h.unlock_armor(0))


func _test_shop() -> void:
	_section("Transacciones")
	var h := Hunter.new()
	var shop := Shop.new()
	h.coins = 5
	var tx := shop.buy("potion", h)
	_case("T-01", "Sin monedas suficientes se rechaza y no cobra", not tx.approved and h.coins == 5 and h.potions == 2)
	h.coins = 30
	tx = shop.buy("potion", h)
	_case("T-02", "La compra cobra y entrega", tx.approved and h.coins == 24 and h.potions == 3)
	_case("T-03", "El comprobante guarda el saldo antes y después", tx.balance_before == 30 and tx.balance_after == 24)
	shop.buy("whetstone", h)
	_case("T-04", "La piedra de afilar da +1 de ataque", h.attack == 7 and h.coins == 14)
	shop.buy("amulet", h)
	_case("T-05", "El amuleto da +6 PV máximos", h.max_hp == 46 and h.hp == 46)
	h.coins = 100
	var lives := [3]
	shop.buy("soul", h, func() -> void: lives[0] += 1)
	_case("T-06", "El ascua de alma da una vida", lives[0] == 4 and h.coins == 80)
	tx = shop.buy("soul", h)
	_case("T-07", "Agotado: se rechaza y no cobra", not tx.approved and tx.reason == "Agotado" and h.coins == 80)
	_case("T-08", "Un objeto inexistente se rechaza", not shop.buy("nada", h).approved)
	_case("T-09", "El historial registra todas las operaciones", shop.history.size() == 7, str(shop.history.size()))


func _test_battle_rules() -> void:
	_section("Reglas de batalla")
	_case("B-01", "Acero es eficaz contra humanos", BattleRules.effectiveness("acero", "humano") == 1.5)
	_case("B-02", "Plata es débil contra humanos", BattleRules.effectiveness("plata", "humano") == 0.5)
	_case("B-03", "Daño = (6 + 6) × 1.5 − 1 = 17", BattleRules.damage(6, 6, 1, 1.5, false, 1.0) == 17)
	_case("B-04", "Ascua ignora la defensa", BattleRules.damage(9, 6, 99, 1.0, true, 1.0) == 15)
	_case("B-05", "El daño mínimo es 1", BattleRules.damage(1, 1, 50, 1.0, false, 1.0) == 1)
	_case("B-06", "La Égida reduce a la mitad (redondea hacia arriba)", BattleRules.shielded(7) == 4)
	_case("B-07", "La quemadura es 6 % de la vida (mínimo 2)", BattleRules.burn_damage(60) == 4 and BattleRules.burn_damage(10) == 2)
	var moves: Array = Bestiary.get_enemy("bandido").moves
	_case("B-08", "El enemigo elige según el peso", BattleRules.pick_move(moves, 0.0).name == "Tajo" and BattleRules.pick_move(moves, 1.0).name == "Patada sucia")


func _test_bestiary() -> void:
	_section("Bestiario")
	var files := {}
	var complete := true
	for kind: String in Bestiary.ENEMIES:
		var e: Dictionary = Bestiary.ENEMIES[kind]
		files[e.model.file] = true
		for key: String in ["name", "type", "hp", "atk", "def", "xp", "score", "coins", "moves"]:
			complete = complete and e.has(key)
		complete = complete and ResourceLoader.exists(Actor.CHARACTER_PATH % e.model.file)
	_case("E-01", "Todos los enemigos tienen datos y modelo", complete)
	_case("E-02", "Ningún enemigo repite modelo", files.size() == Bestiary.ENEMIES.size())
	var boss := Enemy.create("caballero")
	var common := Enemy.create("bandido")
	_case("E-03", "El jefe se crea como Guardian y el común como Enemy", boss is Guardian and not (common is Guardian))
	_case("E-04", "Polimorfismo: is_boss() responde según la clase", boss.is_boss() and not common.is_boss())
	boss.free()
	common.free()


func _test_lives() -> void:
	_section("Vidas")
	Game.new_game()
	_case("V-01", "La partida empieza con 3 vidas", Game.lives == 3)
	_case("V-02", "Perder una vida deja 2 y permite seguir", Game.lose_life() and Game.lives == 2)
	Game.lose_life()
	_case("V-03", "Al perder la última se acaba la partida", not Game.lose_life() and Game.lives == 0)
	Game.new_game()
	_case("V-04", "Una partida nueva reinicia todo", Game.lives == 3 and Game.score.total == 0 and Game.stats.deaths == 0)


## ---------- Integración: se juega el nivel 1 completo ----------

func _test_level() -> void:
	_section("Nivel 1 (integración)")
	_main = Main.new()
	add_child(_main)
	await _frames(3)
	Game.new_game()
	_main.start_level()
	await _frames(5)
	var level := _main.current as LevelBase
	await _seconds(0.6)
	_case("N-01", "El nivel carga con jugador, puerta y HUD", level.player != null and level.door != null and level.hud != null)
	_case("N-02", "Colisión: el jugador se apoya en el suelo", level.player.is_on_floor() and absf(level.player.global_position.y - 2.0) < 0.1, str(level.player.global_position))

	var x0 := level.player.global_position.x
	Input.action_press("move_right")
	await _seconds(0.4)
	Input.action_release("move_right")
	_case("N-03", "Acción: correr a la derecha", level.player.global_position.x > x0 + 1.0)
	await _seconds(0.3)
	Input.action_press("jump")
	await _seconds(0.12)
	var y_jump := level.player.global_position.y
	Input.action_release("jump")
	_case("N-04", "Acción: saltar", y_jump > 2.5, str(y_jump))
	await _seconds(0.8)

	level.player.global_position = Vector3(0.4, 2.0, 0)
	Input.action_press("move_left")
	await _seconds(0.4)
	Input.action_release("move_left")
	_case("N-05", "Colisión: la pared del inicio detiene al jugador", level.player.global_position.x > 0.0)

	var coins := Game.hunter.coins
	var score := Game.score.total
	level.player.global_position = level.cell(7, 6) + Vector3(0, 0.3, 0)
	await _seconds(0.1)
	_case("N-06", "Evento: la moneda suma monedas y puntos", Game.hunter.coins > coins and Game.score.total >= score + 10)

	var foe := _find_enemy(level, "bandido")
	var fx := foe.global_position.x
	await _seconds(0.6)
	_case("N-07", "Comportamiento: el enemigo patrulla", absf(foe.global_position.x - fx) > 0.3)
	var far := 0.0
	for i in 30:
		await _seconds(0.2)
		far = maxf(far, absf(foe.global_position.x - 15.5))
	_case("N-08", "Comportamiento: la patrulla no se sale de su zona", far < 4.0 and foe.global_position.y > 1.5, str(far))

	# Huir y volver a pelear
	var result := await _fight(level, foe, func(b: Battle) -> String: return "huir")
	_case("N-09", "Batalla: huir devuelve al mapa y aturde al enemigo", result == "flee" and foe.stunned > 0.0 and level.state == LevelBase.State.PLAYING, result)
	foe.stunned = 0.0
	level.player.invulnerable = 0.0
	var before := Game.score.total
	result = await _fight(level, foe, _smart)
	_case("N-10", "Batalla: vencer al bandido da puntos y lo retira", result == "win" and Game.score.total >= before + 100 and not is_instance_valid(foe), result)

	# Vacío: pierde una vida y reaparece
	level.player.invulnerable = 0.0
	var lives := Game.lives
	level.player.global_position = Vector3(21.5, 1.0, 0)
	await _seconds(2.2)
	_case("N-11", "Peligro: caer al vacío quita una vida", Game.lives == lives - 1, str(Game.lives))
	_case("N-12", "Vidas: reaparece en el último punto de control", level.player.global_position.distance_to(level.respawn_point) < 1.0 and level.player.active)

	# Hoguera
	Game.hunter.hp = 5
	var fire := _find_bonfire(level)
	level.player.global_position = fire.respawn_point()
	await _seconds(0.2)
	_case("N-13", "Evento: la hoguera se enciende y cura", fire.lit and Game.hunter.hp == Game.hunter.max_hp)
	_case("N-14", "Evento: la hoguera guarda el punto de control", level.respawn_point.distance_to(fire.respawn_point()) < 0.1)

	# Trueque
	Game.hunter.coins = 50
	Events.shop_requested.emit(fire)
	await _frames(3)
	var panel := _find_shop(level)
	_case("N-15", "Transacción: la hoguera abre el trueque y detiene al jugador", panel != null and not level.player.active)
	panel._buy("potion")
	panel._buy("amulet")
	await _frames(2)
	_case("N-16", "Transacción: la compra descuenta el saldo", Game.hunter.coins == 34 and Game.stats.purchases == 2, str(Game.hunter.coins))
	panel._close()
	await _frames(3)
	_case("N-17", "Al cerrar el trueque el juego continúa", level.player.active and level.state == LevelBase.State.PLAYING)

	# Derrota en batalla
	var raider := _find_enemy(level, "saqueador")
	lives = Game.lives
	Game.hunter.hp = 1
	result = await _fight(level, raider, func(b: Battle) -> String: return "plata")
	await _seconds(0.3)
	_case("N-18", "Batalla: perder quita una vida y reaparece con vida completa", result == "lose" and Game.lives == lives - 1 and Game.hunter.hp == Game.hunter.max_hp, result)

	# Puerta sellada, guardián y fin del nivel
	level.player.invulnerable = 0.0
	level.player.global_position = level.door.global_position + Vector3(0, -1.1, 0)
	await _seconds(0.3)
	_case("N-19", "La puerta no abre antes de vencer al guardián", level.state == LevelBase.State.PLAYING and not level.door.opened)
	Game.hunter.full_heal()
	Game.hunter.potions = 5
	var boss := _find_enemy(level, "caballero")
	level.player.global_position = Vector3(90, 2, 0)
	await _seconds(0.2)
	result = await _fight(level, boss, _smart)
	_case("N-20", "Guardián: vencerlo abre la puerta", result == "win" and level.door.opened, result)
	await _seconds(0.3)
	level.player.global_position = level.door.global_position + Vector3(0, -1.1, 0)
	await _seconds(3.0)
	_case("N-21", "La puerta abierta termina el nivel con desglose", _main.current != level and Game.score.summary().has("LEVEL_CLEAR") and Game.score.summary().has("TIME_BONUS"))
	_case("N-22", "Recompensa: se desbloquea la cota de malla", Game.hunter.armor == 1)
	_main._after_level()
	await _frames(3)
	_case("N-23", "Al terminar la beta se suma el bono por vidas", Game.score.summary().has("LIFE_BONUS"))

	# Fin de la partida
	Game.new_game()
	Game.lives = 1
	_main.start_level()
	await _frames(5)
	level = _main.current as LevelBase
	level.player.global_position = Vector3(21.5, 1.0, 0)
	await _seconds(2.5)
	_case("N-24", "Sin vidas se muestra el fin de la partida", Game.lives == 0 and _main.current != level)
	await _test_keyboard()


## ---------- Interfaz con teclado real (eventos de teclas, no llamadas directas) ----------

func _test_keyboard() -> void:
	_section("Interfaz con teclado")
	_main.show_title()
	await _frames(5)
	await _key(KEY_ENTER)
	await _seconds(0.5)
	for i in Main.STORY_INTRO.size():
		await _key(KEY_ENTER)
		await _seconds(0.5)
	var level := _main.current as LevelBase
	_case("I-01", "Enter: título → historia → nivel 1", level != null)
	if level == null:
		return
	await _seconds(0.5)
	await _key(KEY_ESCAPE)
	_case("I-02", "Esc: pausa el juego", get_tree().paused)
	await _key(KEY_ESCAPE)
	_case("I-03", "Esc: continúa el juego", not get_tree().paused)

	var fire := _find_bonfire(level)
	level.player.global_position = fire.respawn_point()
	await _seconds(0.3)
	await _key(KEY_E)
	_case("I-08", "E: abre el trueque junto a la hoguera encendida", _find_shop(level) != null)
	await _key(KEY_ESCAPE)
	await _seconds(0.2)
	_case("I-09", "Esc: cierra el trueque sin pausar el juego", _find_shop(level) == null and not get_tree().paused and level.player.active)

	var foe := _find_enemy(level, "bandido")
	level.player.global_position = foe.global_position + Vector3(-0.3, 0.1, 0)
	for i in 400:
		if level.battle != null:
			break
		await _frames(1)
	var battle := level.battle
	# Vida alta para que un golpe crítico no termine la batalla antes de probar el menú
	battle.foe._max_hp = 500
	battle.foe._hp = 500
	await _wait_menu(battle)
	var hp := battle.foe.hp()
	await _key(KEY_ENTER)
	await _key(KEY_ENTER)
	await _seconds(2.5)
	_case("I-04", "Enter, Enter: ataca con la espada de acero", battle.foe.hp() < hp, str(battle.foe.hp()))
	await _wait_menu(battle)
	await _key(KEY_RIGHT)
	await _key(KEY_ENTER)
	await _key(KEY_ESCAPE)
	_case("I-05", "Esc regresa del submenú sin gastar el turno", battle._ui._menu.get_child_count() == 4)
	var potions := Game.hunter.potions
	for code: Key in [KEY_LEFT, KEY_DOWN, KEY_ENTER]:
		await _key(code)
	await _seconds(1.0)
	_case("I-06", "Flechas + Enter: bebe una poción", Game.hunter.potions == potions - 1, str(Game.hunter.potions))
	_main.show_title()
	await _frames(5)
	_case("I-07", "Salir al título a media batalla no rompe el juego", _main.current != level)


func _wait_menu(battle: Battle) -> void:
	for i in 4000:
		if battle._ui != null and battle._ui._menu.get_child_count() > 0:
			return
		await _frames(1)


func _key(code: Key) -> void:
	for pressed: bool in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = code
		ev.physical_keycode = code
		ev.pressed = pressed
		Input.parse_input_event(ev)
		await _frames(3)


func _smart(b: Battle) -> String:
	if b.hero.hp() < 18 and b.hero.hunter.potions > 0:
		return "pocion"
	if b.hero.vigor >= 3 and b.foe.burn == 0:
		return "ascua"
	return "acero"


## Lleva al jugador hasta el enemigo y juega la batalla con la estrategia indicada. Devuelve el resultado.
func _fight(level: LevelBase, foe: Enemy, strategy: Callable) -> String:
	var outcome := [""]
	var listen := func(result: String, _enemy: Enemy) -> void: outcome[0] = result
	Events.battle_finished.connect(listen)
	level.player.global_position = foe.global_position + Vector3(-0.3, 0.1, 0)
	for i in 400:
		if level.battle != null:
			break
		await _frames(1)
	if level.battle == null:
		Events.battle_finished.disconnect(listen)
		return "sin batalla"
	level.battle.auto_choose = strategy
	for i in 30000:
		if outcome[0] != "":
			break
		await _frames(1)
	Events.battle_finished.disconnect(listen)
	await _frames(3)
	return outcome[0]


func _find_enemy(level: LevelBase, kind: String) -> Enemy:
	for node in level.get_children():
		if node is Enemy and node.kind == kind:
			return node
	return null


func _find_bonfire(level: LevelBase) -> Bonfire:
	for node in level.get_children():
		if node is Bonfire:
			return node
	return null


func _find_shop(level: LevelBase) -> ShopPanel:
	for node in level.get_children():
		if node is ShopPanel:
			return node
	return null


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame


func _seconds(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
