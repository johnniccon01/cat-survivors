extends SceneTree
## Big pictures of one map's enemies, props and bosses, to judge the pixel
## art by eye (needs a window, not --headless):
##   godot --path . -s res://tools/enemy_shot.gd -- LIVING_ROOM
## Saves user://enemy_shot.png (drawing: enemy_shot_canvas.gd, loaded once
## the autoloads exist).

var _frames := 0


func _initialize() -> void:
	root.size = Vector2i(1280, 720)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 2:
		var canvas: Node2D = load("res://tools/enemy_shot_canvas.gd").new()
		var args := OS.get_cmdline_user_args()
		canvas.set("stage", args[0] if args.size() > 0 else "LIVING_ROOM")
		root.add_child(canvas)
	if _frames == 12:
		root.get_texture().get_image().save_png("user://enemy_shot.png")
		return true
	return false
