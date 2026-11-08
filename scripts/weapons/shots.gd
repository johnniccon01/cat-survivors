class_name Shots
## Baked pixel-art pictures of what the weapons throw (balls of yarn,
## feathers, hooks, needles, hairballs, bottle caps, paper planes), made by
## tools/bake_art.gd from each one's shape drawing at REF_RADIUS. (Fish bones
## keep their own blocky drawing.) In the game they are drawn at the projectile's own size.

const PATH := "res://assets/sprites/shots/%s.png"
## The radius the pictures are baked at (one texel = one screen pixel there).
const REF_RADIUS := 5.0
## What gets baked.
const KEYS := ["yarn", "feather", "phoenix", "hook", "golden_hook", "needle", "hairball", "cap", "cap_gold", "plane", "plane_gold"]

static var _tex: Dictionary = {}


static func texture(key: String) -> Texture2D:
	if not _tex.has(key):
		var path := PATH % key
		_tex[key] = load(path) if ResourceLoader.exists(path) else null
	return _tex[key]


## Draws the baked picture `key` centred at the canvas item's origin, scaled
## to `radius`; false when there is none (draw the shapes instead).
static func draw(ci: CanvasItem, key: String, radius: float) -> bool:
	var tex := texture(key)
	if tex == null:
		return false
	# A needle stays a needle: a wider one hits more, but isn't drawn thicker.
	var k := radius / REF_RADIUS if key != "needle" else minf(radius / REF_RADIUS, 1.0)
	var size := Vector2(tex.get_width(), tex.get_height()) * k
	ci.draw_texture_rect(tex, Rect2(-size / 2.0, size), false)
	return true


## The shape drawing of `key` at `radius` (used by the baker).
static func draw_shape(ci: CanvasItem, key: String, radius: float) -> void:
	match key:
		"cap", "cap_gold":
			Gizmo.draw_cap(ci, radius, key == "cap_gold")
		"plane", "plane_gold":
			Gizmo.draw_plane(ci, radius, key == "plane_gold")
		_:
			Projectile.draw_body(ci, key, radius)
