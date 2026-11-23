class_name Entity
extends CharacterBody3D
## Entity: clase base de todo lo que se mueve en el nivel (jugador, enemigos y guardianes).
## Resuelve gravedad, colisiones y animación. Cada clase hija define su comportamiento en _behave().

const GRAVITY := 62.5
const MAX_FALL := 26.0

var actor: Actor
var facing := 1
var active := true
var body_size := Vector3(0.56, 1.4, 0.6)


func _init(spec: Dictionary, size: Vector3) -> void:
	body_size = size
	axis_lock_linear_z = true
	var shape := BoxShape3D.new()
	shape.size = size
	var collider := CollisionShape3D.new()
	collider.shape = shape
	collider.position.y = size.y / 2.0
	add_child(collider)
	set_model(spec)


## Cambia el modelo 3D (por ejemplo al estrenar vestimenta).
func set_model(spec: Dictionary) -> void:
	if actor != null:
		actor.queue_free()
	actor = Actor.new(spec)
	add_child(actor)


func _physics_process(delta: float) -> void:
	if not active:
		return
	_behave(delta)
	velocity.y = maxf(-MAX_FALL, velocity.y - GRAVITY * delta)
	move_and_slide()
	_after_move(delta)
	actor.face(facing)
	actor.play(_pose())


## Comportamiento propio de cada entidad (polimorfismo).
func _behave(_delta: float) -> void:
	pass


func _after_move(_delta: float) -> void:
	pass


## Animación que corresponde al estado físico actual.
func _pose() -> String:
	return "idle"


## Detiene o reanuda la física (batallas, hoguera, muerte).
func set_active(value: bool) -> void:
	active = value
	velocity = Vector3.ZERO
