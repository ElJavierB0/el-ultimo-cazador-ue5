class_name LevelBase
extends Node3D
## LevelBase: clase base de los niveles. Construye el terreno y los objetos a partir del mapa que define
## cada nivel en _layout(), controla la cámara y reacciona a los eventos de la partida.
##
## Mapa: cuadrícula de 11 filas (0 = arriba, 10 = abajo); cada celda mide 1 unidad.
## Un objeto en la fila 8 queda parado sobre un suelo de 2 filas de alto.

enum State { PLAYING, BATTLE, SHOP, DYING, DONE }

const ROWS := 11
const DEPTH := 4.0
const PROP_PATH := "res://assets/models/props/%s.glb"

var level_name := "Nivel"
var music := "forest"
var columns := 100
var demo := false  ## Modo vitrina para la pantalla de título (sin jugador ni HUD).

var state := State.PLAYING
var player: Player
var door: ExitDoor
var camera: Camera3D
var hud: Hud
var elapsed := 0.0
var respawn_point := Vector3.ZERO
var battle: Battle

var _tops := PackedInt32Array()  ## Altura del suelo por columna (0 = vacío).
var _decor := RandomNumberGenerator.new()
var _door_cooldown := 0.0
var _medallion := 0.0
var _demo_time := 0.0


func _ready() -> void:
	_decor.seed = hash(level_name)
	_setup_level()
	_tops.resize(columns)
	_layout()
	_build_terrain()
	_build_environment()
	_build_backdrop()
	_build_void()
	_build_camera()
	if demo:
		Audio.music("title")
		return
	Game.score.start_level()
	hud = Hud.new()
	add_child(hud)
	_connect_events()
	Audio.music(music)
	Events.message.emit(level_name)


## ---------- Lo que define cada nivel ----------

## Nombre, música y ancho del nivel.
func _setup_level() -> void:
	pass


## Mapa del nivel: se arma con ground(), platform(), coins(), enemy(), etc.
func _layout() -> void:
	pass


## Colores del nivel: cielo, niebla, luz de luna y terreno.
func _theme() -> Dictionary:
	return {
		"sky_top": Color("#05070f"), "sky_horizon": Color("#1b2740"), "fog": Color("#16203a"), "fog_density": 0.018,
		"moon": Color("#aebfe8"), "moon_energy": 1.1, "ambient": Color("#4a5a86"), "ambient_energy": 0.55,
		"top": Color("#26382a"), "side": Color("#1a1712"), "platform": Color("#4a3826"), "mountain": Color("#0c1222"),
	}


## Escenografía de fondo del nivel.
func _build_backdrop() -> void:
	pass


## ---------- Herramientas para armar el mapa ----------

func cell(x: float, row: float) -> Vector3:
	return Vector3(x + 0.5, ROWS - 1 - row, 0.0)


## Suelo desde la columna x0 hasta x1 (sin incluirla) con "height" filas de alto.
func ground(x0: int, x1: int, height: int) -> void:
	for x in range(x0, mini(x1, columns)):
		_tops[x] = height


## Plataforma flotante de "length" celdas.
func platform(x: int, row: int, length: int) -> void:
	var size := Vector3(length, 0.34, 1.7)
	var center := Vector3(x + length / 2.0, ROWS - row - 0.17, 0.0)
	_solid(center, size, _material(_theme().platform))
	for side: float in [0.25, length - 0.25]:
		var chain := CylinderMesh.new()
		chain.top_radius = 0.03
		chain.bottom_radius = 0.03
		chain.height = 3.0
		_mesh(chain, _material(Color("#3a3a40")), Vector3(x + side, center.y + 1.6, -0.5))


func water(x0: int, x1: int) -> void:
	var width := float(x1 - x0)
	var mat := Trigger.glow_material(Color("#0f3a30"), 0.5, 0.88)
	mat.roughness = 0.1
	var box := BoxMesh.new()
	box.size = Vector3(width, 0.1, DEPTH)
	_mesh(box, mat, Vector3(x0 + width / 2.0, 1.6, 0))
	var bed := BoxMesh.new()
	bed.size = Vector3(width, 6.0, DEPTH)
	_mesh(bed, _material(Color("#0a1410")), Vector3(x0 + width / 2.0, -1.6, 0))
	var hazard := Hazard.new("water", Vector3(width - 0.2, 1.0, DEPTH))
	hazard.position = Vector3(x0 + width / 2.0, 1.0, 0)
	add_child(hazard)


