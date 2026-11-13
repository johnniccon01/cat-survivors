class_name PaperCard
extends StyleBox
## A small paper note for list rows and tiles: a torn light-kraft piece with a
## hard shadow, ink text on top; the chosen one gets a red marker rectangle.
## Drawn only when its control redraws (the engine caches it otherwise).

var selected := false
var fill_top := Color("eddcb4")
var fill_bottom := Color("e0c99a")
var seed_v := 1
var lit_ring := Color("d3261f")

static var _n := 0


static func make(selected_: bool = false, fill_: Color = Color(0, 0, 0, 0)) -> PaperCard:
	var c := PaperCard.new()
	c.selected = selected_
	_n += 1
	c.seed_v = _n * 17 + 3
	if selected_:
		c.fill_top = Color("faf0d2")
		c.fill_bottom = Color("f1e2bb")
	if fill_.a > 0.0:
		c.fill_top = fill_
		c.fill_bottom = fill_.darkened(0.07)
	c.content_margin_left = 12
	c.content_margin_right = 12
	c.content_margin_top = 8
	c.content_margin_bottom = 8
	return c


## The ink colour that reads on this paper.
static func ink() -> Color:
	return BoxStyle.INK


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	var rs := RenderingServer
	rs.canvas_item_add_set_transform(to_canvas_item, Transform2D(0.0, rect.position))
	var size := rect.size
	var poly := BoxStyle.torn(size, seed_v + int(size.x) % 7, 2.5)
	var sp := PackedVector2Array()
	for p in poly:
		sp.append(p + Vector2(2.5, 3.5))
	rs.canvas_item_add_polygon(to_canvas_item, sp, PackedColorArray([Color(0, 0, 0, 0.4)]))
	var cols := PackedColorArray()
	for p in poly:
		cols.append(fill_top.lerp(fill_bottom, clampf(p.y / maxf(size.y, 1.0), 0.0, 1.0)))
	rs.canvas_item_add_polygon(to_canvas_item, poly, cols)
	var edge := poly.duplicate()
	edge.append(poly[0])
	rs.canvas_item_add_polyline(to_canvas_item, edge, PackedColorArray([fill_bottom.darkened(0.3)]), 1.6, true)
	if selected:
		var ring := BoxStyle.torn(size + Vector2(6, 6), seed_v + 5, 1.5)
		for i in ring.size():
			ring[i] -= Vector2(3, 3)
		ring.append(ring[0])
		rs.canvas_item_add_polyline(to_canvas_item, ring, PackedColorArray([lit_ring]), 3.5, true)
	rs.canvas_item_add_set_transform(to_canvas_item, Transform2D.IDENTITY)

