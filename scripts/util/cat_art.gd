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
## Sheet row with the eyes closed (blinking).
const BLINK_ROW := 4
## Standing cats breathe, flick their tails and blink.
const BREATH := 0.035
## Seconds between blinks (plus a per-cat offset) and how long one lasts.
const BLINK_EVERY := 3.4
const BLINK_TIME := 0.14


## Breathing, step squash, lean and blink for a living cat at this moment.
## Uses the clock (not walk_t) so standing cats keep moving gently; `seed`
## keeps cats side by side out of step.
static func _life(walk_t: float, moving: bool, seed: int) -> Dictionary:
	var t := Time.get_ticks_msec() / 1000.0 + float(seed % 997) * 0.37
	var squash := 0.0
	var lean := 0.0
	var col := 1
	if moving:
		# Walking is the sheet's own frames only: no stretch or lean, which
		# smeared the pixels while the cat moved.
		col = floori(walk_t / 1.6) % 4
	else:
		squash = sin(t * 2.4) * BREATH
		# Frames 1 and 3 differ only in the tail: now and then it flicks.
		col = 3 if fmod(t, 2.6) > 2.0 else 1
	var blink := fmod(t, BLINK_EVERY + float(seed % 7) * 0.3) < BLINK_TIME
	return {"squash": squash, "lean": lean, "col": col, "blink": blink}


static func _draw_sprite(ci: CanvasItem, sprite: Dictionary, lk: Dictionary, facing: int, walk_t: float,
		flash: bool, dead: bool, mood: String, offset: Vector2, zoom: float, moving: bool) -> void:
	var size: float = lk["size"] * zoom
	ci.draw_colored_polygon(Shapes.ellipse(offset + Vector2(0, 9) * size, 9 * size, 2.5 * size), Color(0, 0, 0, 0.25))
	var row: int = 3 if flash else MOOD_ROW.get(mood, 0)
	var life := _life(walk_t, moving, ci.get_instance_id())
	# Walk frames while moving; standing still all paws are down and only
	# the tail flicks now and then.
	var col: int = life["col"]
	if life["blink"] and row == 0:
		row = BLINK_ROW
	var s: float = lk["size"]
	if dead:
		row = 0
		col = 4
		ci.draw_set_transform(offset, 0.0, Vector2(facing, 1) * zoom)
	else:
		# Squash and lean around the paws, so the feet stay on the ground.
		var feet := Vector2(0, 11.0 * s)
		var sq: float = life["squash"]
		var basis := Transform2D(float(life["lean"]) * facing, Vector2(facing * (1.0 - sq * 0.5), 1.0 + sq) * zoom, 0.0, Vector2.ZERO)
		ci.draw_set_transform_matrix(Transform2D(basis.x, basis.y, offset + feet * zoom - basis.basis_xform(feet)))
	# A locked cat on the selection screen is shown as a dark silhouette.
	var tint := Color(0.12, 0.09, 0.15) if lk.get("silhouette", false) else Color.WHITE
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
		_draw_outfit(ci, gear, s, col)
		_draw_gear(ci, gear, s, lk.get("hat", false))
	ci.draw_set_transform(Vector2.ZERO)


## The look with the worn hat (see Items) added: only the hat shows on the
## cat, and every kind of hat looks different.
static func with_gear(lk: Dictionary) -> Dictionary:
	var out := lk.duplicate()
	var gear := {}
	var item := Profile.worn_item("HAT")
	if not item.is_empty():
		gear["hat"] = item["base"]
		gear["color"] = Items.color(item)
	# The rest of the gear shows too: collar, vest, paws and a tail ornament.
	for slot: String in ["COLLAR", "VEST", "PAWS", "TAIL"]:
		var worn := Profile.worn_item(slot)
		if not worn.is_empty():
			gear[slot.to_lower()] = {"base": worn["base"], "color": Items.color(worn)}
	out["gear"] = gear
	return out


