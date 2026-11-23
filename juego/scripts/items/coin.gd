class_name Coin
extends Pickup
## Coin: moneda. Suma dinero para el trueque y puntos.

func _build() -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.2
	mesh.bottom_radius = 0.2
	mesh.height = 0.06
	var gold := glow_material(Color("#f4b532"), 0.55)
	gold.metallic = 0.8
	gold.roughness = 0.3
	add_mesh(mesh, gold).rotation.x = PI / 2.0


func _collect() -> void:
	Game.hunter.add_coins(1)
	Game.stats.coins += 1
	Game.add_score("COIN")
	Events.coin_collected.emit(global_position)
	Events.hunter_changed.emit()
