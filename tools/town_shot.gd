extends SceneTree
## Saves a whole district map picture (the town under the map screen) to
## user://town.png (or town_<district>.png), twice the size, to check it by eye:
##   godot --headless --path . -s res://tools/town_shot.gd [-- wild]
## (cats, dogs, wild or company).


func _initialize() -> void:
	var map: GDScript = load("res://scripts/ui/district_map.gd")
	var d := "cats"
	for a in OS.get_cmdline_user_args():
		if a in ["cats", "dogs", "wild", "company"]:
			d = a
	if d == "cats":
		map.call("_build_town")
	else:
		map.call("_build_dog_town", d)
	var img: Image = map.get("_image")
	img = img.duplicate()
	img.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
	img.save_png("user://town.png" if d == "cats" else "user://town_%s.png" % d)
	quit()
