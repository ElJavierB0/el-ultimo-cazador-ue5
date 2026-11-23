class_name ExitDoor
extends Trigger
## ExitDoor: puerta sellada del nivel. Solo se abre al vencer al guardián.

var opened := false
var _portal: MeshInstance3D
var _light: OmniLight3D


func _init() -> void:
	super(Vector3(1.2, 2.2, 1.6))


func _build() -> void:
	var arch: Node3D = (load("res://assets/models/props/arch_gate.glb") as PackedScene).instantiate()
	arch.scale = Vector3.ONE * 0.75
	arch.position = Vector3(0, -1.1, -0.6)
	add_child(arch)
	var quad := QuadMesh.new()
	quad.size = Vector2(1.7, 2.2)
	_portal = add_mesh(quad, glow_material(Color("#6a1018"), 0.5, 0.75), Vector3(0, 0, -0.65))
	_light = OmniLight3D.new()
	_light.light_color = Color("#c02a2a")
	_light.light_energy = 0.8
	_light.omni_range = 4.0
	_light.position = Vector3(0, 0.3, 0.5)
	add_child(_light)


func open() -> void:
	opened = true
	_portal.material_override = glow_material(Color("#6ad0ff"), 1.8, 0.7)
	_light.light_color = Color("#6ad0ff")
	_light.light_energy = 2.4


func _touch(_player: Player) -> void:
	Events.door_touched.emit()
