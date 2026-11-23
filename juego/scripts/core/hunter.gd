class_name Hunter
extends RefCounted
## Hunter: estadísticas persistentes del cazador.
## Encapsula vida, experiencia, inventario y vestimenta; solo se modifican con sus métodos.

const ARMORS := [
	{"name": "Jubón de cuero", "def": 2},
	{"name": "Cota de malla", "def": 4},
	{"name": "Armadura de la Orden", "def": 6},
]

var display_name := "Kaelen"
var level := 1
var xp := 0
var max_hp := 40
var hp := 40
var attack := 6
var armor := 0
var potions := 2
var coins := 0

var defense: int:
	get: return ARMORS[armor].def
var armor_name: String:
	get: return ARMORS[armor].name
var xp_to_next: int:
	get: return level * 100


func is_alive() -> bool:
	return hp > 0


func take_damage(amount: int) -> int:
	var real := clampi(amount, 0, hp)
	hp -= real
	return real


func heal(amount: int) -> int:
	var before := hp
	hp = mini(max_hp, hp + amount)
	return hp - before


func full_heal() -> void:
	hp = max_hp


## Bebe una poción: cura la mitad de la vida (mínimo 20). Devuelve lo curado o -1 si no hay.
func drink_potion() -> int:
	if potions <= 0:
		return -1
	potions -= 1
	return heal(maxi(20, roundi(max_hp * 0.5)))


func add_coins(amount: int) -> void:
	coins += maxi(0, amount)


## Paga con monedas. Si no alcanza no cobra nada y devuelve false.
func spend_coins(amount: int) -> bool:
	if amount < 0 or coins < amount:
		return false
	coins -= amount
	return true


## Suma experiencia y devuelve cuántos niveles subió.
func gain_xp(amount: int) -> int:
	xp += amount
	var ups := 0
	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		max_hp += 8
		attack += 2
		hp = mini(max_hp, hp + 8)
		ups += 1
	return ups


## Equipa una vestimenta mejor. Devuelve true si cambió.
func unlock_armor(index: int) -> bool:
	if index <= armor or index >= ARMORS.size():
		return false
	armor = index
	return true
