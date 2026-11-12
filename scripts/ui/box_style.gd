class_name BoxStyle
## The "shoe box" look of the menus: torn cardboard, paper tape, a red marker
## and paw prints, all drawn in code (no pictures), plus the fonts that go
## with it. Used through BoxBoard and BoxButton; every `draw_*` takes the
## CanvasItem to draw on and a `base` transform (the rotation the item is
## already drawn in), which it restores when done.

const KRAFT := Color("b98655")
const KRAFT_LIGHT := Color("d2a977")
const KRAFT_DARK := Color("8c5f36")
const KRAFT_DEEP := Color("5b3b21")
const CREAM := Color("f4e8cb")
const TAPE := Color(0.918, 0.851, 0.561, 0.9)
const INK := Color("2b1d12")
const RED := Color("d3261f")

const HEAD_FONT := "res://fonts/DeliciousHandrawn-Regular.ttf"
const BODY_FONT := "res://fonts/ShantellSans.ttf"

static var _head: Font
static var _body: Font


## The headline font (buttons, titles): Delicious Handrawn, then Shantell Sans
## (Cyrillic), then the game's own font; Chinese comes from the system font
## the engine falls back to when none of these has the glyph.
static func head_font() -> Font:
	if _head == null:
		var f := (load(HEAD_FONT) as FontFile).duplicate() as FontFile
		var chain: Array[Font] = [body_font()]
		f.fallbacks = chain
		_head = f
	return _head


## The text font (tips, status lines): Shantell Sans semi-bold, then the game's
## own font (and the system font for Chinese).
static func body_font() -> Font:
	if _body == null:
		var v := FontVariation.new()
		v.base_font = load(BODY_FONT) as Font
		v.variation_opentype = {"weight": 600}
		var chain: Array[Font] = [ThemeDB.fallback_font]
		v.fallbacks = chain
		_body = v
	return _body


## The biggest size up to `size` at which `text` is at most `width` wide.
static func fit_size(text: String, font: Font, size: int, width: float, smallest: int = 13) -> int:
	while size > smallest and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width:
		size -= 1
	return size


