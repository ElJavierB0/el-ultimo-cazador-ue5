class_name LevelForest
extends LevelBase
## Nivel 1: Bosque de Velmora. Guardián: Caballero Caído.

func _setup_level() -> void:
	level_name = "Bosque de Velmora"
	music = "forest"
	columns = 112


func _layout() -> void:
	start(2, 8)
	ground(0, 20, 2)
	coins(6, 6, 3)
	enemy("bandido", 15, 8)

	ground(23, 32, 2)
	platform(25, 6, 4)
	coins(25, 5, 4)
	ground(32, 41, 3)
	potion(39, 7)

	ground(41, 56, 2)
	bonfire(43, 8)
	platform(47, 6, 3)
	platform(51, 4, 3)
	coins(51, 3, 3)

	ground(59, 76, 2)
	enemy("saqueador", 66, 8)
	coins(62, 6, 3)

	platform(77, 7, 3)
	ground(81, 112, 2)
	bonfire(84, 8)
	potion(88, 8)
	enemy("caballero", 98, 8)
	exit(107, 8)


func _build_backdrop() -> void:
	_build_moon()
	_build_mountains()
	_build_trees()
	scatter(["grave_A", "grave_B", "gravestone", "fence_broken"], 0.4, 1.1)
	lanterns(["lantern_standing", "post_lantern"], Color("#ffb45a"), 13.0)


func _build_moon() -> void:
	var sphere := SphereMesh.new()
	sphere.radius = 4.5
	sphere.height = 9.0
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color("#d6deef")
	mat.disable_fog = true
	for x: float in [30.0, 95.0]:
		_mesh(sphere, mat, Vector3(x, 22, -85))


func _build_mountains() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _theme().mountain
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var x := -30.0
	while x < columns + 40:
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = _decor.randf_range(12.0, 22.0)
		cone.height = _decor.randf_range(18.0, 32.0)
		cone.radial_segments = 6
		_mesh(cone, mat, Vector3(x, 2, _decor.randf_range(-70.0, -55.0)))
		x += _decor.randf_range(14.0, 24.0)


func _build_trees() -> void:
	var leaf := [_material(Color("#14251c")), _material(Color("#10201a")), _material(Color("#182c20"))]
	var trunk := _material(Color("#24170f"))
	for layer in 3:
		var z: float = [-3.6, -7.5, -13.0][layer]
		var step: float = [2.8, 3.4, 4.2][layer]
		var x := -12.0
		while x < columns + 12:
			var base := float(ground_at(x)) if ground_at(x) > 0 else 1.0
			if _decor.randf() > 0.25:
				var s := _decor.randf_range(1.3, 2.2) * (1.0 + layer * 0.35)
				var stem := CylinderMesh.new()
				stem.top_radius = 0.12 * s
				stem.bottom_radius = 0.18 * s
				stem.height = 1.6 * s
				_mesh(stem, trunk, Vector3(x, base + 0.6 * s, z))
				for i in 4:
					var cone := CylinderMesh.new()
					cone.top_radius = 0.0
					cone.bottom_radius = (1.2 - i * 0.24) * s
					cone.height = 1.4 * s
					cone.radial_segments = 7
					_mesh(cone, leaf[i % 3], Vector3(x, base + (1.3 + i * 0.75) * s, z))
			else:
				var dead: String = ["tree_dead_large", "tree_dead_medium", "tree_dead_small"][_decor.randi() % 3]
				prop(dead, Vector3(x, base, z), 1.0 + layer * 0.5 + _decor.randf() * 0.6, _decor.randf() * TAU, Color("#5a4a40"))
			x += step + _decor.randf() * step