## Collar, vest, paws and tail ornament over the sprite. Points are in the
## sprite's own units (tools/gen_sprites.py, cat_frame) moved so the body
## centre is the origin; `col` is the walk frame, so paws and tail follow it.
static func _draw_outfit(ci: CanvasItem, gear: Dictionary, s: float, col: int) -> void:
	var frame := col % 4
	var bob := 1.0 if frame in [1, 3] else 0.0
	var at := func(x: float, y: float) -> Vector2: return Vector2(x - 16.0, y - 18.0) * s
	var fill := func(pts: PackedVector2Array, color: Color) -> void:
		ci.draw_colored_polygon(pts, color)
		ci.draw_polyline(Shapes.closed(pts), OUTLINE, 1.0)
	if gear.has("vest"):
		var v: Dictionary = gear["vest"]
		var c: Color = v["color"]
		if String(v["base"]) in ["CAPE", "FEATHER_CAPE"]:
			# A cape from the neck, blowing back over the body.
			fill.call(PackedVector2Array([at.call(21.0, 13.5 - bob), at.call(23.0, 15.5 - bob), at.call(9.0, 21.0 - bob), at.call(6.5, 17.0 - bob)]), c)
		else:
			# A vest over the back: the upper half of the body ellipse.
			var pts := PackedVector2Array()
			for i in 9:
				var a := PI * 1.08 + PI * 0.84 * i / 8.0
				pts.append(at.call(16.0 + cos(a) * 9.0, 18.0 - bob + sin(a) * 4.9))
			pts.append(at.call(23.5, 19.0 - bob))
			pts.append(at.call(8.5, 19.0 - bob))
			fill.call(pts, c)
			ci.draw_line(at.call(9.5, 18.6 - bob), at.call(22.5, 18.6 - bob), c.darkened(0.35), 1.0)
	if gear.has("paws"):
		var c: Color = (gear["paws"] as Dictionary)["color"]
		var lifts: Array = [[0, 2], [1, 1], [2, 0], [1, 1]][frame]
		var swing: Array = [[-1, 1], [0, 0], [1, -1], [0, 0]][frame]
		for leg: Array in [[10.0, 0], [13.0, 1], [21.0, 1], [24.0, 0]]:
			var lift := float(lifts[leg[1]])
			var p: Vector2 = at.call(float(leg[0]) + float(swing[leg[1]]) + 1.3, 26.4 - 2.0 * lift)
			var pts := Shapes.ellipse(p, 2.0 * s, 1.3 * s, 10)
			fill.call(pts, c)
	if gear.has("tail"):
		var t: Dictionary = gear["tail"]
		var c: Color = t["color"]
		var sway := float([0, 1, 0, -1][frame])
		var tip: Vector2 = at.call(6.0 + sway, 7.5)
		if String(t["base"]) in ["TAIL_BELL"]:
			ci.draw_circle(tip, 1.9 * s, OUTLINE)
			ci.draw_circle(tip, 1.4 * s, c)
		else:
			# A little bow tied round the tail.
			fill.call(PackedVector2Array([tip, tip + Vector2(-2.6, -1.6) * s, tip + Vector2(-2.6, 1.6) * s]), c)
			fill.call(PackedVector2Array([tip, tip + Vector2(2.6, -1.6) * s, tip + Vector2(2.6, 1.6) * s]), c)
			ci.draw_circle(tip, 0.9 * s, c.darkened(0.3))
	if gear.has("collar"):
		var k: Dictionary = gear["collar"]
		var c: Color = k["color"]
		var band := PackedVector2Array([at.call(20.2, 14.4 - bob), at.call(22.0, 16.2 - bob), at.call(24.5, 17.0 - bob), at.call(27.0, 16.4 - bob), at.call(28.4, 15.0 - bob)])
		ci.draw_polyline(band, OUTLINE, 2.6 * s)
		ci.draw_polyline(band, c, 1.4 * s)
		var tag: Vector2 = at.call(24.5, 18.0 - bob)
		var bell := String(k["base"]) in ["BELL_COLLAR", "STATION_WHISTLE"]
		ci.draw_circle(tag, (1.5 if bell else 1.1) * s, OUTLINE)
		ci.draw_circle(tag, (1.1 if bell else 0.75) * s, Color("f2c14e") if bell else c.lightened(0.45))


