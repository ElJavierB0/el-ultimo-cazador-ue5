class_name Main
extends Node
## Main: dirige el flujo de pantallas (título → historia → nivel → resumen → final).
## Cada pantalla reemplaza a la anterior.

const STORY_INTRO := [
	"Hace un siglo, la Orden del Cuervo protegía el reino de Velmora de las bestias que nacen de la niebla.",
	"La Orden cayó, traicionada por el mismo reino que juró proteger. Solo queda uno: Kaelen, el último cazador.",
	"Ahora una ceniza negra cae desde el castillo del norte. Donde toca, los muertos se levantan y los hombres se corrompen.",
	"Con una espada de acero para los hombres y una de plata para las bestias, Kaelen emprende el camino.",
]
const STORY_AFTER := [
	[
		"El Caballero Caído se arrodilla por última vez. Bajo su capa, Kaelen encuentra una vieja cota de malla con el emblema del Cuervo.",
		"El medallón tiembla… Algo antiguo despierta en el Pantano de Bruma.",
	],
	[
		"La Bruja del Pantano se deshace en niebla. Sus últimas palabras: «El Señor de la Ceniza te espera, cazador».",
		"Entre sus reliquias brilla la Armadura de la Orden. El Castillo de Ceniza aguarda al norte.",
	],
	[
		"El Señor de la Ceniza se desvanece y la niebla abandona Velmora por primera vez en cien años.",
		"La Orden del Cuervo ya no existe… pero mientras quede un cazador, el reino no estará solo.",
	],
]

var current: Node


func _ready() -> void:
	add_to_group("main")
	show_title()


func _swap(node: Node) -> void:
	get_tree().paused = false
	if current != null:
		current.queue_free()
	current = node
	add_child(node)


func _screen(dim := 0.0, with_backdrop := false) -> VBoxContainer:
	var root := Node.new()
	_swap(root)
	if with_backdrop:
		var stage: LevelBase = (load(Game.LEVELS[0]) as GDScript).new()
		stage.demo = true
		root.add_child(stage)
	var layer := CanvasLayer.new()
	root.add_child(layer)
	return UiKit.screen(layer, dim)


## ---------- Título y menús ----------

func show_title() -> void:
	var c := _screen(0.42, true)
	c.add_child(UiKit.centered("El Último Cazador", 82, UiKit.GOLD, true))
	c.add_child(UiKit.centered("Plata para los muertos. Acero para los hombres.", 24, UiKit.TEXT))
	c.add_child(UiKit.spacer(24))
	var first := UiKit.button("Nueva partida", _new_game)
	for b: Button in [first, UiKit.button("Cómo jugar", show_how_to), UiKit.button("Créditos", show_credits)]:
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		c.add_child(b)
	c.add_child(UiKit.spacer(12))
	c.add_child(UiKit.centered("Versión beta %s" % ProjectSettings.get_setting("application/config/version"), 16, UiKit.MUTED))
	first.grab_focus()


func _new_game() -> void:
	Game.new_game()
	show_story(STORY_INTRO, start_level)


func show_how_to() -> void:
	var c := _screen(0.75, true)
	c.add_child(UiKit.centered("Cómo jugar", 48, UiKit.GOLD, true))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 40)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for row: Array in [
		["Moverse", "← →  o  A D"], ["Saltar", "Espacio, ↑  o  W"], ["Trueque en la hoguera", "E"],
		["Menús y batalla", "Flechas + Enter, o el mouse"], ["Volver / Pausa", "Esc  o  P"], ["Sonido", "M"],
	]:
		grid.add_child(UiKit.label(row[0], 20, UiKit.GOLD))
		grid.add_child(UiKit.label(row[1], 20))
	c.add_child(grid)
	c.add_child(UiKit.spacer(6))
	for line: String in [
		"Enciende las hogueras: curan y guardan tu avance.",
		"En batalla usa ACERO contra humanos y PLATA contra no-muertos.",
		"Las señales gastan vigor; recuperas 1 por turno.",
		"Vence al guardián para abrir la puerta sellada. Tienes 3 vidas.",
	]:
		c.add_child(UiKit.centered(line, 20))
	c.add_child(UiKit.spacer(6))
	_back_button(c)