func start(x: int, row: int) -> void:
	respawn_point = cell(x, row)
	if demo:
		return
	player = Player.new()
	player.position = respawn_point
	player.add_to_group("player")
	add_child(player)


func coins(x: int, row: int, count: int) -> void:
	for i in count:
		_place(Coin.new(), cell(x + i, row) + Vector3(0, 0.5, 0))


func potion(x: int, row: int) -> void:
	_place(Potion.new(), cell(x, row) + Vector3(0, 0.35, 0))


func bonfire(x: int, row: int) -> void:
	_place(Bonfire.new(), cell(x, row) + Vector3(0, 0.8, 0))


func enemy(kind: String, x: int, row: int) -> void:
	if not demo:
		_place(Enemy.create(kind), cell(x, row))


func exit(x: int, row: int) -> void:
	door = ExitDoor.new()
	_place(door, cell(x, row) + Vector3(0, 1.1, 0))


func prop(prop_name: String, pos: Vector3, scale_by := 1.0, rotation_by := 0.0, tint := Color.WHITE) -> Node3D:
	var node: Node3D = (load(PROP_PATH % prop_name) as PackedScene).instantiate()
	node.position = pos
	node.scale = Vector3.ONE * scale_by
	node.rotation.y = rotation_by
	if tint != Color.WHITE:
		for child: Node in node.find_children("*", "MeshInstance3D", true, false):
			var mesh := child as MeshInstance3D
			for i in mesh.mesh.get_surface_count():
				var m := mesh.mesh.surface_get_material(i).duplicate() as BaseMaterial3D
				m.albedo_color = tint
				mesh.set_surface_override_material(i, m)
	add_child(node)
	return node


## Coloca objetos decorativos junto al camino.
func scatter(names: Array, density: float, scale_by: float) -> void:
	var x := 2.0
	while x < columns - 2:
		if _decor.randf() < density and ground_at(x) > 0:
			var n: String = names[_decor.randi() % names.size()]
			prop(n, Vector3(x, ground_at(x), -1.5 - _decor.randf() * 0.35),
				scale_by * _decor.randf_range(0.45, 0.65), _decor.randf_range(-0.6, 0.6), Color("#8a8fa0"))
		x += 1.5 + _decor.randf() * 3.0


## Faroles con luz cálida.
func lanterns(names: Array, color: Color, every: float) -> void:
	var x := 8.0
	var i := 0
	while x < columns - 4:
		if ground_at(x) > 0:
			prop(names[i % names.size()], Vector3(x, ground_at(x), -1.6), 0.8)
			var light := OmniLight3D.new()
			light.light_color = color
			light.light_energy = 1.6
			light.omni_range = 5.5
			light.position = Vector3(x, ground_at(x) + 1.5, -1.0)
			add_child(light)
			i += 1
		x += every + _decor.randf() * 6.0


func ground_at(x: float) -> int:
	var c := floori(x)
	return _tops[c] if c >= 0 and c < columns else 0


## Tramo de suelo continuo a la misma altura alrededor de x (para acomodar a los combatientes).
func segment_at(x: float) -> Vector2:
	var c := clampi(floori(x), 0, columns - 1)
	var a := c
	var b := c
	while a > 0 and _tops[a - 1] == _tops[c]:
		a -= 1
	while b < columns - 1 and _tops[b + 1] == _tops[c]:
		b += 1
	return Vector2(a, b + 1)


## ---------- Construcción ----------

func _place(node: Node3D, pos: Vector3) -> void:
	node.position = pos
	add_child(node)


func _material(color: Color, roughness := 0.95) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	return m


func _mesh(mesh: Mesh, material: Material, pos: Vector3) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.position = pos
	add_child(node)
	return node


func _solid(center: Vector3, size: Vector3, material: Material) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = center
	var shape := BoxShape3D.new()
	shape.size = size
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)
	if material != null:
		var box := BoxMesh.new()
		box.size = size
		var mesh := MeshInstance3D.new()
		mesh.mesh = box
		mesh.material_override = material
		body.add_child(mesh)
	add_child(body)


