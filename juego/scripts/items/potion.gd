class_name Potion
extends Pickup
## Potion: poción para el inventario del cazador.

func _build() -> void:
	var bulb := SphereMesh.new()
	bulb.radius = 0.19
	bulb.height = 0.38
	add_mesh(bulb, glow_material(Color("#ff2a55"), 1.1))
	var neck := CylinderMesh.new()
	neck.top_radius = 0.06
	neck.bottom_radius = 0.07
	neck.height = 0.18
	add_mesh(neck, glow_material(Color("#dfe8ff"), 0.2, 0.6), Vector3(0, 0.24, 0))
	var cork := CylinderMesh.new()
	cork.top_radius = 0.065
	cork.bottom_radius = 0.065
	cork.height = 0.07
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color("#8a5a32")
	add_mesh(cork, wood, Vector3(0, 0.35, 0))


func _collect() -> void:
	Game.hunter.potions += 1
	Game.add_score("POTION")
	Events.potion_collected.emit(global_position)
	Events.hunter_changed.emit()
