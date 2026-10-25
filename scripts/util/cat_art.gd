class_name CatArt
## Draws a cat. Uses the pixel-art sheet from tools/gen_sprites.py when it
## exists (rows: normal, angry, sad, white flash; 4 walk frames plus a lying
## frame), otherwise falls back to simple vector shapes. The look comes from
## data/cats.json, so every cat — player, companion or rival — shares one
## drawing routine.

const OUTLINE := Color("2b1d14")
const NOSE := Color("f3a9b8")

static var _looks: Dictionary = {}


## Parsed look for a cat id (cached).
static func look(cat_id: String) -> Dictionary:
	if not _looks.has(cat_id):
		var d: Dictionary = GameData.cats.get(cat_id, GameData.cats["MICA"])
		_looks[cat_id] = {
			"fur": Color(d.get("fur", "#d98c4a")),
			"dark": Color(d.get("dark", "#a8602c")),
			"belly": Color(d.get("belly", "#f3d9b8")),
			"eyes": Color(d.get("eyes", "#2b1d14")),
			"stripes": d.get("stripes", false),
			"points": d.get("points", false),
			"fluffy": d.get("fluffy", false),
			"patches": d.get("patches", false),
			"size": float(d.get("size", 1.0)),
			"halo": d.get("halo", false),
			"wings": d.get("wings", false),
			"horns": d.get("horns", false),
			"hat": d.get("hat", false),
			"id": cat_id,
		}
	return _looks[cat_id]


## Draws the cat centred on `offset`. `facing` is 1 or -1. `mood` can be
## "normal", "sad" (trapped) or "angry" (rival).
static func draw(ci: CanvasItem, lk: Dictionary, facing: int, walk_t: float,
		flash: bool = false, dead: bool = false, mood: String = "normal", offset: Vector2 = Vector2.ZERO,
		zoom: float = 1.0, moving: bool = true) -> void:
	var sprite := Sprites.cat(lk.get("id", ""))
	if not sprite.is_empty():
		_draw_sprite(ci, sprite, lk, facing, walk_t, flash, dead, mood, offset, zoom, moving)
		return
	var size: float = lk["size"] * zoom
	var fur: Color = Color.WHITE if flash else lk["fur"]
	var dark: Color = Color.WHITE if flash else lk["dark"]
	var belly: Color = lk["belly"]
	var points: bool = lk["points"]
	var step := sin(walk_t)

	ci.draw_colored_polygon(Shapes.ellipse(offset + Vector2(0, 8) * size, 9 * size, 3 * size), Color(0, 0, 0, 0.25))
	if dead:
		ci.draw_set_transform(offset + Vector2(0, 2), PI * 0.5 * facing, Vector2(facing, 1) * size)
	else:
		ci.draw_set_transform(offset, 0.0, Vector2(facing, 1) * size)

	# Tail
	var sway := sin(walk_t * 0.5) * 2.0
	var tail := PackedVector2Array([Vector2(-7, 0), Vector2(-11, -3), Vector2(-11 + sway, -8), Vector2(-9 + sway, -11)])
	ci.draw_polyline(tail, OUTLINE, 5.0 if lk["fluffy"] else 4.0)
	ci.draw_polyline(tail, dark if points else fur, 3.0 if lk["fluffy"] else 2.0)

	# Legs: diagonal pairs move in opposite phase
	for leg: Vector2 in [Vector2(-6, 1), Vector2(-3, -1), Vector2(3, -1), Vector2(6, 1)]:
		var lift := maxf(step * leg.y, 0.0)
		ci.draw_rect(Rect2(leg.x - 1.5, 4 - lift, 3, 4), OUTLINE)
		ci.draw_rect(Rect2(leg.x - 0.5, 4 - lift, 1, 3), dark if points else fur)

	# Body
	if lk["fluffy"]:
		for p: Vector2 in [Vector2(-7, -2), Vector2(-3, -4), Vector2(2, -4), Vector2(6, -1), Vector2(-8, 3), Vector2(7, 4)]:
			ci.draw_circle(p, 3.5, OUTLINE)
	ci.draw_colored_polygon(Shapes.ellipse(Vector2(0, 1), 9, 6), OUTLINE)
	if lk["fluffy"]:
		for p: Vector2 in [Vector2(-7, -2), Vector2(-3, -4), Vector2(2, -4), Vector2(6, -1), Vector2(-8, 3), Vector2(7, 4)]:
			ci.draw_circle(p, 2.5, fur)
	ci.draw_colored_polygon(Shapes.ellipse(Vector2(0, 1), 8, 5), fur)
	ci.draw_colored_polygon(Shapes.ellipse(Vector2(1, 3), 5, 2.5), belly)
	if lk["stripes"]:
		for x: float in [-5.0, -2.0, 1.0]:
			ci.draw_line(Vector2(x, -3), Vector2(x + 1, 0), dark, 1.0)
	if lk["patches"]:
		ci.draw_colored_polygon(Shapes.ellipse(Vector2(-4, -1), 3, 2.5, 10), dark)
		ci.draw_colored_polygon(Shapes.ellipse(Vector2(3, 0), 2, 2, 8), Color("3a2a22"))

	# Head
	var head := Vector2(6, -5)
	var ears: Array[PackedVector2Array] = [
		PackedVector2Array([Vector2(2, -8), Vector2(3, -14), Vector2(7, -9)]),
		PackedVector2Array([Vector2(6, -9), Vector2(10, -14), Vector2(11, -7)]),
	]
	if mood == "sad":
		# Flattened ears
		ears = [
			PackedVector2Array([Vector2(1, -7), Vector2(0, -11), Vector2(5, -9)]),
			PackedVector2Array([Vector2(8, -9), Vector2(13, -10), Vector2(11, -6)]),
		]
	for ear in ears:
		ci.draw_colored_polygon(ear, dark if points else fur)
		ci.draw_polyline(Shapes.closed(ear), OUTLINE, 1.0)
	ci.draw_circle(head, 6.0, OUTLINE)
	ci.draw_circle(head, 5.0, fur)
	if points:
		ci.draw_colored_polygon(Shapes.ellipse(head + Vector2(2, 0), 3.5, 3, 10), dark)
	if lk["patches"]:
		ci.draw_colored_polygon(Shapes.ellipse(head + Vector2(-2, -2), 2.5, 2, 8), dark)
	if lk["stripes"]:
		ci.draw_line(head + Vector2(-2, -4), head + Vector2(-1, -2), dark, 1.0)
		ci.draw_line(head + Vector2(1, -4), head + Vector2(1, -2), dark, 1.0)
	var eye_color: Color = lk["eyes"]
	if dead:
		for e: Vector2 in [head + Vector2(1, -1), head + Vector2(4, -1)]:
			ci.draw_line(e + Vector2(-1, -1), e + Vector2(1, 1), OUTLINE, 1.0)
			ci.draw_line(e + Vector2(-1, 1), e + Vector2(1, -1), OUTLINE, 1.0)
	else:
		ci.draw_rect(Rect2(head + Vector2(0, -2), Vector2(1, 2)), eye_color)
		ci.draw_rect(Rect2(head + Vector2(3, -2), Vector2(1, 2)), eye_color)
		if mood == "angry":
			ci.draw_line(head + Vector2(-1, -4), head + Vector2(1, -3), OUTLINE, 1.0)
			ci.draw_line(head + Vector2(5, -4), head + Vector2(3, -3), OUTLINE, 1.0)
		elif mood == "sad":
			ci.draw_rect(Rect2(head + Vector2(0, 1), Vector2(1, 1)), Color("8fd3ff"))
	ci.draw_rect(Rect2(head + Vector2(4, 1), Vector2(2, 1)), NOSE)
	ci.draw_set_transform(Vector2.ZERO)


