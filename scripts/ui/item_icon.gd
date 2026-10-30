class_name ItemIcon
extends Control
## A small picture of a piece of gear: its slot's shape in the item's own
## colour (collar, hat, vest, paws, tail), with a rarity rim.

const OUTLINE := Color("2b1d14")

var slot := ""
var color := Color.WHITE
var rim := Color(0, 0, 0, 0)


func _init(p_size: float = 26.0) -> void:
	custom_minimum_size = Vector2(p_size, p_size)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_item(item: Dictionary, p_slot: String = "") -> void:
	slot = String(item.get("slot", p_slot)) if not item.is_empty() else p_slot
	color = Items.color(item) if not item.is_empty() else Color(0.4, 0.35, 0.45)
	rim = Items.rarity_color(item) if not item.is_empty() else Color(0, 0, 0, 0)
	queue_redraw()


func _draw() -> void:
	var s := size.x / 26.0
	var c := size * 0.5
	if rim.a > 0.0:
		draw_circle(c, 12.5 * s, Color(rim, 0.25))
		draw_arc(c, 12.5 * s, 0, TAU, 24, rim, 1.5)
	var fill := func(points: Array) -> void:
		var pts := PackedVector2Array()
		for p: Vector2 in points:
			pts.append(c + p * s)
		draw_colored_polygon(pts, color)
		draw_polyline(Shapes.closed(pts), OUTLINE, 1.2)
	match slot:
		"COLLAR":
			draw_arc(c + Vector2(0, -2) * s, 7.0 * s, 0.15 * PI, 0.85 * PI, 12, OUTLINE, 4.5 * s)
			draw_arc(c + Vector2(0, -2) * s, 7.0 * s, 0.15 * PI, 0.85 * PI, 12, color, 2.5 * s)
			draw_circle(c + Vector2(0, 6) * s, 2.6 * s, OUTLINE)
			draw_circle(c + Vector2(0, 6) * s, 1.8 * s, Color("f2c14e"))
		"HAT":
			fill.call([Vector2(-6, 4), Vector2(6, 4), Vector2(0, -8)])
			fill.call([Vector2(-9, 4), Vector2(9, 4), Vector2(9, 6.5), Vector2(-9, 6.5)])
		"VEST":
			fill.call([Vector2(-8, -6), Vector2(-3, -8), Vector2(0, -4), Vector2(3, -8), Vector2(8, -6), Vector2(7, 8), Vector2(-7, 8)])
			draw_line(c + Vector2(0, -4) * s, c + Vector2(0, 8) * s, color.darkened(0.35), 1.0)
		"PAWS":
			var pad := Shapes.ellipse(c + Vector2(0, 3) * s, 5.0 * s, 4.0 * s, 12)
			draw_colored_polygon(pad, color)
			draw_polyline(Shapes.closed(pad), OUTLINE, 1.2)
			for toe: Vector2 in [Vector2(-6, -3), Vector2(-2, -6.5), Vector2(2, -6.5), Vector2(6, -3)]:
				draw_circle(c + toe * s, 2.4 * s, OUTLINE)
				draw_circle(c + toe * s, 1.7 * s, color)
		"TAIL":
			var curve := PackedVector2Array()
			for i in 9:
				var k := float(i) / 8.0
				curve.append(c + Vector2(-6 + k * 10.0, 7 - sin(k * PI * 0.9) * 13.0) * s)
			draw_polyline(curve, OUTLINE, 4.0 * s)
			draw_polyline(curve, Color("d9a066"), 2.4 * s)
			fill.call([Vector2(2, -3), Vector2(-1, -6), Vector2(-1, 0)])
			fill.call([Vector2(2, -3), Vector2(5, -6), Vector2(5, 0)])
