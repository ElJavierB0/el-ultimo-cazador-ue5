class_name Actor
extends Node3D
## Actor: modelo 3D animado de un personaje (composición: cada Entity tiene un Actor).
## Carga el modelo, aplica su paleta, comparte las animaciones del esqueleto y hace transiciones suaves.

const CHARACTER_PATH := "res://assets/models/characters/%s.glb"
const NATIVE_HEIGHT := 2.3
const PALETTE := preload("res://shaders/palette.gdshader")

const ANIMS := {
	"adventurer": {
		"idle": "Idle", "combat": "2H_Melee_Idle", "walk": "Walking_A", "run": "Running_A",
		"jump_start": "Jump_Start", "jump_air": "Jump_Idle", "jump_land": "Jump_Land",
		"attack": "1H_Melee_Attack_Slice_Diagonal", "cast": "Spellcast_Shoot", "raise": "Spellcast_Raise",
		"hit": "Hit_A", "death": "Death_A", "item": "Use_Item", "block": "Block",
		"dodge": "Dodge_Backward", "cheer": "Cheer", "taunt": "Cheer",
	},
	"skeleton": {
		"idle": "Idle_Combat", "combat": "Idle_Combat", "walk": "Walking_D_Skeletons", "run": "Running_A",
		"jump_start": "Jump_Start", "jump_air": "Jump_Idle", "jump_land": "Jump_Land",
		"attack": "1H_Melee_Attack_Chop", "cast": "Spellcast_Shoot", "raise": "Spellcast_Raise",
		"hit": "Hit_B", "death": "Death_C_Skeletons", "item": "Use_Item", "block": "Block",
		"dodge": "Dodge_Backward", "cheer": "Taunt", "taunt": "Taunt",
	},
}
const LOOPS := ["idle", "combat", "walk", "run", "jump_air"]
const LIBRARY_SOURCE := {"adventurer": "Rogue_Hooded", "skeleton": "Skeleton_Warrior"}

static var _libraries := {}

var spec: Dictionary
var height := 1.6
var _family := "adventurer"
var _model: Node3D
var _player: AnimationPlayer
var _current := ""


func _init(p_spec: Dictionary) -> void:
	spec = p_spec
	height = spec.get("height", 1.6)
	var file: String = spec.file
	_family = "skeleton" if file.begins_with("Skeleton") else "adventurer"
	_model = (load(CHARACTER_PATH % file) as PackedScene).instantiate()
	_model.scale = Vector3.ONE * (height / NATIVE_HEIGHT)
	add_child(_model)
	_dress()
	_setup_animations()
	face(1)


## Oculta accesorios, aplica la paleta, enciende los ojos y cambia la daga por la espada.
func _dress() -> void:
	var hidden: Array = spec.get("hide", [])
	var knife: MeshInstance3D = null
	for node: Node in _model.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		for prefix: String in hidden:
			if mesh.name.begins_with(prefix):
				mesh.visible = false
		if mesh.name == "Knife":
			knife = mesh
		for i in mesh.mesh.get_surface_count():
			var base := mesh.mesh.surface_get_material(i) as BaseMaterial3D
			if base == null:
				continue
			if spec.has("eyes") and mesh.name.contains("Eyes"):
				var glow := StandardMaterial3D.new()
				glow.albedo_color = spec.eyes
				glow.emission_enabled = true
				glow.emission = spec.eyes
				glow.emission_energy_multiplier = 3.0
				mesh.set_surface_override_material(i, glow)
			else:
				mesh.set_surface_override_material(i, _palette_material(base))
	if spec.get("sword", false) and knife != null:
		_equip_sword(knife)


func _palette_material(base: BaseMaterial3D) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = PALETTE
	mat.set_shader_parameter("albedo_tex", base.albedo_texture)
	mat.set_shader_parameter("hue", spec.get("hue", 0.0))
	mat.set_shader_parameter("sat", spec.get("sat", 1.0))
	mat.set_shader_parameter("light", spec.get("light", 1.0))
	mat.set_shader_parameter("tint", spec.get("tint", Color.WHITE))
	mat.set_shader_parameter("tint_amount", spec.get("tint_amount", 0.0))
	return mat


func _equip_sword(knife: MeshInstance3D) -> void:
	var sword: Node3D = (load("res://assets/models/props/sword_1handed.glb") as PackedScene).instantiate()
	for node: Node in sword.find_children("*", "MeshInstance3D", true, false):
		var steel := StandardMaterial3D.new()
		var base := (node as MeshInstance3D).mesh.surface_get_material(0) as BaseMaterial3D
		steel.albedo_texture = base.albedo_texture
		steel.metallic = 0.7
		steel.roughness = 0.25
		steel.emission_enabled = true
		steel.emission = Color("#3a5a7a")
		steel.emission_energy_multiplier = 0.4
		(node as MeshInstance3D).set_surface_override_material(0, steel)
	knife.visible = false
	knife.get_parent().add_child(sword)


func _setup_animations() -> void:
	_player = AnimationPlayer.new()
	_model.add_child(_player)
	_player.root_node = NodePath("..")
	_player.add_animation_library("", _library(_family))


## Las animaciones se cargan una sola vez por familia y se comparten entre todos los personajes.
static func _library(family: String) -> AnimationLibrary:
	if _libraries.has(family):
		return _libraries[family]
	var source: Node = (load(CHARACTER_PATH % LIBRARY_SOURCE[family]) as PackedScene).instantiate()
	var players := source.find_children("*", "AnimationPlayer", true, false)
	var lib := ((players[0] as AnimationPlayer).get_animation_library("").duplicate(true)) as AnimationLibrary
	for key: String in LOOPS:
		var anim_name: String = ANIMS[family][key]
		if lib.has_animation(anim_name):
			lib.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR
	source.free()
	_libraries[family] = lib
	return lib


## Reproduce una animación por su nombre lógico ("run", "attack"…). No reinicia la que ya está activa.
func play(key: String, fade := 0.15, speed := 1.0) -> void:
	if _current == key:
		return
	_current = key
	_player.play(ANIMS[_family][key], fade, speed)


## Reproduce una animación completa y espera a que termine; luego pasa a "then" si se indica.
func once(key: String, then := "", speed := 1.0) -> void:
	_current = key
	var anim_name: String = ANIMS[_family][key]
	_player.stop()
	_player.play(anim_name, 0.08, speed)
	var length := _player.get_animation(anim_name).length / speed
	await get_tree().create_timer(length, false).timeout
	if then != "" and _current == key:
		play(then)


## Gira el modelo hacia la derecha (1) o la izquierda (-1).
func face(direction: int) -> void:
	_model.rotation.y = PI / 2.0 * signi(direction) if direction != 0 else _model.rotation.y


func face_camera() -> void:
	_model.rotation.y = 0.0
