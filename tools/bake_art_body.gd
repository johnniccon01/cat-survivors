extends RefCounted
## See bake_art.gd. Each icon: the symbol is drawn alone at BAKE_SIZE, gets
## hard edges, a dark outline, a light top edge and a shaded bottom edge
## (like the game's sprites), and goes on a bevelled tile.

const OUTLINE := Color("1e140f")

var tree: SceneTree
var _jobs: Array = []
var _job: Array = []
var _vp: SubViewport
var _canvas: Control
var _wait := 0
var _out := ""
## BAKE_SOFT=1 in the environment: a softer look (no outline, no shading,
## the icon's own tile), saved to user://bake_preview to look at first.
var _soft := OS.get_environment("BAKE_SOFT") != ""
var _shots_out := ""
## The projectiles: a bigger viewport, drawn around a pen at its centre.
var _svp: SubViewport
var _pen: Node2D
const SHOT_VIEW := 64


func start(p_tree: SceneTree) -> void:
	tree = p_tree
	var root_dir := "user://bake_preview" if _soft else "res://assets/sprites"
	_out = ProjectSettings.globalize_path(root_dir + "/icons")
	DirAccess.make_dir_recursive_absolute(_out)
	_vp = SubViewport.new()
	_vp.size = Vector2i(Icons.BAKE_SIZE, Icons.BAKE_SIZE)
	_vp.transparent_bg = true
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	tree.root.add_child(_vp)
	_canvas = Control.new()
	_canvas.size = Vector2(Icons.BAKE_SIZE, Icons.BAKE_SIZE)
	_vp.add_child(_canvas)
	_canvas.draw.connect(_draw_job)
	for id: String in GameData.weapons:
		_jobs.append(["weapon", id])
	for id: String in GameData.passives:
		_jobs.append(["passive", id])
	_shots_out = ProjectSettings.globalize_path(root_dir + "/shots")
	DirAccess.make_dir_recursive_absolute(_shots_out)
	_svp = SubViewport.new()
	_svp.size = Vector2i(SHOT_VIEW, SHOT_VIEW)
	_svp.transparent_bg = true
	_svp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	tree.root.add_child(_svp)
	_pen = Node2D.new()
	_pen.position = Vector2(SHOT_VIEW / 2.0, SHOT_VIEW / 2.0)
	_svp.add_child(_pen)
	_pen.draw.connect(func() -> void:
		if not _job.is_empty() and _job[0] == "shot":
			Shots.draw_shape(_pen, _job[1], Shots.REF_RADIUS))
	for key: String in Shots.KEYS:
		_jobs.append(["shot", key])
	_next()


func _draw_job() -> void:
	if not _job.is_empty() and _job[0] != "shot":
		Icons.draw_vector(_canvas, _job[0], _job[1], Rect2(0, 0, Icons.BAKE_SIZE, Icons.BAKE_SIZE), _soft)


func step() -> bool:
	_wait += 1
	if _wait < 3:
		return false
	if _job[0] == "shot":
		_save_shot()
	else:
		var sym := _vp.get_texture().get_image()
		sym.convert(Image.FORMAT_RGBA8)
		var img := _hard(sym) if _soft else _tile(Icons.tile_color(_job[0], _job[1]))
		if not _soft:
			_compose(img, _shade(sym))
		img.save_png(_out.path_join("%s_%s.png" % _job))
	if _jobs.is_empty():
		print("BAKE: done")
		tree.quit()
		return true
	_next()
	return false


func _next() -> void:
	_job = _jobs.pop_front()
	_wait = 0
	_canvas.queue_redraw()
	_pen.queue_redraw()


## A projectile: shaded like the icons, cut to its size around the centre
## (so it stays centred when drawn).
func _save_shot() -> void:
	var img := _vp_image(_svp)
	var shaded := _hard(img) if _soft else _shade(img)
	var used := shaded.get_used_rect()
	var c := SHOT_VIEW / 2
	var half_w := maxi(c - used.position.x, used.end.x - c)
	var half_h := maxi(c - used.position.y, used.end.y - c)
	var cut := shaded.get_region(Rect2i(c - half_w, c - half_h, half_w * 2, half_h * 2))
	cut.save_png(_shots_out.path_join("%s.png" % _job[1]))


func _vp_image(vp: SubViewport) -> Image:
	var img := vp.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	return img


## The bevelled tile: dark rim, lighter top half, a highlight row under the
## top rim and a shade row over the bottom one.
func _tile(bg: Color) -> Image:
	var n := Icons.BAKE_SIZE
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	img.fill(OUTLINE)
	img.fill_rect(Rect2i(1, 1, n - 2, n - 2), bg.darkened(0.08))
	img.fill_rect(Rect2i(1, 1, n - 2, n / 2 - 1), bg)
	img.fill_rect(Rect2i(1, 1, n - 2, 1), bg.lightened(0.28))
	img.fill_rect(Rect2i(1, 1, 1, n - 2), bg.lightened(0.14))
	img.fill_rect(Rect2i(1, n - 2, n - 2, 1), bg.darkened(0.3))
	img.fill_rect(Rect2i(n - 2, 1, 1, n - 2), bg.darkened(0.22))
	return img


## Hard edges, a dark outline around the symbol, light on its top edges and
## shade on its bottom edges.
func _shade(src: Image) -> Image:
	var n := src.get_width()
	var solid := func(x: int, y: int) -> bool:
		return x >= 0 and y >= 0 and x < n and y < n and src.get_pixel(x, y).a >= 0.5
	var out := Image.create(n, n, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	for y in n:
		for x in n:
			if solid.call(x, y):
				var c := src.get_pixel(x, y)
				c.a = 1.0
				var dark := c.get_luminance() < 0.18
				if not dark and not solid.call(x, y - 1):
					c = c.lightened(0.3)
				elif not dark and not solid.call(x, y + 1):
					c = c.darkened(0.22)
				out.set_pixel(x, y, c)
			elif solid.call(x - 1, y) or solid.call(x + 1, y) or solid.call(x, y - 1) or solid.call(x, y + 1):
				out.set_pixel(x, y, OUTLINE)
	return out


func _compose(dst: Image, src: Image) -> void:
	var n := dst.get_width()
	for y in range(1, n - 1):
		for x in range(1, n - 1):
			var c := src.get_pixel(x, y)
			if c.a > 0.0:
				dst.set_pixel(x, y, c)


## Hard edges only (the soft look): every pixel there or not, no outline.
func _hard(src: Image) -> Image:
	var out := src.duplicate() as Image
	for y in out.get_height():
		for x in out.get_width():
			var c := out.get_pixel(x, y)
			out.set_pixel(x, y, Color(c.r, c.g, c.b, 1.0 if c.a >= 0.5 else 0.0))
	return out
