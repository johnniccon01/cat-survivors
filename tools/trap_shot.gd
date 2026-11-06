extends SceneTree
## Every trap twice (armed on top, resting below), big, to judge the pixel
## art by eye (needs a window, not --headless):
##   godot --path . -s res://tools/trap_shot.gd
## Saves user://trap_shot.png.

var _frames := 0


func _initialize() -> void:
	root.size = Vector2i(1280, 720)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 2:
		var bg := ColorRect.new()
		bg.color = Color("6e8a5a")
		bg.size = Vector2(1280, 720)
		bg.z_index = -10
		root.add_child(bg)
		var holder := Node2D.new()
		holder.scale = Vector2(2, 2)
		root.add_child(holder)
		var ids: Array = root.get_node("/root/GameData").traps.keys()
		for i in ids.size():
			for row in 2:
				var trap: Node2D = load("res://scripts/world/trap.gd").new()
				trap.setup(ids[i], null)
				trap.process_mode = Node.PROCESS_MODE_DISABLED
				trap.set("_active", row == 0)
				trap.set("_timer", 5.0)
				trap.position = Vector2(40 + (i % 11) * 56, 50 + (i / 11) * 180 + row * 80)
				holder.add_child(trap)
				trap.queue_redraw()
	if _frames == 12:
		root.get_texture().get_image().save_png("user://trap_shot.png")
		return true
	return false
