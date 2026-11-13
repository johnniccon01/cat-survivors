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
## the engine falls back to when none of these has the glyph. Its own space is
## very narrow ("Restablecer teclas" ran together), so it gets a wider one.
static func head_font() -> Font:
	if _head == null:
		var v := FontVariation.new()
		v.base_font = load(HEAD_FONT) as Font
		v.spacing_space = 5
		var chain: Array[Font] = [body_font()]
		v.fallbacks = chain
		_head = v
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


## Only the outline of a paw (an empty one: "not yet").
static func draw_paw_outline(ci: CanvasItem, mid: Vector2, s: float, color: Color, deg: float = 0.0, width: float = 1.4, base: Transform2D = Transform2D.IDENTITY) -> void:
	ci.draw_set_transform_matrix(base * Transform2D(deg_to_rad(deg), mid))
	for part in _paw_parts(s):
		var closed := part.duplicate()
		closed.append(part[0])
		ci.draw_polyline(closed, color, width, true)
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


# ---- In-game HUD helpers (text lies right on the game, so it is bold with a
# thick dark outline; the decorations are drawn once and cached by the engine
# because their owners only call queue_redraw when something changes) --------

const DARK := Color("120b06")

static var _bold: Font


## Shantell Sans extra-bold: numbers and short texts lying on the game.
static func bold_font() -> Font:
	if _bold == null:
		var v := FontVariation.new()
		v.base_font = load(BODY_FONT) as Font
		v.variation_opentype = {"weight": 800}
		var chain: Array[Font] = [ThemeDB.fallback_font]
		v.fallbacks = chain
		_bold = v
	return _bold


## A label for text right on the game: bold, with a thick dark outline.
static func hud_label(size: int, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, color: Color = CREAM, head: bool = false, outline_color: Color = DARK) -> Label:
	var l := Label.new()
	var s := LabelSettings.new()
	s.font = head_font() if head else bold_font()
	s.font_size = size
	s.font_color = color
	s.outline_size = clampi(roundi(size * 0.38), 5, 9)
	s.outline_color = outline_color
	l.label_settings = s
	l.horizontal_alignment = align
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## An uneven rounded outline in `rect` (a squashed circle with a few wobbles).
static func blob(rect: Rect2, seed_v: int, n: int = 20, squareness: float = 0.5) -> PackedVector2Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var mid := rect.get_center()
	var a := rect.size.x * 0.5
	var b := rect.size.y * 0.5
	var pts := PackedVector2Array()
	for i in n:
		var th := TAU * i / n
		var cs := cos(th)
		var sn := sin(th)
		var r := rng.randf_range(0.93, 1.0)
		pts.append(mid + Vector2(a * signf(cs) * pow(absf(cs), squareness), b * signf(sn) * pow(absf(sn), squareness)) * r)
	return pts


## A blob with a hard shadow and an ink edge (icon frames, badges).
static func draw_blob(ci: CanvasItem, rect: Rect2, seed_v: int, fill: Color, edge: Color = INK, edge_w: float = 2.5, shadow: Vector2 = Vector2(2, 2.5), base: Transform2D = Transform2D.IDENTITY, squareness: float = 0.5) -> void:
	ci.draw_set_transform_matrix(base)
	var poly := blob(rect, seed_v, 20, squareness)
	if shadow != Vector2.ZERO:
		var sp := PackedVector2Array()
		for p in poly:
			sp.append(p + shadow)
		ci.draw_colored_polygon(sp, Color(0, 0, 0, 0.55))
	ci.draw_colored_polygon(poly, fill)
	var edge_pts := poly.duplicate()
	edge_pts.append(poly[0])
	ci.draw_polyline(edge_pts, edge, edge_w, true)
	ci.draw_set_transform_matrix(base)


## A heart `s` across, centred on `mid`, with a dark edge.
static func draw_heart(ci: CanvasItem, mid: Vector2, s: float, color: Color = RED) -> void:
	var pts := PackedVector2Array()
	for i in 28:
		var t := TAU * i / 28.0
		var x := 16.0 * pow(sin(t), 3.0)
		var y := -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
		pts.append(mid + Vector2(x, y + 1.0) * (s / 34.0))
	var shadow := PackedVector2Array()
	for p in pts:
		shadow.append(p + Vector2(1.5, 2.0))
	ci.draw_colored_polygon(shadow, Color(0, 0, 0, 0.6))
	ci.draw_colored_polygon(pts, color)
	var closed := pts.duplicate()
	closed.append(pts[0])
	ci.draw_polyline(closed, DARK, 2.5, true)


