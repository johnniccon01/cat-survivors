class_name HedgeWall
extends Node2D
## A hedge the Lawnmower makes spring up (like the Frost Knight's walls in
## Halls of Torment): first a thin outline where it will grow, then a solid
## wall nobody walks through (Terrain.blockers) for a few seconds, then it
## withers away.

const GROW := 0.7
const THICK := 26.0

var rect: Rect2
var stand := 5.0

var _t := 0.0
var _solid := false


## A hedge `length` long, centred on `at`, facing `normal` (it runs across it).
static func plant(parent: Node, at: Vector2, normal: Vector2, length: float, seconds: float) -> HedgeWall:
	var hedge := HedgeWall.new()
	var along := normal.orthogonal().abs()
	# Hedges are kept straight along the grid, so they are simple boxes.
	var horizontal := along.x >= along.y
	var size := Vector2(length, THICK) if horizontal else Vector2(THICK, length)
	hedge.rect = Rect2(at - size * 0.5, size)
	hedge.stand = seconds
	parent.add_child(hedge)
	return hedge


func _init() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_index = -1


func _process(delta: float) -> void:
	_t += delta
	if not _solid and _t >= GROW and _t < GROW + stand:
		_solid = true
		Terrain.blockers.append(rect)
		if Terrain.fix(rect.get_center(), 10.0) == rect.get_center():
			BotLog.fail("a hedge does not block the way")
		BotLog.event("hedge_solid")
	elif _solid and _t >= GROW + stand:
		_solid = false
		Terrain.blockers.erase(rect)
	if _t >= GROW + stand + 0.5:
		queue_free()
	queue_redraw()


func _exit_tree() -> void:
	if _solid:
		Terrain.blockers.erase(rect)


func _draw() -> void:
	if _t < GROW:
		# Where it will grow: a blinking outline.
		draw_rect(rect, Color(0.4, 0.9, 0.35, 0.25 + 0.25 * sin(_t * 20.0)), false, 2.0)
		return
	var k := clampf((GROW + stand + 0.5 - _t) / 0.5, 0.0, 1.0)
	draw_rect(rect.grow(2.0), Color(0.1, 0.25, 0.1, k))
	draw_rect(rect, Color(0.25, 0.5, 0.2, k))
	# Leafy bumps along it.
	var long_side := maxf(rect.size.x, rect.size.y)
	var horizontal := rect.size.x >= rect.size.y
	for i in int(long_side / 18.0):
		var p := rect.position + (Vector2(9.0 + i * 18.0, THICK * 0.5) if horizontal else Vector2(THICK * 0.5, 9.0 + i * 18.0))
		draw_circle(p, 9.0, Color(0.32, 0.6, 0.26, k))
