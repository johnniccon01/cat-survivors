class_name Sprites
## Access to the pixel-art sheets made by tools/gen_sprites.py:
## assets/sprites/<kind>_<id>.png plus sprites.json with each sheet's cell
## size, anchor point and frame count.

const DIR := "res://assets/sprites/"

static var _manifest: Dictionary = {}
static var _textures: Dictionary = {}


static func _load() -> void:
	if not _manifest.is_empty():
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DIR + "sprites.json"))
	_manifest = parsed if typeof(parsed) == TYPE_DICTIONARY else {"cats": {}, "enemies": {}}


## {cell, anchor, frames, texture} for a cat, or {} if there is no sprite.
static func cat(cat_id: String) -> Dictionary:
	return _entry("cats", "cat_", cat_id)


static func enemy(enemy_id: String) -> Dictionary:
	return _entry("enemies", "enemy_", enemy_id)


static func _entry(group: String, prefix: String, id: String) -> Dictionary:
	_load()
	var info: Dictionary = _manifest.get(group, {}).get(id, {})
	if info.is_empty():
		return {}
	var key := prefix + id.to_lower()
	if not _textures.has(key):
		var path := DIR + key + ".png"
		_textures[key] = load(path) if ResourceLoader.exists(path) else null
	if _textures[key] == null:
		return {}
	var out := info.duplicate()
	out["texture"] = _textures[key]
	return out


## Draws frame (col, row) of a sheet with its anchor at the current origin.
static func draw_frame(ci: CanvasItem, info: Dictionary, col: int, row: int, modulate: Color = Color.WHITE) -> void:
	var cell := Vector2(info["cell"][0], info["cell"][1])
	var anchor := Vector2(info["anchor"][0], info["anchor"][1])
	ci.draw_texture_rect_region(info["texture"], Rect2(-anchor, cell), Rect2(Vector2(col, row) * cell, cell), modulate)