func show_credits() -> void:
	var c := _screen(0.75, true)
	c.add_child(UiKit.centered("Créditos", 48, UiKit.GOLD, true))
	for pair: Array in [
		["Programación, animación y efectos", "Javier Antonio Romo Bernal"],
		["Arte, niveles, audio y documentación", "Guadalupe Amavizca Quintero"],
		["Modelos 3D y animaciones", "KayKit · Kay Lousberg (CC0)"],
		["Tipografías", "Cinzel y Nunito (SIL Open Font License)"],
		["Motor", "Godot Engine 4 (licencia MIT)"],
		["Materia", "Creación de Videojuegos · Universidad Tecnológica de Hermosillo"],
	]:
		c.add_child(UiKit.centered(pair[0], 17, UiKit.MUTED))
		c.add_child(UiKit.centered(pair[1], 22))
	c.add_child(UiKit.spacer(6))
	_back_button(c)


func _back_button(c: VBoxContainer) -> void:
	var b := UiKit.button("Volver", show_title)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	c.add_child(b)
	b.grab_focus()


## ---------- Partida ----------

func show_story(lines: Array, then: Callable, page := 0) -> void:
	var c := _screen(0.0)
	var text := UiKit.centered(lines[page], 32, UiKit.TEXT)
	text.custom_minimum_size = Vector2(860, 180)
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	c.add_child(text)
	var last := page + 1 >= lines.size()
	var b := UiKit.button("Continuar", func() -> void:
		if last:
			then.call()
		else:
			show_story(lines, then, page + 1))
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	c.add_child(b)
	b.grab_focus()
	text.modulate.a = 0.0
	text.create_tween().tween_property(text, "modulate:a", 1.0, 0.7)


func start_level() -> void:
	Game.hunter.full_heal()
	_swap((load(Game.LEVELS[Game.level_index]) as GDScript).new())


func show_level_clear(seconds: float) -> void:
	var name_done: String = (current as LevelBase).level_name
	var rewarded := Game.hunter.unlock_armor(Game.level_index + 1)
	var c := _screen(0.0)
	c.add_child(UiKit.centered("Nivel completado", 52, UiKit.GOLD, true))
	c.add_child(UiKit.centered("%s  ·  %d:%02d" % [name_done, int(seconds) / 60, int(seconds) % 60], 22, UiKit.MUTED))
	_summary(c)
	if rewarded:
		c.add_child(UiKit.centered("Nueva vestimenta: %s (DEF %d)" % [Game.hunter.armor_name, Game.hunter.defense], 22, UiKit.BLUE))
	var b := UiKit.button("Continuar", _after_level)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	c.add_child(b)
	b.grab_focus()


func _summary(c: VBoxContainer) -> void:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 80)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var summary := Game.score.summary()
	for event: String in summary:
		grid.add_child(UiKit.label(ScoreSystem.LABELS.get(event, event), 20))
		var value := UiKit.label("%+d" % summary[event], 20, UiKit.GREEN if summary[event] >= 0 else UiKit.RED)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		grid.add_child(value)
	c.add_child(grid)
	c.add_child(UiKit.centered("Total: %d puntos" % Game.score.total, 30, UiKit.GOLD, true))


func _after_level() -> void:
	var story: Array = STORY_AFTER[Game.level_index]
	if Game.has_next_level():
		Game.level_index += 1
		show_story(story, start_level)
	else:
		Game.add_score("LIFE_BONUS", Game.lives * ScoreSystem.LIFE_BONUS)
		show_story(story, show_victory)


func show_victory() -> void:
	var c := _screen(0.62, true)
	var pending := Game.level_index + 1 < STORY_AFTER.size()
	c.add_child(UiKit.centered("Fin de la beta" if pending else "Victoria", 60, UiKit.GOLD, true))
	c.add_child(UiKit.centered("El camino continúa en la próxima versión." if pending else "Velmora está a salvo.", 24))
	_final_stats(c)
	_back_button(c)


func show_game_over() -> void:
	var c := _screen(0.0)
	Audio.sfx("defeat")
	c.add_child(UiKit.centered("Has caído", 72, UiKit.RED, true))
	c.add_child(UiKit.centered("La ceniza cubre Velmora.", 24, UiKit.MUTED))
	_final_stats(c)
	var retry := UiKit.button("Intentar de nuevo", func() -> void:
		Game.new_game()
		start_level())
	retry.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	c.add_child(retry)
	_back_button(c)
	retry.grab_focus()


func _final_stats(c: VBoxContainer) -> void:
	c.add_child(UiKit.centered("%d puntos" % Game.score.total, 44, UiKit.GOLD, true))
	c.add_child(UiKit.centered("Enemigos: %d  ·  Monedas: %d  ·  Compras: %d  ·  Caídas: %d" % [
		Game.stats.enemies, Game.stats.coins, Game.stats.purchases, Game.stats.deaths], 20))
	c.add_child(UiKit.spacer(10))
