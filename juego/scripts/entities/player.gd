class_name Player
extends Entity
## Player: el cazador controlado por el jugador.
## Acciones: correr, salto variable, coyote time, buffer de salto e invulnerabilidad temporal.

const RUN_SPEED := 5.9
const ACCEL := 56.0
const FRICTION := 70.0
const JUMP_VELOCITY := 20.5
const JUMP_CUT := 8.0
const COYOTE_TIME := 0.10
const JUMP_BUFFER := 0.12

var invulnerable := 0.0
var _coyote := 0.0
var _buffer := 0.0
var _land := 0.0
var _was_on_floor := true


func _init() -> void:
	super(Bestiary.hunter_model(Game.hunter.armor), Vector3(0.56, 1.38, 0.6))
	collision_layer = 2
	collision_mask = 1


func _behave(delta: float) -> void:
	var dir := Input.get_axis("move_left", "move_right")
	if absf(dir) > 0.1:
		velocity.x = clampf(velocity.x + signf(dir) * ACCEL * delta, -RUN_SPEED, RUN_SPEED)
		facing = int(signf(dir))
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)

	_coyote = COYOTE_TIME if is_on_floor() else _coyote - delta
	_buffer = JUMP_BUFFER if Input.is_action_just_pressed("jump") else _buffer - delta
	if _buffer > 0.0 and _coyote > 0.0:
		velocity.y = JUMP_VELOCITY
		_coyote = 0.0
		_buffer = 0.0
		Audio.sfx("jump")
	if not Input.is_action_pressed("jump") and velocity.y > JUMP_CUT:
		velocity.y = JUMP_CUT


func _after_move(delta: float) -> void:
	if is_on_floor() and not _was_on_floor:
		_land = 0.2
	_was_on_floor = is_on_floor()
	_land = maxf(0.0, _land - delta)
	if invulnerable > 0.0:
		invulnerable -= delta
		actor.visible = invulnerable <= 0.0 or int(invulnerable * 12.0) % 2 == 0


func _pose() -> String:
	if not is_on_floor():
		return "jump_start" if velocity.y > 0.0 else "jump_air"
	if absf(velocity.x) > 0.6:
		return "run"
	return "jump_land" if _land > 0.0 else "idle"


## Reaparece en un punto con unos segundos de protección.
func respawn(at: Vector3) -> void:
	global_position = at
	velocity = Vector3.ZERO
	invulnerable = 2.0
	actor.visible = true
	set_active(true)


func refresh_outfit() -> void:
	set_model(Bestiary.hunter_model(Game.hunter.armor))
	actor.face(facing)
