class_name SignIcon
extends Control
## One sign from the neighbourhood map (an offer's round sign, the full
## moon, a boss flag, a kidnapped resident) drawn exactly as on the map, for
## the legend, the help and the place panel (DistrictMap.draw_sign).

var kind := ""
var radius := 10.0


func _init(p_kind: String = "", p_radius: float = 10.0) -> void:
	kind = p_kind
	radius = p_radius
	custom_minimum_size = Vector2.ONE * (radius * 2.0 + 6.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_kind(p_kind: String) -> void:
	kind = p_kind
	queue_redraw()


func _draw() -> void:
	if kind != "":
		DistrictMap.draw_sign(self, size * 0.5, kind, radius)
