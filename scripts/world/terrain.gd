class_name Terrain
extends Node2D
## Obstacles a map can have (stage "terrain"): nobody walks through them,
## shots fly over. Kinds:
## - "trees": bushes and trees scattered over the endless lawn.
## - "walls": brick walls in a grid of rooms, each wall with a gap to walk
##   through (Rooftop: parapets between the roofs).
## - "aisles": tall shelves above and below, only a corridor to the left and
##   right is free.
## - "tide": every now and then the sea comes in from above and below and
##   squeezes everyone into a strip of dry land, then goes out again.
## - "belts": conveyor belts across the hall push everyone sideways and
##   switch direction every now and then (Factory).
## Everything that moves or gets placed asks fix() for the nearest free spot.

const TREE_CELL := 250.0
const TREE_CHANCE := 0.5
## No tree this close to where the night starts.
const TREE_CLEAR := 240.0
const AISLE_HALF := 105.0
const BELT_EVERY := 300.0
const BELT_WIDTH := 72.0
const BELT_SPEED := 85.0
const BELT_SWITCH := 25.0
const WALL_CELL := 300.0
const WALL_CHANCE := 0.65
const WALL_THICK := 22.0
## The gap in a wall (share of its length), so every room stays open.
const WALL_GAP := [0.36, 0.64]
## Tide: calm for a while, then a warning, the water rises, stays, goes out.
const TIDE_FIRST := 60.0
const TIDE_CALM := 45.0
const TIDE_WARN := 6.0
const TIDE_RISE := 6.0
const TIDE_HOLD := 18.0
const TIDE_FALL := 7.0
const TIDE_FAR := 900.0
const TIDE_HALF := 115.0

## The terrain of the running night (null on open maps).
static var current: Terrain

var kind := ""
var main: Node
var _trees := {}
var _walls := {}
var _seed := 0
var _t := 0.0
## Tide: "calm", "warn", "rise", "hold", "fall"; the strip around _center_y
## that stays dry is _half tall each way.
var _phase := "calm"
var _phase_t := TIDE_FIRST
var _half := INF
var _center_y := 0.0
## Belts: +1 or -1, flips every BELT_SWITCH seconds.
var _belt_dir := 1.0
var _belt_t := BELT_SWITCH
var _belt_shift := 0.0


func _ready() -> void:
	current = self
	z_index = -5
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_seed = randi()


func _exit_tree() -> void:
	if current == self:
		current = null


## The nearest spot to `pos` where something `r` big fits.
static func fix(pos: Vector2, r: float = 12.0) -> Vector2:
	return current.resolve(pos, r) if current != null else pos


## A spot for a new enemy around `around`: in a corridor it walks in from
## the left or right instead of out of the shelves.
static func fix_spawn(pos: Vector2, around: Vector2, r: float = 12.0) -> Vector2:
	if current == null:
		return pos
	if current._half < INF:
		var half := current._half - r
		if absf(pos.y - current._center_y) > half:
			var dist := pos.distance_to(around)
			var y := clampf(pos.y, current._center_y - half, current._center_y + half)
			var dy := y - around.y
			var side := signf(pos.x - around.x) if pos.x != around.x else (1.0 if randf() < 0.5 else -1.0)
			return Vector2(around.x + side * sqrt(maxf(dist * dist - dy * dy, 0.0)), y)
	return current.resolve(pos, r)


func resolve(pos: Vector2, r: float) -> Vector2:
	if _half < INF:
		var half := maxf(_half - r, 0.0)
		pos.y = clampf(pos.y, _center_y - half, _center_y + half)
	if kind == "walls":
		var wc := Vector2i(floori(pos.x / WALL_CELL), floori(pos.y / WALL_CELL))
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				for rect: Rect2 in _wall_rects(Vector2i(wc.x + dx, wc.y + dy)):
					pos = _push_out_of(rect, pos, r)
	if kind == "trees":
		var c := Vector2i(floori(pos.x / TREE_CELL), floori(pos.y / TREE_CELL))
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				var tree := _tree(Vector2i(c.x + dx, c.y + dy))
				if tree.is_empty():
					continue
				var at: Vector2 = tree["at"]
				var reach: float = tree["r"] + r
				var off := pos - at
				if off.length_squared() < reach * reach:
					pos = at + (off.normalized() if off != Vector2.ZERO else Vector2.RIGHT) * reach
	return pos