func _build_terrain() -> void:
	var th := _theme()
	var side := _material(th.side)
	var top := _material(th.top)
	var from := 0
	for x in range(1, columns + 1):
		if x < columns and _tops[x] == _tops[from]:
			continue
		var h := _tops[from]
		if h > 0:
			var w := float(x - from)
			_solid(Vector3(from + w / 2.0, h / 2.0 - 4.0, 0), Vector3(w, h + 8.0, DEPTH), side)
			var cap := BoxMesh.new()
			cap.size = Vector3(w + 0.08, 0.24, DEPTH + 0.12)
			_mesh(cap, top, Vector3(from + w / 2.0, h - 0.1, 0))
			_build_grass(from, x, h, th.top)
		from = x
	# Paredes invisibles en los extremos
	_solid(Vector3(-0.5, 10, 0), Vector3(1, 40, DEPTH), null)
	_solid(Vector3(columns + 0.5, 10, 0), Vector3(1, 40, DEPTH), null)


func _build_grass(x0: int, x1: int, h: int, color: Color) -> void:
	var blade := CylinderMesh.new()
	blade.top_radius = 0.0
	blade.bottom_radius = 0.035
	blade.height = 0.26
	blade.radial_segments = 4
	blade.rings = 1
	blade.material = _material(color.lightened(0.16))
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = blade
	multi.instance_count = (x1 - x0) * 9
	for i in multi.instance_count:
		var s := _decor.randf_range(0.6, 1.5)
		var basis_rot := Basis.from_euler(Vector3(_decor.randf_range(-0.25, 0.25), _decor.randf() * 3.0, _decor.randf_range(-0.25, 0.25)))
		multi.set_instance_transform(i, Transform3D(basis_rot.scaled(Vector3.ONE * s),
			Vector3(_decor.randf_range(x0, x1), h + 0.1 * s, _decor.randf_range(-1.9, 1.8))))
	var node := MultiMeshInstance3D.new()
	node.multimesh = multi
	add_child(node)


func _build_environment() -> void:
	var th := _theme()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = th.sky_top
	sky_mat.sky_horizon_color = th.sky_horizon
	sky_mat.ground_bottom_color = th.sky_top
	sky_mat.ground_horizon_color = th.sky_horizon
	sky_mat.sun_angle_max = 0.0
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = th.ambient
	env.ambient_light_energy = th.ambient_energy
	env.fog_enabled = true
	env.fog_light_color = th.fog
	env.fog_density = th.fog_density
	env.fog_sky_affect = 0.25
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_bloom = 0.06
	var world := WorldEnvironment.new()
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.light_color = th.moon
	sun.light_energy = th.moon_energy
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 45.0
	sun.rotation_degrees = Vector3(-48, -32, 0)
	add_child(sun)
	var rim := DirectionalLight3D.new()
	rim.light_color = th.moon
	rim.light_energy = th.moon_energy * 0.55
	rim.rotation_degrees = Vector3(-20, 170, 0)
	add_child(rim)


func _build_void() -> void:
	var hazard := Hazard.new("void", Vector3(columns + 20.0, 2.0, 12.0))
	hazard.position = Vector3(columns / 2.0, -4.0, 0)
	add_child(hazard)


func _build_camera() -> void:
	camera = Camera3D.new()
	camera.fov = 46.0
	camera.far = 220.0
	add_child(camera)
	camera.position = Vector3(maxf(7.0, respawn_point.x), 4.6, 11.0)
	camera.current = true


## ---------- Cada cuadro ----------

func _process(delta: float) -> void:
	if demo:
		_demo_time += delta
		camera.position = Vector3(14.0 + sin(_demo_time * 0.12) * 6.0, 4.4, 11.0)
		camera.look_at(camera.position + Vector3(0, -0.5, -11.0))
		return
	if state == State.PLAYING:
		elapsed += delta
		_door_cooldown = maxf(0.0, _door_cooldown - delta)
		_update_medallion(delta)
	if state != State.BATTLE:
		_follow_player(delta)


func _follow_player(delta: float) -> void:
	var target := Vector3(
		clampf(player.global_position.x + player.facing * 1.4, 7.0, columns - 7.0),
		maxf(4.2, player.global_position.y + 2.4), 11.0)
	camera.position = camera.position.lerp(target, minf(1.0, delta * 3.4))
	camera.look_at(camera.position + Vector3(0, -0.65, -11.0))


## El medallón vibra cuando hay un enemigo cerca.
func _update_medallion(delta: float) -> void:
	var near := false
	for node in get_children():
		if node is Enemy and absf(node.global_position.x - player.global_position.x) < 6.0:
			near = true
			break
	hud.set_medallion(near)
	if near:
		_medallion -= delta
		if _medallion <= 0.0:
			Audio.sfx("medallion")
			_medallion = 0.8


## ---------- Eventos ----------

