extends Node
## Game: estado de la partida en curso (cazador, puntaje, vidas, nivel y estadísticas).
## Es un autoload, así que sobrevive a los cambios de pantalla.

const START_LIVES := 3

## Niveles disponibles en orden. Para agregar un nivel basta con sumar su script a esta lista.
const LEVELS: Array[String] = [
	"res://scripts/levels/level_forest.gd",
]

var hunter: Hunter
var score: ScoreSystem
var shop: Shop
var lives := START_LIVES
var level_index := 0
var stats := {}


func _ready() -> void:
	_setup_input()
	new_game()


func new_game() -> void:
	hunter = Hunter.new()
	score = ScoreSystem.new()
	shop = Shop.new()
	lives = START_LIVES
	level_index = 0
	stats = {"coins": 0, "enemies": 0, "deaths": 0, "battles": 0, "purchases": 0}


## Registra un evento en el puntaje y avisa a la interfaz. Devuelve los puntos obtenidos.
func add_score(event: String, amount: int = ScoreSystem.USE_TABLE) -> int:
	var points := score.add(event, amount)
	Events.score_changed.emit(score.total)
	return points


## Quita una vida y penaliza el puntaje. Devuelve true si todavía quedan intentos.
func lose_life() -> bool:
	lives = maxi(0, lives - 1)
	stats.deaths += 1
	add_score("LIFE_LOST")
	Events.life_lost.emit(lives)
	return lives > 0


func gain_life() -> void:
	lives += 1
	Events.hunter_changed.emit()


func has_next_level() -> bool:
	return level_index + 1 < LEVELS.size()


func _setup_input() -> void:
	_bind("move_left", [KEY_LEFT, KEY_A], JOY_BUTTON_DPAD_LEFT)
	_bind("move_right", [KEY_RIGHT, KEY_D], JOY_BUTTON_DPAD_RIGHT)
	_bind("jump", [KEY_SPACE, KEY_UP, KEY_W], JOY_BUTTON_A)
	_bind("interact", [KEY_E], JOY_BUTTON_X)
	_bind("pause", [KEY_P, KEY_ESCAPE], JOY_BUTTON_START)
	_bind("mute", [KEY_M], JOY_BUTTON_INVALID)
	_bind("skip", [KEY_ENTER, KEY_SPACE, KEY_Z], JOY_BUTTON_A)


func _bind(action: String, keys: Array, button: int) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for key: int in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = key as Key
		InputMap.action_add_event(action, ev)
	if button != JOY_BUTTON_INVALID:
		var jb := InputEventJoypadButton.new()
		jb.button_index = button as JoyButton
		InputMap.action_add_event(action, jb)
