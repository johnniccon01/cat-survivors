class_name FloorChunk
extends Node2D
## One layer of one floor chunk, drawn once from the description made by
## floor.gd. GROUND = floor surface, DECOR = rugs, furniture and clutter
## (plus real lights for lamps), OVERLAY = moonlight and lamp glow.

enum Layer { GROUND, DECOR, OVERLAY }

const OUTLINE := Color("2b1d14")
const WOOD := Color("8a5a3b")
const WOOD_DARK := Color("6b4630")
const SEAM := Color("5e3b26")
const PLANK := Vector2(96, 16)
const TILE := 32.0
const RUG_COLORS: Array[Color] = [Color("8e3b46"), Color("2f6f73"), Color("c9a24a"), Color("5b4a8a"), Color("3f6b3a")]
const ITEM_KINDS: Array[String] = ["mouse", "book", "ball", "feather", "crumbs"]
const BASEMENT_ITEMS: Array[String] = ["cobweb", "bolt", "rag", "crumbs", "jar"]
const GARDEN_ITEMS: Array[String] = ["leaf", "leaf", "pebble", "flower", "acorn", "twig"]
const ROOFTOP_ITEMS: Array[String] = ["leaf", "pebble", "feather", "bottle_cap", "bolt"]
const SUPERMARKET_ITEMS: Array[String] = ["receipt", "grape", "price_tag", "coin_small", "crumbs"]
const HARBOR_ITEMS: Array[String] = ["shell", "starfish", "pebble", "rope_bit", "feather"]
const FACTORY_ITEMS: Array[String] = ["bolt", "bolt", "rag", "coin_small", "crumbs"]
const CEMETERY_ITEMS: Array[String] = ["leaf", "twig", "pebble", "feather", "leaf"]
const STATION_ITEMS: Array[String] = ["receipt", "coin_small", "bolt", "crumbs", "feather"]
const THEME_ITEMS := {"basement": BASEMENT_ITEMS, "garden": GARDEN_ITEMS, "rooftop": ROOFTOP_ITEMS,
	"supermarket": SUPERMARKET_ITEMS, "harbor": HARBOR_ITEMS, "factory": FACTORY_ITEMS, "cemetery": CEMETERY_ITEMS,
	"station": STATION_ITEMS}
## Zones per theme, from low noise to high noise.
const THEME_ZONES := {
	"apartment": ["kitchen", "living", "bedroom"],
	"basement": ["laundry", "concrete", "storage"],
	"garden": ["path", "lawn", "flowerbed"],
	"rooftop": ["deck", "tar", "tiles"],
	"supermarket": ["produce", "aisle", "freezer"],
	"harbor": ["beach", "dock", "pier"],
	"factory": ["storage_bay", "assembly", "conveyor"],
	"cemetery": ["gravel", "grave_lawn", "graves"],
	"station": ["hall", "platform", "tracks"],
}
const FURNITURE := {
	"living": ["sofa", "armchair", "coffee_table", "bookshelf", "tv", "floor_lamp", "plant", "cat_tree"],
	"kitchen": ["dining_table", "cat_bowls", "trash_bin", "counter", "dining_table"],
	"bedroom": ["bed", "nightstand", "wardrobe", "cat_bed", "bed", "floor_lamp"],
	"concrete": ["boiler", "pipes", "bike", "bulb", "paint_cans", "pipes"],
	"storage": ["shelf", "crates", "covered_sofa", "bulb", "crates", "shelf"],
		"laundry": ["washer", "washer", "drying_rack", "laundry_pile", "bulb"],
	"lawn": ["tree", "bush", "tree", "bench", "birdbath", "garden_lamp", "bush"],
	"path": ["garden_lamp", "wheelbarrow", "bush", "bench", "watering_can"],
	"flowerbed": ["flowers", "veggies", "flowers", "scarecrow", "compost", "veggies"],
	"tar": ["ac_unit", "vent_box", "antenna", "water_tank", "solar_panel", "roof_lamp"],
	"tiles": ["chimney", "skylight", "chimney", "antenna", "roof_lamp"],
	"deck": ["deck_chair", "potted_tree", "clothesline", "roof_lamp", "deck_chair", "potted_tree"],
	"aisle": ["store_shelf", "store_shelf", "price_sign", "cart_row", "shop_lamp", "store_shelf"],
	"produce": ["fruit_stand", "melon_bin", "fruit_stand", "price_sign", "shop_lamp"],
	"freezer": ["freezer_chest", "freezer_chest", "ice_block", "shop_lamp", "price_sign"],
	"beach": ["beach_umbrella", "towel", "sandcastle", "lifebuoy", "beach_umbrella"],
	"dock": ["bollard", "barrels", "crates", "rope_coil", "harbor_lamp", "fish_crate"],
	"pier": ["rope_coil", "lifebuoy", "fish_net", "bollard", "harbor_lamp", "fish_crate"],
	"storage_bay": ["pallet_stack", "pallet_stack", "barrels", "crates", "factory_lamp"],
	"assembly": ["machine", "robot_arm", "control_panel", "factory_lamp", "machine"],
	"conveyor": ["gear_pile", "robot_arm", "factory_lamp", "control_panel"],
	"grave_lawn": ["dead_tree", "gravestone", "bench", "grave_candle", "gravestone", "bush"],
	"gravel": ["grave_candle", "bench", "grave_cross", "gravestone"],
	"graves": ["gravestone", "grave_cross", "gravestone", "grave_candle", "crypt", "grave_cross"],
	"hall": ["bench", "ticket_machine", "station_lamp", "plant", "trash_bin"],
	"platform": ["bench", "station_lamp", "luggage", "ticket_machine", "trash_bin", "station_lamp"],
	"tracks": ["signal", "buffer_stop", "crates", "signal"],
}
const LAMPS := ["floor_lamp", "nightstand", "bulb", "garden_lamp", "roof_lamp", "shop_lamp", "harbor_lamp", "factory_lamp", "grave_candle", "station_lamp"]
const LAMP_COLOR := Color(1.0, 0.82, 0.55)

static var _light_texture: Texture2D

var layer := Layer.GROUND
var desc: Dictionary
## Where the lamp lights go (the chunk itself is baked into a texture).
var light_parent: Node2D


func _ready() -> void:
	# Real lights cost a lot on weak laptops: the effect saver leaves them out.
	if layer != Layer.DECOR or Settings.low_effects:
		return
	for f: Dictionary in desc["furniture"]:
		if f["kind"] in LAMPS:
			var light := PointLight2D.new()
			light.texture = _get_light_texture()
			light.texture_scale = 1.6
			light.energy = 0.9
			light.color = LAMP_COLOR
			light.position = f["pos"]
			(light_parent if light_parent != null else self).add_child(light)


static func _get_light_texture() -> Texture2D:
	if _light_texture == null:
		var gradient := Gradient.new()
		gradient.set_color(0, Color(1, 1, 1, 1))
		gradient.set_color(1, Color(1, 1, 1, 0))
		var tex := GradientTexture2D.new()
		tex.gradient = gradient
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(1.0, 0.5)
		tex.width = 128
		tex.height = 128
		_light_texture = tex
	return _light_texture


func _draw() -> void:
	match layer:
		Layer.GROUND:
			_draw_ground()
		Layer.DECOR:
			if desc.has("rug"):
				_draw_rug(desc["rug"])
			for item: Dictionary in desc["items"]:
				_draw_item(item)
			for f: Dictionary in desc["furniture"]:
				_draw_furniture(f)
		Layer.OVERLAY:
			if desc.has("moon"):
				_draw_moon(desc["moon"])
			for f: Dictionary in desc["furniture"]:
				if f["kind"] in LAMPS:
					for i in 4:
						draw_circle(f["pos"], 18.0 + i * 14.0, Color(LAMP_COLOR, 0.05))


# --- Ground -----------------------------------------------------------------

func _draw_ground() -> void:
	var size: float = desc["size"]
	var area := Rect2(Vector2.ZERO, Vector2(size, size))
	match desc["zone"]:
		"kitchen":
			_draw_tiles(size)
		"concrete", "storage", "laundry":
			_draw_concrete(size, desc["zone"])
		"lawn", "flowerbed", "grave_lawn", "graves":
			_draw_grass(size, desc["zone"])
		"path", "gravel":
			_draw_path(size)
		"hall":
			_draw_tiles(size)
		"platform":
			_draw_platform(size)
		"tracks":
			_draw_tracks(size)
		"tar":
			_draw_tar(size)
		"tiles":
			_draw_roof_tiles(size)
		"deck":
			_draw_deck(area)
		"bedroom":
			_draw_carpet(size)
		"aisle", "produce", "freezer":
			_draw_store_floor(size, desc["zone"])
		"beach":
			_draw_beach(size)
		"dock":
			_draw_dock(size)
		"pier":
			_draw_pier(area)
		"storage_bay", "assembly", "conveyor":
			_draw_factory(size, desc["zone"])
		_:
			_draw_planks(area)
	var strip := Color("3e2a1c")
	if desc["zone"] in ["lawn", "flowerbed", "path", "grave_lawn", "graves", "gravel"]:
		strip = Color(0.2, 0.3, 0.12, 0.35)
	elif desc["zone"] in ["tar", "tiles", "deck", "platform", "tracks", "hall"]:
		strip = Color("4a4a52")
	elif desc["zone"] in ["aisle", "produce", "freezer"]:
		strip = Color("8a9096")
	elif desc["zone"] in ["storage_bay", "assembly", "conveyor"]:
		strip = Color("c9a24a")
	elif desc["zone"] in ["beach", "dock", "pier"]:
		strip = Color(0.25, 0.3, 0.35, 0.35)
	if desc["edge_right"]:
		draw_rect(Rect2(size - 3, 0, 3, size), strip)
	if desc["edge_bottom"]:
		draw_rect(Rect2(0, size - 3, size, 3), strip)


