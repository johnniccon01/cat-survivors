extends Node2D
## Endless living-room floor drawn around the camera: wooden planks plus
## procedurally placed rugs, window light and scattered clutter. Decorations
## are generated per CHUNK from a seeded RNG, so the same spot always looks
## the same. Purely visual: nothing here collides.

const PLANK := Vector2(96, 16)
const WOOD := Color("8a5a3b")
const SEAM := Color("5e3b26")
const KNOT := Color("6d4530")
const OUTLINE := Color("2b1d14")

const CHUNK := 320.0
const MAX_CACHE := 400
const RUG_COLORS: Array[Color] = [Color("8e3b46"), Color("2f6f73"), Color("c9a24a"), Color("5b4a8a"), Color("3f6b3a")]
const ITEM_KINDS: Array[String] = ["mouse", "book", "ball", "feather", "crumbs"]

## chunk coords -> generated decoration description
var _cache: Dictionary = {}


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	var center := camera.get_screen_center_position()
	var half := get_viewport_rect().size / camera.zoom * 0.5
	_draw_planks(center, half + PLANK)

	# Decorations can stick out of their chunk, so include a one-chunk margin.
	var c0 := Vector2i(floori((center.x - half.x) / CHUNK) - 1, floori((center.y - half.y) / CHUNK) - 1)
	var c1 := Vector2i(floori((center.x + half.x) / CHUNK) + 1, floori((center.y + half.y) / CHUNK) + 1)
	var chunks: Array[Dictionary] = []
	for cx in range(c0.x, c1.x + 1):
		for cy in range(c0.y, c1.y + 1):
			chunks.append(_chunk(Vector2i(cx, cy)))
	# Layers: rugs first, then clutter, then light on top of everything.
	for decor in chunks:
		if decor.has("rug"):
			_draw_rug(decor["rug"])
	for decor in chunks:
		for item: Dictionary in decor["items"]:
			_draw_item(item)
	for decor in chunks:
		if decor.has("sun"):
			_draw_sun(decor["sun"])


func _draw_planks(center: Vector2, half: Vector2) -> void:
	var row0 := floori((center.y - half.y) / PLANK.y)
	var row1 := floori((center.y + half.y) / PLANK.y)
	for row in range(row0, row1 + 1):
		var shift := fposmod(row * 37.0, PLANK.x)
		var col0 := floori((center.x - half.x - shift) / PLANK.x)
		var col1 := floori((center.x + half.x - shift) / PLANK.x)
		for col in range(col0, col1 + 1):
			var pos := Vector2(col * PLANK.x + shift, row * PLANK.y)
			var h := hash(Vector2i(col, row))
			draw_rect(Rect2(pos, PLANK), WOOD.darkened((h % 9) * 0.015))
			draw_line(pos, pos + Vector2(0, PLANK.y), SEAM, 1.0)
			draw_line(pos + Vector2(0, PLANK.y - 1), pos + Vector2(PLANK.x, PLANK.y - 1), SEAM, 1.0)
			if h % 7 == 0:
				var knot := pos + Vector2(12 + (h >> 4) % 70, PLANK.y * 0.5)
				draw_colored_polygon(Shapes.ellipse(knot, 3, 1.5, 8), KNOT)


