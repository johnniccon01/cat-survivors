class_name PawRating
extends Control
## A rating of 1 to 3 as paws: a red filled paw is done, an outline is not yet.
## Used on the map's place signs and in the place panel.

var count := 0
var total := 3
var paw := 14.0
var gap := 3.0
var empty_color := Color(BoxStyle.INK, 0.5)


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_rating(n: int, total_: int = 3, paw_: float = 14.0) -> void:
	count = n
	total = total_
	paw = paw_
	custom_minimum_size = Vector2(total * paw + (total - 1) * gap, paw * 1.2)
	queue_redraw()


func _draw() -> void:
	var w := total * paw + (total - 1) * gap
	var x0 := (size.x - w) * 0.5
	for i in total:
		var mid := Vector2(x0 + paw * 0.5 + i * (paw + gap), size.y * 0.5)
		if i < count:
			BoxStyle.draw_paw(self, mid, paw, BoxStyle.RED, -10.0)
		else:
			BoxStyle.draw_paw_outline(self, mid, paw, empty_color, -10.0)