## A label in the box look (ink on card, no outline).
static func label(text: String, size: int, color: Color = INK, head: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	var s := LabelSettings.new()
	s.font = head_font() if head else body_font()
	s.font_size = size
	s.font_color = color
	l.label_settings = s
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Transform that turns what is drawn by `deg` around the middle of `size`.
static func around(size: Vector2, deg: float) -> Transform2D:
	var rot := deg_to_rad(deg)
	var mid := size * 0.5
	return Transform2D(rot, mid - Transform2D(rot, Vector2.ZERO) * mid)


## A torn-edged outline of a `size` rectangle: every point sits a little way
## inside it, a few notches deeper. The same seed gives the same shape.
static func torn(size: Vector2, seed_v: int, jag: float = 3.0) -> PackedVector2Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var inset := func() -> float:
		var d := rng.randf_range(0.0, jag)
		return d * 1.7 if rng.randf() < 0.15 else d
	var nx := maxi(2, roundi(size.x / 24.0))
	var ny := maxi(2, roundi(size.y / 24.0))
	var pts := PackedVector2Array()
	for i in nx:
		pts.append(Vector2(size.x * i / nx + (inset.call() if i == 0 else 0.0), inset.call()))
	for i in ny:
		pts.append(Vector2(size.x - inset.call(), size.y * i / ny + (inset.call() if i == 0 else 0.0)))
	for i in nx:
		pts.append(Vector2(size.x * (nx - i) / nx - (inset.call() if i == 0 else 0.0), size.y - inset.call()))
	for i in ny:
		pts.append(Vector2(inset.call(), size.y * (ny - i) / ny - (inset.call() if i == 0 else 0.0)))
	return pts


## A piece of torn cardboard: a solid dark shadow, the shape filled top to
## bottom, faint fibres and a darker edge.
static func draw_board(ci: CanvasItem, size: Vector2, seed_v: int, top: Color, bottom: Color, base: Transform2D = Transform2D.IDENTITY, shadow: Vector2 = Vector2(6, 7), fibre: Color = Color(0.31, 0.19, 0.08, 0.11)) -> void:
	ci.draw_set_transform_matrix(base)
	var poly := torn(size, seed_v)
	if shadow != Vector2.ZERO:
		var sp := PackedVector2Array()
		for p in poly:
			sp.append(p + shadow)
		ci.draw_colored_polygon(sp, Color(0, 0, 0, 0.5))
	var cols := PackedColorArray()
	for p in poly:
		cols.append(top.lerp(bottom, clampf(p.y / maxf(size.y, 1.0), 0.0, 1.0)))
	ci.draw_polygon(poly, cols)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v + 7
	var x := 9.0
	while x < size.x - 9.0:
		ci.draw_line(Vector2(x, 7), Vector2(x + 3, size.y - 7), fibre, 1.5)
		x += rng.randf_range(5.0, 12.0)
	var edge := poly.duplicate()
	edge.append(poly[0])
	ci.draw_polyline(edge, bottom.darkened(0.25), 2.0)
	ci.draw_set_transform_matrix(base)


## A strip of paper tape with zigzag ends.
static func draw_tape(ci: CanvasItem, size: Vector2, seed_v: int, color: Color = TAPE, base: Transform2D = Transform2D.IDENTITY) -> void:
	ci.draw_set_transform_matrix(base)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var teeth := maxi(4, roundi(size.y / 7.0))
	var pts := PackedVector2Array()
	for i in teeth + 1:
		pts.append(Vector2(float(i % 2) * 5.0 + rng.randf_range(0.0, 1.5), size.y * i / teeth))
	for i in teeth + 1:
		var j := teeth - i
		pts.append(Vector2(size.x - float(j % 2) * 5.0 - rng.randf_range(0.0, 1.5), size.y * j / teeth))
	ci.draw_colored_polygon(pts, color)
	ci.draw_line(Vector2(8, 3), Vector2(size.x - 8, 2), Color(1, 1, 1, 0.25), 1.5)
	ci.draw_set_transform_matrix(base)


## A wobbly red-marker ring around `rect`, slightly rotated, overshooting its
## start a little the way a hand does.
static func draw_ring(ci: CanvasItem, rect: Rect2, seed_v: int, color: Color = RED, width: float = 4.5, grow: float = 8.0, base: Transform2D = Transform2D.IDENTITY) -> void:
	ci.draw_set_transform_matrix(base)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var mid := rect.get_center()
	var a := rect.size.x * 0.5 + grow
	var b := rect.size.y * 0.5 + grow
	var phase := rng.randf() * TAU
	var start := rng.randf() * TAU
	var tilt := deg_to_rad(rng.randf_range(-1.5, 1.5))
	var pts := PackedVector2Array()
	var n := 56
	for i in n + 1:
		var t := float(i) / n
		var th := start + TAU * 1.07 * t
		var r := 1.0 + 0.022 * sin(th * 3.0 + phase) + 0.025 * t
		var cs := cos(th)
		var sn := sin(th)
		var p := Vector2(a * signf(cs) * pow(absf(cs), 0.3), b * signf(sn) * pow(absf(sn), 0.3)) * r
		pts.append(mid + p.rotated(tilt))
	ci.draw_polyline(pts, color, width, true)
	ci.draw_set_transform_matrix(base)


## A wavy marker line (an underline) across `width`.
static func draw_scribble(ci: CanvasItem, width: float, height: float, seed_v: int, color: Color = RED, thickness: float = 5.0, base: Transform2D = Transform2D.IDENTITY) -> void:
	ci.draw_set_transform_matrix(base)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var pts := PackedVector2Array()
	var phase := rng.randf() * TAU
	var n := 28
	for i in n + 1:
		var t := float(i) / n
		pts.append(Vector2(4.0 + (width - 8.0) * t, height * 0.5 + sin(t * 7.0 + phase) * height * 0.28 - (t - 0.5) * height * 0.3))
	ci.draw_polyline(pts, color, thickness, true)
	ci.draw_set_transform_matrix(base)


static func _ellipse(mid: Vector2, rx: float, ry: float, rot: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		pts.append(mid + Vector2(cos(a) * rx, sin(a) * ry).rotated(rot))
	return pts


## The five parts of a paw print (the pad first, then four toes) for a print
## `s` across, centred on the origin.
static func _paw_parts(s: float) -> Array[PackedVector2Array]:
	return [
		_ellipse(Vector2(0, 0.2 * s), 0.3 * s, 0.23 * s, 0.0),
		_ellipse(Vector2(-0.36 * s, -0.04 * s), 0.09 * s, 0.135 * s, deg_to_rad(-28)),
		_ellipse(Vector2(-0.13 * s, -0.27 * s), 0.095 * s, 0.14 * s, deg_to_rad(-8)),
		_ellipse(Vector2(0.13 * s, -0.27 * s), 0.095 * s, 0.14 * s, deg_to_rad(8)),
		_ellipse(Vector2(0.36 * s, -0.04 * s), 0.09 * s, 0.135 * s, deg_to_rad(28)),
	]


## A paw (pad and four toes), `s` across, centred on `mid`, turned by `deg`.
static func draw_paw(ci: CanvasItem, mid: Vector2, s: float, color: Color = RED, deg: float = 0.0, base: Transform2D = Transform2D.IDENTITY) -> void:
	ci.draw_set_transform_matrix(base * Transform2D(deg_to_rad(deg), mid))
	for part in _paw_parts(s):
		ci.draw_colored_polygon(part, color)
	ci.draw_set_transform_matrix(base)


## A rubber stamp of a paw: uneven pressure (every part a different strength)
## and little holes where the ink missed (drawn in `hole`, the colour of what
## it is stamped on).
static func draw_paw_stamp(ci: CanvasItem, mid: Vector2, s: float, seed_v: int, hole: Color, deg: float = 0.0, color: Color = RED, base: Transform2D = Transform2D.IDENTITY) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	ci.draw_set_transform_matrix(base * Transform2D(deg_to_rad(deg), mid))
	var parts := _paw_parts(s)
	for part in parts:
		ci.draw_colored_polygon(part, Color(color, rng.randf_range(0.62, 0.95)))
	for i in 22:
		var part := parts[0 if i % 3 == 0 else rng.randi_range(0, 4)]
		var at := part[rng.randi_range(0, part.size() - 1)].lerp(part[rng.randi_range(0, part.size() - 1)], rng.randf())
		ci.draw_circle(at, rng.randf_range(0.012, 0.03) * s, Color(hole, 0.85))
	ci.draw_set_transform_matrix(base)
