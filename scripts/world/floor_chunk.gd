class_name FloorChunk
extends Node2D
## One layer of one floor chunk, drawn once from the description made by
## floor.gd. GROUND = floor surface, DECOR = rugs, furniture and clutter
## (plus real lights for lamps), OVERLAY = moonlight and lamp glow.

enum Layer { GROUND, DECOR, OVERLAY }

const OUTLINE := Color("2b1d14")
const WOOD := Color("8a5a3b")
const WOOD_DARK := Color("6b4630")
const SEAM := Color("5e3b26")
const PLANK := Vector2(96, 16)
const TILE := 32.0
const RUG_COLORS: Array[Color] = [Color("8e3b46"), Color("2f6f73"), Color("c9a24a"), Color("5b4a8a"), Color("3f6b3a")]
const ITEM_KINDS: Array[String] = ["mouse", "book", "ball", "feather", "crumbs"]
const FURNITURE := {
	"living": ["sofa", "armchair", "coffee_table", "bookshelf", "tv", "floor_lamp", "plant", "cat_tree"],
	"kitchen": ["dining_table", "cat_bowls", "trash_bin", "counter", "dining_table"],
	"bedroom": ["bed", "nightstand", "wardrobe", "cat_bed", "bed", "floor_lamp"],
}
const LAMPS := ["floor_lamp", "nightstand"]
const LAMP_COLOR := Color(1.0, 0.82, 0.55)

static var _light_texture: Texture2D

var layer := Layer.GROUND
var desc: Dictionary


func _ready() -> void:
	if layer != Layer.DECOR:
		return
	for f: Dictionary in desc["furniture"]:
		if f["kind"] in LAMPS:
			var light := PointLight2D.new()
			light.texture = _get_light_texture()
			light.texture_scale = 1.6
			light.energy = 0.9
			light.color = LAMP_COLOR
			light.position = f["pos"]
			add_child(light)


static func _get_light_texture() -> Texture2D:
	if _light_texture == null:
		var gradient := Gradient.new()
		gradient.set_color(0, Color(1, 1, 1, 1))
		gradient.set_color(1, Color(1, 1, 1, 0))
		var tex := GradientTexture2D.new()
		tex.gradient = gradient
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(1.0, 0.5)
		tex.width = 128
		tex.height = 128
		_light_texture = tex
	return _light_texture


func _draw() -> void:
	match layer:
		Layer.GROUND:
			_draw_ground()
		Layer.DECOR:
			if desc.has("rug"):
				_draw_rug(desc["rug"])
			for item: Dictionary in desc["items"]:
				_draw_item(item)
			for f: Dictionary in desc["furniture"]:
				_draw_furniture(f)
		Layer.OVERLAY:
			if desc.has("moon"):
				_draw_moon(desc["moon"])
			for f: Dictionary in desc["furniture"]:
				if f["kind"] in LAMPS:
					for i in 4:
						draw_circle(f["pos"], 18.0 + i * 14.0, Color(LAMP_COLOR, 0.05))


# --- Ground -----------------------------------------------------------------

func _draw_ground() -> void:
	var size: float = desc["size"]
	var area := Rect2(Vector2.ZERO, Vector2(size, size))
	match desc["zone"]:
		"kitchen":
			_draw_tiles(size)
		"bedroom":
			_draw_carpet(size)
		_:
			_draw_planks(area)
	var strip := Color("3e2a1c")
	if desc["edge_right"]:
		draw_rect(Rect2(size - 3, 0, 3, size), strip)
	if desc["edge_bottom"]:
		draw_rect(Rect2(0, size - 3, size, 3), strip)


func _draw_planks(area: Rect2) -> void:
	# Planks are laid out in world coordinates so they line up across chunks.
	var origin := position
	var row0 := floori(origin.y / PLANK.y)
	for r in int(area.size.y / PLANK.y):
		var row := row0 + r
		var shift := fposmod(row * 37.0, PLANK.x)
		var y := row * PLANK.y - origin.y
		var col0 := floori((origin.x - shift) / PLANK.x)
		var col1 := floori((origin.x + area.size.x - shift) / PLANK.x)
		for col in range(col0, col1 + 1):
			var x := col * PLANK.x + shift - origin.x
			var rect := Rect2(x, y, PLANK.x, PLANK.y).intersection(area)
			if rect.size.x <= 0.0:
				continue
			var h := hash(Vector2i(col, row))
			draw_rect(rect, WOOD.darkened((h % 9) * 0.015))
			if x >= 0.0:
				draw_line(Vector2(x, y), Vector2(x, y + PLANK.y), SEAM, 1.0)
			draw_line(Vector2(rect.position.x, y + PLANK.y - 1), Vector2(rect.end.x, y + PLANK.y - 1), SEAM, 1.0)
			if h % 7 == 0:
				var knot := Vector2(x + 12 + (h >> 4) % 70, y + PLANK.y * 0.5)
				if area.has_point(knot):
					draw_colored_polygon(Shapes.ellipse(knot, 3, 1.5, 8), Color("6d4530"))


