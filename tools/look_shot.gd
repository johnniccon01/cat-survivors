extends SceneTree
## Every quest look's pixel art (apt_look_*.png), twice the size, to judge
## it by eye (needs a window):  godot --path . -s res://tools/look_shot.gd
## Saves user://look_shot.png (drawing: look_shot_canvas.gd).

var _frames := 0


func _initialize() -> void:
	root.size = Vector2i(1280, 720)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 2:
		var bg := ColorRect.new()
		bg.color = Color("6e8a5a")
		bg.size = Vector2(1280, 720)
		root.add_child(bg)
		var sheet: Node2D = load("res://tools/look_shot_canvas.gd").new()
		sheet.scale = Vector2(2, 2)
		root.add_child(sheet)
	if _frames == 12:
		root.get_texture().get_image().save_png("user://look_shot.png")
		return true
	return false
