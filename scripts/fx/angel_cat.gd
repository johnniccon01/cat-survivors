class_name AngelCat
extends Node2D
## The angel cat's visit: floats down onto the fallen cat in a beam of light,
## hovers while the cat gets back up, then rises and fades away. Purely
## visual; main.gd does the actual revive.

const DESCEND := 0.9
const HOVER := 1.4
const RISE := 1.2

var _t := 0.0


func _ready() -> void:
	z_index = 20


func _process(delta: float) -> void:
	_t += delta
	if _t >= DESCEND + HOVER + RISE:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var y := -34.0
	var alpha := 1.0
	if _t < DESCEND:
		var k := _t / DESCEND
		y = lerpf(-140.0, -34.0, 1.0 - (1.0 - k) * (1.0 - k))
		alpha = k
	elif _t > DESCEND + HOVER:
		var k := (_t - DESCEND - HOVER) / RISE
		y = lerpf(-34.0, -180.0, k * k)
		alpha = 1.0 - k
	y += sin(_t * 4.0) * 2.0
	# Beam of light from above onto the cat.
	var beam := Color(1.0, 0.95, 0.7, 0.18 * alpha)
	draw_colored_polygon(PackedVector2Array([Vector2(-10, -260), Vector2(10, -260), Vector2(26, 10), Vector2(-26, 10)]), beam)
	for i in 4:
		draw_circle(Vector2(0, y), 14.0 + i * 8.0, Color(1.0, 0.95, 0.75, 0.08 * alpha))
	# Sparkles.
	for i in 8:
		var a := _t * 1.5 + TAU * i / 8.0
		var p := Vector2(0, y) + Vector2.from_angle(a) * (22.0 + sin(_t * 3.0 + i) * 4.0)
		draw_rect(Rect2(p - Vector2(1, 1), Vector2(2, 2)), Color(1.0, 0.97, 0.8, alpha))
	CatArt.draw(self, CatArt.look("ANGEL"), 1, _t * 6.0, false, false, "normal", Vector2(0, y), 1.0, false)
	if alpha < 1.0:
		# Fade the cat by washing it out with the glow colour.
		draw_circle(Vector2(0, y), 18.0, Color(1.0, 0.97, 0.85, (1.0 - alpha) * 0.9))
