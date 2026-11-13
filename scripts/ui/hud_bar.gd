class_name HudBar
extends Control
## A bar of the in-game HUD (xp, health, boss): a dark trough with a cream
## edge and a fill whose end is uneven, like torn paper. The trough is drawn
## once (and again on a resize); the fill is redrawn only when it grows or
## shrinks by a whole pixel, so the bar costs nothing while it stands still.

var fill_color := Color("e9b445")
var shine := true
## "xp": a flat strip across the screen. Otherwise a framed bar.
var kind := "bar"
## A red paw left of the bar (the boss bar).
var paw := false
var look_seed := 3
var label: Label
var value := 1.0:
	set(v):
		v = clampf(v, 0.0, 1.0)
		var px := roundi(v * _inner_width())
		if px != _px:
			_px = px
			queue_redraw()
		value = v

var _px := -1
var _frame: _Frame


class _Frame:
	extends Control
	var bar: HudBar

	func _draw() -> void:
		if bar.kind == "xp":
			draw_rect(Rect2(Vector2.ZERO, size), Color(BoxStyle.DARK, 0.94))
			draw_rect(Rect2(0, size.y - 3, size.x, 3), Color(BoxStyle.CREAM, 0.9))
			return
		var poly := BoxStyle.torn(size, bar.look_seed, 1.6)
		draw_colored_polygon(poly, Color(BoxStyle.DARK, 0.9))
		var closed := poly.duplicate()
		closed.append(poly[0])
		draw_polyline(closed, BoxStyle.CREAM, 2.6, true)
		if bar.paw:
			BoxStyle.draw_paw(self, Vector2(-22, size.y * 0.5 + 1.5), 28.0, Color(0, 0, 0, 0.6))
			BoxStyle.draw_paw(self, Vector2(-23.5, size.y * 0.5), 28.0, Color("ff6a5c"))


static func make(kind_: String, color: Color, seed_: int = 3) -> HudBar:
	var b := HudBar.new()
	b.kind = kind_
	b.fill_color = color
	b.look_seed = seed_
	return b


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false


func _ready() -> void:
	_frame = _Frame.new()
	_frame.bar = self
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_frame.show_behind_parent = true
	add_child(_frame)
	move_child(_frame, 0)
	resized.connect(func() -> void:
		_px = -1
		queue_redraw())


func _inset() -> float:
	return 0.0 if kind == "xp" else 4.0


func _inner_width() -> float:
	return maxf(size.x - _inset() * 2.0, 1.0)


func _draw() -> void:
	var inset := _inset()
	if value <= 0.0:
		return
	# Never thinner than a few pixels, so a first bit of xp already shows.
	var w := maxf(_inner_width() * value, 4.0)
	var h := size.y - inset * 2.0 - (3.0 if kind == "xp" else 0.0)
	var x0 := inset
	if w < 7.0 or h < 6.0:
		draw_rect(Rect2(x0, inset, w, h), fill_color)
	else:
		# The end of the fill: a few small steps in and out, like torn paper.
		# No point may repeat its neighbour (the polygon would not triangulate).
		var pts := PackedVector2Array([Vector2(x0, inset), Vector2(x0 + w, inset)])
		var steps := maxi(3, roundi(h / 4.0))
		for i in range(1, steps + 1):
			pts.append(Vector2(x0 + w - (2.0 if i % 2 == 1 else 0.0), inset + h * i / steps))
		pts.append(Vector2(x0, inset + h))
		draw_colored_polygon(pts, fill_color)
	if shine:
		draw_rect(Rect2(x0, inset, maxf(w - 2.0, 0.0), maxf(h * 0.3, 1.5)), Color(1, 1, 1, 0.28))