func _draw_tiles(size: float) -> void:
	var t0 := Vector2i(floori(position.x / TILE), floori(position.y / TILE))
	var n := int(size / TILE)
	for ix in n:
		for iy in n:
			var odd := (t0.x + ix + t0.y + iy) % 2 != 0
			draw_rect(Rect2(ix * TILE, iy * TILE, TILE, TILE), Color("b7c4cc") if odd else Color("e9e2d0"))
	var grout := Color("8f9a9e")
	for i in n + 1:
		draw_line(Vector2(i * TILE, 0), Vector2(i * TILE, size), grout, 1.0)
		draw_line(Vector2(0, i * TILE), Vector2(size, i * TILE), grout, 1.0)


func _draw_carpet(size: float) -> void:
	draw_rect(Rect2(0, 0, size, size), Color("6f5f86"))
	var dot := Color("7d6d95")
	for iy in int(size / 8.0):
		var shift := 4.0 if iy % 2 == 0 else 0.0
		for ix in int(size / 8.0):
			draw_rect(Rect2(ix * 8.0 + shift, iy * 8.0, 1, 1), dot)


# --- Decor ------------------------------------------------------------------

func _draw_rug(rug: Dictionary) -> void:
	var r: Rect2 = rug["rect"]
	var color: Color = rug["color"]
	var c := r.get_center()
	if rug["oval"]:
		for i in 5:
			var k := 1.0 - i * 0.18
			var ring := color if i % 2 == 0 else color.lightened(0.25)
			draw_colored_polygon(Shapes.ellipse(c, r.size.x * 0.5 * k, r.size.y * 0.5 * k, 32), ring)
		draw_polyline(Shapes.closed(Shapes.ellipse(c, r.size.x * 0.5, r.size.y * 0.5, 32)), color.darkened(0.4), 1.0)
		return
	for y in range(int(r.position.y) + 2, int(r.end.y) - 1, 3):
		draw_line(Vector2(r.position.x - 4, y), Vector2(r.position.x, y), Color("e8dcc0"), 1.0)
		draw_line(Vector2(r.end.x, y), Vector2(r.end.x + 4, y), Color("e8dcc0"), 1.0)
	draw_rect(r, color.darkened(0.25))
	var inner := r.grow(-6)
	draw_rect(inner, color)
	draw_rect(inner, color.lightened(0.3), false, 1.0)
	for i in range(1, 4):
		var x := inner.position.x + inner.size.x * i / 4.0
		draw_line(Vector2(x, inner.position.y + 4), Vector2(x, inner.end.y - 4), color.lightened(0.18), 2.0)
	var diamond := PackedVector2Array([c + Vector2(0, -12), c + Vector2(16, 0), c + Vector2(0, 12), c + Vector2(-16, 0)])
	draw_colored_polygon(diamond, color.lightened(0.3))


func _draw_moon(moon: Dictionary) -> void:
	# Moonlight falling through a 2x2 window, skewed.
	var pos: Vector2 = moon["pos"]
	var size: Vector2 = moon["size"]
	var skew := Vector2(size.y * 0.5, 0)
	var light := Color(0.72, 0.82, 1.0, 0.16)
	var pane := (size - Vector2(4, 4)) * 0.5
	for ix in 2:
		for iy in 2:
			var p := pos + Vector2(ix * (pane.x + 4), iy * (pane.y + 4))
			var top := p + skew * (iy * (pane.y + 4) / size.y)
			var bottom_skew := skew * ((iy * (pane.y + 4) + pane.y) / size.y)
			draw_colored_polygon(PackedVector2Array([
				top, top + Vector2(pane.x, 0),
				p + Vector2(pane.x, pane.y) + bottom_skew, p + Vector2(0, pane.y) + bottom_skew,
			]), light)


