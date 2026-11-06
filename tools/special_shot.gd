extends SceneTree
## The maps' special things big (shrines, the cat-flap door, quest
## buildings), to judge the pixel art by eye (needs a window):
##   godot --path . -s res://tools/special_shot.gd
## Saves user://special_shot.png.

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
		holder.scale = Vector2(3, 3)
		root.add_child(holder)
		var things: Array[Node2D] = []
		for used in [false, true]:
			var shrine: Node2D = load("res://scripts/world/shrine.gd").new()
			shrine.set("used", used)
			things.append(shrine)
		things.append(load("res://scripts/world/extraction.gd").new())
		for kind: String in ["heal_spot", "turret", "lighthouse", "scarecrow"]:
			var feature: Node2D = load("res://scripts/world/map_feature.gd").new()
			feature.set("kind", kind)
			things.append(feature)
		for i in things.size():
			things[i].process_mode = Node.PROCESS_MODE_DISABLED
			things[i].position = Vector2(50 + (i % 6) * 70, 70 + (i / 6) * 110)
			holder.add_child(things[i])
			things[i].queue_redraw()
	if _frames == 12:
		root.get_texture().get_image().save_png("user://special_shot.png")
		return true
	return false
