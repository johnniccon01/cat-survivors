class_name Sprites
## Access to the pixel-art sheets made by tools/gen_sprites.py:
## assets/sprites/<kind>_<id>.png plus sprites.json with each sheet's cell
## size, anchor point and frame count.
##
## All sheets of a group (cats, enemies) are packed into one atlas texture
## when first used: a crowd of different enemies then shares one texture,
## and Godot draws it in a few draw calls instead of one per enemy.

const DIR := "res://assets/sprites/"
const ATLAS_WIDTH := 1024
const PAD := 2

static var _manifest: Dictionary = {}
## "<group>:<id>" -> finished entry (or {} when there is no sprite).
static var _entries: Dictionary = {}
static var _packed: Dictionary = {}


static func _load() -> void:
	if not _manifest.is_empty():
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DIR + "sprites.json"))
	_manifest = parsed if typeof(parsed) == TYPE_DICTIONARY else {"cats": {}, "enemies": {}}


## {cell, anchor, frames, texture, origin} for a cat, or {} if there is no
## sprite. The sheet sits at `origin` inside `texture`.
static func cat(cat_id: String) -> Dictionary:
	return _entry("cats", "cat_", cat_id)


static func enemy(enemy_id: String) -> Dictionary:
	return _entry("enemies", "enemy_", enemy_id)


static func _entry(group: String, prefix: String, id: String) -> Dictionary:
	var key := group + ":" + id
	var cached: Variant = _entries.get(key)
	if cached != null:
		return cached
	_load()
	if not _packed.has(group):
		_pack(group, prefix)
	_entries[key] = {}
	var info: Dictionary = _manifest.get(group, {}).get(id, {})
	var spot: Variant = _packed[group]["spots"].get(id)
	if not info.is_empty() and spot != null:
		var out := info.duplicate()
		out["texture"] = _packed[group]["texture"]
		out["origin"] = spot
		_entries[key] = out
	return _entries[key]


## Packs both atlases now (while a night loads) instead of when the first
## enemy is drawn, which made the game hitch for a moment.
static func warm() -> void:
	cat("")
	enemy("")


## Packs every sheet of the group into one texture, row by row.
static func _pack(group: String, prefix: String) -> void:
	var images: Dictionary = {}
	for id: String in _manifest.get(group, {}):
		var path := DIR + prefix + id.to_lower() + ".png"
		if not ResourceLoader.exists(path):
			continue
		var tex: Texture2D = load(path)
		var img := tex.get_image()
		if img == null:
			continue
		if img.is_compressed():
			img.decompress()
		img.convert(Image.FORMAT_RGBA8)
		images[id] = img
	var spots: Dictionary = {}
	var x := 0
	var y := 0
	var row_h := 0
	for id: String in images:
		var img: Image = images[id]
		if x + img.get_width() > ATLAS_WIDTH:
			x = 0
			y += row_h + PAD
			row_h = 0
		spots[id] = Vector2(x, y)
		x += img.get_width() + PAD
		row_h = maxi(row_h, img.get_height())
	var atlas := Image.create(ATLAS_WIDTH, maxi(y + row_h, 1), false, Image.FORMAT_RGBA8)
	for id: String in images:
		var img: Image = images[id]
		atlas.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i(spots[id]))
	_packed[group] = {"texture": ImageTexture.create_from_image(atlas), "spots": spots}


## Draws frame (col, row) of a sheet with its anchor at the current origin.
static func draw_frame(ci: CanvasItem, info: Dictionary, col: int, row: int, modulate: Color = Color.WHITE) -> void:
	var cell := Vector2(info["cell"][0], info["cell"][1])
	var anchor := Vector2(info["anchor"][0], info["anchor"][1])
	ci.draw_texture_rect_region(info["texture"], Rect2(-anchor, cell), Rect2(info["origin"] + Vector2(col, row) * cell, cell), modulate)
