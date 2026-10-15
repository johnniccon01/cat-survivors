class_name QuestArrow
extends Control
## Points at the active quest: an arrow at the screen edge while it is off
## screen, a bouncing marker above it while it is visible.

const MARGIN := 40.0
const OUTLINE := Color("2b1d14")

## Arrow colour (gold for quests, green for the cat flap).
var color := Color("f2c14e")

## World position of the target, or null for none.
var target: Variant = null

var _t := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	if target == null:
		return
	var screen: Vector2 = get_viewport().get_canvas_transform() * (target as Vector2)
	var rect := get_viewport_rect().grow(-MARGIN)
	if rect.has_point(screen):
		var p := screen + Vector2(0, -70 - absf(sin(_t * 4.0)) * 8.0)
		_triangle(p, Vector2.DOWN, 12.0)
		return
	var center := rect.get_center()
	var dir := (screen - center).normalized()
	# Clamp to the screen edge along the direction to the target.
	var half := rect.size * 0.5
	var k := minf(half.x / maxf(absf(dir.x), 0.001), half.y / maxf(absf(dir.y), 0.001))
	_triangle(center + dir * k, dir, 16.0 + sin(_t * 6.0) * 2.0)


func _triangle(tip: Vector2, dir: Vector2, size: float) -> void:
	var side := dir.orthogonal() * size * 0.6
	var base := tip - dir * size
	var pts := PackedVector2Array([tip, base + side, base - side])
	draw_colored_polygon(pts, color)
	draw_polyline(Shapes.closed(pts), OUTLINE, 2.0)
