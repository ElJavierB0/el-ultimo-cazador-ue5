class_name BattleRules
extends RefCounted
## BattleRules: fórmulas del combate. Son funciones puras (sin nodos), fáciles de probar.

const MAX_VIGOR := 3
const CRIT_CHANCE := 0.10
const MISS_CHANCE := 0.05
const DODGE_CHANCE := 0.10
const FLEE_CHANCE := 0.70

## Multiplicador de daño del arma o la señal contra el tipo de enemigo.
const EFFECTIVENESS := {
	"acero": {"humano": 1.5, "nomuerto": 0.5, "arcano": 1.0},
	"plata": {"humano": 0.5, "nomuerto": 1.5, "arcano": 1.25},
	"ascua": {"humano": 1.0, "nomuerto": 1.5, "arcano": 0.75},
}


static func effectiveness(weapon: String, type: String) -> float:
	return EFFECTIVENESS.get(weapon, {}).get(type, 1.0)


## Daño = (poder + ataque) × multiplicador × variación − defensa. Siempre hace al menos 1.
static func damage(power: int, attack: int, defense: int, mult := 1.0, ignore_def := false, variance := -1.0) -> int:
	var v := variance if variance > 0.0 else randf_range(0.85, 1.0)
	return maxi(1, roundi((power + attack) * mult * v - (0 if ignore_def else defense)))


static func shielded(amount: int) -> int:
	return ceili(amount / 2.0)


static func burn_damage(max_hp: int) -> int:
	return maxi(2, roundi(max_hp * 0.06))


## Elige un movimiento al azar según su peso. "roll" (0 a 1) permite fijar el resultado en las pruebas.
static func pick_move(moves: Array, roll := -1.0) -> Dictionary:
	var total := 0.0
	for m: Dictionary in moves:
		total += m.weight
	var r := (roll if roll >= 0.0 else randf()) * total
	for m: Dictionary in moves:
		r -= m.weight
		if r <= 0.0:
			return m
	return moves[0]
