class_name ShopPanel
extends CanvasLayer
## ShopPanel: ventana del trueque en la hoguera. Muestra los artículos y el resultado de cada transacción.

signal closed

var _rows: VBoxContainer
var _balance: Label
var _result: Label


func _ready() -> void:
	var column := UiKit.screen(self, 0.6)
	var panel := UiKit.panel(0.94, 28)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(panel)
	var body := VBoxContainer.new()
	body.custom_minimum_size = Vector2(680, 0)
	body.add_theme_constant_override("separation", 12)
	panel.add_child(body)
	body.add_child(UiKit.centered("Trueque en la hoguera", 34, UiKit.GOLD, true))
	_balance = UiKit.centered("", 22, Color("#ffd86a"))
	body.add_child(_balance)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 8)
	body.add_child(_rows)
	_result = UiKit.centered("Elige qué ofrecer al fuego.", 20, UiKit.MUTED)
	body.add_child(_result)
	var close := UiKit.button("Volver al camino", _close)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	body.add_child(close)
	_render()
	(_rows.get_child(0) as Button).grab_focus()


func _render() -> void:
	var focused := 0
	for i in _rows.get_child_count():
		if (_rows.get_child(i) as Control).has_focus():
			focused = i
	for child in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	_balance.text = "Monedas: %d" % Game.hunter.coins
	for id: String in Shop.ITEMS:
		var item: Dictionary = Shop.ITEMS[id]
		var left: int = Game.shop.stock[id]
		var text := "%s  ·  %d monedas  ·  %s" % [item.name, item.price, "quedan %d" % left if left > 0 else "agotado"]
		var b := UiKit.button(text, _buy.bind(id), Vector2(620, 50))
		b.tooltip_text = item.hint
		b.focus_entered.connect(func() -> void: _show(item.hint, UiKit.MUTED))
		_rows.add_child(b)
	(_rows.get_child(focused) as Button).grab_focus()


func _buy(id: String) -> void:
	var tx := Game.shop.buy(id, Game.hunter, Game.gain_life)
	if tx.approved:
		Game.stats.purchases += 1
		Audio.sfx("buy")
	else:
		Audio.sfx("locked")
	Events.transaction_done.emit(tx)
	Events.hunter_changed.emit()
	_render()
	if tx.approved:
		_show("%s: %d → %d monedas" % [tx.item_name, tx.balance_before, tx.balance_after], UiKit.GREEN)
	else:
		_show("%s: %s" % [tx.item_name, tx.reason], UiKit.RED.lightened(0.25))


func _show(text: String, color: Color) -> void:
	_result.text = text
	_result.add_theme_color_override("font_color", color)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_close()


func _close() -> void:
	closed.emit()
	queue_free()
