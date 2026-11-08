class_name ShopIcon
extends Control
## The icon of an upgrade-shop power-up: the matching passive's icon, or a
## pixel glyph on a passive-style tile for the ones without one.

var id := ""


func _init(p_id: String = "", side: float = 44.0) -> void:
	id = p_id
	custom_minimum_size = Vector2(side, side)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var side := minf(size.x, size.y)
	var r := Rect2((size - Vector2(side, side)) * 0.5, Vector2(side, side))
	if ShopPanel.PASSIVE_ICON.has(id):
		Icons.draw(self, "passive", ShopPanel.PASSIVE_ICON[id], r)
	elif PixelGlyph.SHOP_TILES.has(id):
		PixelGlyph.draw_tile(self, PixelGlyph.SHOP_TILES[id], r)
