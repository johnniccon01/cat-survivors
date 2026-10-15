class_name CatArt
## Draws a cat in the game's placeholder pixel style. The look comes from
## data/cats.json (colors plus optional stripes, Siamese points, fluffy fur,
## calico patches and size), so every cat — player, companion or rival —
## shares one drawing routine.

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
		}
	return _looks[cat_id]


## Draws the cat centred on `offset`. `facing` is 1 or -1. `mood` can be
## "normal", "sad" (trapped) or "angry" (rival).
static func draw(ci: CanvasItem, lk: Dictionary, facing: int, walk_t: float,
		flash: bool = false, dead: bool = false, mood: String = "normal", offset: Vector2 = Vector2.ZERO,
		zoom: float = 1.0) -> void:
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
