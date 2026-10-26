class_name LegendaryBurst
extends Node2D
## A legendary was found: a golden flash round the cat, rings rolling out,
## turning rays and stars shooting up, while the fanfare plays.

const DURATION := 2.6
const GOLD := Color("f2c14e")

var color := GOLD

var _t := 0.0
var _stars: Array = []


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 5


func _ready() -> void:
	for i in 18:
		_stars.append({"dir": Vector2.from_angle(TAU * i / 18.0 + randf() * 0.3), "speed": randf_range(70.0, 150.0), "size": randf_range(1.5, 3.0)})


func _process(delta: float) -> void:
	_t += delta
	if _t >= DURATION:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var fade := clampf((DURATION - _t) / 0.8, 0.0, 1.0)
	if _t < 0.25:
		Blit.disc(self, Vector2.ZERO, 60.0 * _t / 0.25, Color(1, 1, 0.9, 0.6 * (1.0 - _t / 0.25)))
	for i in 3:
		var k := clampf((_t - i * 0.25) / 1.0, 0.0, 1.0)
		if k > 0.0 and k < 1.0:
			Blit.ring(self, Vector2.ZERO, 12.0 + 140.0 * k, 3.0, Color(color, 0.8 * (1.0 - k)))
	for i in 12:
		var a := _t * 0.8 + TAU * i / 12.0
		var tip := Vector2.from_angle(a) * (70.0 + 10.0 * sin(_t * 6.0 + i))
		draw_colored_polygon(PackedVector2Array([Vector2.ZERO, tip.rotated(0.07), tip.rotated(-0.07)]), Color(color, 0.25 * fade))
	Blit.disc(self, Vector2.ZERO, 22.0, Color(1, 1, 0.85, 0.25 * fade))
	for star: Dictionary in _stars:
		var at: Vector2 = star["dir"] * star["speed"] * _t + Vector2(0, -30.0 * _t * _t)
		var s: float = star["size"]
		var c := Color(1, 1, 0.8, fade)
		draw_line(at + Vector2(-s * 2.0, 0), at + Vector2(s * 2.0, 0), c, 1.0)
		draw_line(at + Vector2(0, -s * 2.0), at + Vector2(0, s * 2.0), c, 1.0)
		Blit.disc(self, at, s * 0.6, c)
