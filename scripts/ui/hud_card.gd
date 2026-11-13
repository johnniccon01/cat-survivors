class_name HudCard
extends Control
## A small card of the in-game HUD: bold ink text on a piece of cream
## cardboard (or red, for a banner), a little crooked, with an optional red
## paw. The cardboard is drawn once; changing the text only re-fits it (and
## only when the text is wider than before), so a ticking clock is cheap.

var look_seed := 2
var tilt := 0.0
var text_size := 20
var min_width := 0.0
var with_paw := false
var text_color := BoxStyle.INK
## "left", "center" or "right": which edge the card keeps when it grows.
var anchor := "left"
## Gap from the screen edge (right) or the left edge (left), and from the top.
var margin := Vector2(12, 12)

var _board: BoxBoard
var _label: Label
var _paw: BoxBoard


static func make(size_: int, seed_: int, tilt_: float, anchor_: String, margin_: Vector2, min_width_: float = 0.0, paw_: bool = false, kind: String = "light") -> HudCard:
	var c := HudCard.new()
	c.text_size = size_
	c.look_seed = seed_
	c.tilt = tilt_
	c.anchor = anchor_
	c.margin = margin_
	c.min_width = min_width_
	c.with_paw = paw_
	c._build(kind)
	return c


func _build(kind: String) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_board = BoxBoard.make(kind, Vector2.ZERO, Vector2(10, 10), look_seed)
	_board.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_board)
	_label = BoxStyle.label("", text_size, text_color)
	(_label.label_settings as LabelSettings).font = BoxStyle.bold_font()
	add_child(_label)
	if with_paw:
		_paw = BoxBoard.make("paw", Vector2.ZERO, Vector2(text_size, text_size), 1)
		add_child(_paw)
	match anchor:
		"center":
			set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
		"right":
			set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_fit(Vector2(min_width, text_size * 1.5))


func set_text(t: String) -> void:
	if t == _label.text:
		return
	_label.text = t
	var font := BoxStyle.bold_font()
	var w := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size).x + text_size * 1.1 + (text_size * 1.3 if with_paw else 0.0)
	# Only grow: a clock that gets narrower must not make the card jump.
	var wanted := maxf(maxf(min_width, w), size.x if t != "" else 0.0)
	_fit(Vector2(wanted, text_size * 1.5))


func _fit(s: Vector2) -> void:
	var room := text_size * 1.3 if with_paw else 0.0
	var top := margin.y
	match anchor:
		"center":
			offset_left = -s.x * 0.5
			offset_right = s.x * 0.5
		"right":
			offset_right = -margin.x
			offset_left = -margin.x - s.x
		_:
			offset_left = margin.x
			offset_right = margin.x + s.x
	offset_top = top
	offset_bottom = top + s.y
	pivot_offset = s * 0.5
	rotation_degrees = tilt
	_label.size = Vector2(s.x - room, s.y)
	_label.position = Vector2(room, 0)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if _paw != null:
		_paw.size = Vector2(text_size, text_size)
		_paw.position = Vector2(text_size * 0.55, (s.y - text_size) * 0.5 + 1.0)
		_paw.pivot_offset = _paw.size * 0.5


## Another colour for the text (a red card gets cream).
func set_text_color(c: Color) -> void:
	(_label.label_settings as LabelSettings).font_color = c