func _connect_events() -> void:
	Events.coin_collected.connect(_on_coin)
	Events.potion_collected.connect(_on_potion)
	Events.bonfire_lit.connect(_on_bonfire)
	Events.enemy_touched.connect(_on_enemy_touched)
	Events.battle_finished.connect(_on_battle_finished)
	Events.hazard_touched.connect(_on_hazard)
	Events.door_touched.connect(_on_door)
	Events.shop_requested.connect(_on_shop)


func _on_coin(at: Vector3) -> void:
	Audio.sfx("coin")
	Fx.burst(self, at, Color("#ffd86a"), 14)
	Fx.popup(self, at, "+%d" % ScoreSystem.POINTS.COIN, Color("#ffe08a"))


func _on_potion(at: Vector3) -> void:
	Audio.sfx("potion")
	Fx.burst(self, at, Color("#ff6a8a"), 14)
	Fx.popup(self, at, "+%d Poción" % ScoreSystem.POINTS.POTION, Color("#ff9fb2"))


func _on_bonfire(bonfire_node: Bonfire) -> void:
	respawn_point = bonfire_node.respawn_point()
	Audio.sfx("checkpoint")
	Fx.burst(self, bonfire_node.global_position, Color("#ff9a3a"), 30)
	Fx.popup(self, bonfire_node.global_position + Vector3(0, 0.6, 0), "+%d" % ScoreSystem.POINTS.BONFIRE, Color("#ffb04a"))
	Events.message.emit("Hoguera encendida · vida restaurada · E: trueque")


func _on_enemy_touched(foe: Enemy) -> void:
	if state != State.PLAYING:
		return
	state = State.BATTLE
	player.set_active(false)
	for node in get_children():
		if node is Enemy:
			node.set_active(false)
	Audio.stop_music()
	Audio.sfx("battle_start")
	Game.stats.battles += 1
	hud.visible = false
	battle = Battle.new(self, player, foe)
	add_child(battle)
	Events.battle_started.emit(foe)


func _on_battle_finished(result: String, foe: Enemy) -> void:
	battle = null
	hud.visible = true
	for node in get_children():
		if node is Enemy:
			node.set_active(true)
	if result == "lose":
		_lose_life()
		return
	if result == "win":
		player.invulnerable = 1.0
		if foe.is_boss():
			door.open()
			Audio.sfx("checkpoint")
			Events.message.emit("¡La puerta se ha abierto!")
		foe.defeat()
	else:
		foe.stunned = 2.5
		player.invulnerable = 2.5
	player.set_active(true)
	state = State.PLAYING
	Audio.music(music)
	Events.hunter_changed.emit()


func _on_hazard(_kind: String) -> void:
	if state != State.PLAYING:
		return
	state = State.DYING
	player.set_active(false)
	player.actor.visible = false
	Audio.sfx("death")
	Fx.burst(self, player.global_position + Vector3(0, 0.8, 0), Color("#9fe0d0"), 30)
	await get_tree().create_timer(1.0, false).timeout
	_lose_life()


func _lose_life() -> void:
	if not Game.lose_life():
		state = State.DONE
		Audio.stop_music()
		(get_tree().get_first_node_in_group("main") as Main).show_game_over()
		return
	Game.hunter.full_heal()
	player.respawn(respawn_point)
	state = State.PLAYING
	Audio.music(music)
	Events.hunter_changed.emit()
	Events.message.emit("Te quedan %d %s" % [Game.lives, "vida" if Game.lives == 1 else "vidas"])


func _on_door() -> void:
	if state != State.PLAYING:
		return
	if not door.opened:
		if _door_cooldown <= 0.0:
			_door_cooldown = 2.0
			Audio.sfx("locked")
			Events.message.emit("La puerta está sellada · vence al guardián")
		return
	state = State.DONE
	player.set_active(false)
	player.actor.face_camera()
	player.actor.play("cheer")
	Game.add_score("LEVEL_CLEAR")
	Game.add_score("TIME_BONUS", Game.score.time_bonus(elapsed))
	Audio.stop_music()
	Audio.sfx("clear")
	Events.level_completed.emit()
	await get_tree().create_timer(1.8, false).timeout
	(get_tree().get_first_node_in_group("main") as Main).show_level_clear(elapsed)


func _on_shop(_bonfire: Bonfire) -> void:
	if state != State.PLAYING:
		return
	state = State.SHOP
	player.set_active(false)
	player.actor.play("idle")
	var panel := ShopPanel.new()
	panel.closed.connect(func() -> void:
		player.set_active(true)
		state = State.PLAYING)
	add_child(panel)