func _draw_item(item: Dictionary) -> void:
	var color: Color = item["color"]
	draw_set_transform(item["pos"], item["rot"])
	match item["kind"]:
		"mouse":
			draw_line(Vector2(-5, 0), Vector2(-10, -2), Color("d9a0a8"), 1.0)
			draw_colored_polygon(Shapes.ellipse(Vector2.ZERO, 5, 3), Color("9a9a9a"))
			draw_polyline(Shapes.closed(Shapes.ellipse(Vector2.ZERO, 5, 3)), OUTLINE, 1.0)
			draw_circle(Vector2(2, -3), 1.5, Color("d9a0a8"))
			draw_rect(Rect2(3, -1, 1, 1), OUTLINE)
		"book":
			draw_rect(Rect2(-7, -5, 14, 10), color)
			draw_rect(Rect2(-7, 3, 14, 2), Color("efe6d0"))
			draw_rect(Rect2(-7, -5, 14, 10), OUTLINE, false, 1.0)
		"ball":
			draw_circle(Vector2.ZERO, 4.0, OUTLINE)
			draw_circle(Vector2.ZERO, 3.0, color.lightened(0.2))
			draw_rect(Rect2(-1, -2, 1, 1), Color(1, 1, 1, 0.8))
		"feather":
			draw_line(Vector2(-7, 2), Vector2(7, -2), Color("e8e0d0"), 1.0)
			for i in 5:
				var x := -4.0 + i * 2.5
				draw_line(Vector2(x, 1 - i * 0.6), Vector2(x - 2, -2 - i * 0.6), color.lightened(0.4), 1.0)
				draw_line(Vector2(x, 1 - i * 0.6), Vector2(x - 1, 4 - i * 0.6), color.lightened(0.4), 1.0)
		"crumbs":
			for p: Vector2 in [Vector2(-3, 0), Vector2(1, -2), Vector2(3, 2), Vector2(-1, 3)]:
				draw_rect(Rect2(p, Vector2(1, 1)), Color("d8b77a"))
	draw_set_transform(Vector2.ZERO)


# --- Furniture (top-down, drawn centred on the origin) -----------------------

