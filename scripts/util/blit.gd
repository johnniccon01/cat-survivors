class_name Blit
## Cheap drawing for things there are many of (shadows, hit sparks, bullets).
## Godot draws every circle, polygon and thick line as its own draw call, but
## textured rectangles that share a texture are merged into one. These helpers
## draw discs, rings, ellipses, bars and lines as rectangles cut from one small
## texture, so a whole crowd of them costs about one draw call.
##
## line() uses draw_set_transform: from a _draw that sets its own transform,
## pass that transform as `base` (it is restored afterwards).

const CELL := 64
## Ring cells: how thick the ring is, as a share of its radius.
const RING_WIDTHS := [0.08, 0.16, 0.3, 0.5]

static var _tex: ImageTexture
## Cells of the atlas: solid, disc, then the rings.
static var _solid := Rect2(CELL * 0.5 - 2, CELL * 0.5 - 2, 4, 4)
static var _disc := Rect2(CELL, 0, CELL, CELL)


static func texture() -> Texture2D:
	if _tex == null:
		var img := Image.create(CELL * (2 + RING_WIDTHS.size()), CELL, false, Image.FORMAT_RGBA8)
		img.fill_rect(Rect2i(0, 0, CELL, CELL), Color.WHITE)
		var half := CELL * 0.5
		for x in CELL:
			for y in CELL:
				# Distance from the centre in radii, with a one-texel soft edge.
				var d := Vector2(x + 0.5 - half, y + 0.5 - half).length()
				img.set_pixel(CELL + x, y, Color(1, 1, 1, clampf(half - d, 0.0, 1.0)))
				for i in RING_WIDTHS.size():
					var inner: float = half * (1.0 - RING_WIDTHS[i])
					var a := clampf(half - d, 0.0, 1.0) * clampf(d - inner, 0.0, 1.0)
					img.set_pixel(CELL * (2 + i) + x, y, Color(1, 1, 1, a))
		_tex = ImageTexture.create_from_image(img)
	return _tex


## A filled circle.
static func disc(ci: CanvasItem, center: Vector2, r: float, color: Color) -> void:
	ci.draw_texture_rect_region(texture(), Rect2(center.x - r, center.y - r, r * 2.0, r * 2.0), _disc, color)


## A filled ellipse (shadows).
static func ellipse(ci: CanvasItem, center: Vector2, rx: float, ry: float, color: Color) -> void:
	ci.draw_texture_rect_region(texture(), Rect2(center.x - rx, center.y - ry, rx * 2.0, ry * 2.0), _disc, color)


## A circle outline `width` thick (its outer edge at `r`).
static func ring(ci: CanvasItem, center: Vector2, r: float, width: float, color: Color) -> void:
	if r <= 0.0:
		return
	var share := width / r
	var best := 0
	for i in RING_WIDTHS.size():
		if absf(RING_WIDTHS[i] - share) < absf(RING_WIDTHS[best] - share):
			best = i
	ci.draw_texture_rect_region(texture(), Rect2(center.x - r, center.y - r, r * 2.0, r * 2.0), Rect2(CELL * (2 + best), 0, CELL, CELL), color)


## A filled axis-aligned rectangle (batches with the rest, unlike draw_rect
## when mixed with them).
static func rect(ci: CanvasItem, r: Rect2, color: Color) -> void:
	ci.draw_texture_rect_region(texture(), r, _solid, color)


## A straight line `width` thick; `base` is the transform the _draw uses.
static func line(ci: CanvasItem, a: Vector2, b: Vector2, color: Color, width: float = 1.0, base := Transform2D.IDENTITY) -> void:
	var d := b - a
	var length := d.length()
	if length < 0.001:
		return
	ci.draw_set_transform_matrix(base * Transform2D(d.angle(), a))
	ci.draw_texture_rect_region(texture(), Rect2(0.0, -width * 0.5, length, width), _solid, color)
	ci.draw_set_transform_matrix(base)
