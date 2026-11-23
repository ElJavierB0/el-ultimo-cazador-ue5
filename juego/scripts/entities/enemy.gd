class_name Enemy
extends Entity
## Enemy: enemigo del mapa. Patrulla alrededor de su punto de origen, da la vuelta en paredes y orillas
## y provoca una batalla al tocar al jugador.

var kind: String
var data: Dictionary
var stunned := 0.0
var patrol_speed := 1.6
var patrol_range := 3.0
var _home_x := 0.0
var _contact: Area3D
var _edge: RayCast3D


func _init(p_kind: String) -> void:
	kind = p_kind
	data = Bestiary.get_enemy(kind)
	var h: float = data.model.height
	super(data.model, Vector3(0.7, h * 0.88, 0.7))
	collision_layer = 4
	collision_mask = 1
	facing = -1
	_setup_sensors()


## Crea la enemy correcta según el bestiario: los guardianes tienen su propia clase.
static func create(p_kind: String) -> Enemy:
	return Guardian.new(p_kind) if Bestiary.get_enemy(p_kind).get("boss", false) else Enemy.new(p_kind)


func _ready() -> void:
	_home_x = global_position.x


func _setup_sensors() -> void:
	_contact = Area3D.new()
	_contact.collision_layer = 0
	_contact.collision_mask = 2
	var shape := BoxShape3D.new()
	shape.size = body_size + Vector3(0.1, 0.0, 0.4)
	var collider := CollisionShape3D.new()
	collider.shape = shape
	collider.position.y = body_size.y / 2.0
	_contact.add_child(collider)
	add_child(_contact)
	_edge = RayCast3D.new()
	_edge.collision_mask = 1
	_edge.target_position = Vector3(0, -0.8, 0)
	add_child(_edge)


func is_boss() -> bool:
	return false


func _behave(delta: float) -> void:
	if stunned > 0.0:
		stunned -= delta
		velocity.x = 0.0
		return
	_choose_direction()
	velocity.x = facing * patrol_speed
	_edge.position = Vector3(facing * (body_size.x / 2.0 + 0.15), 0.3, 0.0)


func _choose_direction() -> void:
	if (global_position.x - _home_x) * facing > patrol_range:
		facing *= -1
	elif is_on_wall() and signf(get_wall_normal().x) != facing:
		facing *= -1
	elif is_on_floor() and not _edge.is_colliding():
		facing *= -1


func _after_move(_delta: float) -> void:
	if stunned > 0.0:
		return
	for body in _contact.get_overlapping_bodies():
		if body is Player and body.active and body.invulnerable <= 0.0:
			Events.enemy_touched.emit(self)
			return


func _pose() -> String:
	return "walk" if absf(velocity.x) > 0.1 else "idle"


func defeat() -> void:
	queue_free()
