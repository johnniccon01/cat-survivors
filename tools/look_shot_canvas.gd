extends Node2D
## Draws every apt_look_*.png for tools/look_shot.gd.


func _draw() -> void:
	var files: Array = []
	for file: String in DirAccess.get_files_at("res://assets/sprites"):
		var plain := file.trim_suffix(".import")
		if plain.begins_with("apt_look_") and plain.ends_with(".png") and plain not in files:
			files.append(plain)
	var x := 10.0
	var y := 10.0
	var row := 0.0
	for f: String in files:
		var tex: Texture2D = FloorChunk.art(f.trim_prefix("apt_").trim_suffix(".png"))
		if x + tex.get_width() > 630.0:
			x = 10.0
			y += row + 8.0
			row = 0.0
		draw_texture(tex, Vector2(x, y))
		x += tex.get_width() + 8.0
		row = maxf(row, tex.get_height())