const MOOD_ROW := {"normal": 0, "angry": 1, "sad": 2}


static func _draw_sprite(ci: CanvasItem, sprite: Dictionary, lk: Dictionary, facing: int, walk_t: float,
		flash: bool, dead: bool, mood: String, offset: Vector2, zoom: float, moving: bool) -> void:
	var size: float = lk["size"] * zoom
	ci.draw_colored_polygon(Shapes.ellipse(offset + Vector2(0, 9) * size, 9 * size, 2.5 * size), Color(0, 0, 0, 0.25))
	var row: int = 3 if flash else MOOD_ROW.get(mood, 0)
	# Walk frames while moving; frame 1 (all paws down) when standing still.
	var col := (floori(walk_t / 1.6) % 4) if moving else 1
	if dead:
		row = 0
		col = 4
	# A locked cat on the selection screen is shown as a dark silhouette.
	var tint := Color(0.12, 0.09, 0.15) if lk.get("silhouette", false) else Color.WHITE
	ci.draw_set_transform(offset, 0.0, Vector2(facing, 1) * zoom)
	var s: float = lk["size"]
	# A silhouette keeps secrets: no wings, halo or horns to give it away.
	var extras: bool = not lk.get("silhouette", false)
	if extras and lk.get("wings", false) and not dead:
		_draw_wings(ci, s, walk_t)
	Sprites.draw_frame(ci, sprite, col, row, tint)
	if extras and lk.get("halo", false) and not dead:
		var c := Vector2(9.5, -21.0 + sin(walk_t * 0.4)) * s
		ci.draw_polyline(Shapes.closed(Shapes.ellipse(c, 5.5 * s, 1.8 * s, 16)), OUTLINE, 2.5)
		ci.draw_polyline(Shapes.closed(Shapes.ellipse(c, 5.5 * s, 1.8 * s, 16)), Color("f2d14e"), 1.2)
	if extras and lk.get("horns", false):
		for horn: Array in [[Vector2(5, -13), Vector2(3, -21)], [Vector2(12, -13), Vector2(15, -21)]]:
			var base: Vector2 = horn[0] * s
			var tip: Vector2 = horn[1] * s
			var tri := PackedVector2Array([base + Vector2(-1.8, 0) * s, tip, base + Vector2(1.8, 0) * s])
			ci.draw_colored_polygon(tri, Color("c92a2a"))
			ci.draw_polyline(Shapes.closed(tri), OUTLINE, 1.0)
	if extras and lk.get("hat", false) and not dead:
		# A captain's cap: white crown, navy band, black visor, gold badge.
		var crown := PackedVector2Array([Vector2(3, -14) * s, Vector2(4, -19) * s, Vector2(15, -19) * s, Vector2(16, -14) * s])
		ci.draw_colored_polygon(crown, Color("f4f1ea"))
		ci.draw_polyline(Shapes.closed(crown), OUTLINE, 1.0)
		ci.draw_rect(Rect2(Vector2(3, -15.5) * s, Vector2(13, 2) * s), Color("2a3a6a"))
		ci.draw_colored_polygon(Shapes.ellipse(Vector2(13, -13.5) * s, 4.0 * s, 1.3 * s, 10), Color("1f1c25"))
		ci.draw_circle(Vector2(9.5, -17) * s, 1.0 * s, Color("f2c14e"))
	var gear: Dictionary = lk.get("gear", {})
	if extras and not dead and not gear.is_empty():
		_draw_gear(ci, gear, s, lk.get("hat", false))
	ci.draw_set_transform(Vector2.ZERO)


