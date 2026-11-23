class_name UiKit
extends RefCounted
## UiKit: piezas de interfaz reutilizables con el estilo del juego (paneles oscuros y detalles dorados).

const GOLD := Color("#d9b46a")
const INK := Color("#0b0d14")
const TEXT := Color("#e9e4d6")
const MUTED := Color("#a7a295")
const RED := Color("#c8323f")
const GREEN := Color("#57c07a")
const BLUE := Color("#6ab0ff")

static var _title_font: FontVariation


static func title_font() -> Font:
	if _title_font == null:
		_title_font = FontVariation.new()
		_title_font.base_font = load("res://assets/fonts/Cinzel.ttf")
		_title_font.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 700}
	return _title_font


static func box(bg: Color, border := GOLD, width := 1, radius := 8, pad := 16) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(pad)
	return s


static func panel(alpha := 0.86, pad := 16) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(Color(INK, alpha), Color(GOLD, 0.45), 1, 8, pad))
	return p


static func label(text: String, size := 20, color := TEXT, title := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if title:
		l.add_theme_font_override("font", title_font())
	return l


static func centered(text: String, size := 20, color := TEXT, title := false) -> Label:
	var l := label(text, size, color, title)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


static func button(text: String, on_press: Callable, min_size := Vector2(250, 50)) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.add_theme_font_override("font", title_font())
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_color_override("font_color", TEXT)
	b.add_theme_color_override("font_focus_color", INK)
	b.add_theme_color_override("font_hover_color", INK)
	b.add_theme_color_override("font_hover_pressed_color", INK)
	b.add_theme_color_override("font_pressed_color", INK)
	b.add_theme_color_override("font_disabled_color", Color(MUTED, 0.5))
	b.add_theme_stylebox_override("normal", box(Color("#171a24", 0.95), Color(GOLD, 0.5), 1, 6, 8))
	b.add_theme_stylebox_override("hover", box(GOLD.lightened(0.1), GOLD, 1, 6, 8))
	b.add_theme_stylebox_override("focus", box(GOLD, Color.WHITE, 2, 6, 8))
	b.add_theme_stylebox_override("pressed", box(GOLD.darkened(0.2), GOLD, 1, 6, 8))
	b.add_theme_stylebox_override("disabled", box(Color("#101218", 0.9), Color(GOLD, 0.15), 1, 6, 8))
	b.focus_entered.connect(func() -> void: Audio.sfx("move"))
	b.mouse_entered.connect(b.grab_focus)
	b.pressed.connect(func() -> void:
		Audio.sfx("select")
		on_press.call())
	return b


static func bar(color: Color, size := Vector2(230, 16)) -> ProgressBar:
	var b := ProgressBar.new()
	b.custom_minimum_size = size
	b.show_percentage = false
	b.min_value = 0.0
	b.max_value = 1.0
	b.step = 0.001
	b.value = 1.0
	b.add_theme_stylebox_override("background", box(Color("#1c1f2b"), Color(0, 0, 0, 0.6), 1, 5, 0))
	b.add_theme_stylebox_override("fill", box(color, color, 0, 5, 0))
	return b


## Mueve la barra con suavidad hasta su nuevo valor.
static func slide(b: ProgressBar, ratio: float) -> void:
	if not b.is_inside_tree():
		b.value = ratio
		return
	b.create_tween().tween_property(b, "value", clampf(ratio, 0.0, 1.0), 0.25)


## Contenedor a pantalla completa con su contenido centrado. "dim" oscurece lo que hay detrás.
static func screen(parent: Node, dim := 0.0) -> VBoxContainer:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(root)
	if dim > 0.0:
		var shade := ColorRect.new()
		shade.color = Color(0.02, 0.02, 0.04, dim)
		shade.set_anchors_preset(Control.PRESET_FULL_RECT)
		root.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(1000, 0)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 14)
	center.add_child(column)
	return column


static func spacer(height := 12) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, height)
	return c
