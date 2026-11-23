class_name Hud
extends CanvasLayer
## Hud: información de la partida (vida, vidas, monedas, pociones, puntaje y medallón), avisos y pausa.
## Se actualiza con las señales de Events; no consulta al nivel.

var _hp_bar: ProgressBar
var _hp_text: Label
var _level: Label
var _lives: Label
var _coins: Label
var _potions: Label
var _score: Label
var _medallion: Label
var _toast: PanelContainer
var _toast_text: Label
var _toast_tween: Tween
var _pause: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_status()
	_build_score()
	_build_toast()
	Events.hunter_changed.connect(refresh)
	Events.score_changed.connect(_on_score)
	Events.life_lost.connect(_on_life_lost)
	Events.message.connect(show_message)
	refresh()
	_on_score(Game.score.total)


func _build_status() -> void:
	var panel := UiKit.panel(0.72, 14)
	panel.position = Vector2(20, 18)
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	panel.add_child(column)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	column.add_child(row)
	row.add_child(UiKit.label("Kaelen", 22, UiKit.GOLD, true))
	_level = UiKit.label("", 18, UiKit.MUTED)
	row.add_child(_level)
	var life := HBoxContainer.new()
	life.add_theme_constant_override("separation", 10)
	column.add_child(life)
	_hp_bar = UiKit.bar(UiKit.RED)
	_hp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	life.add_child(_hp_bar)
	_hp_text = UiKit.label("", 18)
	life.add_child(_hp_text)
	var items := HBoxContainer.new()
	items.add_theme_constant_override("separation", 20)
	column.add_child(items)
	_lives = UiKit.label("", 18, Color("#ff9a9a"))
	_coins = UiKit.label("", 18, Color("#ffd86a"))
	_potions = UiKit.label("", 18, Color("#ff9fb2"))
	for l: Label in [_lives, _coins, _potions]:
		items.add_child(l)


func _build_score() -> void:
	var panel := UiKit.panel(0.72, 14)
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.offset_right = -20
	panel.offset_top = 18
	add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	_score = UiKit.label("0", 26, UiKit.GOLD, true)
	_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	column.add_child(_score)
	_medallion = UiKit.label("Medallón en calma", 16, UiKit.MUTED)
	_medallion.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	column.add_child(_medallion)


func _build_toast() -> void:
	var strip := CenterContainer.new()
	strip.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	strip.offset_top = -110
	strip.offset_bottom = -30
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(strip)
	_toast = UiKit.panel(0.85, 14)
	_toast.modulate.a = 0.0
	strip.add_child(_toast)
	_toast_text = UiKit.label("", 22)
	_toast.add_child(_toast_text)


func refresh() -> void:
	var h := Game.hunter
	UiKit.slide(_hp_bar, float(h.hp) / h.max_hp)
	_hp_text.text = "%d/%d" % [h.hp, h.max_hp]
	_level.text = "Nv %d · %s" % [h.level, h.armor_name]
	_lives.text = "Vidas %d" % Game.lives
	_coins.text = "Monedas %d" % h.coins
	_potions.text = "Pociones %d" % h.potions


func set_medallion(near: bool) -> void:
	_medallion.text = "¡El medallón vibra!" if near else "Medallón en calma"
	_medallion.add_theme_color_override("font_color", UiKit.RED.lightened(0.25) if near else UiKit.MUTED)


func show_message(text: String) -> void:
	_toast_text.text = text
	if _toast_tween != null:
		_toast_tween.kill()
	_toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(2.2)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.5)


func _on_score(total: int) -> void:
	_score.text = "%d puntos" % total


func _on_life_lost(_left: int) -> void:
	refresh()


func _unhandled_input(event: InputEvent) -> void:
	var level := get_parent() as LevelBase
	if event.is_action_pressed("pause") and (level.state == LevelBase.State.PLAYING or _pause != null):
		get_viewport().set_input_as_handled()
		_toggle_pause()


func _toggle_pause() -> void:
	Audio.sfx("select")
	if _pause != null:
		_pause.queue_free()
		_pause = null
		get_tree().paused = false
		return
	get_tree().paused = true
	var column := UiKit.screen(self, 0.72)
	_pause = column.get_parent().get_parent() as Control
	column.add_child(UiKit.centered("Pausa", 56, UiKit.GOLD, true))
	var resume := UiKit.button("Continuar", _toggle_pause)
	column.add_child(resume)
	column.add_child(UiKit.button("Salir al título", func() -> void:
		get_tree().paused = false
		(get_tree().get_first_node_in_group("main") as Main).show_title()))
	column.add_child(UiKit.centered("M: sonido", 18, UiKit.MUTED))
	resume.grab_focus()