## How fast the ground under `pos` carries things (conveyor belts).
static func flow(pos: Vector2) -> Vector2:
	if current == null or current.kind != "belts":
		return Vector2.ZERO
	var row := floori(pos.y / BELT_EVERY)
	var inside := pos.y - row * BELT_EVERY
	if inside > BELT_WIDTH or absf(pos.y) < BELT_EVERY * 0.5:
		return Vector2.ZERO
	# Neighbouring belts run opposite ways.
	return Vector2(current._belt_dir * (1.0 if posmod(row, 2) == 0 else -1.0) * BELT_SPEED, 0.0)


## True when `pos` is inside an obstacle.
func blocked(pos: Vector2, r: float = 0.0) -> bool:
	return resolve(pos, r).distance_squared_to(pos) > 0.01


## The tree in a cell (empty when the cell has none), the same every time.
func _tree(c: Vector2i) -> Dictionary:
	if _trees.has(c):
		return _trees[c]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([c.x, c.y, _seed])
	var tree := {}
	if rng.randf() < TREE_CHANCE:
		var r := rng.randf_range(24.0, 52.0)
		var at := Vector2((c.x + rng.randf_range(0.2, 0.8)) * TREE_CELL, (c.y + rng.randf_range(0.2, 0.8)) * TREE_CELL)
		if at.length() > TREE_CLEAR + r:
			tree = {"at": at, "r": r, "bush": rng.randf() < 0.35, "tint": rng.randf()}
	_trees[c] = tree
	if _trees.size() > 4000:
		_trees.clear()
	return tree


func setup(p_kind: String, p_main: Node) -> void:
	kind = p_kind
	main = p_main
	if kind == "aisles":
		_half = AISLE_HALF


func _process(delta: float) -> void:
	_t += delta
	if kind == "tide":
		_tick_tide(delta)
	elif kind == "belts":
		_belt_t -= delta
		_belt_shift += _belt_dir * BELT_SPEED * delta
		if _belt_t <= 0.0:
			_belt_t = BELT_SWITCH
			_belt_dir = -_belt_dir
			if main != null and main.get("hud") != null:
				main.hud.show_banner(tr("BELTS_SWITCH"), 2.0)
	queue_redraw()


func _tick_tide(delta: float) -> void:
	_phase_t -= delta
	match _phase:
		"rise":
			_half = lerpf(TIDE_FAR, TIDE_HALF, clampf(1.0 - _phase_t / TIDE_RISE, 0.0, 1.0))
		"fall":
			_half = lerpf(TIDE_HALF, TIDE_FAR, clampf(1.0 - _phase_t / TIDE_FALL, 0.0, 1.0))
	if _phase_t > 0.0:
		return
	match _phase:
		"calm":
			_phase = "warn"
			_phase_t = TIDE_WARN
			if main != null and main.get("hud") != null:
				main.hud.show_banner(tr("TIDE_WARNING"), 4.0)
		"warn":
			_phase = "rise"
			_phase_t = TIDE_RISE
			# The dry strip forms around the cat, so nobody gets drowned.
			if main != null and main.get("player") != null:
				_center_y = main.player.position.y
			_half = TIDE_FAR
		"rise":
			_phase = "hold"
			_phase_t = TIDE_HOLD
			_half = TIDE_HALF
		"hold":
			_phase = "fall"
			_phase_t = TIDE_FALL
		"fall":
			_phase = "calm"
			_phase_t = TIDE_CALM
			_half = INF


## The tide's state for tests and the HUD: "calm", "warn", "rise", "hold", "fall".
func tide_phase() -> String:
	return _phase


