class_name Guardian
extends Enemy
## Guardian: jefe del nivel. Camina lento, vigila un tramo corto y se detiene a mirar al jugador si se acerca.
## Al vencerlo se abre la puerta sellada.

const SIGHT := 6.0


func _init(p_kind: String) -> void:
	super(p_kind)
	patrol_speed = 1.1
	patrol_range = 2.0
	var aura := OmniLight3D.new()
	aura.light_color = Color("#ff3a2a")
	aura.light_energy = 1.1
	aura.omni_range = 3.2
	aura.position = Vector3(0, 0.6, -1.1)
	add_child(aura)


func is_boss() -> bool:
	return true


func _choose_direction() -> void:
	super()
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return
	var gap := player.global_position.x - global_position.x
	if absf(gap) < SIGHT and absf(global_position.x + signf(gap) * 0.2 - _home_x) <= patrol_range:
		facing = 1 if gap > 0.0 else -1
