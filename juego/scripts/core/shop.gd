class_name Shop
extends RefCounted
## Shop: trueque con el espíritu de la hoguera (transacciones de monedas).
## Cada compra se valida completa antes de aplicarse: o se cobra y se entrega, o no cambia nada.
## Todas quedan en el historial, también las rechazadas.

const ITEMS := {
	"potion": {"name": "Poción", "price": 6, "stock": 5, "hint": "Cura la mitad de la vida en batalla"},
	"whetstone": {"name": "Piedra de afilar", "price": 10, "stock": 2, "hint": "+1 de ataque permanente"},
	"amulet": {"name": "Amuleto del Cuervo", "price": 10, "stock": 2, "hint": "+6 PV máximos"},
	"soul": {"name": "Ascua de alma", "price": 20, "stock": 1, "hint": "+1 vida"},
}

var stock := {}
var history: Array[Transaction] = []


func _init() -> void:
	for id: String in ITEMS:
		stock[id] = ITEMS[id].stock


## Intenta comprar. "state" es el autoload Game (o un doble en las pruebas) con hunter y gain_life().
func buy(item_id: String, hunter: Hunter, on_life: Callable = Callable()) -> Transaction:
	var tx := _process(item_id, hunter, on_life)
	history.append(tx)
	return tx


func _process(item_id: String, hunter: Hunter, on_life: Callable) -> Transaction:
	if not ITEMS.has(item_id):
		return Transaction.new(item_id, "?", 0, hunter.coins).reject("El objeto no existe")
	var item: Dictionary = ITEMS[item_id]
	var tx := Transaction.new(item_id, item.name, item.price, hunter.coins)
	if stock[item_id] <= 0:
		return tx.reject("Agotado")
	if not hunter.spend_coins(item.price):
		return tx.reject("Monedas insuficientes")
	stock[item_id] -= 1
	match item_id:
		"potion": hunter.potions += 1
		"whetstone": hunter.attack += 1
		"amulet":
			hunter.max_hp += 6
			hunter.heal(6)
		"soul":
			if on_life.is_valid():
				on_life.call()
	return tx.approve(hunter.coins)