func _view() -> Rect2:
	var inv := get_viewport().get_canvas_transform().affine_inverse()
	var rect := get_viewport_rect()
	return Rect2(inv * rect.position, inv.basis_xform(rect.size)).abs().grow(80.0)


func _draw() -> void:
	var view := _view()
	match kind:
		"trees":
			_draw_trees(view)
		"walls":
			_draw_walls(view)
		"belts":
			_draw_belts(view)
		"aisles":
			_draw_aisles(view)
		"tide":
			_draw_tide(view)


func _draw_trees(view: Rect2) -> void:
	var c0 := Vector2i(floori(view.position.x / TREE_CELL) - 1, floori(view.position.y / TREE_CELL) - 1)
	var c1 := Vector2i(floori(view.end.x / TREE_CELL) + 1, floori(view.end.y / TREE_CELL) + 1)
	for cx in range(c0.x, c1.x + 1):
		for cy in range(c0.y, c1.y + 1):
			var tree := _tree(Vector2i(cx, cy))
			if tree.is_empty():
				continue
			var at: Vector2 = tree["at"]
			var r: float = tree["r"]
			var tint: float = tree["tint"]
			draw_circle(at + Vector2(6, 10), r * 1.08, Color(0, 0, 0, 0.25))
			if tree["bush"]:
				var leaf := Color("4f8a3a").lerp(Color("6b9a2f"), tint)
				for i in 5:
					var a := TAU * i / 5.0 + tint * 3.0
					draw_circle(at + Vector2.from_angle(a) * r * 0.45, r * 0.62, leaf.darkened(0.25))
				draw_circle(at, r * 0.8, leaf)
				for i in 3:
					draw_circle(at + Vector2.from_angle(TAU * i / 3.0 + 1.0) * r * 0.4, 3.5, Color("e85a7a") if tint > 0.5 else Color("f2e15c"))
			else:
				var leaf := Color("2f6b34").lerp(Color("3f7d2c"), tint)
				draw_circle(at, r * 1.12, Color("1d3f22"))
				draw_circle(at, r, leaf)
				draw_circle(at + Vector2(-r * 0.25, -r * 0.3), r * 0.55, leaf.lightened(0.15))
				draw_circle(at + Vector2(-r * 0.35, -r * 0.4), r * 0.22, leaf.lightened(0.3))


func _draw_aisles(view: Rect2) -> void:
	var top := _center_y - _half
	var bottom := _center_y + _half
	for side in [-1, 1]:
		var edge: float = top if side < 0 else bottom
		var far: float = view.position.y if side < 0 else view.end.y
		if (side < 0 and far > edge) or (side > 0 and far < edge):
			continue
		var y0 := minf(edge, far)
		var y1 := maxf(edge, far)
		draw_rect(Rect2(view.position.x, y0, view.size.x, y1 - y0), Color("6d7480"))
		# Shelf rows with goods, 64 px apart, the same wherever you look.
		var row := 64.0
		var r0 := floori(y0 / row)
		var r1 := floori(y1 / row)
		var x0 := floori(view.position.x / 40.0)
		var x1 := floori(view.end.x / 40.0)
		for ry in range(r0, r1 + 1):
			var ys := ry * row
			draw_rect(Rect2(view.position.x, ys + 50.0, view.size.x, 8.0), Color("4a505a"))
			for bx in range(x0, x1 + 1):
				var h := absi((bx * 92821) ^ (ry * 68917) ^ _seed)
				if h % 7 == 0:
					continue
				var hue := float(h % 360) / 360.0
				var tall := 22.0 + float((h >> 8) % 20)
				draw_rect(Rect2(bx * 40.0 + 4.0, ys + 50.0 - tall, 32.0, tall), Color.from_hsv(hue, 0.55, 0.85))
				draw_rect(Rect2(bx * 40.0 + 8.0, ys + 50.0 - tall + 5.0, 24.0, 6.0), Color(1, 1, 1, 0.55))
		# The shelf's front edge.
		draw_rect(Rect2(view.position.x, edge - (10.0 if side > 0 else 0.0), view.size.x, 10.0), Color("2b2f36"))
		draw_rect(Rect2(view.position.x, edge + (0.0 if side > 0 else -14.0), view.size.x, 14.0), Color(0, 0, 0, 0.18))


