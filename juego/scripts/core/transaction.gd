class_name Transaction
extends RefCounted
## Transaction: comprobante de una operación de compra en la hoguera (aprobada o rechazada).

var item_id: String
var item_name: String
var price: int
var balance_before: int
var balance_after: int
var approved: bool
var reason: String


func _init(p_id: String, p_name: String, p_price: int, p_before: int) -> void:
	item_id = p_id
	item_name = p_name
	price = p_price
	balance_before = p_before
	balance_after = p_before
	approved = false
	reason = ""


func approve(new_balance: int) -> Transaction:
	approved = true
	balance_after = new_balance
	reason = "Compra realizada"
	return self


func reject(why: String) -> Transaction:
	approved = false
	balance_after = balance_before
	reason = why
	return self
