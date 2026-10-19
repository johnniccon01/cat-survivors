class_name MenuSky
extends Control
## Twinkling stars and now and then a shooting star, drawn over the night
## city on the menu screens.

const STARS := 70
const SKY_HEIGHT := 0.55

var _stars: Array[Vector3] = []
var _t := 0.0
var _shoot_t := 2.0
var _shoot_from := Vector2.ZERO
var _shoot_life := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = 17
	for i in STARS:
		# x, y as a share of the screen; z = phase.
		_stars.append(Vector3(rng.randf(), rng.randf() * SKY_HEIGHT, rng.randf() * TAU))


func _process(delta: float) -> void:
	_t += delta
	_shoot_t -= delta
	if _shoot_t <= 0.0:
		_shoot_t = randf_range(3.5, 7.0)
		_shoot_from = Vector2(randf_range(0.15, 0.8) * size.x, randf_range(0.03, 0.25) * size.y)
		_shoot_life = 1.0
	_shoot_life = maxf(_shoot_life - delta * 1.4, 0.0)
	queue_redraw()


func _draw() -> void:
	for s in _stars:
		var a := 0.5 + 0.5 * sin(_t * (1.2 + s.z * 0.3) + s.z * 5.0)
		if a < 0.55:
			continue
		var p := Vector2(s.x * size.x, s.y * size.y)
		var r := 1.0 + (a - 0.55) * 2.5
		draw_rect(Rect2(p - Vector2(r, r) * 0.5, Vector2(r, r)), Color(1.0, 0.97, 0.85, a * 0.8))
		if a > 0.95:
			draw_line(p - Vector2(4, 0), p + Vector2(4, 0), Color(1, 1, 0.9, 0.5), 1.0)
			draw_line(p - Vector2(0, 4), p + Vector2(0, 4), Color(1, 1, 0.9, 0.5), 1.0)
	if _shoot_life > 0.0:
		var k := 1.0 - _shoot_life
		var head := _shoot_from + Vector2(260, 110) * k
		for i in 8:
			var back := head - Vector2(26, 11) * (i + 1) * 0.6
			draw_line(head - Vector2(26, 11) * i * 0.6, back, Color(1.0, 0.95, 0.8, _shoot_life * (1.0 - i / 8.0)), 2.0)
		draw_circle(head, 2.0, Color(1, 1, 0.95, _shoot_life))
