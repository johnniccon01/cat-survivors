extends Control
## Store media: each district's whole town map (DistrictMap) without the
## select screen around it, its buttons or the hint, saved as a PNG at the
## window's real size. Run with the capture flags so nothing is saved:
##
##   godot --path . --fixed-fps 60 res://tools/media/district_shot.tscn -- --no-save --open-all --lang=en --capture --capture-size=3840x2160 --out=C:/dir
##
## Writes <out>/district_<id>.png for cats, dogs, wild and company.

const DISTRICTS := ["cats", "dogs", "wild", "company"]


func _ready() -> void:
	var out := GameData.arg("--out=", OS.get_user_data_dir())
	DirAccess.make_dir_recursive_absolute(out)
	var bg := ColorRect.new()
	bg.color = Color("1c120c")
	bg.size = Vector2(1280, 720)
	add_child(bg)
	for d: String in DISTRICTS:
		# The map opens on the profile's district (never saved: --no-save).
		Profile.district = d
		var map := DistrictMap.new()
		# The whole town at its smallest zoom, scaled down to fit the screen.
		var full := Vector2(DistrictMap.WW, DistrictMap.WH) * DistrictMap.MIN_PX
		map.size = full
		var k := minf(1280.0 / full.x, 720.0 / full.y)
		map.scale = Vector2(k, k)
		map.position = (Vector2(1280, 720) - full * k) * 0.5
		add_child(map)
		for i in 20:
			await get_tree().process_frame
		for node: Control in [map._mini, map._paths_btn, map._dogs_btn, map._hint]:
			node.visible = false
		for arrow: Control in map._arrows.values():
			arrow.visible = false
		for i in 3:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out.path_join("district_%s.png" % d))
		print("district ", d)
		map.queue_free()
		await get_tree().process_frame
	get_tree().quit()
