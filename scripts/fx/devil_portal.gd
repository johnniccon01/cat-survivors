class_name DevilPortal
extends Node2D
## A burning circle that opens on the floor before the devil cat climbs out.
## Emits `opened` when it is time to spawn the devil, then fades away.

signal opened

const GROW := 1.8
const FADE := 1.0

var _t := 0.0
var _done := false


func _ready() -> void:
	z_index = 5
	Audio.play("devil", 2.0, 0.0)


func _process(delta: float) -> void:
	_t += delta
	if not _done and _t >= GROW:
		_done = true
		opened.emit()
	if _t >= GROW + FADE:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := clampf(_t / GROW, 0.0, 1.0)
	var a := 1.0 - clampf((_t - GROW) / FADE, 0.0, 1.0)
	var r := 6.0 + k * 34.0
	draw_colored_polygon(Shapes.ellipse(Vector2.ZERO, r, r * 0.55, 32), Color(0.1, 0.0, 0.02, 0.85 * a))
	draw_polyline(Shapes.closed(Shapes.ellipse(Vector2.ZERO, r, r * 0.55, 32)), Color(1.0, 0.25, 0.1, a), 2.0)
	# A star scratched into the circle.
	var star := PackedVector2Array()
	for i in 6:
		var p := Vector2.from_angle(-PI * 0.5 + i * TAU * 2.0 / 5.0) * r * 0.85
		star.append(Vector2(p.x, p.y * 0.55))
	draw_polyline(star, Color(1.0, 0.35, 0.1, 0.8 * a), 1.0)
	# Flames licking up around the edge.
	for i in 14:
		var ang := TAU * i / 14.0 + _t * 0.8
		var base := Vector2(cos(ang) * r, sin(ang) * r * 0.55)
		var h := (6.0 + 6.0 * sin(_t * 9.0 + i * 1.7)) * k
		draw_line(base, base + Vector2(0, -h), Color(1.0, 0.45 + 0.3 * sin(i + _t * 5.0), 0.1, a), 2.0)
	for i in 3:
		draw_circle(Vector2.ZERO, r + i * 10.0, Color(1.0, 0.1, 0.05, 0.06 * a))
