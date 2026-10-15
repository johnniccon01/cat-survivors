class_name IconView
extends Control
## A Control that shows one weapon or passive icon (used on level-up cards).

var kind := "weapon"
var id := ""


func _init(p_kind: String = "weapon", p_id: String = "", side: float = 40.0) -> void:
	kind = p_kind
	id = p_id
	custom_minimum_size = Vector2(side, side)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var side := minf(size.x, size.y)
	Icons.draw(self, kind, id, Rect2((size - Vector2(side, side)) * 0.5, Vector2(side, side)))
