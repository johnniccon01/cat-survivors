extends SceneTree
## A big picture of cats wearing every kind of gear, to check by eye that
## hats, collars, vests, paws and tail ornaments sit right on the sprites
## (needs a window, not --headless):
##   godot --path . -s res://tools/gear_shot.gd
## Saves user://gear_shot.png. The drawing is in gear_shot_canvas.gd: a -s
## script is compiled before the autoloads exist, so it loads that later.

var _frames := 0


func _initialize() -> void:
	root.size = Vector2i(1100, 760)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 2:
		root.add_child(load("res://tools/gear_shot_canvas.gd").new())
	if _frames == 12:
		root.get_texture().get_image().save_png("user://gear_shot.png")
		return true
	return false
