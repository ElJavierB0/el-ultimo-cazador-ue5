class_name BattleUi
extends CanvasLayer
## BattleUi: cajas de vida, mensajes y menú de la batalla.

signal picked(id: String)

const MAIN_MENU := [
	{"label": "Espada", "sub": ["acero", "plata"]},
	{"label": "Señal", "sub": ["ascua", "egida"]},
	{"label": "Poción", "id": "pocion"},
	{"label": "Huir", "id": "huir"},
]
const CHARS_PER_SEC := 70.0

var _battle: Battle
var _message: Label
var _menu: GridContainer
var _hint: Label
var _hero := {}
var _foe := {}
var _skip := false
var _in_submenu := false
var _main_index := 0


func _init(battle: Battle) -> void:
	_battle = battle


func _ready() -> void:
	_foe = _build_card(false)
	_hero = _build_card(true)
	_build_console()


func _build_card(is_hero: bool) -> Dictionary:
	var panel := UiKit.panel(0.82, 14)
	panel.custom_minimum_size = Vector2(340, 0)
	if is_hero:
		panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		panel.offset_left = 24
	else:
		panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		panel.offset_right = -24
	panel.offset_top = 22
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	panel.add_child(column)
	var row := HBoxContainer.new()
	column.add_child(row)
	var title := UiKit.label("", 22, UiKit.GOLD, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	var lvl := UiKit.label("", 18, UiKit.MUTED)
	row.add_child(lvl)
	var bar := UiKit.bar(UiKit.RED if is_hero else Color("#b0524a"), Vector2(310, 16))
	column.add_child(bar)
	var detail := UiKit.label("", 17)
	column.add_child(detail)
	var chips := UiKit.label("", 16, Color("#9fd3ff"))
	column.add_child(chips)
	return {"title": title, "level": lvl, "bar": bar, "detail": detail, "chips": chips}


func _build_console() -> void:
	var panel := UiKit.panel(0.9, 18)
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.offset_left = 24
	panel.offset_right = -24
	panel.offset_bottom = -20
	panel.offset_top = -170
	add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	panel.add_child(row)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(left)
	_message = UiKit.label("", 26)
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(_message)
	_hint = UiKit.label("", 18, UiKit.MUTED)
	left.add_child(_hint)
	_menu = GridContainer.new()
	_menu.columns = 2
	_menu.add_theme_constant_override("h_separation", 12)
	_menu.add_theme_constant_override("v_separation", 12)
	_menu.custom_minimum_size = Vector2(480, 120)
	_menu.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_menu)


func refresh() -> void:
	var hero := _battle.hero
	var foe := _battle.foe
	_fill(_hero, hero)
	_fill(_foe, foe)
	_hero.detail.text = "%d/%d PV    Vigor %s" % [hero.hp(), hero.max_hp(), "◆".repeat(hero.vigor) + "◇".repeat(BattleRules.MAX_VIGOR - hero.vigor)]
	var chips: Array[String] = []
	if hero.shield:
		chips.append("ÉGIDA")
	if hero.atk_mod < 0:
		chips.append("ATK baja")
	if hero.def_mod < 0:
		chips.append("DEF baja")
	_hero.chips.text = "  ·  ".join(chips)
	_hero.chips.visible = not chips.is_empty()
	_foe.detail.text = Bestiary.TYPE_LABEL[foe.type] + ("  ·  GUARDIÁN" if foe.boss else "")
	chips.clear()
	if foe.burn > 0:
		chips.append("QUEMADO")
	if foe.atk_mod > 0:
		chips.append("ATK sube")
	_foe.chips.text = "  ·  ".join(chips)
	_foe.chips.visible = not chips.is_empty()


func _fill(card: Dictionary, c: Combatant) -> void:
	card.title.text = c.display_name
	card.level.text = "Nv %d" % c.level()
	UiKit.slide(card.bar, float(c.hp()) / c.max_hp())


## ---------- Mensajes ----------

func set_message(text: String) -> void:
	_message.text = text
	_message.visible_ratio = 1.0
	_hint.text = ""


## Escribe el texto letra por letra y espera. Enter o Espacio lo adelantan.
func say(text: String, hold: float) -> void:
	set_message(text)
	_skip = false
	var shown := 0.0
	while shown < text.length() and not _skip:
		shown += get_process_delta_time() * CHARS_PER_SEC
		_message.visible_characters = int(shown)
		await get_tree().process_frame
	_message.visible_characters = -1
	_skip = false
	var t := 0.0
	while t < hold and not _skip:
		t += get_process_delta_time()
		await get_tree().process_frame
	_skip = false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("skip") and _menu.get_child_count() == 0:
		_skip = true
	elif event.is_action_pressed("pause") and _in_submenu:
		get_viewport().set_input_as_handled()
		Audio.sfx("back")
		_open_main()


## ---------- Menú ----------

## Muestra el menú y espera a que el jugador elija una acción. Devuelve su identificador.
func choose() -> String:
	_open_main()
	var id: String = await picked
	_clear_menu()
	_in_submenu = false
	return id


func _clear_menu() -> void:
	for child in _menu.get_children():
		_menu.remove_child(child)
		child.queue_free()


func _open_main() -> void:
	_in_submenu = false
	_clear_menu()
	set_message("¿Qué hará %s?" % _battle.hero.display_name)
	for i in MAIN_MENU.size():
		var entry: Dictionary = MAIN_MENU[i]
		var text: String = entry.label
		if entry.get("id", "") == "pocion":
			text += " ×%d" % _battle.hero.hunter.potions
		_add_button(text, func() -> void:
			_main_index = i
			if entry.has("sub"):
				_open_sub(entry.sub)
			else:
				picked.emit(entry.id))
	(_menu.get_child(_main_index) as Button).grab_focus()


func _open_sub(ids: Array) -> void:
	_clear_menu()
	_in_submenu = true
	for id: String in ids:
		var action: BattleAction = _battle.actions[id]
		var text := action.label + (" (%d)" % action.cost if action.cost > 0 else "")
		var b := _add_button(text, func() -> void: picked.emit(id))
		b.focus_entered.connect(func() -> void:
			_hint.text = action.hint + ("  ·  cuesta %d de vigor" % action.cost if action.cost > 0 else "")
			_message.text = action.label)
	_add_button("Volver", _open_main)
	(_menu.get_child(0) as Button).grab_focus()


func _add_button(text: String, on_press: Callable) -> Button:
	var b := UiKit.button(text, on_press, Vector2(234, 52))
	_menu.add_child(b)
	return b
