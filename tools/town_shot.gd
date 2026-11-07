extends SceneTree
## Saves the whole district map picture (the town under the map screen) to
## user://town.png, three times the size, to check it by eye:
##   godot --headless --path . -s res://tools/town_shot.gd


func _initialize() -> void:
	var map: GDScript = load("res://scripts/ui/district_map.gd")
	map.call("_build_town")
	var img: Image = map.get("_image")
	img = img.duplicate()
	img.resize(img.get_width() * 3, img.get_height() * 3, Image.INTERPOLATE_NEAREST)
	img.save_png("user://town.png")
	quit()