func _draw_planks(area: Rect2) -> void:
	# Planks are laid out in world coordinates so they line up across chunks.
	var origin := position
	var row0 := floori(origin.y / PLANK.y)
	for r in int(area.size.y / PLANK.y):
		var row := row0 + r
		var shift := fposmod(row * 37.0, PLANK.x)
		var y := row * PLANK.y - origin.y
		var col0 := floori((origin.x - shift) / PLANK.x)
		var col1 := floori((origin.x + area.size.x - shift) / PLANK.x)
		for col in range(col0, col1 + 1):
			var x := col * PLANK.x + shift - origin.x
			var rect := Rect2(x, y, PLANK.x, PLANK.y).intersection(area)
			if rect.size.x <= 0.0:
				continue
			var h := hash(Vector2i(col, row))
			draw_rect(rect, WOOD.darkened((h % 9) * 0.015))
			if x >= 0.0:
				draw_line(Vector2(x, y), Vector2(x, y + PLANK.y), SEAM, 1.0)
			draw_line(Vector2(rect.position.x, y + PLANK.y - 1), Vector2(rect.end.x, y + PLANK.y - 1), SEAM, 1.0)
			if h % 7 == 0:
				var knot := Vector2(x + 12 + (h >> 4) % 70, y + PLANK.y * 0.5)
				if area.has_point(knot):
					draw_colored_polygon(Shapes.ellipse(knot, 3, 1.5, 8), Color("6d4530"))


func _draw_tiles(size: float) -> void:
	var t0 := Vector2i(floori(position.x / TILE), floori(position.y / TILE))
	var n := int(size / TILE)
	for ix in n:
		for iy in n:
			var odd := (t0.x + ix + t0.y + iy) % 2 != 0
			draw_rect(Rect2(ix * TILE, iy * TILE, TILE, TILE), Color("b7c4cc") if odd else Color("e9e2d0"))
	var grout := Color("8f9a9e")
	for i in n + 1:
		draw_line(Vector2(i * TILE, 0), Vector2(i * TILE, size), grout, 1.0)
		draw_line(Vector2(0, i * TILE), Vector2(size, i * TILE), grout, 1.0)


