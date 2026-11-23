class_name Pickup
extends Trigger
## Pickup: objeto que se recoge una sola vez. Flota y gira; al tocarlo se aplica su efecto y desaparece.

var taken := false
var _time := randf() * 6.0
var _base_y := 0.0


func _init() -> void:
	super(Vector3(0.7, 0.8, 1.2))


func _ready() -> void:
	_base_y = position.y


func _process(delta: float) -> void:
	_time += delta
	position.y = _base_y + sin(_time * 2.5) * 0.08
	rotation.y += delta * 2.4


func _touch(_player: Player) -> void:
	if taken:
		return
	taken = true
	_collect()
	set_deferred("monitoring", false)
	queue_free()


## Efecto al recogerlo: lo define cada objeto.
func _collect() -> void:
	pass