func _draw_furniture(f: Dictionary) -> void:
	var color: Color = f["color"]
	draw_set_transform(f["pos"], f["rot"])
	match f["kind"]:
		"sofa":
			_box(Rect2(-56, -22, 112, 44), color.darkened(0.2))
			_box(Rect2(-56, -22, 112, 12), color.darkened(0.35))
			for i in 3:
				_box(Rect2(-44 + i * 30, -10, 28, 28), color)
				draw_line(Vector2(-40 + i * 30, -6), Vector2(-24 + i * 30, -6), color.lightened(0.2), 1.0)
			_box(Rect2(-56, -22, 10, 44), color.darkened(0.3))
			_box(Rect2(46, -22, 10, 44), color.darkened(0.3))
		"armchair":
			_box(Rect2(-22, -22, 44, 44), color.darkened(0.2))
			_box(Rect2(-22, -22, 44, 11), color.darkened(0.35))
			_box(Rect2(-14, -10, 28, 28), color)
			_box(Rect2(-22, -22, 8, 44), color.darkened(0.3))
			_box(Rect2(14, -22, 8, 44), color.darkened(0.3))
		"coffee_table":
			_box(Rect2(-32, -18, 64, 36), WOOD_DARK)
			draw_rect(Rect2(-28, -14, 56, 28), WOOD)
			draw_circle(Vector2(14, -2), 5.0, OUTLINE)
			draw_circle(Vector2(14, -2), 4.0, Color("efe6d0"))
			draw_circle(Vector2(14, -2), 2.5, Color("5a3a26"))
			_box(Rect2(-22, -8, 18, 14), color.lightened(0.2))
		"bookshelf":
			_box(Rect2(-55, -11, 110, 22), WOOD_DARK)
			var rng := RandomNumberGenerator.new()
			rng.seed = int(f["pos"].x * 31 + f["pos"].y)
			var x := -52.0
			while x < 50.0:
				var w := rng.randf_range(3, 7)
				draw_rect(Rect2(x, -8, w - 1, 16), RUG_COLORS[rng.randi() % RUG_COLORS.size()].lightened(rng.randf() * 0.3))
				x += w
		"tv":
			_box(Rect2(-45, -11, 90, 22), WOOD_DARK)
			_box(Rect2(-36, -14, 72, 7), Color("1d1d24"))
			draw_line(Vector2(-30, -11), Vector2(30, -11), Color("4a5a7a"), 1.0)
			draw_circle(Vector2(30, 4), 3.0, Color("2a2a30"))
		"floor_lamp":
			draw_circle(Vector2.ZERO, 13.0, OUTLINE)
			draw_circle(Vector2.ZERO, 12.0, Color("f3e3b8"))
			draw_circle(Vector2.ZERO, 6.0, Color("fff3c8"))
		"plant":
			draw_circle(Vector2.ZERO, 13.0, OUTLINE)
			draw_circle(Vector2.ZERO, 12.0, Color("b5603a"))
			for i in 7:
				var a := TAU * i / 7.0
				var tip := Vector2.from_angle(a) * 22.0
				var side := Vector2.from_angle(a + PI * 0.5) * 5.0
				var leaf := PackedVector2Array([Vector2.ZERO, tip * 0.5 + side, tip, tip * 0.5 - side])
				draw_colored_polygon(leaf, Color("4f8f3e") if i % 2 == 0 else Color("5ea84a"))
				draw_polyline(Shapes.closed(leaf), OUTLINE, 1.0)
		"cat_tree":
			_box(Rect2(-24, -24, 48, 48), Color("d8c8a8"))
			for p: Vector2 in [Vector2(-14, -14), Vector2(14, 14)]:
				draw_circle(p, 6.0, OUTLINE)
				draw_circle(p, 5.0, Color("c9a26a"))
			draw_circle(Vector2(8, -8), 13.0, OUTLINE)
			draw_circle(Vector2(8, -8), 12.0, color.lightened(0.2))
			draw_line(Vector2(-12, 10), Vector2(-12, 22), Color("e04646"), 1.0)
			draw_circle(Vector2(-12, 22), 2.5, Color("e04646"))
		"dining_table":
			for chair: Vector2 in [Vector2(-22, -38), Vector2(22, -38), Vector2(-22, 38), Vector2(22, 38)]:
				_box(Rect2(chair - Vector2(9, 9), Vector2(18, 18)), WOOD)
			_box(Rect2(-46, -28, 92, 56), WOOD_DARK)
			draw_rect(Rect2(-42, -24, 84, 48), WOOD)
			for plate: Vector2 in [Vector2(-22, -14), Vector2(22, -14), Vector2(-22, 14), Vector2(22, 14)]:
				draw_circle(plate, 7.0, Color("f4f1ea"))
				draw_circle(plate, 4.0, Color("e2ddd0"))
		"cat_bowls":
			_box(Rect2(-24, -12, 48, 24), color.lightened(0.3))
			for b: Vector2 in [Vector2(-11, 0), Vector2(11, 0)]:
				draw_circle(b, 8.0, OUTLINE)
				draw_circle(b, 7.0, Color("d9d9e0"))
			draw_circle(Vector2(11, 0), 5.0, Color("6fb0e0"))
			for k: Vector2 in [Vector2(-13, -1), Vector2(-10, 1), Vector2(-9, -2), Vector2(-12, 2)]:
				draw_rect(Rect2(k, Vector2(2, 2)), Color("9a6a3a"))
		"trash_bin":
			draw_circle(Vector2.ZERO, 11.0, OUTLINE)
			draw_circle(Vector2.ZERO, 10.0, Color("8a9096"))
			draw_line(Vector2(-6, 0), Vector2(6, 0), Color("5f6468"), 2.0)
		"counter":
			_box(Rect2(-56, -18, 112, 36), Color("c9ced2"))
			_box(Rect2(-46, -11, 30, 22), Color("9fb2bf"))
			draw_circle(Vector2(-31, 0), 2.0, Color("6a7a85"))
			for p: Vector2 in [Vector2(14, -7), Vector2(34, -7), Vector2(14, 7), Vector2(34, 7)]:
				draw_circle(p, 6.0, Color("2a2a30"))
				draw_arc(p, 4.0, 0.0, TAU, 12, Color("5a5a64"), 1.0)
		"bed":
			_box(Rect2(-46, -62, 92, 124), WOOD_DARK)
			draw_rect(Rect2(-42, -58, 84, 116), Color("f1ece2"))
			_box(Rect2(-38, -54, 34, 20), Color("ffffff"))
			_box(Rect2(4, -54, 34, 20), Color("ffffff"))
			_box(Rect2(-42, -24, 84, 82), color)
			draw_line(Vector2(-42, -18), Vector2(42, -18), color.lightened(0.3), 2.0)
		"nightstand":
			_box(Rect2(-14, -14, 28, 28), WOOD)
			draw_circle(Vector2.ZERO, 8.0, OUTLINE)
			draw_circle(Vector2.ZERO, 7.0, Color("f3e3b8"))
			draw_circle(Vector2.ZERO, 3.0, Color("fff3c8"))
		"wardrobe":
			_box(Rect2(-55, -16, 110, 32), WOOD_DARK)
			draw_line(Vector2(0, -16), Vector2(0, 16), OUTLINE, 1.0)
			draw_rect(Rect2(-5, -2, 2, 4), Color("f2c14e"))
			draw_rect(Rect2(3, -2, 2, 4), Color("f2c14e"))
		"cat_bed":
			draw_circle(Vector2.ZERO, 18.0, OUTLINE)
			draw_circle(Vector2.ZERO, 17.0, color)
			draw_circle(Vector2.ZERO, 11.0, color.lightened(0.35))
			draw_circle(Vector2(-4, 3), 2.0, Color(1, 1, 1, 0.5))
	draw_set_transform(Vector2.ZERO)


## Filled rectangle with an outline and a soft drop shadow.
func _box(r: Rect2, fill: Color) -> void:
	draw_rect(Rect2(r.position + Vector2(2, 3), r.size), Color(0, 0, 0, 0.18))
	draw_rect(r, fill)
	draw_rect(r, OUTLINE, false, 1.0)
