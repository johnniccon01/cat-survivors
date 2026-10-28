class_name BloodTrail
extends Node2D
## A long trail of blood drops on the floor (Halls of Torment-like) that
## leads criss-cross over the map from near the cat's start to a secret
## quest (a "trail" secret, see QuestDirector). The drops grow bigger and
## fresher towards the end, so the cat can tell which way to follow. The
## trail winds but never doubles back, and its end is a big pulsing pool
## that can be seen from afar, so the cat doesn't have to walk every drop.
## data (the chain's "secret"): legs, leg [min, max], start [min, max].

const REACH := 110.0
const DROP_EVERY := 22.0
const BLOOD := Color(0.55, 0.05, 0.07)

var end := Vector2.ZERO

## Drops: position, size, alpha (filled in setup, drawn once).
var _drops: PackedVector2Array = []
var _sizes: PackedFloat32Array = []
var _alphas: PackedFloat32Array = []


func setup(origin: Vector2, data: Dictionary) -> void:
	z_index = -4
	var start: Array = data.get("start", [300.0, 450.0])
	var leg: Array = data.get("leg", [380.0, 560.0])
	var p := origin + Vector2.from_angle(randf() * TAU) * randf_range(float(start[0]), float(start[1]))
	var dir := Vector2.from_angle(randf() * TAU)
	var points: Array[Vector2] = [p]
	for i in int(data.get("legs", 12)):
		# Gentle turns both ways: the trail winds but keeps heading away,
		# so it never crosses itself and the way on is always clear.
		dir = dir.rotated(randf_range(0.25, 0.9) * (1.0 if randf() < 0.5 else -1.0))
		p += dir * randf_range(float(leg[0]), float(leg[1]))
		points.append(p)
	end = p
	var total := 0.0
	for i in points.size() - 1:
		total += points[i].distance_to(points[i + 1])
	var walked := 0.0
	for i in points.size() - 1:
		var a := points[i]
		var b := points[i + 1]
		var length := a.distance_to(b)
		var side := (b - a).normalized().orthogonal()
		var d := 0.0
		while d < length:
			var k := (walked + d) / total
			_drops.append(a.lerp(b, d / length) + side * randf_range(-5.0, 5.0))
			_sizes.append(lerpf(1.6, 3.4, k) * randf_range(0.7, 1.2))
			_alphas.append(lerpf(0.35, 0.9, k))
			d += DROP_EVERY * randf_range(0.6, 1.4)
		walked += length
	var marker := _EndMarker.new()
	marker.position = end
	add_child(marker)
	queue_redraw()


## The pulsing glow over the trail's end (redrawn every frame on its own,
## so the many drops are drawn only once).
class _EndMarker extends Node2D:
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var pulse := 0.5 + 0.5 * sin(_t * 3.0)
		draw_circle(Vector2.ZERO, 46.0 + pulse * 14.0, Color(0.9, 0.1, 0.12, 0.10 + pulse * 0.08))
		draw_arc(Vector2.ZERO, 30.0 + pulse * 30.0, 0.0, TAU, 40, Color(1.0, 0.25, 0.2, 0.7 * (1.0 - pulse)), 3.0)
		# A small skull mark over the pool.
		draw_circle(Vector2(0, -26), 7.0, Color(0.95, 0.9, 0.85))
		draw_rect(Rect2(-4, -22, 8, 5), Color(0.95, 0.9, 0.85))
		draw_circle(Vector2(-2.5, -27), 1.8, Color(0.2, 0.05, 0.05))
		draw_circle(Vector2(2.5, -27), 1.8, Color(0.2, 0.05, 0.05))


func reached(pos: Vector2) -> bool:
	return pos.distance_squared_to(end) < REACH * REACH


func _draw() -> void:
	for i in _drops.size():
		var at := _drops[i]
		var r := _sizes[i]
		var color := Color(BLOOD, _alphas[i])
		draw_circle(at, r, color)
		# A small splash next to every other drop.
		if i % 2 == 0:
			draw_circle(at + Vector2(r * 1.3, -r * 0.6), r * 0.45, color)
	# A pool where the trail ends.
	draw_circle(end, 14.0, Color(BLOOD, 0.8))
	draw_circle(end + Vector2(10, 6), 7.0, Color(BLOOD, 0.8))
	draw_circle(end + Vector2(-9, 7), 5.0, Color(BLOOD, 0.75))
