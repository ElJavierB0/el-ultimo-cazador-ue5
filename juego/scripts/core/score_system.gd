class_name ScoreSystem
extends RefCounted
## ScoreSystem: calcula el puntaje a partir de los eventos del juego (tabla del GDD).
## Guarda el registro del nivel para mostrar el desglose al terminarlo.

const USE_TABLE := -999999
const POINTS := {
	"COIN": 10,
	"POTION": 25,
	"BONFIRE": 50,
	"EFFECTIVE_HIT": 10,
	"CRITICAL_HIT": 15,
	"FLAWLESS_BATTLE": 50,
	"LEVEL_CLEAR": 500,
	"FLEE": -25,
	"LIFE_LOST": -200,
}
const LABELS := {
	"COIN": "Monedas",
	"POTION": "Pociones recogidas",
	"BONFIRE": "Hogueras encendidas",
	"EFFECTIVE_HIT": "Golpes certeros",
	"CRITICAL_HIT": "Golpes críticos",
	"FLAWLESS_BATTLE": "Batallas sin daño",
	"LEVEL_CLEAR": "Nivel completado",
	"FLEE": "Huidas",
	"LIFE_LOST": "Vidas perdidas",
	"ENEMY_DEFEATED": "Enemigos derrotados",
	"TIME_BONUS": "Bono de tiempo",
	"LIFE_BONUS": "Bono por vidas",
}
const TIME_LIMIT := 240
const TIME_BONUS_PER_SEC := 5
const LIFE_BONUS := 1000

var total := 0
var level_log: Array[Dictionary] = []


## Registra un evento. Sin "amount" usa el valor de la tabla POINTS. El total nunca baja de cero.
func add(event: String, amount: int = USE_TABLE) -> int:
	var points: int = POINTS.get(event, 0) if amount == USE_TABLE else amount
	total = maxi(0, total + points)
	level_log.append({"event": event, "points": points})
	return points


func time_bonus(seconds: float) -> int:
	return maxi(0, floori(TIME_LIMIT - seconds)) * TIME_BONUS_PER_SEC


## Puntos del nivel actual agrupados por evento.
func summary() -> Dictionary:
	var out := {}
	for entry in level_log:
		out[entry.event] = out.get(entry.event, 0) + entry.points
	return out


func start_level() -> void:
	level_log.clear()
