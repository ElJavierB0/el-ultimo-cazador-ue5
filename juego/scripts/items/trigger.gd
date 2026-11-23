class_name Trigger
extends Area3D
## Trigger: clase base de los objetos que reaccionan cuando el jugador los toca
## (monedas, pociones, hogueras, puerta y peligros).

func _init(size: Vector3) -> void:
	collision_layer = 8
	collision_mask = 2
	var shape := BoxShape3D.new()
	shape.size = size
	var collider := CollisionShape3D.new()
	collider.shape = shape
	add_child(collider)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_build()


## Construye el aspecto del objeto.
func _build() -> void:
	pass


## Reacción del objeto al contacto (polimorfismo).
func _touch(_player: Player) -> void:
	pass


func _leave(_player: Player) -> void:
	pass


func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		_touch(body as Player)


func _on_body_exited(body: Node3D) -> void:
	if body is Player:
		_leave(body as Player)


static func glow_material(color: Color, energy := 1.0, alpha := 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color, alpha)
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


func add_mesh(mesh: Mesh, material: Material, pos := Vector3.ZERO) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.position = pos
	add_child(node)
	return node