func _draw_tide(view: Rect2) -> void:
	if _phase == "warn":
		# Wet sand marks where the water will come.
		var a := 0.25 + 0.15 * sin(_t * 6.0)
		for side in [-1, 1]:
			var y: float = (main.player.position.y if main != null else _center_y) + side * TIDE_HALF
			draw_line(Vector2(view.position.x, y), Vector2(view.end.x, y), Color(0.6, 0.85, 1.0, a), 6.0)
	if _half >= INF:
		return
	for side in [-1, 1]:
		var edge: float = _center_y + side * _half
		var far: float = view.end.y if side > 0 else view.position.y
		if (side < 0 and far > edge) or (side > 0 and far < edge):
			continue
		var y0 := minf(edge, far)
		var y1 := maxf(edge, far)
		draw_rect(Rect2(view.position.x, y0, view.size.x, y1 - y0), Color(0.16, 0.42, 0.66, 0.88))
		# Foam along the shore and a few waves.
		var pts := PackedVector2Array()
		var step := 24.0
		var x := floorf(view.position.x / step) * step
		while x <= view.end.x + step:
			pts.append(Vector2(x, edge + sin(x * 0.03 + _t * 2.5) * 5.0))
			x += step
		draw_polyline(pts, Color(0.92, 0.97, 1.0, 0.85), 7.0)
		for i in 6:
			var wy: float = edge + side * (40.0 + i * 70.0)
			if wy < view.position.y or wy > view.end.y:
				continue
			var wx := fposmod(_t * 30.0 * (1 if i % 2 == 0 else -1) + i * 137.0, 200.0)
			var px := floorf(view.position.x / 200.0) * 200.0 + wx
			while px < view.end.x:
				draw_arc(Vector2(px, wy), 14.0, PI * 1.1, PI * 1.9, 6, Color(0.8, 0.92, 1.0, 0.45), 3.0)
				px += 200.0


## The wall pieces on a cell's top and left edges (each wall in two pieces
## with a gap between them), the same every time.
func _wall_rects(c: Vector2i) -> Array:
	if _walls.has(c):
		return _walls[c]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([c.x, c.y, _seed, "walls"])
	var rects: Array = []
	var o := Vector2(c) * WALL_CELL
	# Nothing right around where the night starts.
	var near_start := o.length() < WALL_CELL * 1.2 or (o + Vector2(WALL_CELL, WALL_CELL) * 0.5).length() < WALL_CELL
	if not near_start:
		var a: float = WALL_GAP[0] + rng.randf_range(-0.2, 0.2)
		var b: float = a + (WALL_GAP[1] - WALL_GAP[0])
		if rng.randf() < WALL_CHANCE:
			rects.append(Rect2(o.x, o.y - WALL_THICK * 0.5, WALL_CELL * a, WALL_THICK))
			rects.append(Rect2(o.x + WALL_CELL * b, o.y - WALL_THICK * 0.5, WALL_CELL * (1.0 - b) + WALL_THICK * 0.5, WALL_THICK))
		a = WALL_GAP[0] + rng.randf_range(-0.2, 0.2)
		b = a + (WALL_GAP[1] - WALL_GAP[0])
		if rng.randf() < WALL_CHANCE:
			rects.append(Rect2(o.x - WALL_THICK * 0.5, o.y, WALL_THICK, WALL_CELL * a))
			rects.append(Rect2(o.x - WALL_THICK * 0.5, o.y + WALL_CELL * b, WALL_THICK, WALL_CELL * (1.0 - b)))
	_walls[c] = rects
	if _walls.size() > 4000:
		_walls.clear()
	return rects


