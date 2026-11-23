class_name Fx
extends RefCounted
## Fx: efectos visuales de un solo uso (chispas, textos flotantes y proyectiles).

static func burst(parent: Node3D, at: Vector3, color: Color, amount := 20) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = amount
	p.lifetime = 0.7
	p.direction = Vector3.UP
	p.spread = 180.0
	p.gravity = Vector3(0, -5, 0)
	p.initial_velocity_min = 1.2
	p.initial_velocity_max = 3.6
	var spark := SphereMesh.new()
	spark.radius = 0.05
	spark.height = 0.1
	spark.radial_segments = 6
	spark.rings = 3
	spark.material = Trigger.glow_material(color, 2.0)
	p.mesh = spark
	parent.add_child(p)
	p.global_position = at
	p.emitting = true
	parent.get_tree().create_timer(1.2, false).timeout.connect(p.queue_free)


static func popup(parent: Node3D, at: Vector3, text: String, color: Color, big := false) -> void:
	var label := Label3D.new()
	label.text = text
	label.modulate = color
	label.font = UiKit.title_font()
	label.font_size = 96 if big else 72
	label.outline_size = 22
	label.pixel_size = 0.0055
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	parent.add_child(label)
	label.global_position = at + Vector3(0, 0.4, 0.6)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y + 0.9, 0.9).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.35).set_delay(0.55)
	tween.tween_property(label, "outline_modulate:a", 0.0, 0.35).set_delay(0.55)
	tween.chain().tween_callback(label.queue_free)


## Proyectil luminoso con arco entre dos puntos.
static func projectile(parent: Node3D, from: Vector3, to: Vector3, color: Color) -> void:
	var orb := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.22
	mesh.height = 0.44
	mesh.material = Trigger.glow_material(color, 3.0)
	orb.mesh = mesh
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 3.0
	light.omni_range = 5.0
	orb.add_child(light)
	parent.add_child(orb)
	var fly := func(k: float) -> void:
		orb.global_position = from.lerp(to, k) + Vector3(0, sin(k * PI) * 0.5, 0)
	var tween := orb.create_tween()
	tween.tween_method(fly, 0.0, 1.0, 0.45)
	await tween.finished
	orb.queue_free()
	burst(parent, to, color, 34)
