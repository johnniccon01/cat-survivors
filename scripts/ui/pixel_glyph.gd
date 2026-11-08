class_name PixelGlyph
## Small pixel-art icons for the HUD and menus (coin, paw, heart, cat flap…),
## drawn from text maps in the same chunky style as the weapon icons. Each
## texture is made once and kept.

const PALETTE := {
	"k": Color("0d0912"), "r": Color("e5544b"), "R": Color("b5352f"), "w": Color("ffffff"),
	"W": Color("e9e1f2"), "y": Color("f2c14e"), "o": Color("c7932a"), "Y": Color("ffe39a"),
	"g": Color("8ee07a"), "G": Color("4c8a43"), "d": Color("1c2a1b"), "b": Color("a8743a"),
	"s": Color("ffd36e"), "p": Color("b99cff"), "P": Color("7a5ad8"), "c": Color("8fd3ff"),
}

const MAPS := {
	"heart": [".kk...kk.", "krrk.kRrk", "krwrkrrRk", "krrrrrrRk", "krrrrrrRk", ".krrrrRk.", "..krrRk..", "...krk...", "....k...."],
	"coin": ["..kkkkk..", ".kyyyyyk.", "kyYyyyyok", "kyYyoyyok", "kyyyoyyok", "kyyyoyyok", "kyyyyyyok", ".kooooook", "..kkkkk.."],
	"paw": [".kk...kk.", "kWWk.kWWk", "kWWk.kWWk", ".kk.k.kk.", "...kWk...", "..kWWWk..", ".kWWWWWk.", ".kWWWWWk.", "..kkkkk.."],
	"door": ["..kkkkk..", ".kgggggk.", "kggdddggk", "kgdddddgk", "kgdddddgk", "kgddddgGk", "kgdddddgk", "kgdddddgk", "kkkkkkkkk"],
	"bolt": ["....kkk", "...kssk", "..kssk.", ".ksssk.", "kssssk.", ".kksk..", "..ksk..", ".kkk...", ".k....."],
	"star": ["...k...", "..kyk..", "kkkykkk", "kyyyyyk", ".kyyyk.", ".kykyk.", ".kk.kk."],
	"skull": ["...kkkk...", "..kWWWWk..", ".kWWWWWWk.", ".kWkkWkkWk", ".kWkkWkkWk", ".kWWWkWWWk", "..kWWWWWk.", "..kWkWkWk.", "...kkkkk.."],
	"shuffle": ["..........", ".......k..", ".wwk..kwwk", "...wkkw.k.", "....ww....", "....ww....", "...wkkw.k.", ".wwk..kwwk", ".......k..", ".........."],
	"broom": [".......bb.", "......bb..", ".....bb...", "....bb....", "..kkkkk...", ".kyyyyyk..", ".kyyyyyyk.", "kyyyyyyyk.", "kyoyoyoyk.", ".kkkkkkk.."],
	"slot": ["yyyyyyyyyy", "y........y", "y...ww...y", "y...ww...y", "y.wwwwww.y", "y.wwwwww.y", "y...ww...y", "y...ww...y", "y........y", "yyyyyyyyyy"],
	"revive": [".kk...kk.", "krrk.krrk", "krrrkrrrk", "krrwwwrrk", "krrwwwrrk", ".krrwrrk.", "..krwrk..", "...krk...", "....k...."],
	"soul": ["..kkk..", ".kpppk.", "kppwppk", "kpPppPk", "kppppPk", ".kPPPk.", "..kkk.."],
}

## Upgrade shop icons that have no passive of their own: drawn on a tile.
const SHOP_TILES := {"REVIVAL": "revive", "REROLL": "shuffle", "DISCARD": "broom", "CURSE": "skull", "WEAPON_SLOT": "slot"}

static var _cache := {}


## The glyph `name` as a texture, one texel per pixel of the map (scale it
## up with a nearest filter: see `rect`).
static func texture(name: String) -> Texture2D:
	if _cache.has(name):
		return _cache[name]
	var rows: Array = MAPS[name]
	var img := Image.create(String(rows[0]).length(), rows.size(), false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			if PALETTE.has(row[x]):
				img.set_pixel(x, y, PALETTE[row[x]])
	var tex := ImageTexture.create_from_image(img)
	_cache[name] = tex
	return tex


## A TextureRect showing glyph `name` at `scale` screen pixels per pixel.
static func rect(name: String, scale: int = 2) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = texture(name)
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.custom_minimum_size = Vector2(tr.texture.get_width(), tr.texture.get_height()) * scale
	tr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr


## Draws glyph `name` into `r` (nearest filter is up to the canvas item).
static func draw(ci: CanvasItem, name: String, r: Rect2) -> void:
	ci.draw_texture_rect(texture(name), r, false)


## Draws a passive-style tile (the teal of the game's passive icons) with
## glyph `name` on it, like Icons.draw does for real passives.
static func draw_tile(ci: CanvasItem, name: String, r: Rect2) -> void:
	# The bevelled tile of the baked skill icons (see tools/bake_art_body.gd).
	var bg := Icons.PASSIVE_BG
	var px := r.size.x / Icons.BAKE_SIZE
	ci.draw_rect(r, Color("1e140f"))
	var inner := r.grow(-px)
	ci.draw_rect(inner, bg.darkened(0.08))
	ci.draw_rect(Rect2(inner.position, Vector2(inner.size.x, inner.size.y * 0.5 - px)), bg)
	ci.draw_rect(Rect2(inner.position, Vector2(inner.size.x, px)), bg.lightened(0.28))
	ci.draw_rect(Rect2(inner.position, Vector2(px, inner.size.y)), bg.lightened(0.14))
	ci.draw_rect(Rect2(Vector2(inner.position.x, inner.end.y - px), Vector2(inner.size.x, px)), bg.darkened(0.3))
	ci.draw_rect(Rect2(Vector2(inner.end.x - px, inner.position.y), Vector2(px, inner.size.y)), bg.darkened(0.22))
	var tex := texture(name)
	var scale := floorf(r.size.x * 0.7 / maxf(tex.get_width(), tex.get_height()))
	var size := Vector2(tex.get_width(), tex.get_height()) * maxf(scale, 1.0)
	ci.draw_texture_rect(tex, Rect2(r.get_center() - size / 2.0, size).abs(), false)