## A round, uneven marker with an arrow in it, pointing along `dir`.
static func draw_arrow_badge(ci: CanvasItem, mid: Vector2, dir: Vector2, r: float, color: Color, seed_v: int = 3) -> void:
	draw_blob(ci, Rect2(mid - Vector2(r, r), Vector2(r, r) * 2.0), seed_v, color, DARK, 3.0, Vector2(2, 2.5), Transform2D.IDENTITY, 0.8)
	var side := dir.orthogonal()
	var tip := mid + dir * r * 0.62
	var back := mid - dir * r * 0.38
	var pts := PackedVector2Array([tip, back + side * r * 0.5, mid - dir * r * 0.1, back - side * r * 0.5])
	ci.draw_colored_polygon(pts, Color("fff7e2"))
	var closed := pts.duplicate()
	closed.append(pts[0])
	ci.draw_polyline(closed, DARK, 2.0, true)


static var _global: Theme


## The theme of the whole window: whatever has no look of its own (scroll
## bars, tooltips, popup menus, dialogs, check boxes, text fields, plain
## buttons) comes out as cardboard and paper in the Krabica fonts instead of
## the engine's grey-blue default.
static func global_theme() -> Theme:
	if _global != null:
		return _global
	var t := Theme.new()
	t.default_font = body_font()
	t.default_font_size = 16
	var dark := Color("120b06")
	var paper := func(fill: Color, edge: Color, bw: int, margin: float) -> StyleBoxFlat:
		var sb := StyleBoxFlat.new()
		sb.bg_color = fill
		sb.border_color = edge
		sb.set_border_width_all(bw)
		sb.set_corner_radius_all(3)
		sb.set_content_margin_all(margin)
		return sb
	# Scroll bars: a dark brown groove with a kraft cardboard handle.
	for kind in ["VScrollBar", "HScrollBar"]:
		var groove: StyleBoxFlat = paper.call(Color(dark, 0.55), Color("3a2412"), 1, 2.0)
		t.set_stylebox("scroll", kind, groove)
		t.set_stylebox("scroll_focus", kind, groove)
		t.set_stylebox("grabber", kind, paper.call(KRAFT, KRAFT_DARK, 2, 2.0))
		t.set_stylebox("grabber_highlight", kind, paper.call(KRAFT_LIGHT, RED, 2, 2.0))
		t.set_stylebox("grabber_pressed", kind, paper.call(CREAM, RED, 2, 2.0))
	# Tooltips: a small cream paper note with ink text.
	var tip: StyleBoxFlat = paper.call(Color("f4e8cb"), Color("8c5f36"), 2, 8.0)
	tip.shadow_color = Color(dark, 0.5)
	tip.shadow_size = 3
	tip.shadow_offset = Vector2(2, 3)
	t.set_stylebox("panel", "TooltipPanel", tip)
	t.set_color("font_color", "TooltipLabel", INK)
	t.set_color("font_shadow_color", "TooltipLabel", Color(0, 0, 0, 0))
	t.set_font("font", "TooltipLabel", body_font())
	t.set_font_size("font_size", "TooltipLabel", 15)
	# Popup menus and dialogs: dark cardboard with cream text, a red marker bar.
	var board: StyleBoxFlat = paper.call(Color("5b3b21"), Color("a47646"), 2, 6.0)
	t.set_stylebox("panel", "PopupPanel", board)
	t.set_stylebox("panel", "PopupMenu", board)
	t.set_stylebox("hover", "PopupMenu", paper.call(Color("a8261f"), Color("a8261f"), 0, 4.0))
	t.set_stylebox("separator", "PopupMenu", paper.call(Color("a47646"), Color("a47646"), 0, 0.0))
	t.set_stylebox("embedded_border", "Window", board)
	t.set_stylebox("embedded_unfocused_border", "Window", board)
	t.set_stylebox("panel", "AcceptDialog", board)
	for c in ["font_color", "font_hover_color", "font_accelerator_color", "font_separator_color"]:
		t.set_color(c, "PopupMenu", CREAM)
	t.set_color("font_disabled_color", "PopupMenu", Color(CREAM, 0.45))
	t.set_color("title_color", "Window", CREAM)
	t.set_font("title_font", "Window", head_font())
	t.set_font_size("title_font_size", "Window", 20)
	# Plain buttons (the game builds its own, but a stray one stays on theme).
	var btn_cols := {"font_color": INK, "font_hover_color": INK, "font_focus_color": INK, "font_pressed_color": INK, "font_hover_pressed_color": INK, "font_disabled_color": Color(INK, 0.45)}
	for kind in ["Button", "OptionButton", "MenuButton"]:
		for c: String in btn_cols:
			t.set_color(c, kind, btn_cols[c])
		t.set_stylebox("normal", kind, UiStyle.cardboard(Color("c99a64"), KRAFT_DARK, 1))
		t.set_stylebox("hover", kind, UiStyle.cardboard(Color("fbf1d6"), RED, 1))
		t.set_stylebox("focus", kind, UiStyle.cardboard(Color("fbf1d6"), RED, 1))
		t.set_stylebox("pressed", kind, UiStyle.cardboard(Color("ecdcb2"), RED, 1))
		t.set_stylebox("hover_pressed", kind, UiStyle.cardboard(Color("ecdcb2"), RED, 1))
		t.set_stylebox("disabled", kind, UiStyle.cardboard(Color("a98558"), KRAFT_DARK, 1))
		t.set_font("font", kind, head_font())
	# Check boxes, text fields and tabs: cream text on dark cardboard.
	for kind in ["CheckBox", "CheckButton"]:
		for c in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
			t.set_color(c, kind, CREAM)
		t.set_stylebox("focus", kind, paper.call(Color(0, 0, 0, 0), RED, 2, 2.0))
	t.set_stylebox("normal", "LineEdit", paper.call(Color("2b1a0e"), KRAFT_DARK, 2, 5.0))
	t.set_stylebox("focus", "LineEdit", paper.call(Color("2b1a0e"), RED, 2, 5.0))
	t.set_stylebox("read_only", "LineEdit", paper.call(Color("2b1a0e"), KRAFT_DARK, 2, 5.0))
	t.set_color("font_color", "LineEdit", CREAM)
	t.set_color("caret_color", "LineEdit", CREAM)
	t.set_color("selection_color", "LineEdit", Color(RED, 0.6))
	t.set_color("font_placeholder_color", "LineEdit", Color(CREAM, 0.5))
	t.set_stylebox("panel", "TabContainer", board)
	t.set_stylebox("tab_selected", "TabContainer", UiStyle.cardboard(Color("d2a977"), KRAFT_DARK, 2))
	t.set_stylebox("tab_unselected", "TabContainer", UiStyle.cardboard(Color("8c5f36"), KRAFT_DEEP, 1))
	t.set_stylebox("tab_hovered", "TabContainer", UiStyle.cardboard(Color("b98655"), RED, 1))
	t.set_color("font_selected_color", "TabContainer", INK)
	t.set_color("font_unselected_color", "TabContainer", CREAM)
	t.set_color("font_hovered_color", "TabContainer", INK)
	# Sliders and progress bars.
	for kind in ["HSlider", "VSlider"]:
		t.set_stylebox("slider", kind, paper.call(Color(dark, 0.7), KRAFT_DARK, 1, 2.0))
		t.set_stylebox("grabber_area", kind, paper.call(RED, RED, 0, 2.0))
		t.set_stylebox("grabber_area_highlight", kind, paper.call(Color("e5463e"), Color("e5463e"), 0, 2.0))
	t.set_stylebox("background", "ProgressBar", paper.call(Color(dark, 0.7), KRAFT_DARK, 1, 2.0))
	t.set_stylebox("fill", "ProgressBar", paper.call(RED, RED, 0, 2.0))
	t.set_color("font_color", "ProgressBar", CREAM)
	t.set_stylebox("panel", "PanelContainer", board)
	t.set_stylebox("panel", "Panel", board)
	t.set_color("font_color", "Label", CREAM)
	_global = t
	return t
