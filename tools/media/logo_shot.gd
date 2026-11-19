extends SceneTree
## Saves the title board from the main menu ("Cat Survivors" on cardboard,
## stamp, tape, scribble and the tagline) as a PNG with a transparent
## background, drawn 3x (crisp for 4K and store capsules).
##
##   godot --path . -s res://tools/media/logo_shot.gd -- --out=C:/path/logo.png [--no-tagline] [--lang=en]

const SCALE := 3.0
const SIZE := Vector2(700, 330)


func _initialize() -> void:
	var out := "user://logo.png"
	var tagline := true
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
		elif a == "--no-tagline":
			tagline = false
	var vp := SubViewport.new()
	vp.size = Vector2i(SIZE * SCALE)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var art := Control.new()
	art.scale = Vector2(SCALE, SCALE)
	art.size = SIZE
	vp.add_child(art)
	# Same layout as MainMenu._build_title, moved in so the tape and stamp fit.
	var board := BoxBoard.make("board", Vector2(40, 46), Vector2(589, 192), 2, -2.0)
	art.add_child(board)
	var head := BoxStyle.head_font()
	var name_label := BoxStyle.label("Cat Survivors", BoxStyle.fit_size("Cat Survivors", head, 106, 520.0), BoxStyle.INK, true)
	name_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	name_label.offset_top = 8
	name_label.offset_bottom = 150
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	board.add_child(name_label)
	board.add_child(BoxBoard.make("scribble", Vector2(64, 144), Vector2(461, 26), 9))
	board.add_child(BoxBoard.make("stamp", Vector2(470, -32), Vector2(102, 102), 4, 16.0))
	board.add_child(BoxBoard.make("tape", Vector2(-12, 6), Vector2(102, 36), 3, -38.0))
	if tagline:
		var tag := TranslationServer.translate("MENU_TAGLINE")
		var body := BoxStyle.body_font()
		var tag_size := 24
		var tag_w := minf(body.get_string_size(tag, HORIZONTAL_ALIGNMENT_LEFT, -1, tag_size).x + 64.0, 560.0)
		tag_size = BoxStyle.fit_size(tag, body, tag_size, tag_w - 64.0)
		var tape := BoxBoard.make("tape", Vector2(72, 260), Vector2(maxf(tag_w, 300.0), 44), 7, 1.2)
		art.add_child(tape)
		var tag_label := BoxStyle.label("MENU_TAGLINE", tag_size)
		tag_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		tape.add_child(tag_label)
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	img.save_png(out)
	print("logo -> ", out, " ", img.get_size())
	quit()
