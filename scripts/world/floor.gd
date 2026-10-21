extends Node2D
## Endless apartment floor. The world is split into CHUNK-sized squares; each
## visible chunk gets three FloorChunk nodes (ground, furniture, light
## overlay) that draw once and are freed when the camera moves away, so
## nothing is redrawn per frame.
##
## Rooms come from low-frequency noise (kitchen tiles, living-room planks,
## bedroom carpet) and the layout is seeded per run, so every game looks
## different while the same spot stays the same during a run.

const CHUNK := 320.0
const KEEP_MARGIN := 2
## Texels per world unit of the baked ground (1 = the pixel size of the sprites).
const BAKE_SCALE := 2.0

## "apartment", "basement", "garden" or "rooftop"; picks rooms, floors and
## furniture.
var theme := "apartment"
const FLOOR_DIM := Color(0.8, 0.8, 0.84)
const FLOOR_DIM_STRONG := Color(0.45, 0.45, 0.5)

var _noise := FastNoiseLite.new()
var _seed := randi()
## chunk coords -> the nodes of that chunk (layers, baked ground and its viewport)
var _chunks: Dictionary = {}


func _ready() -> void:
	_noise.seed = _seed
	_noise.frequency = 0.22
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	Settings.contrast_changed.connect(_apply_contrast)


func _apply_contrast() -> void:
	for nodes: Array in _chunks.values():
		for node: Node in nodes:
			if node is Node2D and node.z_index != FloorChunk.Layer.OVERLAY:
				node.modulate = FLOOR_DIM_STRONG if Settings.high_contrast else FLOOR_DIM


func zone_at(c: Vector2i) -> String:
	var n := _noise.get_noise_2d(c.x, c.y)
	var zones: Array = FloorChunk.THEME_ZONES.get(theme, FloorChunk.THEME_ZONES["apartment"])
	if n < -0.22:
		return zones[0]
	if n > 0.22:
		return zones[2]
	return zones[1]


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	var center := camera.get_screen_center_position()
	var half := get_viewport_rect().size / camera.zoom * 0.5
	var c0 := Vector2i(floori((center.x - half.x) / CHUNK) - 1, floori((center.y - half.y) / CHUNK) - 1)
	var c1 := Vector2i(floori((center.x + half.x) / CHUNK) + 1, floori((center.y + half.y) / CHUNK) + 1)
	for cx in range(c0.x, c1.x + 1):
		for cy in range(c0.y, c1.y + 1):
			var c := Vector2i(cx, cy)
			if not _chunks.has(c):
				_create(c)
	for c: Vector2i in _chunks.keys():
		if c.x < c0.x - KEEP_MARGIN or c.x > c1.x + KEEP_MARGIN or c.y < c0.y - KEEP_MARGIN or c.y > c1.y + KEEP_MARGIN:
			for node: Node in _chunks[c]:
				node.queue_free()
			_chunks.erase(c)


func _create(c: Vector2i) -> void:
	var desc := _generate(c)
	var nodes: Array[Node] = []
	for layer in [FloorChunk.Layer.GROUND, FloorChunk.Layer.DECOR, FloorChunk.Layer.OVERLAY]:
		var node := FloorChunk.new()
		node.layer = layer
		node.desc = desc
		node.position = Vector2(c) * CHUNK
		var shown: Node2D = node
		if layer == FloorChunk.Layer.GROUND:
			shown = _bake(node)
			nodes.append(node.get_parent().get_parent())
		else:
			add_child(node)
		# The floor stays a little dim so enemies stand out against it.
		if layer != FloorChunk.Layer.OVERLAY:
			shown.modulate = FLOOR_DIM_STRONG if Settings.high_contrast else FLOOR_DIM
		shown.z_index = layer
		nodes.append(shown)
	_chunks[c] = nodes


## Draws the ground of a chunk once into a texture and returns the sprite
## that shows it. Drawn live, its hundreds of seams and tiles cost a draw call
## each, every frame; baked, the whole chunk is a single one.
func _bake(node: FloorChunk) -> Sprite2D:
	var vp := SubViewport.new()
	vp.size = Vector2i(int(CHUNK * BAKE_SCALE), int(CHUNK * BAKE_SCALE))
	vp.disable_3d = true
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	# The chunk keeps its world position (planks line up across chunks);
	# its parent moves it back into the texture.
	var shift := Node2D.new()
	shift.scale = Vector2(BAKE_SCALE, BAKE_SCALE)
	shift.position = -node.position * BAKE_SCALE
	shift.add_child(node)
	vp.add_child(shift)
	add_child(vp)
	var sprite := Sprite2D.new()
	sprite.texture = vp.get_texture()
	sprite.centered = false
	sprite.position = node.position
	sprite.scale = Vector2.ONE / BAKE_SCALE
	add_child(sprite)
	return sprite


func _pick(rng: RandomNumberGenerator, list: Array) -> Variant:
	return list[rng.randi() % list.size()]


## Describes everything in one chunk; positions are local to the chunk.
func _generate(c: Vector2i) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(c) ^ _seed
	var zone := zone_at(c)
	var desc := {
		"zone": zone,
		"size": CHUNK,
		"seed": rng.randi(),
		# Draw a threshold strip where the room changes.
		"edge_right": zone_at(c + Vector2i.RIGHT) != zone,
		"edge_bottom": zone_at(c + Vector2i.DOWN) != zone,
		"furniture": [],
		"items": [],
	}
	if zone in ["living", "bedroom", "deck"] and rng.randf() < 0.45:
		var size := Vector2(rng.randf_range(110, 180), rng.randf_range(70, 120))
		desc["rug"] = {
			"rect": Rect2(Vector2(rng.randf_range(20, CHUNK - size.x - 20), rng.randf_range(20, CHUNK - size.y - 20)), size),
			"color": FloorChunk.RUG_COLORS[rng.randi() % FloorChunk.RUG_COLORS.size()],
			"oval": rng.randf() < 0.4,
		}
	var pool: Array = FloorChunk.FURNITURE[zone]
	# Two loose slots per chunk, in opposite corners, so pieces don't overlap.
	for slot: Vector2 in [Vector2(0.28, 0.3), Vector2(0.72, 0.72)]:
		if rng.randf() < 0.55:
			desc["furniture"].append({
				"kind": pool[rng.randi() % pool.size()],
				"pos": slot * CHUNK + Vector2(rng.randf_range(-25, 25), rng.randf_range(-25, 25)),
				"rot": [0.0, PI * 0.5, PI, PI * 1.5][rng.randi() % 4],
				"color": FloorChunk.RUG_COLORS[rng.randi() % FloorChunk.RUG_COLORS.size()],
			})
	for i in rng.randi_range(1, 4):
		desc["items"].append({
			"kind": _pick(rng, FloorChunk.THEME_ITEMS.get(theme, FloorChunk.ITEM_KINDS)),
			"pos": Vector2(rng.randf_range(10, CHUNK - 10), rng.randf_range(10, CHUNK - 10)),
			"rot": rng.randf_range(-0.6, 0.6),
			"color": FloorChunk.RUG_COLORS[rng.randi() % FloorChunk.RUG_COLORS.size()],
		})
	if theme == "apartment" and rng.randf() < 0.3:
		desc["moon"] = {
			"pos": Vector2(rng.randf_range(0, CHUNK - 120), rng.randf_range(0, CHUNK - 90)),
			"size": Vector2(rng.randf_range(70, 110), rng.randf_range(55, 80)),
		}
	return desc