## The hat from the gear (none over a cat that already wears one).
static func _draw_gear(ci: CanvasItem, gear: Dictionary, s: float, has_hat: bool) -> void:
	if has_hat or not gear.has("hat"):
		return
	var c: Color = gear["color"]
	var poly := func(points: Array, color: Color) -> void:
		var pts := PackedVector2Array()
		for p: Vector2 in points:
			pts.append(p * s)
		ci.draw_colored_polygon(pts, color)
		ci.draw_polyline(Shapes.closed(pts), OUTLINE, 1.0)
	var oval := func(center: Vector2, rx: float, ry: float, color: Color) -> void:
		var pts := Shapes.ellipse(center * s, rx * s, ry * s, 16)
		ci.draw_colored_polygon(pts, color)
		ci.draw_polyline(Shapes.closed(pts), OUTLINE, 1.0)
	match String(gear["hat"]):
		"PARTY_HAT":
			poly.call([Vector2(6, -14), Vector2(13, -14), Vector2(10, -25)], c)
			ci.draw_line(Vector2(7.5, -17) * s, Vector2(12, -17.5) * s, Color.WHITE, 1.0)
			ci.draw_line(Vector2(8.5, -20.5) * s, Vector2(11, -21) * s, Color.WHITE, 1.0)
			ci.draw_circle(Vector2(10, -25.5) * s, 1.3 * s, Color("f2d14e"))
		"STRAW_HAT":
			oval.call(Vector2(9.5, -14), 9.0, 2.0, c)
			oval.call(Vector2(9.5, -16), 4.5, 2.8, c.lightened(0.1))
			ci.draw_rect(Rect2(Vector2(5.2, -15.2) * s, Vector2(8.6, 1.2) * s), Color("c0504d"))
		"BERET":
			oval.call(Vector2(10.5, -15.5), 6.5, 2.4, c)
			ci.draw_rect(Rect2(Vector2(10.2, -19) * s, Vector2(1.0, 1.6) * s), c.darkened(0.3))
		"PIRATE_HAT":
			poly.call([Vector2(2, -14), Vector2(17, -14), Vector2(15.5, -19.5), Vector2(9.5, -17.5), Vector2(3.5, -19.5)], c)
			ci.draw_circle(Vector2(9.5, -15.8) * s, 1.1 * s, Color("f4f1ea"))
		"WIZARD_HAT":
			oval.call(Vector2(9.5, -14), 7.5, 1.6, c.darkened(0.15))
			poly.call([Vector2(5.5, -14.5), Vector2(13.5, -14.5), Vector2(12.5, -21), Vector2(14.5, -27), Vector2(9, -21)], c)
			ci.draw_circle(Vector2(9.5, -17.5) * s, 1.0 * s, Color("f2d14e"))
		"PAPER_CROWN", "RAT_CROWN":
			poly.call([Vector2(5, -14), Vector2(14, -14), Vector2(14, -19.5), Vector2(12.5, -16.8), Vector2(11, -20), Vector2(9.5, -16.8), Vector2(8, -20), Vector2(6.5, -16.8), Vector2(5, -19.5)], c)
			if gear["hat"] == "RAT_CROWN":
				for x: float in [7.0, 9.5, 12.0]:
					ci.draw_circle(Vector2(x, -15.3) * s, 0.8 * s, Color("d94848"))
		"COUNT_HAT":
			# The count's tall black top hat with a red band.
			oval.call(Vector2(9.5, -14), 7.0, 1.5, c)
			poly.call([Vector2(5.5, -14.5), Vector2(13.5, -14.5), Vector2(13.0, -23), Vector2(6.0, -23)], c)
			ci.draw_rect(Rect2(Vector2(5.6, -16.5) * s, Vector2(7.8, 1.4) * s), Color("b02a2a"))
		"NUTSHELL_HELMET":
			var dome: Array = []
			for i in 9:
				var a := PI + PI * i / 8.0
				dome.append(Vector2(9.5, -14) + Vector2(cos(a) * 6.0, sin(a) * 5.0))
			poly.call(dome, c)
			for x: float in [7.0, 9.5, 12.0]:
				ci.draw_line(Vector2(x, -18.3) * s, Vector2(x, -14.5) * s, c.darkened(0.35), 1.0)
			ci.draw_rect(Rect2(Vector2(9.0, -21) * s, Vector2(1.0, 2.0) * s), c.darkened(0.4))
		_:
			# A knitted hat with a pompom (the wool hat, and any hat not drawn yet).
			var dome: Array = []
			for i in 9:
				var a := PI + PI * i / 8.0
				dome.append(Vector2(9.5, -14.5) + Vector2(cos(a) * 5.5, sin(a) * 4.5))
			poly.call(dome, c)
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