## The look with the worn gear (see Items) added: the collar and the hat
## show on the cat.
static func with_gear(lk: Dictionary) -> Dictionary:
	var out := lk.duplicate()
	var gear := {}
	for slot: String in ["COLLAR", "HAT"]:
		var item := Profile.worn_item(slot)
		if not item.is_empty():
			gear[slot] = Items.color(item)
	out["gear"] = gear
	return out


## A collar with a little tag round the neck and a knitted hat with a pompom
## (no hat over a cat that already wears one).
static func _draw_gear(ci: CanvasItem, gear: Dictionary, s: float, has_hat: bool) -> void:
	if gear.has("COLLAR"):
		var c: Color = gear["COLLAR"]
		var band := Shapes.ellipse(Vector2(10.0, -3.0) * s, 4.2 * s, 1.2 * s, 14)
		ci.draw_colored_polygon(band, c)
		ci.draw_polyline(Shapes.closed(band), OUTLINE, 1.0)
		ci.draw_circle(Vector2(11.0, -1.7) * s, 1.1 * s, Color("f2c14e"))
	if gear.has("HAT") and not has_hat:
		var c: Color = gear["HAT"]
		var dome := PackedVector2Array()
		for i in 9:
			var a := PI + PI * i / 8.0
			dome.append(Vector2(9.5, -14.5) * s + Vector2(cos(a) * 5.5, sin(a) * 4.5) * s)
		ci.draw_colored_polygon(dome, c)
		ci.draw_polyline(Shapes.closed(dome), OUTLINE, 1.0)
		ci.draw_rect(Rect2(Vector2(4.0, -15.5) * s, Vector2(11.0, 2.0) * s), c.darkened(0.25))
		ci.draw_circle(Vector2(9.5, -19.5) * s, 1.4 * s, c.lightened(0.4))


## Two feathered wings behind the back that flap slowly.
static func _draw_wings(ci: CanvasItem, s: float, t: float) -> void:
	var flap := sin(t * 0.5) * 0.25
	for k in 2:
		var root := Vector2(-2 + k * 4, -5) * s
		var shade := Color("e8e2d6") if k == 0 else Color.WHITE
		var pts := PackedVector2Array()
		for p: Vector2 in [Vector2(0, 0), Vector2(-5, -9), Vector2(-11, -14), Vector2(-15, -12), Vector2(-14, -7), Vector2(-11, -3), Vector2(-6, 1)]:
			pts.append(root + (p * 1.6).rotated(-flap) * s)
		ci.draw_colored_polygon(pts, shade)
		ci.draw_polyline(Shapes.closed(pts), OUTLINE, 1.0)
		for f in 3:
			ci.draw_line(root + (Vector2(-5 - f * 3, -2 - f) * 1.6).rotated(-flap) * s, root + (Vector2(-9 - f * 2, -8 - f * 1.5) * 1.6).rotated(-flap) * s, Color("c9c2b4"), 1.0)