func _chunk(c: Vector2i) -> Dictionary:
	if _cache.has(c):
		return _cache[c]
	if _cache.size() > MAX_CACHE:
		_cache.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(c) + 7919
	var origin := Vector2(c) * CHUNK
	var decor := {"items": []}
	var roll := rng.randf()
	if roll < 0.4:
		var size := Vector2(rng.randf_range(110, 190), rng.randf_range(70, 120))
		decor["rug"] = {
			"rect": Rect2(origin + Vector2(rng.randf_range(20, CHUNK - size.x - 20), rng.randf_range(20, CHUNK - size.y - 20)), size),
			"color": RUG_COLORS[rng.randi() % RUG_COLORS.size()],
			"oval": rng.randf() < 0.4,
		}
	if rng.randf() < 0.3:
		decor["sun"] = {
			"pos": origin + Vector2(rng.randf_range(0, CHUNK - 120), rng.randf_range(0, CHUNK - 90)),
			"size": Vector2(rng.randf_range(70, 110), rng.randf_range(55, 80)),
		}
	for i in rng.randi_range(1, 4):
		decor["items"].append({
			"kind": ITEM_KINDS[rng.randi() % ITEM_KINDS.size()],
			"pos": origin + Vector2(rng.randf_range(10, CHUNK - 10), rng.randf_range(10, CHUNK - 10)),
			"rot": rng.randf_range(-0.6, 0.6),
			"color": RUG_COLORS[rng.randi() % RUG_COLORS.size()],
		})
	_cache[c] = decor
	return decor


func _draw_rug(rug: Dictionary) -> void:
	var r: Rect2 = rug["rect"]
	var color: Color = rug["color"]
	var c := r.get_center()
	if rug["oval"]:
		# Braided rug: rings of alternating shades.
		for i in 5:
			var k := 1.0 - i * 0.18
			var ring := color if i % 2 == 0 else color.lightened(0.25)
			draw_colored_polygon(Shapes.ellipse(c, r.size.x * 0.5 * k, r.size.y * 0.5 * k, 32), ring)
		draw_polyline(Shapes.closed(Shapes.ellipse(c, r.size.x * 0.5, r.size.y * 0.5, 32)), color.darkened(0.4), 1.0)
		return
	# Rectangular rug with border, stripes and fringe on the short sides.
	for y in range(int(r.position.y) + 2, int(r.end.y) - 1, 3):
		draw_line(Vector2(r.position.x - 4, y), Vector2(r.position.x, y), Color("e8dcc0"), 1.0)
		draw_line(Vector2(r.end.x, y), Vector2(r.end.x + 4, y), Color("e8dcc0"), 1.0)
	draw_rect(r, color.darkened(0.25))
	var inner := r.grow(-6)
	draw_rect(inner, color)
	draw_rect(inner, color.lightened(0.3), false, 1.0)
	var stripe := color.lightened(0.18)
	for i in range(1, 4):
		var x := inner.position.x + inner.size.x * i / 4.0
		draw_line(Vector2(x, inner.position.y + 4), Vector2(x, inner.end.y - 4), stripe, 2.0)
	var diamond := PackedVector2Array([c + Vector2(0, -12), c + Vector2(16, 0), c + Vector2(0, 12), c + Vector2(-16, 0)])
	draw_colored_polygon(diamond, color.lightened(0.3))


func _draw_sun(sun: Dictionary) -> void:
	# Light falling through a 2x2 window, skewed as if the sun is low.
	var pos: Vector2 = sun["pos"]
	var size: Vector2 = sun["size"]
	var skew := Vector2(size.y * 0.5, 0)
	var light := Color(1.0, 0.93, 0.7, 0.13)
	var pane := (size - Vector2(4, 4)) * 0.5
	for ix in 2:
		for iy in 2:
			var p := pos + Vector2(ix * (pane.x + 4), iy * (pane.y + 4))
			var top := p + skew * (iy * (pane.y + 4) / size.y)
			var bottom_skew := skew * ((iy * (pane.y + 4) + pane.y) / size.y)
			var quad := PackedVector2Array([
				top, top + Vector2(pane.x, 0),
				p + Vector2(pane.x, pane.y) + bottom_skew, p + Vector2(0, pane.y) + bottom_skew,
			])
			draw_colored_polygon(quad, light)


func _draw_item(item: Dictionary) -> void:
	var pos: Vector2 = item["pos"]
	var color: Color = item["color"]
	draw_set_transform(pos, item["rot"])
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
			draw_line(Vector2(-4, -5), Vector2(-4, 3), color.darkened(0.3), 1.0)
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
