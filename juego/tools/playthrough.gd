extends Node
## Recorre el juego completo usando solo los controles (sin mover al jugador por código).
## Comprueba que el nivel se puede terminar y, con ventana, guarda capturas de cada momento.
## Uso: godot --path juego res://tools/playthrough.tscn -- --shots=/ruta/de/salida

var _main: Main
var _shots := ""
var _index := 0
var _seen := {}


func _ready() -> void:
	seed(7)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			_shots = arg.trim_prefix("--shots=")
		elif arg.begins_with("--seed="):
			seed(int(arg.trim_prefix("--seed=")))
		elif arg.begins_with("--speed="):
			Engine.time_scale = float(arg.trim_prefix("--speed="))
			Engine.physics_ticks_per_second = int(60 * Engine.time_scale)
			Engine.max_physics_steps_per_frame = 64
	_main = Main.new()
	add_child(_main)
	await _seconds(2.5)
	await _shot("titulo")
	_main.show_how_to()
	await _seconds(0.5)
	await _shot("como_jugar")
	Game.new_game()
	_main.show_story(Main.STORY_INTRO, _main.start_level)
	await _seconds(1.2)
	await _shot("prologo")
	_main.start_level()
	await _seconds(0.8)
	var ok := await _walk(_main.current as LevelBase)
	ok = ok and Game.lives > 0
	print("RECORRIDO %s · vidas %d · puntos %d · enemigos %d · batallas %d · nivel %d · PV %d/%d" % [
		"COMPLETO" if ok else "INCOMPLETO", Game.lives, Game.score.total, Game.stats.enemies, Game.stats.battles,
		Game.hunter.level, Game.hunter.hp, Game.hunter.max_hp])
	if ok:
		await _seconds(1.0)
		await _shot("nivel_completado")
		_main.show_victory()
		await _seconds(0.8)
		await _shot("fin_beta")
	get_tree().quit(0 if ok else 1)


## Avanza a la derecha y salta cuando hay un vacío o un escalón enfrente.
func _walk(level: LevelBase) -> bool:
	var traded := false
	var limit := 240.0
	while limit > 0.0:
		await get_tree().physics_frame
		limit -= get_physics_process_delta_time()
		if not is_instance_valid(level) or level.state == LevelBase.State.DONE:
			_release()
			await _seconds(2.2)
			return not is_instance_valid(level) or _main.current != level
		if level.battle != null:
			_release()
			await _play_battle(level)
			continue
		if level.state != LevelBase.State.PLAYING:
			_release()
			continue
		var p := level.player
		var x := p.global_position.x
		Input.action_press("move_right")
		var ahead_gap := level.ground_at(x + 0.45) == 0
		var step := level.ground_at(x + 1.2) > p.global_position.y + 0.1
		if p.is_on_floor() and (ahead_gap or step):
			Input.action_press("jump")
		elif p.velocity.y <= 0.0:
			Input.action_release("jump")
		if x > 26.0 and not _seen.has("exploracion"):
			_seen["exploracion"] = true
			await _shot("exploracion")
		if x > 44.5 and not traded:
			traded = true
			_release()
			await _seconds(0.6)
			await _shot("hoguera")
			await _trade(level)
	return false


func _trade(level: LevelBase) -> void:
	Game.hunter.add_coins(0)
	for node in level.get_children():
		if node is Bonfire and node.lit:
			Events.shop_requested.emit(node)
			break
	await _seconds(0.4)
	for node in level.get_children():
		if node is ShopPanel:
			node._buy("potion")
			await _seconds(0.4)
			await _shot("trueque")
			node._close()
	await _seconds(0.2)


func _play_battle(level: LevelBase) -> void:
	var b := level.battle
	var tag := "guardian" if b.foe.boss else "batalla"
	var first := not _seen.has(tag)
	_seen[tag] = true
	b.auto_choose = func(battle: Battle) -> String:
		if battle.hero.hp() < 18 and battle.hero.hunter.potions > 0:
			return "pocion"
		return "ascua" if battle.hero.vigor >= 3 and battle.foe.burn == 0 else "acero"
	if first:
		await _seconds(1.6)
		await _shot(tag + "_inicio")
		if tag == "batalla":
			b._ui._open_main()
			await _seconds(0.2)
			await _shot("batalla_menu")
			b._ui._clear_menu()
		await _seconds(2.6)
		await _shot(tag + "_accion")
	while level.battle != null and is_instance_valid(b):
		await get_tree().process_frame


func _release() -> void:
	Input.action_release("move_right")
	Input.action_release("jump")


func _shot(shot_name: String) -> void:
	if _shots == "":
		return
	await RenderingServer.frame_post_draw
	_index += 1
	get_viewport().get_texture().get_image().save_png("%s/%02d_%s.png" % [_shots, _index, shot_name])


func _seconds(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
