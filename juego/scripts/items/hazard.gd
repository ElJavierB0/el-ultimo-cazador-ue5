class_name Hazard
extends Trigger
## Hazard: peligro mortal (vacío o agua). Tocarlo cuesta una vida.

var kind: String


func _init(p_kind: String, size: Vector3) -> void:
	kind = p_kind
	super(size)


func _touch(player: Player) -> void:
	if player.active:
		Events.hazard_touched.emit(kind)
