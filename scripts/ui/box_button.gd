class_name BoxButton
extends Button
## A button cut from cardboard: its own torn shape (from `look_seed`), drawn a
## degree or two crooked while the clickable rectangle stays straight. Focused
## or hovered it turns light cream, gets a red marker ring and a red paw on
## the left. Text is ink in the headline font (the body font with `body`).
## `focusable` false is a mouse-only button (like UiStyle.click_button).

var look_seed := 1
var tilt := 0.0
var text_size := 30
var body := false
var min_width := 0.0
## "l", "r", "u" or "d": an arrow drawn as a marker stroke instead of text.
var arrow := ""
## A small note after the text ("Enter", "R"), drawn in the body font.
var hint := ""

var _paw_room := 0.0


static func make(text_: String, size_: int, seed_: int, tilt_: float, focusable: bool = true, body_: bool = false, min_width_: float = 0.0) -> BoxButton:
	var b := BoxButton.new()
	b.text = text_
	b.text_size = size_
	b.look_seed = seed_
	b.tilt = tilt_
	b.body = body_
	b.min_width = min_width_
	b.focus_mode = Control.FOCUS_ALL if focusable else Control.FOCUS_NONE
	b._setup()
	return b


func _setup() -> void:
	var empty := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		add_theme_stylebox_override(state, empty)
	# The text is drawn by _draw; the button's own copy stays invisible.
	for c in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color", "font_disabled_color", "font_outline_color"]:
		add_theme_color_override(c, Color(0, 0, 0, 0))
	add_theme_font_override("font", _font())
	add_theme_font_size_override("font_size", text_size)
	_paw_room = text_size * 0.85 if focus_mode != Control.FOCUS_NONE else 0.0
	_fit()
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	if focus_mode != Control.FOCUS_NONE:
		mouse_entered.connect(grab_focus)
		focus_entered.connect(func() -> void: Audio.play("click", -14.0, 0.0))
	else:
		pressed.connect(func() -> void: Audio.play("click", -8.0, 0.0))


func _font() -> Font:
	return BoxStyle.body_font() if body else BoxStyle.head_font()


## The button is as wide as its text needs (so long translations fit).
func _fit() -> void:
	var w := _font().get_string_size(atr(text), HORIZONTAL_ALIGNMENT_LEFT, -1, text_size).x + _hint_width()
	custom_minimum_size = Vector2(maxf(min_width, w + text_size * 1.1 + _paw_room * (1.35 if hint != "" else 1.0)), roundf(text_size * 1.55))


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_fit()
		queue_redraw()


## Another text (the button grows or shrinks to fit it).
func relabel(text_: String) -> void:
	text = text_
	if is_node_ready():
		_fit()
		queue_redraw()


func _hint_size() -> int:
	return maxi(roundi(text_size * 0.52), 12)


func _hint_width() -> float:
	if hint == "":
		return 0.0
	return BoxStyle.body_font().get_string_size("(%s)" % hint, HORIZONTAL_ALIGNMENT_LEFT, -1, _hint_size()).x + text_size * 0.3


## Sets the note after the text and refits the button.
func set_hint(h: String) -> void:
	hint = h
	_fit()
	queue_redraw()


func _lit() -> bool:
	return has_focus() or is_hovered()


func _draw() -> void:
	var base := BoxStyle.around(size, tilt)
	var lit := _lit() and not disabled
	if lit:
		BoxStyle.draw_board(self, size, look_seed, Color("fbf1d6"), Color("ecdcb2"), base, Vector2(5, 6), Color(0.31, 0.19, 0.08, 0.08))
		BoxStyle.draw_ring(self, Rect2(Vector2.ZERO, size), look_seed + 3, BoxStyle.RED, 4.5, 7.0, base)
		BoxStyle.draw_paw(self, Vector2(_paw_room * 0.5 + text_size * 0.5, size.y * 0.5), text_size * 0.95, BoxStyle.RED, -15.0, base)
	else:
		BoxStyle.draw_board(self, size, look_seed, Color("c99a64"), Color("ad7c4a"), base, Vector2(5, 6), Color(0.31, 0.19, 0.08, 0.12))
	var font := _font()
	var shown := atr(text)
	var tw := font.get_string_size(shown, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size).x + _hint_width()
	var shift := _paw_room * (0.8 if hint != "" else 0.5) if lit else 0.0
	var x := (size.x - tw) * 0.5 + shift
	var y := size.y * 0.5 + (font.get_ascent(text_size) - font.get_descent(text_size)) * 0.5
	draw_set_transform_matrix(base)
	var ink := Color(BoxStyle.INK, 0.45) if disabled else BoxStyle.INK
	draw_string(font, Vector2(x, y), shown, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size, ink)
	if hint != "":
		var hs := _hint_size()
		var hx := x + tw - _hint_width() + text_size * 0.3
		draw_string(BoxStyle.body_font(), Vector2(hx, y), "(%s)" % hint, HORIZONTAL_ALIGNMENT_LEFT, -1, hs, Color(ink, ink.a * 0.8))
	if arrow != "":
		var dir: Vector2 = {"l": Vector2(-1, 0), "r": Vector2(1, 0), "u": Vector2(0, -1), "d": Vector2(0, 1)}[arrow]
		var n := dir.orthogonal()
		var c := size * 0.5
		draw_polyline(PackedVector2Array([c - dir * 7.0 + n * 9.0, c + dir * 7.0, c - dir * 7.0 - n * 9.0]), BoxStyle.INK, 4.0, true)
	draw_set_transform_matrix(Transform2D.IDENTITY)
