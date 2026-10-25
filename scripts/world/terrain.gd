class_name Terrain
extends Node2D
## Obstacles a map can have (stage "terrain"): nobody walks through them,
## shots fly over. Kinds:
## - "trees": bushes and trees scattered over the endless lawn.
## - "aisles": tall shelves above and below, only a corridor to the left and
##   right is free.
## - "tide": every now and then the sea comes in from above and below and
##   squeezes everyone into a strip of dry land, then goes out again.
## Everything that moves or gets placed asks fix() for the nearest free spot.

const TREE_CELL := 250.0
const TREE_CHANCE := 0.5
## No tree this close to where the night starts.
const TREE_CLEAR := 240.0
const AISLE_HALF := 105.0
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
var _seed := 0
var _t := 0.0
## Tide: "calm", "warn", "rise", "hold", "fall"; the strip around _center_y
## that stays dry is _half tall each way.
var _phase := "calm"
var _phase_t := TIDE_FIRST
var _half := INF
var _center_y := 0.0


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
