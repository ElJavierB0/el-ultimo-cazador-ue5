class_name Bonfire
extends Trigger
## Bonfire: hoguera. La primera vez se enciende (punto de control y curación);
## después permite el trueque de monedas con la tecla E.

var lit := false
var player_near := false
var _light: OmniLight3D
var _flames: CPUParticles3D
var _time := randf() * 10.0


func _init() -> void:
	super(Vector3(1.6, 1.6, 1.6))


func _build() -> void:
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color("#3a2618")
	for i in 5:
		var log_mesh := CylinderMesh.new()
		log_mesh.top_radius = 0.06
		log_mesh.bottom_radius = 0.09
		log_mesh.height = 0.8
		var piece := add_mesh(log_mesh, wood, Vector3(0, -0.62, 0))
		piece.rotation = Vector3(PI / 2.6, TAU * i / 5.0, 0)
	_light = OmniLight3D.new()
	_light.light_color = Color("#ff8a2a")
	_light.light_energy = 0.0
	_light.omni_range = 6.5
	_light.position = Vector3(0, 0.2, 0.4)
	add_child(_light)
	_flames = CPUParticles3D.new()
	_flames.emitting = false
	_flames.amount = 34
	_flames.lifetime = 0.8
	_flames.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_flames.emission_sphere_radius = 0.2
	_flames.direction = Vector3.UP
	_flames.spread = 14.0
	_flames.gravity = Vector3(0, 1.6, 0)
	_flames.initial_velocity_min = 0.7
	_flames.initial_velocity_max = 1.5
	_flames.scale_amount_min = 0.5
	_flames.scale_amount_max = 1.1
	var ember := SphereMesh.new()
	ember.radius = 0.11
	ember.height = 0.22
	ember.radial_segments = 8
	ember.rings = 4
	ember.material = glow_material(Color("#ff7a1a"), 2.2, 0.7)
	_flames.mesh = ember
	var shrink := Curve.new()
	shrink.add_point(Vector2(0, 1))
	shrink.add_point(Vector2(1, 0))
	_flames.scale_amount_curve = shrink
	_flames.position.y = -0.6
	add_child(_flames)


func _process(delta: float) -> void:
	if not lit:
		return
	_time += delta
	_light.light_energy = 2.6 + sin(_time * 11.0) * 0.35 + sin(_time * 23.0) * 0.2


func _touch(_player: Player) -> void:
	player_near = true
	if not lit:
		light()
	else:
		Events.message.emit("E: trueque en la hoguera")


func _leave(_player: Player) -> void:
	player_near = false


## Enciende la hoguera: guarda el punto de control y cura por completo.
func light() -> void:
	lit = true
	_flames.emitting = true
	Game.hunter.full_heal()
	Game.add_score("BONFIRE")
	Events.bonfire_lit.emit(self)
	Events.hunter_changed.emit()


func respawn_point() -> Vector3:
	return global_position + Vector3(0, -0.7, 0)


func _unhandled_input(event: InputEvent) -> void:
	if player_near and lit and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		Events.shop_requested.emit(self)
