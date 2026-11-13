class_name HudIcon
extends Control
## The heart next to the health bar, drawn once.


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(26, 26)
	size = Vector2(26, 26)


func _draw() -> void:
	BoxStyle.draw_heart(self, size * 0.5, 26.0)
