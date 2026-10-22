extends Node2D
## Endless apartment floor. The world is split into CHUNK-sized squares; each
## visible chunk draws its three FloorChunk layers (ground, furniture, light
## overlay) once into a texture and is freed when the camera moves away, so
## nothing is redrawn per frame.
##
## Rooms come from low-frequency noise (kitchen tiles, living-room planks,
## bedroom carpet) and the layout is seeded per run, so every game looks
## different while the same spot stays the same during a run.

const CHUNK := 320.0
const KEEP_MARGIN := 1
## Texels per world unit of the baked ground (1 = the pixel size of the sprites).
const BAKE_SCALE := 2.0
## Bake viewports made up front: about as many as there are ever chunks at
## once (the ones in view plus a ring around them).
const SPARE_AT_START := 40

## "apartment", "basement", "garden" or "rooftop"; picks rooms, floors and
## furniture.
var theme := "apartment"
const FLOOR_DIM := Color(0.8, 0.8, 0.84)
const FLOOR_DIM_STRONG := Color(0.45, 0.45, 0.5)

var _noise := FastNoiseLite.new()
var _seed := randi()
## chunk coords -> [bake viewport, the sprite showing it, lamp lights]
var _chunks: Dictionary = {}
## Bake viewports of chunks gone out of view, ready for new ones.
var _spare: Array[SubViewport] = []


func _ready() -> void:
	_noise.seed = _seed
	_noise.frequency = 0.22
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	Settings.contrast_changed.connect(_apply_contrast)
	# A stock of bake viewports made while the night loads, so walking into
	# new areas never has to make one.
	for i in SPARE_AT_START:
		_spare.append(_new_viewport())


func _apply_contrast() -> void:
	for nodes: Array in _chunks.values():
		_dim(nodes[0])


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
			_release(c)


func _create(c: Vector2i) -> void:
	var desc := _generate(c)
	var origin := Vector2(c) * CHUNK
	# Lamp lights live in the world (a light baked into the texture would
	# be darkened by the night like everything else).
	var lamps := Node2D.new()
	lamps.position = origin
	add_child(lamps)
	var layers: Array[FloorChunk] = []
	for layer in [FloorChunk.Layer.GROUND, FloorChunk.Layer.DECOR, FloorChunk.Layer.OVERLAY]:
		var node := FloorChunk.new()
		node.layer = layer
		node.desc = desc
		node.position = origin
		node.light_parent = lamps
		node.z_index = layer
		layers.append(node)
	var vp := _bake(layers)
	_dim(vp)
	_chunks[c] = [vp, vp.get_meta("sprite"), lamps]


## Draws all layers of a chunk once into a texture and shows it with one
## sprite. Drawn live, the seams, tiles and furniture cost a draw call each,
## every frame; baked, the whole chunk is a single one. Everything a chunk
## draws stays inside its square (the biggest furniture is placed so).
func _bake(layers: Array[FloorChunk]) -> SubViewport:
	var vp: SubViewport = _spare.pop_back() if not _spare.is_empty() else _new_viewport()
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	# The chunk keeps its world position (planks line up across chunks);
	# its parent moves it back into the texture.
	var shift: Node2D = vp.get_child(0)
	shift.position = -layers[0].position * BAKE_SCALE
	for node in layers:
		shift.add_child(node)
	var sprite: Sprite2D = vp.get_meta("sprite")
	sprite.position = layers[0].position
	sprite.visible = true
	vp.set_meta("layers", layers)
	return vp


## A viewport (with the sprite that shows it) for baking chunks. Making one
## costs a few milliseconds, so they are kept and reused (see _release).
func _new_viewport() -> SubViewport:
	var vp := SubViewport.new()
	vp.size = Vector2i(int(CHUNK * BAKE_SCALE), int(CHUNK * BAKE_SCALE))
	vp.disable_3d = true
	vp.transparent_bg = true
	var shift := Node2D.new()
	shift.scale = Vector2(BAKE_SCALE, BAKE_SCALE)
	vp.add_child(shift)
	add_child(vp)
	var sprite := Sprite2D.new()
	sprite.texture = vp.get_texture()
	sprite.centered = false
	sprite.scale = Vector2.ONE / BAKE_SCALE
	sprite.visible = false
	add_child(sprite)
	vp.set_meta("sprite", sprite)
	return vp


## Frees a chunk that went out of view; its viewport waits for the next one.
func _release(c: Vector2i) -> void:
	var vp: SubViewport = _chunks[c][0]
	for node: FloorChunk in vp.get_meta("layers"):
		node.get_parent().remove_child(node)
		node.queue_free()
	(vp.get_meta("sprite") as Sprite2D).visible = false
	_spare.append(vp)
	(_chunks[c][2] as Node).queue_free()
	_chunks.erase(c)


## The floor stays a little dim so enemies stand out against it (the light
## overlay is not dimmed). Bakes the chunk again when it changes.
func _dim(vp: SubViewport) -> void:
	for node: FloorChunk in vp.get_meta("layers"):
		if node.layer != FloorChunk.Layer.OVERLAY:
			node.modulate = FLOOR_DIM_STRONG if Settings.high_contrast else FLOOR_DIM
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE


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