## Station platform: big concrete slabs with a yellow safety line.
func _draw_platform(size: float) -> void:
	draw_rect(Rect2(0, 0, size, size), Color("a8a49c"))
	var slab := 64.0
	var n := int(size / slab)
	for i in n + 1:
		draw_line(Vector2(i * slab, 0), Vector2(i * slab, size), Color("8e8a82"), 1.0)
		draw_line(Vector2(0, i * slab), Vector2(size, i * slab), Color("8e8a82"), 1.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = desc["seed"]
	for i in 60:
		draw_rect(Rect2(Vector2(rng.randf_range(0, size), rng.randf_range(0, size)), Vector2(1, 1)), Color("948f87"))
	# The safety line runs along the world, every few chunks.
	var y := fmod(-position.y, 512.0)
	if y < 0.0:
		y += 512.0
	if y < size:
		draw_rect(Rect2(0, y, size, 8), Color("e8c02a"))
		for x in range(0, int(size), 16):
			draw_rect(Rect2(x, y + 2, 8, 4), Color("c9a020"))


## Station tracks: gravel, sleepers and two shiny rails, lined up in world space.
func _draw_tracks(size: float) -> void:
	draw_rect(Rect2(0, 0, size, size), Color("7a7268"))
	var rng := RandomNumberGenerator.new()
	rng.seed = desc["seed"]
	for i in 220:
		draw_rect(Rect2(Vector2(rng.randf_range(0, size), rng.randf_range(0, size)), Vector2(2, 2)), Color("6a6258") if i % 2 else Color("8a8276"))
	var gauge := 128.0
	var y0 := fmod(-position.y, gauge)
	if y0 < 0.0:
		y0 += gauge
	var y := y0 - gauge
	while y < size:
		for x in range(0, int(size), 24):
			draw_rect(Rect2(x, y + 20, 10, 48), Color("5a3a24"))
		for ry: float in [y + 30.0, y + 58.0]:
			draw_rect(Rect2(0, ry, size, 4), Color("6a6a72"))
			draw_rect(Rect2(0, ry, size, 2), Color("c8c8d0"))
		y += gauge


func _draw_concrete(size: float, zone: String) -> void:
	var base := Color("6a6e72")
	if zone == "storage":
		base = Color("5a5650")
	elif zone == "laundry":
		base = Color("7a8288")
	draw_rect(Rect2(0, 0, size, size), base)
	var rng := RandomNumberGenerator.new()
	rng.seed = desc["seed"]
	# Stains and cracks.
	for i in 6:
		var p := Vector2(rng.randf_range(0, size), rng.randf_range(0, size))
		draw_colored_polygon(Shapes.ellipse(p, rng.randf_range(10, 34), rng.randf_range(6, 20), 12), base.darkened(rng.randf_range(0.05, 0.15)))
	for i in 3:
		var p := Vector2(rng.randf_range(0, size), rng.randf_range(0, size))
		var crack := PackedVector2Array([p])
		for k in 4:
			p += Vector2(rng.randf_range(-14, 14), rng.randf_range(4, 16))
			crack.append(p)
		draw_polyline(crack, base.darkened(0.35), 1.0)
	if zone == "laundry":
		# Large floor tiles with a drain in the middle of the chunk.
		for i in int(size / 64.0) + 1:
			draw_line(Vector2(i * 64, 0), Vector2(i * 64, size), base.darkened(0.2), 1.0)
			draw_line(Vector2(0, i * 64), Vector2(size, i * 64), base.darkened(0.2), 1.0)
		var mid := Vector2(size, size) * 0.5
		draw_circle(mid, 7.0, Color("3a3e42"))
		for k in 3:
			draw_line(mid + Vector2(-5, -3 + k * 3), mid + Vector2(5, -3 + k * 3), Color("6a6e72"), 1.0)
	elif zone == "storage":
		# Yellow-black hazard stripe across the chunk.
		draw_rect(Rect2(0, size * 0.5 - 3, size, 6), Color("c9a24a"))
		for x in range(0, int(size), 16):
			draw_colored_polygon(PackedVector2Array([Vector2(x, size * 0.5 - 3), Vector2(x + 8, size * 0.5 - 3), Vector2(x + 2, size * 0.5 + 3), Vector2(x - 6, size * 0.5 + 3)]), Color("2b2b2b"))


func _draw_carpet(size: float) -> void:
	draw_rect(Rect2(0, 0, size, size), Color("6f5f86"))
	var dot := Color("7d6d95")
	for iy in int(size / 8.0):
		var shift := 4.0 if iy % 2 == 0 else 0.0
		for ix in int(size / 8.0):
			draw_rect(Rect2(ix * 8.0 + shift, iy * 8.0, 1, 1), dot)


func _draw_grass(size: float, zone: String) -> void:
	var base: Color = {"lawn": Color("5e9e4a"), "grave_lawn": Color("3f5e38"), "graves": Color("4a3a30")}.get(zone, Color("6b4a32"))
	draw_rect(Rect2(0, 0, size, size), base)
	var rng := RandomNumberGenerator.new()
	rng.seed = desc["seed"]
	if zone == "lawn" or zone == "grave_lawn":
		# Mowing stripes in world space, then tufts.
		var stripe := 40.0
		var x0 := floori(position.x / stripe)
		for i in int(size / stripe) + 1:
			if (x0 + i) % 2 == 0:
				draw_rect(Rect2(i * stripe, 0, stripe, size), Color(1, 1, 1, 0.05))
		for i in 70:
			var p := Vector2(rng.randf_range(0, size), rng.randf_range(0, size))
			var c := base.darkened(0.2) if i % 2 else base.lightened(0.15)
			draw_line(p, p + Vector2(-1, -3), c, 1.0)
			draw_line(p, p + Vector2(1, -3), c, 1.0)
		for i in 5:
			var p := Vector2(rng.randf_range(4, size - 4), rng.randf_range(4, size - 4))
			draw_rect(Rect2(p, Vector2(2, 2)), [Color("f4f1ea"), Color("f2d14e"), Color("e07aa0")][i % 3])
	else:
		# Dug soil in rows.
		for y in range(8, int(size), 24):
			draw_rect(Rect2(0, y, size, 10), base.darkened(0.15))
			draw_line(Vector2(0, y), Vector2(size, y), base.lightened(0.1), 1.0)
		for i in 40:
			var p := Vector2(rng.randf_range(0, size), rng.randf_range(0, size))
			draw_rect(Rect2(p, Vector2(1, 1)), base.darkened(0.35))


func _draw_path(size: float) -> void:
	var base := Color("5e9e4a")
	draw_rect(Rect2(0, 0, size, size), base)
	# Gravel field with flagstones laid in world coordinates.
	draw_rect(Rect2(0, 0, size, size), Color("b8ab92"))
	var rng := RandomNumberGenerator.new()
	rng.seed = desc["seed"]
	for i in 160:
		var p := Vector2(rng.randf_range(0, size), rng.randf_range(0, size))
		draw_rect(Rect2(p, Vector2(1, 1)), Color("8f8370") if i % 2 else Color("d4c9b0"))
	var step := 40.0
	var t0 := Vector2i(floori(position.x / step), floori(position.y / step))
	for ix in int(size / step):
		for iy in int(size / step):
			var h := hash(t0 + Vector2i(ix, iy))
			var c := Vector2(ix + 0.5, iy + 0.5) * step + Vector2((h % 7) - 3, ((h >> 3) % 7) - 3)
			var poly := Shapes.ellipse(c, 15.0 + (h >> 6) % 4, 12.0 + (h >> 8) % 4, 7)
			draw_colored_polygon(poly, Color("9a948c").darkened((h % 5) * 0.03))
			draw_polyline(Shapes.closed(poly), Color("6f6a63"), 1.0)


func _draw_tar(size: float) -> void:
	var base := Color("3e3e46")
	draw_rect(Rect2(0, 0, size, size), base)
	var rng := RandomNumberGenerator.new()
	rng.seed = desc["seed"]
	for i in 120:
		var p := Vector2(rng.randf_range(0, size), rng.randf_range(0, size))
		draw_rect(Rect2(p, Vector2(1, 1)), base.lightened(0.15))
	# Seams of the roofing membrane.
	for y in range(0, int(size), 80):
		draw_line(Vector2(0, y), Vector2(size, y), base.darkened(0.3), 2.0)
		draw_line(Vector2(0, y + 2), Vector2(size, y + 2), base.lightened(0.08), 1.0)
	for i in 3:
		var p := Vector2(rng.randf_range(0, size), rng.randf_range(0, size))
		draw_colored_polygon(Shapes.ellipse(p, rng.randf_range(12, 30), rng.randf_range(8, 18), 12), Color(0.45, 0.55, 0.7, 0.25))


func _draw_roof_tiles(size: float) -> void:
	var base := Color("a8503a")
	draw_rect(Rect2(0, 0, size, size), base.darkened(0.3))
	var tile := Vector2(20, 14)
	var row0 := floori(position.y / tile.y)
	for r in int(size / tile.y) + 1:
		var row := row0 + r
		var shift := tile.x * 0.5 if row % 2 else 0.0
		for i in int(size / tile.x) + 2:
			var x := i * tile.x - shift
			var h := hash(Vector2i(i, row))
			var c := base.darkened((h % 6) * 0.03)
			var y := r * tile.y
			draw_rect(Rect2(x + 1, y, tile.x - 2, tile.y - 2), c)
			draw_line(Vector2(x + 1, y + tile.y - 3), Vector2(x + tile.x - 1, y + tile.y - 3), c.darkened(0.25), 1.0)
			draw_line(Vector2(x + 2, y + 1), Vector2(x + tile.x - 3, y + 1), c.lightened(0.15), 1.0)


func _draw_deck(area: Rect2) -> void:
	draw_rect(area, Color("9a7048"))
	var step := 12.0
	var x0 := floori(position.x / step)
	for i in int(area.size.x / step) + 1:
		var h := hash(Vector2i(x0 + i, 7))
		draw_rect(Rect2(i * step, 0, step - 1, area.size.y), Color("a47a50").darkened((h % 5) * 0.03))
		draw_line(Vector2(i * step + step - 1, 0), Vector2(i * step + step - 1, area.size.y), Color("6b4a30"), 1.0)
		for y in range(int(h % 40), int(area.size.y), 60):
			draw_rect(Rect2(i * step + 5, y, 1, 1), Color("4a3a2a"))


func _draw_store_floor(size: float, zone: String) -> void:
	var a := Color("dcd8cc")
	var b := Color("cac6ba")
	var step := 40.0
	if zone == "freezer":
		a = Color("d4e6ee")
		b = Color("bcd6e2")
		step = 32.0
	elif zone == "produce":
		a = Color("b88a5a")
		b = Color("a87c4e")
		step = 32.0
	var t0 := Vector2i(floori(position.x / step), floori(position.y / step))
	var n := int(size / step)
	for ix in n:
		for iy in n:
			var odd := (t0.x + ix + t0.y + iy) % 2 != 0
			draw_rect(Rect2(ix * step, iy * step, step, step), b if odd else a)
	for i in n + 1:
		draw_line(Vector2(i * step, 0), Vector2(i * step, size), a.darkened(0.2), 1.0)
		draw_line(Vector2(0, i * step), Vector2(size, i * step), a.darkened(0.2), 1.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = desc["seed"]
	if zone == "aisle":
		# Polished floor: long reflections of the ceiling lights.
		for i in 3:
			draw_rect(Rect2(rng.randf_range(0, size - 6), 0, 6, size), Color(1, 1, 1, 0.12))
	elif zone == "freezer":
		for i in 50:
			var p := Vector2(rng.randf_range(0, size), rng.randf_range(0, size))
			draw_rect(Rect2(p, Vector2(1, 1)), Color(1, 1, 1, 0.8))
	else:
		# Squashed leaves and juice stains.
		for i in 6:
			var p := Vector2(rng.randf_range(0, size), rng.randf_range(0, size))
			draw_colored_polygon(Shapes.ellipse(p, rng.randf_range(4, 10), rng.randf_range(3, 6), 8), Color(0.35, 0.5, 0.2, 0.25))


func _draw_beach(size: float) -> void:
	var base := Color("e2cc94")
	draw_rect(Rect2(0, 0, size, size), base)
	var rng := RandomNumberGenerator.new()
	rng.seed = desc["seed"]
	# Ripples left by the wind, in world space so they line up across chunks.
	var y0 := fposmod(position.y, 22.0)
	for y in range(0, int(size) + 22, 22):
		var pts := PackedVector2Array()
		for x in range(0, int(size) + 16, 16):
			pts.append(Vector2(x, clampf(y - y0 + sin((x + position.x) * 0.05) * 3.0, 0.0, size)))
		draw_polyline(pts, base.darkened(0.08), 1.0)
	for i in 90:
		var p := Vector2(rng.randf_range(0, size), rng.randf_range(0, size))
		draw_rect(Rect2(p, Vector2(1, 1)), base.darkened(0.2) if i % 2 else base.lightened(0.2))
	# Puddles left by the tide.
	for i in 2:
		var p := Vector2(rng.randf_range(40, size - 40), rng.randf_range(30, size - 30))
		draw_colored_polygon(Shapes.ellipse(p, rng.randf_range(20, 36), rng.randf_range(10, 18), 14), Color(0.3, 0.55, 0.75, 0.25))


func _draw_dock(size: float) -> void:
	draw_rect(Rect2(0, 0, size, size), Color("4a4e54"))
	var stone := Vector2(40, 20)
	var row0 := floori(position.y / stone.y)
	for r in int(size / stone.y):
		var row := row0 + r
		var shift := stone.x * 0.5 if row % 2 else 0.0
		for i in int(size / stone.x) + 1:
			var x := i * stone.x - shift
			var h := hash(Vector2i(i, row))
			var rect := Rect2(x + 1, r * stone.y + 1, stone.x - 2, stone.y - 2).intersection(Rect2(0, 0, size, size))
			if rect.size.x > 0.0:
				draw_rect(rect, Color("767a80").darkened((h % 6) * 0.04))
	# Some chunks have the painted edge of the quay.
	if hash(Vector2i(floori(position.x), floori(position.y))) % 3 == 0:
		draw_rect(Rect2(0, size * 0.5 - 2, size, 4), Color("e0b84a"))


func _draw_pier(area: Rect2) -> void:
	# Boards across the pier with dark water showing through the gaps.
	draw_rect(area, Color("1f4a6a"))
	var step := 14.0
	var y0 := floori(position.y / step)
	for i in int(area.size.y / step) + 1:
		var h := hash(Vector2i(9, y0 + i))
		var board := Rect2(0, i * step, area.size.x, step - 3).intersection(area)
		if board.size.y <= 0.0:
			continue
		draw_rect(board, Color("7a5a3a").darkened((h % 5) * 0.04))
		for x in range(int(h % 50), int(area.size.x), 70):
			draw_rect(Rect2(x, i * step + 4, 2, 2).intersection(area), Color("3a2a1a"))


func _draw_factory(size: float, zone: String) -> void:
	var base := Color("5a6068") if zone != "assembly" else Color("666a70")
	draw_rect(Rect2(0, 0, size, size), base)
	var step := 40.0
	var n := int(size / step)
	for ix in n:
		for iy in n:
			var p := Vector2(ix * step, iy * step)
			draw_rect(Rect2(p + Vector2(1, 1), Vector2(step - 2, step - 2)), base.lightened(0.05) if (ix + iy) % 2 == 0 else base)
			for corner: Vector2 in [Vector2(4, 4), Vector2(step - 4, 4), Vector2(4, step - 4), Vector2(step - 4, step - 4)]:
				# Rivets: little squares (hundreds of circles made the chunk slow to draw).
				draw_rect(Rect2(p + corner - Vector2(1.2, 1.2), Vector2(2.4, 2.4)), base.darkened(0.3))
	if zone == "conveyor":
		# Two belts across the chunk, arrows showing the way they run.
		for y: float in [size * 0.3, size * 0.7]:
			draw_rect(Rect2(0, y - 18, size, 36), Color("2a2c30"))
			draw_rect(Rect2(0, y - 20, size, 3), Color("c9a24a"))
			draw_rect(Rect2(0, y + 17, size, 3), Color("c9a24a"))
			for x in range(0, int(size), 32):
				draw_colored_polygon(PackedVector2Array([Vector2(x + 8, y - 6), Vector2(x + 18, y), Vector2(x + 8, y + 6)]), Color("4a4e54"))
	elif zone == "assembly":
		draw_rect(Rect2(0, size * 0.5 - 3, size, 6), Color("c9a24a"))
		for x in range(0, int(size), 16):
			draw_colored_polygon(PackedVector2Array([Vector2(x, size * 0.5 - 3), Vector2(x + 8, size * 0.5 - 3), Vector2(x + 2, size * 0.5 + 3), Vector2(x - 6, size * 0.5 + 3)]), Color("2b2b2b"))


# --- Decor ------------------------------------------------------------------

func _draw_rug(rug: Dictionary) -> void:
	var r: Rect2 = rug["rect"]
	var color: Color = rug["color"]
	var c := r.get_center()
	if rug["oval"]:
		for i in 5:
			var k := 1.0 - i * 0.18
			var ring := color if i % 2 == 0 else color.lightened(0.25)
			draw_colored_polygon(Shapes.ellipse(c, r.size.x * 0.5 * k, r.size.y * 0.5 * k, 32), ring)
		draw_polyline(Shapes.closed(Shapes.ellipse(c, r.size.x * 0.5, r.size.y * 0.5, 32)), color.darkened(0.4), 1.0)
		return
	for y in range(int(r.position.y) + 2, int(r.end.y) - 1, 3):
		draw_line(Vector2(r.position.x - 4, y), Vector2(r.position.x, y), Color("e8dcc0"), 1.0)
		draw_line(Vector2(r.end.x, y), Vector2(r.end.x + 4, y), Color("e8dcc0"), 1.0)
	draw_rect(r, color.darkened(0.25))
	var inner := r.grow(-6)
	draw_rect(inner, color)
	draw_rect(inner, color.lightened(0.3), false, 1.0)
	for i in range(1, 4):
		var x := inner.position.x + inner.size.x * i / 4.0
		draw_line(Vector2(x, inner.position.y + 4), Vector2(x, inner.end.y - 4), color.lightened(0.18), 2.0)
	var diamond := PackedVector2Array([c + Vector2(0, -12), c + Vector2(16, 0), c + Vector2(0, 12), c + Vector2(-16, 0)])
	draw_colored_polygon(diamond, color.lightened(0.3))


func _draw_moon(moon: Dictionary) -> void:
	# Moonlight falling through a 2x2 window, skewed.
	var pos: Vector2 = moon["pos"]
	var size: Vector2 = moon["size"]
	var skew := Vector2(size.y * 0.5, 0)
	var light := Color(0.72, 0.82, 1.0, 0.16)
	var pane := (size - Vector2(4, 4)) * 0.5
	for ix in 2:
		for iy in 2:
			var p := pos + Vector2(ix * (pane.x + 4), iy * (pane.y + 4))
			var top := p + skew * (iy * (pane.y + 4) / size.y)
			var bottom_skew := skew * ((iy * (pane.y + 4) + pane.y) / size.y)
			draw_colored_polygon(PackedVector2Array([
				top, top + Vector2(pane.x, 0),
				p + Vector2(pane.x, pane.y) + bottom_skew, p + Vector2(0, pane.y) + bottom_skew,
			]), light)


func _draw_item(item: Dictionary) -> void:
	var color: Color = item["color"]
	draw_set_transform(item["pos"], item["rot"])
	match item["kind"]:
		"mouse":
			draw_line(Vector2(-5, 0), Vector2(-10, -2), Color("d9a0a8"), 1.0)
			draw_colored_polygon(Shapes.ellipse(Vector2.ZERO, 5, 3), Color("9a9a9a"))
			draw_polyline(Shapes.closed(Shapes.ellipse(Vector2.ZERO, 5, 3)), OUTLINE, 1.0)
			draw_circle(Vector2(2, -3), 1.5, Color("d9a0a8"))
			draw_rect(Rect2(3, -1, 1, 1), OUTLINE)
		"book":
			draw_rect(Rect2(-7, -5, 14, 10), color)
			draw_rect(Rect2(-7, 3, 14, 2), Color("efe6d0"))
			draw_rect(Rect2(-7, -5, 14, 10), OUTLINE, false, 1.0)
		"ball":
			draw_circle(Vector2.ZERO, 4.0, OUTLINE)
			draw_circle(Vector2.ZERO, 3.0, color.lightened(0.2))
			draw_rect(Rect2(-1, -2, 1, 1), Color(1, 1, 1, 0.8))
		"feather":
			draw_line(Vector2(-7, 2), Vector2(7, -2), Color("e8e0d0"), 1.0)
			for i in 5:
				var x := -4.0 + i * 2.5
				draw_line(Vector2(x, 1 - i * 0.6), Vector2(x - 2, -2 - i * 0.6), color.lightened(0.4), 1.0)
				draw_line(Vector2(x, 1 - i * 0.6), Vector2(x - 1, 4 - i * 0.6), color.lightened(0.4), 1.0)
		"crumbs":
			for p: Vector2 in [Vector2(-3, 0), Vector2(1, -2), Vector2(3, 2), Vector2(-1, 3)]:
				draw_rect(Rect2(p, Vector2(1, 1)), Color("d8b77a"))
		"cobweb":
			for i in 5:
				draw_line(Vector2.ZERO, Vector2.from_angle(i * 0.4) * 14.0, Color(1, 1, 1, 0.35), 1.0)
			for r: float in [5.0, 9.0, 13.0]:
				draw_arc(Vector2.ZERO, r, 0.0, 1.6, 6, Color(1, 1, 1, 0.3), 1.0)
		"bolt":
			draw_circle(Vector2.ZERO, 2.5, Color("4a4e52"))
			draw_rect(Rect2(-1, -1, 2, 2), Color("9aa0a6"))
		"rag":
			draw_colored_polygon(PackedVector2Array([Vector2(-6, -3), Vector2(4, -5), Vector2(7, 2), Vector2(-2, 5), Vector2(-7, 2)]), color.darkened(0.2))
		"leaf":
			var leaf := PackedVector2Array([Vector2(-5, 0), Vector2(0, -3), Vector2(5, 0), Vector2(0, 3)])
			draw_colored_polygon(leaf, [Color("c9a24a"), Color("d9743a"), Color("8a9a3a")][int(absf(item["rot"]) * 10.0) % 3])
			draw_line(Vector2(-5, 0), Vector2(5, 0), Color(0, 0, 0, 0.25), 1.0)
		"pebble":
			draw_colored_polygon(Shapes.ellipse(Vector2.ZERO, 3, 2, 8), Color("9a948c"))
			draw_rect(Rect2(-1, -1, 1, 1), Color("c9c4bc"))
		"flower":
			for k in 5:
				draw_circle(Vector2.from_angle(TAU * k / 5.0) * 2.5, 1.8, color.lightened(0.4))
			draw_circle(Vector2.ZERO, 1.5, Color("f2d14e"))
		"acorn":
			draw_colored_polygon(Shapes.ellipse(Vector2(0, 1), 2.5, 3, 8), Color("b07a3a"))
			draw_rect(Rect2(-3, -3, 6, 2), Color("6b4630"))
		"twig":
			draw_line(Vector2(-7, 1), Vector2(7, -1), Color("6b4630"), 1.0)
			draw_line(Vector2(1, 0), Vector2(4, -4), Color("6b4630"), 1.0)
		"bottle_cap":
			draw_circle(Vector2.ZERO, 3.0, OUTLINE)
			draw_circle(Vector2.ZERO, 2.2, color.lightened(0.2))
		"jar":
			draw_circle(Vector2.ZERO, 4.0, OUTLINE)
			draw_circle(Vector2.ZERO, 3.0, Color(0.7, 0.85, 0.7, 0.8))
			draw_rect(Rect2(-2, -1, 1, 1), Color.WHITE)
		"receipt":
			draw_rect(Rect2(-3, -6, 6, 12), Color("f4f1ea"))
			for k in 4:
				draw_line(Vector2(-2, -4 + k * 3), Vector2(2, -4 + k * 3), Color("9aa0a6"), 1.0)
		"grape":
			for p: Vector2 in [Vector2(-2, -2), Vector2(2, -2), Vector2(0, 1), Vector2(-2, 3), Vector2(2, 3)]:
				draw_circle(p, 1.8, Color("7a4a9a"))
		"price_tag":
			draw_colored_polygon(PackedVector2Array([Vector2(-5, -3), Vector2(3, -3), Vector2(6, 0), Vector2(3, 3), Vector2(-5, 3)]), Color("f2d14e"))
			draw_circle(Vector2(3, 0), 0.8, OUTLINE)
		"coin_small":
			draw_circle(Vector2.ZERO, 2.5, Color("a07a2a"))
			draw_circle(Vector2.ZERO, 1.8, Color("f2c14e"))
		"shell":
			draw_colored_polygon(PackedVector2Array([Vector2(0, 3), Vector2(-4, -1), Vector2(-2, -4), Vector2(2, -4), Vector2(4, -1)]), Color("f0d8c8"))
			for k in 3:
				draw_line(Vector2(0, 3), Vector2(-2 + k * 2, -4), Color("c9a08a"), 1.0)
		"starfish":
			var star := PackedVector2Array()
			for k in 10:
				star.append(Vector2.from_angle(TAU * k / 10.0 - PI * 0.5) * (5.0 if k % 2 == 0 else 2.0))
			draw_colored_polygon(star, Color("f2a03a"))
		"rope_bit":
			draw_polyline(PackedVector2Array([Vector2(-6, 0), Vector2(-2, -2), Vector2(2, 1), Vector2(6, -1)]), Color("c9a26a"), 1.5)
	draw_set_transform(Vector2.ZERO)


# --- Furniture (top-down, drawn centred on the origin) -----------------------

func _draw_furniture(f: Dictionary) -> void:
	var color: Color = f["color"]
	draw_set_transform(f["pos"], f["rot"])
	match f["kind"]:
		"sofa":
			_box(Rect2(-56, -22, 112, 44), color.darkened(0.2))
			_box(Rect2(-56, -22, 112, 12), color.darkened(0.35))
			for i in 3:
				_box(Rect2(-44 + i * 30, -10, 28, 28), color)
				draw_line(Vector2(-40 + i * 30, -6), Vector2(-24 + i * 30, -6), color.lightened(0.2), 1.0)
			_box(Rect2(-56, -22, 10, 44), color.darkened(0.3))
			_box(Rect2(46, -22, 10, 44), color.darkened(0.3))
		"armchair":
			_box(Rect2(-22, -22, 44, 44), color.darkened(0.2))
			_box(Rect2(-22, -22, 44, 11), color.darkened(0.35))
			_box(Rect2(-14, -10, 28, 28), color)
			_box(Rect2(-22, -22, 8, 44), color.darkened(0.3))
			_box(Rect2(14, -22, 8, 44), color.darkened(0.3))
		"coffee_table":
			_box(Rect2(-32, -18, 64, 36), WOOD_DARK)
			draw_rect(Rect2(-28, -14, 56, 28), WOOD)
			draw_circle(Vector2(14, -2), 5.0, OUTLINE)
			draw_circle(Vector2(14, -2), 4.0, Color("efe6d0"))
			draw_circle(Vector2(14, -2), 2.5, Color("5a3a26"))
			_box(Rect2(-22, -8, 18, 14), color.lightened(0.2))
		"bookshelf":
			_box(Rect2(-55, -11, 110, 22), WOOD_DARK)
			var rng := RandomNumberGenerator.new()
			rng.seed = int(f["pos"].x * 31 + f["pos"].y)
			var x := -52.0
			while x < 50.0:
				var w := rng.randf_range(3, 7)
				draw_rect(Rect2(x, -8, w - 1, 16), RUG_COLORS[rng.randi() % RUG_COLORS.size()].lightened(rng.randf() * 0.3))
				x += w
		"tv":
			_box(Rect2(-45, -11, 90, 22), WOOD_DARK)
			_box(Rect2(-36, -14, 72, 7), Color("1d1d24"))
			draw_line(Vector2(-30, -11), Vector2(30, -11), Color("4a5a7a"), 1.0)
			draw_circle(Vector2(30, 4), 3.0, Color("2a2a30"))
		"floor_lamp":
			draw_circle(Vector2.ZERO, 13.0, OUTLINE)
			draw_circle(Vector2.ZERO, 12.0, Color("f3e3b8"))
			draw_circle(Vector2.ZERO, 6.0, Color("fff3c8"))
		"plant":
			draw_circle(Vector2.ZERO, 13.0, OUTLINE)
			draw_circle(Vector2.ZERO, 12.0, Color("b5603a"))
			for i in 7:
				var a := TAU * i / 7.0
				var tip := Vector2.from_angle(a) * 22.0
				var side := Vector2.from_angle(a + PI * 0.5) * 5.0
				var leaf := PackedVector2Array([Vector2.ZERO, tip * 0.5 + side, tip, tip * 0.5 - side])
				draw_colored_polygon(leaf, Color("4f8f3e") if i % 2 == 0 else Color("5ea84a"))
				draw_polyline(Shapes.closed(leaf), OUTLINE, 1.0)
		"cat_tree":
			_box(Rect2(-24, -24, 48, 48), Color("d8c8a8"))
			for p: Vector2 in [Vector2(-14, -14), Vector2(14, 14)]:
				draw_circle(p, 6.0, OUTLINE)
				draw_circle(p, 5.0, Color("c9a26a"))
			draw_circle(Vector2(8, -8), 13.0, OUTLINE)
			draw_circle(Vector2(8, -8), 12.0, color.lightened(0.2))
			draw_line(Vector2(-12, 10), Vector2(-12, 22), Color("e04646"), 1.0)
			draw_circle(Vector2(-12, 22), 2.5, Color("e04646"))
		"dining_table":
			for chair: Vector2 in [Vector2(-22, -38), Vector2(22, -38), Vector2(-22, 38), Vector2(22, 38)]:
				_box(Rect2(chair - Vector2(9, 9), Vector2(18, 18)), WOOD)
			_box(Rect2(-46, -28, 92, 56), WOOD_DARK)
			draw_rect(Rect2(-42, -24, 84, 48), WOOD)
			for plate: Vector2 in [Vector2(-22, -14), Vector2(22, -14), Vector2(-22, 14), Vector2(22, 14)]:
				draw_circle(plate, 7.0, Color("f4f1ea"))
				draw_circle(plate, 4.0, Color("e2ddd0"))
		"cat_bowls":
			_box(Rect2(-24, -12, 48, 24), color.lightened(0.3))
			for b: Vector2 in [Vector2(-11, 0), Vector2(11, 0)]:
				draw_circle(b, 8.0, OUTLINE)
				draw_circle(b, 7.0, Color("d9d9e0"))
			draw_circle(Vector2(11, 0), 5.0, Color("6fb0e0"))
			for k: Vector2 in [Vector2(-13, -1), Vector2(-10, 1), Vector2(-9, -2), Vector2(-12, 2)]:
				draw_rect(Rect2(k, Vector2(2, 2)), Color("9a6a3a"))
		"trash_bin":
			draw_circle(Vector2.ZERO, 11.0, OUTLINE)
			draw_circle(Vector2.ZERO, 10.0, Color("8a9096"))
			draw_line(Vector2(-6, 0), Vector2(6, 0), Color("5f6468"), 2.0)
		"counter":
			_box(Rect2(-56, -18, 112, 36), Color("c9ced2"))
			_box(Rect2(-46, -11, 30, 22), Color("9fb2bf"))
			draw_circle(Vector2(-31, 0), 2.0, Color("6a7a85"))
			for p: Vector2 in [Vector2(14, -7), Vector2(34, -7), Vector2(14, 7), Vector2(34, 7)]:
				draw_circle(p, 6.0, Color("2a2a30"))
				draw_arc(p, 4.0, 0.0, TAU, 12, Color("5a5a64"), 1.0)
		"bed":
			_box(Rect2(-46, -62, 92, 124), WOOD_DARK)
			draw_rect(Rect2(-42, -58, 84, 116), Color("f1ece2"))
			_box(Rect2(-38, -54, 34, 20), Color("ffffff"))
			_box(Rect2(4, -54, 34, 20), Color("ffffff"))
			_box(Rect2(-42, -24, 84, 82), color)
			draw_line(Vector2(-42, -18), Vector2(42, -18), color.lightened(0.3), 2.0)
		"nightstand":
			_box(Rect2(-14, -14, 28, 28), WOOD)
			draw_circle(Vector2.ZERO, 8.0, OUTLINE)
			draw_circle(Vector2.ZERO, 7.0, Color("f3e3b8"))
			draw_circle(Vector2.ZERO, 3.0, Color("fff3c8"))
		"wardrobe":
			_box(Rect2(-55, -16, 110, 32), WOOD_DARK)
			draw_line(Vector2(0, -16), Vector2(0, 16), OUTLINE, 1.0)
			draw_rect(Rect2(-5, -2, 2, 4), Color("f2c14e"))
			draw_rect(Rect2(3, -2, 2, 4), Color("f2c14e"))
		"boiler":
			_box(Rect2(-30, -30, 60, 60), Color("8a8f94"))
			draw_circle(Vector2.ZERO, 22.0, OUTLINE)
			draw_circle(Vector2.ZERO, 21.0, Color("b0b5ba"))
			draw_circle(Vector2(8, -8), 6.0, Color("e8e2d0"))
			draw_line(Vector2(8, -8), Vector2(11, -11), Color("e04646"), 1.0)
			draw_rect(Rect2(-4, 30, 8, 40), Color("9a6a4a"))
			draw_rect(Rect2(-4, 30, 8, 40), OUTLINE, false, 1.0)
		"pipes":
			for k in 2:
				var y := -6.0 + k * 10.0
				draw_rect(Rect2(-90, y - 3, 180, 6), OUTLINE)
				draw_rect(Rect2(-89, y - 2, 178, 4), Color("9a6a4a") if k == 0 else Color("8a9096"))
				for x: float in [-60.0, 0.0, 60.0]:
					draw_rect(Rect2(x - 3, y - 4, 6, 8), Color("5a5e62"))
		"bike":
			for w: Vector2 in [Vector2(-20, 0), Vector2(20, 0)]:
				draw_arc(w, 12.0, 0.0, TAU, 20, OUTLINE, 3.0)
				draw_arc(w, 12.0, 0.0, TAU, 20, Color("3a3a3a"), 1.0)
			draw_polyline(PackedVector2Array([Vector2(-20, 0), Vector2(-4, -10), Vector2(14, -10), Vector2(20, 0), Vector2(0, 0), Vector2(-4, -10)]), color, 2.0)
			draw_line(Vector2(14, -10), Vector2(16, -16), OUTLINE, 2.0)
		"bulb":
			draw_line(Vector2(0, -60), Vector2(0, -6), Color(0, 0, 0, 0.35), 1.0)
			draw_circle(Vector2.ZERO, 6.0, OUTLINE)
			draw_circle(Vector2.ZERO, 5.0, Color("fff3c8"))
		"paint_cans":
			for c: Vector2 in [Vector2(-10, -4), Vector2(4, -6), Vector2(-2, 8)]:
				draw_circle(c, 7.0, OUTLINE)
				draw_circle(c, 6.0, Color("c9ced2"))
				draw_circle(c, 3.0, color)
		"shelf":
			_box(Rect2(-60, -14, 120, 28), Color("6b4630"))
			var shelf_rng := RandomNumberGenerator.new()
			shelf_rng.seed = int(f["pos"].x * 17 + f["pos"].y)
			for i in 10:
				var jar := Vector2(-54 + i * 12, shelf_rng.randf_range(-6, 6))
				draw_circle(jar, 4.5, OUTLINE)
				draw_circle(jar, 3.5, RUG_COLORS[shelf_rng.randi() % RUG_COLORS.size()].lightened(0.3))
		"crates":
			for b: Vector2 in [Vector2(-34, -18), Vector2(0, -18), Vector2(-17, 12)]:
				_box(Rect2(b, Vector2(32, 28)), Color("8a6a42"))
				draw_line(b, b + Vector2(32, 28), Color("5e4630"), 1.0)
				draw_line(b + Vector2(32, 0), b + Vector2(0, 28), Color("5e4630"), 1.0)
		"covered_sofa":
			_box(Rect2(-56, -24, 112, 48), Color("d8d2c4"))
			for x: float in [-30.0, 0.0, 30.0]:
				draw_line(Vector2(x, -22), Vector2(x + 6, 22), Color("b8b2a4"), 1.0)
		"washer":
			_box(Rect2(-22, -22, 44, 44), Color("e8ecef"))
			draw_circle(Vector2(0, 3), 14.0, OUTLINE)
			draw_circle(Vector2(0, 3), 13.0, Color("9fb2bf"))
			draw_circle(Vector2(0, 3), 9.0, Color("6f8a9a"))
			draw_rect(Rect2(-18, -19, 10, 4), Color("5aa9e6"))
		"drying_rack":
			draw_rect(Rect2(-40, -16, 80, 32), Color(0, 0, 0, 0.15))
			for y: float in [-12.0, -4.0, 4.0, 12.0]:
				draw_line(Vector2(-40, y), Vector2(40, y), Color("c9ced2"), 1.0)
			var i := 0
			for cloth: Rect2 in [Rect2(-30, -14, 14, 10), Rect2(-6, -6, 18, 12), Rect2(16, 2, 14, 12)]:
				draw_rect(cloth, RUG_COLORS[i % RUG_COLORS.size()].lightened(0.25))
				i += 1
		"laundry_pile":
			for k in 5:
				var c := Vector2(-12 + k * 6, -4 + (k % 2) * 7)
				draw_colored_polygon(Shapes.ellipse(c, 10, 6, 10), RUG_COLORS[k % RUG_COLORS.size()].lightened(0.2))
		"tree":
			draw_circle(Vector2(6, 8), 40.0, Color(0, 0, 0, 0.2))
			for k in 6:
				var c := Vector2.from_angle(TAU * k / 6.0) * 18.0
				draw_circle(c, 22.0, OUTLINE)
			for k in 6:
				var c := Vector2.from_angle(TAU * k / 6.0) * 18.0
				draw_circle(c, 21.0, Color("3f7a34"))
			draw_circle(Vector2.ZERO, 26.0, Color("4f8f3e"))
			for k in 5:
				draw_circle(Vector2.from_angle(TAU * k / 5.0 + 0.6) * 14.0 + Vector2(-4, -4), 7.0, Color("6aae52"))
			if color == RUG_COLORS[0]:
				for k in 4:
					draw_circle(Vector2.from_angle(k * 1.7) * 20.0, 3.0, Color("d9443a"))
		"bush":
			for c: Vector2 in [Vector2(-10, 2), Vector2(9, 3), Vector2(0, -7)]:
				draw_circle(c, 13.0, OUTLINE)
			for c: Vector2 in [Vector2(-10, 2), Vector2(9, 3), Vector2(0, -7)]:
				draw_circle(c, 12.0, Color("3f7a34"))
				draw_circle(c + Vector2(-3, -3), 6.0, Color("5ea84a"))
		"bench":
			_box(Rect2(-40, -12, 80, 24), WOOD)
			for x: float in [-38.0, -26.0, -14.0, -2.0, 10.0, 22.0]:
				draw_line(Vector2(x + 11, -12), Vector2(x + 11, 12), WOOD_DARK, 1.0)
			_box(Rect2(-40, -16, 80, 5), Color("3a3a40"))
		"ticket_machine":
			_box(Rect2(-14, -20, 28, 36), Color("c0392b"))
			draw_rect(Rect2(-9, -15, 18, 10), Color("8fd0f0"))
			draw_rect(Rect2(-6, 0, 12, 3), Color("2a2a30"))
			draw_rect(Rect2(-6, 7, 12, 5), Color("f4f1ea"))
		"luggage":
			_box(Rect2(-14, -10, 28, 20), Color("8a5a34"))
			draw_rect(Rect2(-5, -14, 10, 4), OUTLINE)
			draw_line(Vector2(-14, 0), Vector2(14, 0), Color("6a4428"), 2.0)
			_box(Rect2(10, -4, 14, 12), Color("3a6ac8"))
		"signal":
			draw_rect(Rect2(-2, -30, 4, 40), OUTLINE)
			_box(Rect2(-8, -42, 16, 22), Color("2a2a30"))
			draw_circle(Vector2(0, -36), 4.0, Color("e24b4a"))
			draw_circle(Vector2(0, -26), 4.0, Color("3a4a3a"))
		"buffer_stop":
			_box(Rect2(-30, -10, 60, 20), Color("c0392b"))
			for x: float in [-26.0, -10.0, 6.0, 22.0]:
				draw_rect(Rect2(x, -10, 6, 20), Color("f4f1ea"))
			draw_circle(Vector2(-18, 12), 5.0, Color("3a3a40"))
			draw_circle(Vector2(18, 12), 5.0, Color("3a3a40"))
		"gravestone":
			draw_rect(Rect2(-14, 6, 28, 6), Color(0, 0, 0, 0.25))
			draw_circle(Vector2(0, -16), 13.0, OUTLINE)
			draw_rect(Rect2(-13, -16, 26, 26), OUTLINE)
			draw_circle(Vector2(0, -16), 12.0, Color("8a8a92"))
			draw_rect(Rect2(-12, -16, 24, 25), Color("8a8a92"))
			draw_rect(Rect2(-12, -16, 4, 25), Color("9e9ea8"))
			draw_line(Vector2(-6, -14), Vector2(6, -14), Color("5a5a62"), 2.0)
			draw_line(Vector2(-6, -8), Vector2(6, -8), Color("5a5a62"), 2.0)
			draw_line(Vector2(3, -2), Vector2(6, 4), Color("5a5a62"), 1.0)
			draw_rect(Rect2(-16, 8, 32, 4), Color("3f5e38"))
		"grave_cross":
			draw_rect(Rect2(-12, 10, 24, 4), Color(0, 0, 0, 0.25))
			draw_rect(Rect2(-4, -30, 8, 42), OUTLINE)
			draw_rect(Rect2(-13, -22, 26, 8), OUTLINE)
			draw_rect(Rect2(-3, -29, 6, 40), Color("9a9aa2"))
			draw_rect(Rect2(-12, -21, 24, 6), Color("9a9aa2"))
			draw_rect(Rect2(-3, -29, 2, 40), Color("b0b0b8"))
		"dead_tree":
			draw_circle(Vector2(4, 6), 16.0, Color(0, 0, 0, 0.2))
			for b: Array in [[Vector2(0, 8), Vector2(0, -30), 6.0], [Vector2(0, -12), Vector2(-18, -28), 3.0], [Vector2(0, -18), Vector2(16, -34), 3.0],
					[Vector2(-10, -20), Vector2(-14, -36), 2.0], [Vector2(8, -26), Vector2(20, -24), 2.0]]:
				draw_line(b[0], b[1], OUTLINE, b[2] + 2.0)
				draw_line(b[0], b[1], Color("4a3a36"), b[2])
		"grave_candle":
			draw_rect(Rect2(-4, -4, 8, 10), OUTLINE)
			draw_rect(Rect2(-3, -3, 6, 8), Color("f4ecd4"))
			draw_circle(Vector2(0, -8), 3.5, Color("ff9a2a"))
			draw_circle(Vector2(0, -8), 2.0, Color("fff3c8"))
		"crypt":
			draw_rect(Rect2(-34, 20, 72, 8), Color(0, 0, 0, 0.25))
			_box(Rect2(-34, -20, 68, 42), Color("6a6a72"))
			draw_colored_polygon(PackedVector2Array([Vector2(-40, -18), Vector2(0, -42), Vector2(40, -18)]), OUTLINE)
			draw_colored_polygon(PackedVector2Array([Vector2(-36, -19), Vector2(0, -39), Vector2(36, -19)]), Color("4a4a52"))
			_box(Rect2(-10, -2, 20, 24), Color("2a2a30"))
			draw_rect(Rect2(-2, -34, 4, 10), Color("9a9aa2"))
			draw_rect(Rect2(-6, -31, 12, 3), Color("9a9aa2"))
		"birdbath":
			draw_circle(Vector2.ZERO, 17.0, OUTLINE)
			draw_circle(Vector2.ZERO, 16.0, Color("c9c4bc"))
			draw_circle(Vector2.ZERO, 12.0, Color("6fb0e0"))
			draw_rect(Rect2(-5, -6, 3, 2), Color(1, 1, 1, 0.7))
		"garden_lamp", "roof_lamp", "shop_lamp", "harbor_lamp", "factory_lamp", "station_lamp":
			draw_circle(Vector2.ZERO, 8.0, OUTLINE)
			draw_circle(Vector2.ZERO, 7.0, Color("3a3a40"))
			draw_circle(Vector2.ZERO, 4.0, Color("fff3c8"))
		"wheelbarrow":
			_box(Rect2(-20, -14, 34, 28), Color("4a8ac4"))
			draw_rect(Rect2(-16, -10, 26, 20), Color("6b4a32"))
			draw_line(Vector2(-20, -10), Vector2(-36, -12), OUTLINE, 2.0)
			draw_line(Vector2(-20, 10), Vector2(-36, 12), OUTLINE, 2.0)
			draw_circle(Vector2(18, 0), 6.0, OUTLINE)
			draw_circle(Vector2(18, 0), 4.0, Color("3a3a40"))
		"watering_can":
			draw_line(Vector2(6, -2), Vector2(18, -8), OUTLINE, 3.0)
			draw_line(Vector2(6, -2), Vector2(18, -8), Color("5aa96a"), 1.0)
			draw_circle(Vector2.ZERO, 9.0, OUTLINE)
			draw_circle(Vector2.ZERO, 8.0, Color("5aa96a"))
			draw_circle(Vector2(-2, -2), 3.0, Color("7ac98a"))
		"flowers":
			var frng := RandomNumberGenerator.new()
			frng.seed = int(f["pos"].x * 13 + f["pos"].y)
			for k in 14:
				var p := Vector2(frng.randf_range(-36, 36), frng.randf_range(-22, 22))
				draw_circle(p, 4.0, Color("3f7a34"))
				var petal: Color = [Color("e07aa0"), Color("f2d14e"), Color("f4f1ea"), Color("9a7ad9"), Color("e05a4a")][frng.randi() % 5]
				for q in 4:
					draw_circle(p + Vector2.from_angle(q * PI * 0.5) * 2.2, 1.8, petal)
				draw_circle(p, 1.2, Color("f2c14e"))
		"veggies":
			for row in 3:
				var y := -16.0 + row * 16.0
				for k in 6:
					var p := Vector2(-40 + k * 16, y)
					if row == 1:
						draw_colored_polygon(Shapes.ellipse(p, 5, 5, 10), Color("e08a2a"))
						draw_line(p + Vector2(0, -5), p + Vector2(-2, -9), Color("4f8f3e"), 2.0)
					else:
						for q in 3:
							var leaf := Vector2.from_angle(q * TAU / 3.0 + k) * 5.0
							draw_colored_polygon(Shapes.ellipse(p + leaf, 4, 3, 8), Color("5ea84a"))
		"scarecrow":
			draw_line(Vector2(-22, 0), Vector2(22, 0), WOOD_DARK, 3.0)
			draw_line(Vector2(0, -6), Vector2(0, 28), WOOD_DARK, 3.0)
			_box(Rect2(-12, -4, 24, 16), color)
			draw_circle(Vector2(0, -12), 8.0, OUTLINE)
			draw_circle(Vector2(0, -12), 7.0, Color("e8d0a0"))
			draw_colored_polygon(Shapes.ellipse(Vector2(0, -18), 12, 4, 12), Color("c9a24a"))
			draw_rect(Rect2(-3, -13, 1, 1), OUTLINE)
			draw_rect(Rect2(2, -13, 1, 1), OUTLINE)
		"compost":
			_box(Rect2(-24, -20, 48, 40), WOOD_DARK)
			draw_rect(Rect2(-20, -16, 40, 32), Color("4a3a2a"))
			for k in 6:
				draw_rect(Rect2(-16 + k * 6, -10 + (k % 3) * 8, 3, 2), Color("8a9a3a"))
		"ac_unit":
			_box(Rect2(-26, -20, 52, 40), Color("c9ced2"))
			draw_circle(Vector2(-6, 0), 14.0, OUTLINE)
			draw_circle(Vector2(-6, 0), 13.0, Color("8a9096"))
			for k in 3:
				var a := TAU * k / 3.0 + float(f["rot"])
				draw_line(Vector2(-6, 0), Vector2(-6, 0) + Vector2.from_angle(a) * 11.0, Color("5a5e62"), 3.0)
			for y in range(-16, 18, 4):
				draw_line(Vector2(12, y), Vector2(22, y), Color("8a9096"), 1.0)
		"vent_box":
			_box(Rect2(-14, -14, 28, 28), Color("9aa0a6"))
			draw_circle(Vector2.ZERO, 9.0, OUTLINE)
			draw_circle(Vector2.ZERO, 8.0, Color("5a5e62"))
		"antenna":
			draw_line(Vector2(0, -40), Vector2(0, 30), OUTLINE, 3.0)
			draw_line(Vector2(0, -40), Vector2(0, 30), Color("9aa0a6"), 1.0)
			for k in 4:
				var y := -32.0 + k * 10.0
				var w := 22.0 - k * 4.0
				draw_line(Vector2(-w, y), Vector2(w, y), Color("9aa0a6"), 1.0)
			draw_circle(Vector2(0, -40), 2.0, Color("e04646"))
		"water_tank":
			draw_circle(Vector2(3, 4), 30.0, Color(0, 0, 0, 0.2))
			draw_circle(Vector2.ZERO, 30.0, OUTLINE)
			draw_circle(Vector2.ZERO, 29.0, Color("8a6a4a"))
			for r: float in [22.0, 14.0]:
				draw_arc(Vector2.ZERO, r, 0.0, TAU, 24, Color("6b4a30"), 1.0)
			draw_circle(Vector2.ZERO, 6.0, Color("5a5e62"))
		"solar_panel":
			_box(Rect2(-40, -24, 80, 48), Color("2a3a6a"))
			for x in range(-30, 40, 10):
				draw_line(Vector2(x, -24), Vector2(x, 24), Color("6a8ac4"), 1.0)
			for y in range(-14, 24, 12):
				draw_line(Vector2(-40, y), Vector2(40, y), Color("6a8ac4"), 1.0)
			draw_line(Vector2(-36, -20), Vector2(-10, -20), Color(1, 1, 1, 0.35), 2.0)
		"chimney":
			_box(Rect2(-18, -18, 36, 36), Color("a8503a"))
			for y in range(-14, 18, 8):
				draw_line(Vector2(-18, y), Vector2(18, y), Color("7a3a2a"), 1.0)
			draw_rect(Rect2(-12, -12, 24, 24), Color("2a2224"))
			draw_rect(Rect2(-12, -12, 24, 24), OUTLINE, false, 1.0)
		"skylight":
			_box(Rect2(-26, -20, 52, 40), Color("5a5e62"))
			draw_rect(Rect2(-22, -16, 44, 32), Color("8ab4d8"))
			draw_line(Vector2(0, -16), Vector2(0, 16), Color("5a5e62"), 2.0)
			draw_line(Vector2(-18, -12), Vector2(-8, -12), Color(1, 1, 1, 0.6), 1.0)
		"deck_chair":
			_box(Rect2(-14, -26, 28, 52), WOOD)
			for y in range(-20, 26, 8):
				draw_rect(Rect2(-12, y, 24, 4), color.lightened(0.2) if (y / 8) % 2 == 0 else Color("f4f1ea"))
		"potted_tree":
			_box(Rect2(-14, -14, 28, 28), Color("6b6e72"))
			for k in 5:
				var c := Vector2.from_angle(TAU * k / 5.0) * 9.0
				draw_circle(c, 10.0, OUTLINE)
			for k in 5:
				var c := Vector2.from_angle(TAU * k / 5.0) * 9.0
				draw_circle(c, 9.0, Color("4f8f3e"))
			draw_circle(Vector2(-3, -3), 7.0, Color("6aae52"))
		"clothesline":
			draw_line(Vector2(-70, 0), Vector2(70, 0), Color("e8e2d0"), 1.0)
			for p: Vector2 in [Vector2(-70, 0), Vector2(70, 0)]:
				draw_circle(p, 3.0, OUTLINE)
				draw_circle(p, 2.0, Color("9aa0a6"))
			var k := 0
			for cloth: Rect2 in [Rect2(-56, 0, 18, 22), Rect2(-24, 0, 26, 16), Rect2(16, 0, 14, 20), Rect2(40, 0, 20, 14)]:
				draw_rect(cloth, RUG_COLORS[(k + int(f["pos"].x)) % RUG_COLORS.size()].lightened(0.25))
				draw_rect(cloth, OUTLINE, false, 1.0)
				k += 1
		"store_shelf":
			_box(Rect2(-60, -14, 120, 28), Color("e8e4dc"))
			for i in 10:
				var c: Color = RUG_COLORS[(i + int(f["pos"].x)) % RUG_COLORS.size()].lightened(0.2)
				draw_rect(Rect2(-57 + i * 11.5, -11, 9, 9), c)
				draw_rect(Rect2(-57 + i * 11.5, 2, 9, 9), c.darkened(0.2))
			draw_line(Vector2(-60, 0), Vector2(60, 0), Color("9aa0a6"), 1.0)
		"cart_row":
			for k in 4:
				var o := Vector2(-30 + k * 10, 0)
				draw_rect(Rect2(o + Vector2(-12, -10), Vector2(24, 20)), Color(0.75, 0.78, 0.8, 0.5))
				draw_rect(Rect2(o + Vector2(-12, -10), Vector2(24, 20)), OUTLINE, false, 1.0)
			draw_line(Vector2(-42, -10), Vector2(-42, 10), Color("d9534f"), 2.0)
		"price_sign":
			_box(Rect2(-16, -10, 32, 20), Color("f2d14e"))
			draw_rect(Rect2(-12, -6, 14, 5), Color("d9534f"))
			draw_rect(Rect2(-12, 2, 24, 2), OUTLINE)
		"fruit_stand":
			_box(Rect2(-36, -24, 72, 48), WOOD)
			for i in 12:
				var p := Vector2(-28 + (i % 6) * 11, -12 + (i / 6) * 22)
				var c: Color = [Color("d9534f"), Color("f2a03a"), Color("8ac04a")][(i / 6 + absi(int(f["pos"].y))) % 3]
				for k in 3:
					draw_circle(p + Vector2(k % 2 * 4 - 2, k * 3 - 3), 4.0, c)
		"melon_bin":
			_box(Rect2(-24, -24, 48, 48), Color("6b4630"))
			for p: Vector2 in [Vector2(-10, -10), Vector2(10, -9), Vector2(-9, 10), Vector2(10, 10), Vector2(0, 0)]:
				draw_circle(p, 9.0, OUTLINE)
				draw_circle(p, 8.0, Color("4f8f3e"))
				draw_line(p + Vector2(-5, -3), p + Vector2(5, 3), Color("8ac04a"), 1.0)
		"freezer_chest":
			_box(Rect2(-50, -20, 100, 40), Color("f4f1ea"))
			draw_rect(Rect2(-46, -16, 92, 32), Color(0.6, 0.85, 1.0, 0.6))
			for k in 6:
				draw_rect(Rect2(-40 + k * 14, -12, 10, 8), RUG_COLORS[k % RUG_COLORS.size()].lightened(0.3))
			draw_line(Vector2(-46, 0), Vector2(46, 0), Color(1, 1, 1, 0.8), 1.0)
		"ice_block":
			_box(Rect2(-14, -14, 28, 28), Color("cfe8f4"))
			draw_line(Vector2(-10, -8), Vector2(6, -10), Color(1, 1, 1, 0.9), 1.0)
			draw_line(Vector2(-8, 6), Vector2(8, 2), Color(1, 1, 1, 0.6), 1.0)
		"beach_umbrella":
			for k in 8:
				var a0 := TAU * k / 8.0
				var tri := PackedVector2Array([Vector2.ZERO, Vector2.from_angle(a0) * 30.0, Vector2.from_angle(a0 + TAU / 8.0) * 30.0])
				draw_colored_polygon(tri, color.lightened(0.2) if k % 2 == 0 else Color("f4f1ea"))
			draw_polyline(Shapes.closed(Shapes.ellipse(Vector2.ZERO, 30, 30, 8)), OUTLINE, 1.0)
			draw_circle(Vector2.ZERO, 2.5, OUTLINE)
		"towel":
			_box(Rect2(-14, -28, 28, 56), color.lightened(0.2))
			for y in range(-24, 28, 10):
				draw_rect(Rect2(-14, y, 28, 4), Color("f4f1ea"))
		"sandcastle":
			draw_colored_polygon(Shapes.ellipse(Vector2.ZERO, 22, 22, 16), Color("c9b07a"))
			for p: Vector2 in [Vector2(-12, -12), Vector2(12, -12), Vector2(-12, 12), Vector2(12, 12)]:
				_box(Rect2(p - Vector2(6, 6), Vector2(12, 12)), Color("d8c08a"))
			_box(Rect2(-7, -7, 14, 14), Color("e2cc94"))
			draw_line(Vector2(0, -7), Vector2(0, -18), OUTLINE, 1.0)
			draw_rect(Rect2(0, -18, 6, 4), Color("d9534f"))
		"bollard":
			draw_circle(Vector2.ZERO, 9.0, OUTLINE)
			draw_circle(Vector2.ZERO, 8.0, Color("3a3a40"))
			draw_circle(Vector2(-2, -2), 3.0, Color("5a5a62"))
			draw_arc(Vector2.ZERO, 12.0, 0.4, 2.6, 10, Color("c9a26a"), 2.0)
		"rope_coil":
			for r: float in [12.0, 9.0, 6.0, 3.0]:
				draw_arc(Vector2.ZERO, r, 0.0, TAU, 20, Color("c9a26a"), 2.0)
			draw_line(Vector2(12, 0), Vector2(26, 6), Color("c9a26a"), 2.0)
		"barrels":
			for p: Vector2 in [Vector2(-12, -8), Vector2(12, -8), Vector2(0, 12)]:
				draw_circle(p, 12.0, OUTLINE)
				draw_circle(p, 11.0, Color("8a5a3b"))
				draw_arc(p, 8.0, 0.0, TAU, 16, Color("4a3a2a"), 1.0)
		"lifebuoy":
			draw_arc(Vector2.ZERO, 11.0, 0.0, TAU, 24, OUTLINE, 9.0)
			for k in 4:
				draw_arc(Vector2.ZERO, 11.0, k * PI * 0.5, k * PI * 0.5 + PI * 0.5, 8, Color("d9534f") if k % 2 == 0 else Color("f4f1ea"), 7.0)
		"fish_net":
			for i in 7:
				draw_line(Vector2(-30 + i * 10, -20), Vector2(-24 + i * 8, 20), Color(0.6, 0.55, 0.4, 0.7), 1.0)
				draw_line(Vector2(-30, -20 + i * 6.6), Vector2(30, -18 + i * 6.4), Color(0.6, 0.55, 0.4, 0.7), 1.0)
			for p: Vector2 in [Vector2(-30, -20), Vector2(30, 20), Vector2(28, -18)]:
				draw_circle(p, 2.5, Color("f2a03a"))
		"fish_crate":
			_box(Rect2(-22, -16, 44, 32), Color("9a7048"))
			for k in 5:
				var p := Vector2(-14 + k * 7, -6 + (k % 2) * 10)
				draw_colored_polygon(Shapes.ellipse(p, 6, 2.5, 10), Color("aab4c0"))
				draw_colored_polygon(PackedVector2Array([p + Vector2(5, 0), p + Vector2(9, -3), p + Vector2(9, 3)]), Color("8a96a4"))
		"machine":
			_box(Rect2(-36, -26, 72, 52), Color("6a7a8a"))
			draw_rect(Rect2(-30, -20, 30, 18), Color("2a3a4a"))
			draw_circle(Vector2(18, -10), 8.0, Color("c9ced2"))
			draw_line(Vector2(18, -10), Vector2(22, -15), Color("d9534f"), 2.0)
			for i in 3:
				draw_circle(Vector2(-24 + i * 10, 14), 3.0, [Color("5ad16a"), Color("f2c14e"), Color("d9534f")][i])
		"robot_arm":
			draw_circle(Vector2.ZERO, 14.0, OUTLINE)
			draw_circle(Vector2.ZERO, 13.0, Color("f2c14e"))
			draw_line(Vector2.ZERO, Vector2(30, -14), Color("4a4e54"), 6.0)
			draw_line(Vector2(30, -14), Vector2(44, 4), Color("4a4e54"), 5.0)
			draw_circle(Vector2(30, -14), 4.0, Color("2a2c30"))
		"pallet_stack":
			_box(Rect2(-24, -24, 48, 48), Color("b08a5a"))
			for k in 3:
				draw_rect(Rect2(-22, -20 + k * 15, 44, 4), Color("8a6a42"))
			_box(Rect2(-14, -14, 28, 28), Color("c8955a"))
		"control_panel":
			_box(Rect2(-26, -12, 52, 24), Color("3a3e44"))
			for i in 5:
				draw_rect(Rect2(-22 + i * 9, -6, 6, 5), [Color("5ad16a"), Color("d9534f"), Color("f2c14e")][i % 3])
			draw_rect(Rect2(-20, 3, 40, 4), Color("9ae0ff"))
		"gear_pile":
			for p: Vector2 in [Vector2(-8, -4), Vector2(8, 2), Vector2(-2, 8)]:
				for k in 8:
					draw_line(p + Vector2.from_angle(TAU * k / 8.0) * 8.0, p + Vector2.from_angle(TAU * k / 8.0) * 11.0, Color("8a8e94"), 3.0)
				draw_circle(p, 9.0, Color("8a8e94"))
				draw_circle(p, 3.0, Color("3a3e44"))
		"cat_bed":
			draw_circle(Vector2.ZERO, 18.0, OUTLINE)
			draw_circle(Vector2.ZERO, 17.0, color)
			draw_circle(Vector2.ZERO, 11.0, color.lightened(0.35))
			draw_circle(Vector2(-4, 3), 2.0, Color(1, 1, 1, 0.5))
	draw_set_transform(Vector2.ZERO)


## Filled rectangle with an outline and a soft drop shadow.
func _box(r: Rect2, fill: Color) -> void:
	draw_rect(Rect2(r.position + Vector2(2, 3), r.size), Color(0, 0, 0, 0.18))
	draw_rect(r, fill)
	draw_rect(r, OUTLINE, false, 1.0)