## `pos` moved just outside `rect` if something `r` big would overlap it.
func _push_out_of(rect: Rect2, pos: Vector2, r: float) -> Vector2:
	var closest := Vector2(clampf(pos.x, rect.position.x, rect.end.x), clampf(pos.y, rect.position.y, rect.end.y))
	var off := pos - closest
	if off != Vector2.ZERO:
		var d := off.length()
		return pos if d >= r else closest + off / d * r
	# The centre is inside: out through the nearest side.
	var left := pos.x - rect.position.x
	var right := rect.end.x - pos.x
	var up := pos.y - rect.position.y
	var down := rect.end.y - pos.y
	var m := minf(minf(left, right), minf(up, down))
	if m == left:
		return Vector2(rect.position.x - r, pos.y)
	if m == right:
		return Vector2(rect.end.x + r, pos.y)
	if m == up:
		return Vector2(pos.x, rect.position.y - r)
	return Vector2(pos.x, rect.end.y + r)


func _draw_walls(view: Rect2) -> void:
	var c0 := Vector2i(floori(view.position.x / WALL_CELL) - 1, floori(view.position.y / WALL_CELL) - 1)
	var c1 := Vector2i(floori(view.end.x / WALL_CELL) + 1, floori(view.end.y / WALL_CELL) + 1)
	var brick := Color("b3aa9c")
	for cx in range(c0.x, c1.x + 1):
		for cy in range(c0.y, c1.y + 1):
			for rect: Rect2 in _wall_rects(Vector2i(cx, cy)):
				if not rect.intersects(view):
					continue
				draw_rect(Rect2(rect.position + Vector2(5, 8), rect.size), Color(0, 0, 0, 0.3))
				draw_rect(rect, brick)
				# Brick rows and a lighter top.
				var horizontal := rect.size.x > rect.size.y
				var length := rect.size.x if horizontal else rect.size.y
				var n := int(length / 18.0)
				for i in range(1, n + 1):
					var t := i * 18.0
					if horizontal:
						draw_line(rect.position + Vector2(t, 0), rect.position + Vector2(t, rect.size.y), brick.darkened(0.25), 1.5)
					else:
						draw_line(rect.position + Vector2(0, t), rect.position + Vector2(rect.size.x, t), brick.darkened(0.25), 1.5)
				if horizontal:
					draw_line(rect.position + Vector2(0, rect.size.y * 0.5), rect.position + Vector2(rect.size.x, rect.size.y * 0.5), brick.darkened(0.25), 1.5)
				else:
					draw_line(rect.position + Vector2(rect.size.x * 0.5, 0), rect.position + Vector2(rect.size.x * 0.5, rect.size.y), brick.darkened(0.25), 1.5)
				draw_rect(rect, Color("2b2520"), false, 3.0)


func _draw_belts(view: Rect2) -> void:
	var r0 := floori(view.position.y / BELT_EVERY)
	var r1 := floori(view.end.y / BELT_EVERY)
	for row in range(r0, r1 + 1):
		var y := row * BELT_EVERY
		if absf(y + BELT_WIDTH * 0.5) < BELT_EVERY * 0.5:
			continue
		var dir := _belt_dir * (1.0 if posmod(row, 2) == 0 else -1.0)
		draw_rect(Rect2(view.position.x, y, view.size.x, BELT_WIDTH), Color("3a3d44"))
		draw_rect(Rect2(view.position.x, y, view.size.x, 6.0), Color("e0b53a"))
		draw_rect(Rect2(view.position.x, y + BELT_WIDTH - 6.0, view.size.x, 6.0), Color("e0b53a"))
		# Chevrons moving the way the belt runs.
		var shift := fposmod(_belt_shift * (1.0 if posmod(row, 2) == 0 else -1.0), 48.0)
		var x := floorf(view.position.x / 48.0) * 48.0 + shift - 48.0
		while x < view.end.x + 48.0:
			var tip := x + dir * 10.0
			var mid := y + BELT_WIDTH * 0.5
			draw_polyline(PackedVector2Array([Vector2(x - dir * 6.0, mid - 14.0), Vector2(tip, mid), Vector2(x - dir * 6.0, mid + 14.0)]), Color(0.75, 0.78, 0.82, 0.55), 5.0)
			x += 48.0
